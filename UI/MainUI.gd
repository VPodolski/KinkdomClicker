extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $RootVBox/TopPanel/TopHBox/GoldLabel

@onready var right_panel = $RootVBox/HBoxContainer/RightPanel
@onready var buildings_container = $RootVBox/HBoxContainer/RightPanel/BuildingTab/Buildings/BuildingsContainer
@onready var upgrades_container = $RootVBox/HBoxContainer/RightPanel/ForgeTab/Upgrades/UpgradesContainer
@onready var buy_all_upgrades_button = $RootVBox/HBoxContainer/RightPanel/ForgeTab/BuyAllUpgradesButton

@onready var achievements_tab = $RootVBox/HBoxContainer/RightPanel/AchievementsTab
@onready var multiplier_label = $RootVBox/HBoxContainer/RightPanel/AchievementsTab/MultiplierLabel
@onready var achievements_container = $RootVBox/HBoxContainer/RightPanel/AchievementsTab/ScrollContainer/AchievementsContainer

@onready var ascension_tab = $RootVBox/TopPanel/TopHBox/AscensionPanel
@onready var prestige_label = $RootVBox/TopPanel/TopHBox/AscensionPanel/PrestigeLabel
@onready var ascend_button = $RootVBox/TopPanel/TopHBox/AscensionPanel/AscendButton

@onready var confirm_dialog = $AscensionConfirmDialog

@onready var mode_toggle_button = $RootVBox/TopPanel/TopHBox/ModeToggleButton
@onready var kingdom_screen = $RootVBox/HBoxContainer
@onready var war_screen = $RootVBox/WarScreen
@onready var troops_container = $RootVBox/WarScreen/RightPanel/Обучение/ScrollContainer/TroopsContainer
@onready var war_info_label = $RootVBox/WarScreen/LeftPanel/Panel/VBoxContainer/WarInfo
@onready var war_visualizer = $RootVBox/WarScreen/LeftPanel/Panel/VBoxContainer/WarVisualizer
@onready var commanders_container = $"RootVBox/WarScreen/RightPanel/Полководцы/ScrollContainer/CommandersContainer"

var building_item_scene = preload("res://ui/BuildingItem.tscn")
var upgrade_item_scene = preload("res://ui/UpgradeItem.tscn")
var floating_text_scene = preload("res://ui/FloatingText.tscn")
var troop_item_scene = preload("res://UI/TroopItem.tscn")
var commander_item_scene = preload("res://UI/CommanderItem.tscn")
var battle_results_scene = preload("res://UI/BattleResultsWindow.tscn")

var ui_update_timer = 0.0
var notifications_container: VBoxContainer
var battle_results_window: BattleResultsWindow

func _ready():
	apply_tabular_fonts()
	await get_tree().process_frame
	var tab_idx = achievements_tab.get_index()
	right_panel.set_tab_hidden(tab_idx, true)
	
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.buildings_changed.connect(update_troops_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	game.achievement_unlocked.connect(_on_achievement_unlocked)
	if game.has_signal("upgrade_completed"):
		game.upgrade_completed.connect(_on_upgrade_completed)
		
	mode_toggle_button.pressed.connect(_on_mode_toggle_pressed)
	game.war.military_power_changed.connect(update_war_info)
	game.war.troops_changed.connect(update_troops_ui)
	game.war.troops_changed.connect(update_commanders_ui)
	game.war.troops_changed.connect(war_visualizer.update_visuals)
	game.expeditions.expedition_finished.connect(_on_expedition_finished)
		
	if not ascend_button.pressed.is_connected(_on_ascend_pressed):
		ascend_button.pressed.connect(_on_ascend_pressed)
	buy_all_upgrades_button.pressed.connect(_on_buy_all_upgrades_pressed)

	battle_results_window = battle_results_scene.instantiate()
	add_child(battle_results_window)

	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()
	update_achievements_ui()
	update_prestige_ui()
	create_troops_ui()
	create_commanders_ui()
	check_war_mode_unlock()
	right_panel.current_tab = 0

	notifications_container = VBoxContainer.new()
	notifications_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	notifications_container.set_anchor(SIDE_LEFT, 0.0)
	notifications_container.set_anchor(SIDE_BOTTOM, 1.0)
	notifications_container.set_offset(SIDE_LEFT, 20)
	notifications_container.set_offset(SIDE_BOTTOM, -20)
	notifications_container.grow_horizontal = Control.GROW_DIRECTION_END
	notifications_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	notifications_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notifications_container)

	right_panel.set_tab_title(0, "Постройки")
	right_panel.set_tab_title(1, "Кузница")
	right_panel.set_tab_title(2, "Достижения")

func _process(delta):
	ui_update_timer += delta
	
	if ui_update_timer >= 0.05: # 20 раз в секунду
		ui_update_timer = 0.0
		update_gold(game.economy.gold)
		update_upgrades_ui()
		update_buildings_ui()
		update_commanders_ui()
		update_visibility()
		update_prestige_ui()

# =========================
# 🖱️ INPUT
# =========================

func _on_gold_button_pressed():
	pass


func _on_building_pressed(index, amount = 1):
	game.buy_building(index, amount)


func _on_upgrade_pressed(upgrade: UpgradeData) -> void:
	game.start_upgrade(upgrade)

func _on_buy_all_upgrades_pressed() -> void:
	game.buy_all_affordable_upgrades()


func _on_achievement_unlocked(achievement) -> void:
	update_achievements_ui()
	show_achievement_notification(achievement)

func _on_upgrade_completed(upgrade) -> void:
	show_upgrade_notification(upgrade)

# =========================
# ⚔️ ВОЙНА UI
# =========================

func _on_mode_toggle_pressed():
	if kingdom_screen.visible:
		kingdom_screen.visible = false
		war_screen.visible = true
		mode_toggle_button.text = "🏰 Королевство"
	else:
		kingdom_screen.visible = true
		war_screen.visible = false
		mode_toggle_button.text = "⚔️ Война"

func check_war_mode_unlock():
	var barracks = game.buildings.get_building_by_name("Казармы")
	if barracks and barracks.count > 0:
		mode_toggle_button.visible = true
	else:
		mode_toggle_button.visible = false

func update_war_info(power):
	war_info_label.text = "Военная мощь: %s" % game.format_number(power)

func create_troops_ui():
	for child in troops_container.get_children():
		child.queue_free()
	
	for troop in game.war.troops:
		var item = troop_item_scene.instantiate()
		troops_container.add_child(item)
		item.setup(troop)
		item.train_pressed.connect(game.war.start_training)
	update_troops_ui()
	war_visualizer.update_visuals()

func create_commanders_ui():
	for child in commanders_container.get_children():
		child.queue_free()
		
	for troop in game.war.troops:
		var item = commander_item_scene.instantiate()
		commanders_container.add_child(item)
		item.setup(troop)
	update_commanders_ui()

func update_commanders_ui():
	for child in commanders_container.get_children():
		if child is CommanderItem:
			var is_unlocked = game.war.is_troop_unlocked(child.troop)
			child.visible = is_unlocked
			if is_unlocked:
				var speed = child.troop.speed_multiplier
				if child.troop.required_building != "":
					var b = game.buildings.get_building_by_id(child.troop.required_building)
					if b and b.count > 0:
						speed *= (1.0 + b.count * 0.05)
				child.update_ui(speed)

func update_troops_ui():
	for child in troops_container.get_children():
		if child is TroopItem:
			var is_unlocked = game.war.is_troop_unlocked(child.troop)
			child.visible = is_unlocked
			if is_unlocked:
				var speed = child.troop.speed_multiplier
				if child.troop.required_building != "":
					var b = game.buildings.get_building_by_id(child.troop.required_building)
					if b and b.count > 0:
						speed *= (1.0 + b.count * 0.05)
				child.update_ui(game.economy.gold, speed, game.currentBaseNetIncome, game.economy.upkeep_reduction_multiplier)

func _on_expedition_finished(result_data: Dictionary) -> void:
	if battle_results_window:
		battle_results_window.setup(result_data, game)

# =========================
# 💰 UI ОБНОВЛЕНИЕ
# =========================

func update_gold(value):
	var text = "🪙 Золото: " + game.format_number(value) + " (+" + game.format_number(game.currentGoldPerSecond) + " 🪙/сек)"
	
	var chapel = game.buildings.get_building_by_name("Часовня")
	if game.economy.lifetime_prayers.is_greater_than(0) or (chapel and chapel.count > 0):
		text += "   |   🙏 Молитвы: " + game.format_number(game.economy.prayers)
	
	gold_label.text = text
	update_troops_ui()


# =========================
# 🏗️ BUILDINGS UI
# =========================

func create_buildings_ui():
	for child in buildings_container.get_children():
		child.queue_free()
	
	for i in range(game.buildings.buildings.size()):
		var b = game.buildings.buildings[i]
		
		var item = building_item_scene.instantiate()
		buildings_container.add_child(item)
		
		item.setup(b, i)
		item.buy_pressed.connect(_on_building_pressed)


func update_buildings_ui():
	for child in buildings_container.get_children():
		child.update_ui(game.economy.gold)
	check_war_mode_unlock()


# =========================
# ⚙️ UPGRADES UI
# =========================

func create_upgrades_ui():
	for child in upgrades_container.get_children():
		child.queue_free()
	
	for i in range(game.upgrades.upgrades.size()):
		var u = game.upgrades.upgrades[i]
		
		var item = upgrade_item_scene.instantiate()
		upgrades_container.add_child(item)
		
		item.setup(u, i)
		item.craft_pressed.connect(_on_upgrade_pressed)


func update_upgrades_ui():
	for child in upgrades_container.get_children():
		var upgrade = child.upgrade

		# Текущее количество золота
		var current_gold = game.economy.gold

		# Доступен ли апгрейд для покупки
		var is_unlocked = current_gold.is_greater_equal(upgrade.cost) and not upgrade.is_crafting

		# Текст предпросмотра эффекта
		var preview_text = ""
		if upgrade.has_method("get_preview_text"):
			preview_text = upgrade.get_preview_text(game)

		# Оставшееся время крафта
		var remaining_text = ""
		if upgrade.is_crafting:
			var speed = game.get_forge_speed_multiplier()
			var remaining = max(0.0, (upgrade.base_time - upgrade.progress) / speed)
			remaining_text = "%.1f сек" % remaining

		# Передаём все параметры в UpgradeItem
		child.update_ui(
			current_gold,
			is_unlocked,
			preview_text,
			remaining_text
		)

	var available_upgrades_count = 0
	for u in game.upgrades.upgrades:
		if not u.is_crafting and not game.upgrades.active_upgrades.has(u):
			available_upgrades_count += 1
			
	var affordable_upgrades = game.get_affordable_upgrades()
	var forge_tab_idx = right_panel.get_node("ForgeTab").get_index()
	
	if available_upgrades_count > 0:
		right_panel.set_tab_title(forge_tab_idx, "Кузница (%d)" % available_upgrades_count)
	else:
		right_panel.set_tab_title(forge_tab_idx, "Кузница")
		
	if affordable_upgrades.size() > 0:
		buy_all_upgrades_button.text = "Купить всё (%d)" % affordable_upgrades.size()
		buy_all_upgrades_button.disabled = false
	else:
		buy_all_upgrades_button.text = "Купить всё"
		buy_all_upgrades_button.disabled = true
		
	buy_all_upgrades_button.visible = game.ascension.has_skill("buy_all")

	update_visibility()
	
func update_achievements_ui() -> void:
	var unlocked = game.achievements.get_unlocked_achievements()
	print("Unlocked achievements: ", unlocked.size())
	var tab_index = achievements_tab.get_index()
	if unlocked.is_empty():
		right_panel.set_tab_hidden(tab_index, true)
		return

	# Показываем вкладку
	right_panel.set_tab_hidden(tab_index, false)

	# Обновляем текст множителя
	var multiplier = game.achievements.get_income_multiplier()
	multiplier_label.text = "Бонус к доходу: x%s" % game.format_number(multiplier)

	# Удаляем старые элементы
	for child in achievements_container.get_children():
		child.queue_free()

	# Создаём новые элементы
	for achievement in unlocked:
		var item = VBoxContainer.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_label = Label.new()
		title_label.text = "🏆 " + achievement.title
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var description_label = Label.new()
		description_label.text = achievement.description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		item.add_child(title_label)
		item.add_child(description_label)

		achievements_container.add_child(item)

func show_achievement_notification(achievement) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2C1E16")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 3
	style.border_width_top = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = Color("#C5A059")
	style.shadow_color = Color(0,0,0, 0.7)
	style.shadow_size = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏆 Достижение разблокировано!"
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = achievement.title + "\n" + achievement.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	notifications_container.add_child(panel)
	
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(4.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
		
func show_upgrade_notification(upgrade) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1E2C28")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 3
	style.border_width_top = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = Color("#59C59A")
	style.shadow_color = Color(0,0,0, 0.7)
	style.shadow_size = 8
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🔨 Улучшение готово!"
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.8))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = upgrade.name + "\n" + upgrade.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	notifications_container.add_child(panel)
	
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(4.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func update_achievements_tab_visibility() -> void:
	var tab_index = achievements_tab.get_index()
	var has_achievements = game.get_unlocked_achievement_count() > 0

	right_panel.set_tab_hidden(tab_index, not has_achievements)
# =========================
# 👁️ VISIBILITY
# =========================

func update_visibility() -> void:
	var current_gold = game.economy.gold
	var max_visible_cost = current_gold.mul(1.5)
	if current_gold.is_less_than(1.0):
		max_visible_cost = BigNum.new(100.0, 0)
		
	var visible_upgrades = 0
	var first_unseen_upgrade_found = false
	for child in upgrades_container.get_children():
		var upgrade = child.upgrade

		# Если апгрейд уже завершён и находится в списке активных,
		# полностью скрываем его.
		if game.upgrades.active_upgrades.has(upgrade):
			child.visible = false
			continue

		# Если апгрейд сейчас создаётся — всегда показываем.
		if upgrade.is_crafting:
			child.visible = true
			child.modulate.a = 1.0
			visible_upgrades += 1
			continue

		if upgrade.cost.is_greater_than(max_visible_cost):
			if not first_unseen_upgrade_found:
				child.visible = true
				if not upgrade.has_been_seen:
					upgrade.is_masked = true
				else:
					upgrade.is_masked = false
				first_unseen_upgrade_found = true
				visible_upgrades += 1
			else:
				child.visible = false
		else:
			upgrade.has_been_seen = true
			upgrade.is_masked = false
			child.visible = true
			visible_upgrades += 1

		# Если пока нельзя купить — делаем полупрозрачным.
		if upgrade.cost.is_greater_than(current_gold):
			child.modulate.a = 0.5
		else:
			child.modulate.a = 1.0
			

	var visible_buildings = 0
	var first_unseen_found = false
	for child in buildings_container.get_children():
		var b = child.building
		
		if b.cost.is_greater_than(max_visible_cost) and not b.has_been_seen:
			if not first_unseen_found:
				b.is_masked = true
				child.visible = true
				first_unseen_found = true
				visible_buildings += 1
			else:
				child.visible = false
		else:
			b.has_been_seen = true
			b.is_masked = false
			child.visible = true
			visible_buildings += 1
			
		if b.cost.is_greater_than(current_gold) and b.count == 0:
			child.modulate.a = 0.5
		else:
			child.modulate.a = 1.0
			
	var forge_tab = $RootVBox/HBoxContainer/RightPanel/ForgeTab
	if forge_tab:
		var forge = game.buildings.get_building_by_name("Кузница")
		var has_forge = forge != null and forge.count > 0
		right_panel.set_tab_hidden(forge_tab.get_index(), not has_forge or visible_upgrades == 0)

	var building_tab = $RootVBox/HBoxContainer/RightPanel/BuildingTab
	if building_tab:
		right_panel.set_tab_hidden(building_tab.get_index(), visible_buildings == 0)

# =========================
# 🔽 SORT
# =========================

func sort_upgrade_items():
	var items = upgrades_container.get_children()
	
	items.sort_custom(func(a, b):
		var a_can = a.upgrade.cost.is_less_equal(game.economy.gold)
		var b_can = b.upgrade.cost.is_less_equal(game.economy.gold)
		
		if a_can != b_can:
			return a_can
		
		return a.upgrade.cost.is_less_than(b.upgrade.cost)
	)
	
	for i in range(items.size()):
		upgrades_container.move_child(items[i], i)

func spawn_floating_text(amount) -> void:
	var text = floating_text_scene.instantiate()

	text.text = "+" + game.format_number(amount)

	var mouse_pos = get_viewport().get_mouse_position()
	text.position = mouse_pos
	text.position += Vector2(
		randf_range(-20, 20),
		randf_range(-10, 10)
	)

	add_child(text)


# =========================
# 🔘 АНИМАЦИЯ КНОПКИ
# =========================

func animate_button_press(button: Control) -> void:
	var tween = create_tween()

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# Масштабируем относительно центра
	button.pivot_offset = button.size / 2.0

	tween.tween_property(
		button,
		"scale",
		Vector2(0.9, 0.9),
		0.05
	)

	tween.tween_property(
		button,
		"scale",
		Vector2.ONE,
		0.10
	)


func update_prestige_ui():
	if prestige_label == null or ascend_button == null:
		return

	var current_bonus = (game.economy.prestige_multiplier - 1.0) * 100.0
	var prayers_sec = game.buildings.get_total_prayer_income(game.economy.prayer_multiplier)
	prestige_label.text = "Бонус: +%s%%  |  🙏/сек: %s" % [game.format_number(current_bonus), game.format_number(prayers_sec)]

	var has_chapel = false
	var chapel = game.buildings.get_building_by_name("Часовня")
	if chapel and chapel.count > 0:
		has_chapel = true
		
	var can_ascend = has_chapel or game.economy.lifetime_prayers.is_greater_than(0.0)
	ascension_tab.visible = can_ascend

	if can_ascend:
		ascend_button.disabled = false
		ascend_button.text = "Открыть Древо Возвышения"
	else:
		ascend_button.disabled = true
		ascend_button.text = "Возвышение недоступно"

var ascension_shop = null

func _on_ascend_pressed():
	confirm_dialog.popup_centered()

func _on_ascension_confirmed():
	if ascension_shop == null:
		var scene = preload("res://UI/AscensionShop.tscn")
		ascension_shop = scene.instantiate()
		add_child(ascension_shop)
	ascension_shop.open()

func _on_rebirth_completed():
	create_buildings_ui()
	create_upgrades_ui()
	update_achievements_ui()
	update_prestige_ui()
	
	kingdom_screen.visible = true
	war_screen.visible = false
	mode_toggle_button.text = "⚔️ Война"
	check_war_mode_unlock()
	
	right_panel.current_tab = 0

func apply_tabular_fonts() -> void:
	if not self.theme:
		return
	var font_var = FontVariation.new()
	font_var.base_font = ThemeDB.fallback_font
	var tnum_tag = TextServerManager.get_primary_interface().name_to_tag("tnum")
	font_var.opentype_features = { tnum_tag: 1 }
	self.theme.set_font("font", "Label", font_var)
	self.theme.set_font("font", "Button", font_var)
	
	# Global Background
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#181716") # dark stone
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)
	move_child(bg, 0)
func _input(event):
	if event is InputEventKey and event.keycode == KEY_F11 and event.pressed and not event.echo:
		_toggle_fullscreen()

func _toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
