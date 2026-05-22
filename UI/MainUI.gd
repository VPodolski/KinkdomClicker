extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $HBoxContainer/LeftPanel/GoldLabel
@onready var gold_button = $HBoxContainer/LeftPanel/GoldButton

@onready var right_panel = $HBoxContainer/RightPanel
@onready var buildings_container = $HBoxContainer/RightPanel/BuildingTab/Buildings/BuildingsContainer
@onready var upgrades_container = $HBoxContainer/RightPanel/ForgeTab/Upgrades/UpgradesContainer
@onready var buy_all_upgrades_button = $HBoxContainer/RightPanel/ForgeTab/BuyAllUpgradesButton

@onready var achievements_tab = $HBoxContainer/RightPanel/AchievementsTab
@onready var multiplier_label = $HBoxContainer/RightPanel/AchievementsTab/MultiplierLabel
@onready var achievements_container = $HBoxContainer/RightPanel/AchievementsTab/ScrollContainer/AchievementsContainer

@onready var ascension_tab = $HBoxContainer/LeftPanel/AscensionPanel
@onready var prestige_current_label = $HBoxContainer/LeftPanel/AscensionPanel/CurrentBonusLabel
@onready var prestige_expected_label = $HBoxContainer/LeftPanel/AscensionPanel/ExpectedBonusLabel
@onready var ascend_button = $HBoxContainer/LeftPanel/AscensionPanel/AscendButton

var building_item_scene = preload("res://ui/BuildingItem.tscn")
var upgrade_item_scene = preload("res://ui/UpgradeItem.tscn")
var floating_text_scene = preload("res://ui/FloatingText.tscn")

var ui_update_timer = 0.0
var notifications_container: VBoxContainer

func _ready():
	apply_medieval_theme()
	await get_tree().process_frame
	var tab_idx = achievements_tab.get_index()
	right_panel.set_tab_hidden(tab_idx, true)
	
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	game.achievement_unlocked.connect(_on_achievement_unlocked)
	ascend_button.pressed.connect(_on_ascend_pressed)
	buy_all_upgrades_button.pressed.connect(_on_buy_all_upgrades_pressed)

	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()
	update_achievements_ui()
	update_prestige_ui()
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
			update_gold(game.economy.gold)
			update_upgrades_ui()
			update_buildings_ui()
			update_visibility()
			update_prestige_ui()

# =========================
# 🖱️ INPUT
# =========================

func _on_gold_button_pressed():
	var click_amount = game.get_click_value()

	# Выполняем сам клик
	game.on_click()

	# Визуальные эффекты
	spawn_floating_text(click_amount)
	animate_button_press(gold_button)


func _on_building_pressed(index, amount = 1):
	game.buy_building(index, amount)


func _on_upgrade_pressed(upgrade: UpgradeData) -> void:
	game.start_upgrade(upgrade)

func _on_buy_all_upgrades_pressed() -> void:
	game.buy_all_affordable_upgrades()


func _on_achievement_unlocked(achievement) -> void:
	update_achievements_ui()
	show_achievement_notification(achievement)

# =========================
# 💰 UI ОБНОВЛЕНИЕ
# =========================

func update_gold(value):
	var text ="Золото: %.1f" % value + \
	"\n(+" + str(game.currentGoldPerSecond) + "/сек)"
	
	gold_label.text = str(text)


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
		var is_unlocked = current_gold >= upgrade.cost and not upgrade.is_crafting

		# Текст предпросмотра эффекта
		var preview_text = ""
		if upgrade.has_method("get_preview_text"):
			preview_text = upgrade.get_preview_text(game)

		# Оставшееся время крафта
		var remaining_text = ""
		if upgrade.is_crafting:
			var remaining = max(0.0, upgrade.base_time - upgrade.progress)
			remaining_text = "%.1f сек" % remaining

		# Передаём все параметры в UpgradeItem
		child.update_ui(
			current_gold,
			is_unlocked,
			preview_text,
			remaining_text
		)

	var affordable_upgrades = game.get_affordable_upgrades()
	if affordable_upgrades.size() > 0:
		buy_all_upgrades_button.text = "Купить всё (%d)" % affordable_upgrades.size()
		buy_all_upgrades_button.disabled = false
	else:
		buy_all_upgrades_button.text = "Купить всё"
		buy_all_upgrades_button.disabled = true

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
		
func update_achievements_tab_visibility() -> void:
	var tab_index = achievements_tab.get_index()
	var has_achievements = game.get_unlocked_achievement_count() > 0

	right_panel.set_tab_hidden(tab_index, not has_achievements)
# =========================
# 👁️ VISIBILITY
# =========================

func update_visibility() -> void:
	var visible_upgrades = 0
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

		var current_gold = game.economy.gold
		var max_visible_cost = current_gold * 1.5

		# Если золота мало (например, 0), всё равно показываем
		# хотя бы самые дешёвые апгрейды.
		if current_gold < 1.0:
			max_visible_cost = 100.0

		# Слишком дорогие скрываем.
		if upgrade.cost > max_visible_cost:
			child.visible = false
			continue

		# Показываем апгрейд.
		child.visible = true
		visible_upgrades += 1

		# Если пока нельзя купить — делаем полупрозрачным.
		if upgrade.cost > current_gold:
			child.modulate.a = 0.5
		else:
			child.modulate.a = 1.0
			
	var forge_tab = $HBoxContainer/RightPanel/ForgeTab
	if forge_tab:
		var forge = game.buildings.get_building_by_name("Кузница")
		var has_forge = forge != null and forge.count > 0
		right_panel.set_tab_hidden(forge_tab.get_index(), not has_forge or visible_upgrades == 0)

	var building_tab = $HBoxContainer/RightPanel/BuildingTab
	if building_tab:
		var visible_buildings = buildings_container.get_child_count()
		right_panel.set_tab_hidden(building_tab.get_index(), visible_buildings == 0)

# =========================
# 🔽 SORT
# =========================

func sort_upgrade_items():
	var items = upgrades_container.get_children()
	
	items.sort_custom(func(a, b):
		var a_can = a.upgrade.cost <= game.economy.gold
		var b_can = b.upgrade.cost <= game.economy.gold
		
		if a_can != b_can:
			return a_can
		
		return a.upgrade.cost < b.upgrade.cost
	)
	
	for i in range(items.size()):
		upgrades_container.move_child(items[i], i)

func spawn_floating_text(amount: float) -> void:
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
	if prestige_current_label == null or prestige_expected_label == null or ascend_button == null:
		return

	# Текущий бонус престижа
	var current_bonus = (game.economy.prestige_multiplier - 1.0) * 100.0
	prestige_current_label.text = "Текущий бонус престижа: +%.1f%%" % current_bonus

	# Ожидаемый бонус престижа при сбросе
	var expected_bonus = game.get_expected_prestige_bonus(game.economy.gold) * 100.0
	prestige_expected_label.text = "Ожидаемый бонус при сбросе: +%.1f%%" % expected_bonus

	# Кнопка активна при золоте >= 500 000
	var can_ascend = game.economy.gold >= 500000.0
	ascend_button.disabled = not can_ascend

	# Показываем задизейбленную кнопку возвышения, когда до стоимости покупки не хватает 35% (т.е. 500000 * 0.65 = 325000)
	ascension_tab.visible = game.economy.gold >= 325000.0

	if can_ascend:
		ascend_button.text = "Совершить Возвышение!"
	else:
		ascend_button.text = "Совершить Возвышение (требуется 500K золота)"


func _on_ascend_pressed():
	if game.ascend():
		create_buildings_ui()
		create_upgrades_ui()
		update_achievements_ui()
		update_prestige_ui()
		right_panel.current_tab = 0

func apply_medieval_theme() -> void:
	var th = Theme.new()
	
	# Medieval Colors
	var color_wood_dark = Color("#2C1E16")
	var color_wood_medium = Color("#4A3320")
	var color_wood_light = Color("#6B4C31")
	var color_gold = Color("#C5A059")
	var color_gold_hover = Color("#E8C77B")
	var color_gold_dark = Color("#8B6E32")
	var color_parchment = Color("#E8DCC4")
	var color_text_light = Color("#FCEFC7")
	
	# PanelContainer / Panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = color_wood_dark
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = color_gold_dark
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.shadow_color = Color(0,0,0, 0.6)
	panel_style.shadow_size = 6
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	th.set_stylebox("panel", "PanelContainer", panel_style)
	th.set_stylebox("panel", "Panel", panel_style)
	
	# Button Normal
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = color_wood_medium
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = color_gold_dark
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.content_margin_left = 10
	btn_normal.content_margin_right = 10
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	th.set_stylebox("normal", "Button", btn_normal)
	
	# Button Hover
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = color_wood_light
	btn_hover.border_color = color_gold_hover
	th.set_stylebox("hover", "Button", btn_hover)
	
	# Button Pressed
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = color_wood_dark
	btn_pressed.border_color = color_gold
	th.set_stylebox("pressed", "Button", btn_pressed)
	
	# Button Disabled
	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color("#222222")
	btn_disabled.border_color = Color("#444444")
	th.set_stylebox("disabled", "Button", btn_disabled)
	
	th.set_color("font_color", "Button", color_text_light)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", color_text_light)
	th.set_color("font_disabled_color", "Button", Color.GRAY)
	
	# TabContainer
	var tab_panel = panel_style.duplicate()
	th.set_stylebox("panel", "TabContainer", tab_panel)
	
	var tab_selected = btn_hover.duplicate()
	tab_selected.corner_radius_bottom_left = 0
	tab_selected.corner_radius_bottom_right = 0
	th.set_stylebox("tab_selected", "TabContainer", tab_selected)
	
	var tab_unselected = btn_normal.duplicate()
	tab_unselected.corner_radius_bottom_left = 0
	tab_unselected.corner_radius_bottom_right = 0
	tab_unselected.content_margin_top = 6
	tab_unselected.content_margin_bottom = 6
	th.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	
	# ScrollBar
	var scroll = StyleBoxFlat.new()
	scroll.bg_color = color_wood_dark
	scroll.corner_radius_top_left = 4
	scroll.corner_radius_top_right = 4
	scroll.corner_radius_bottom_left = 4
	scroll.corner_radius_bottom_right = 4
	scroll.content_margin_left = 10
	scroll.content_margin_right = 10
	scroll.content_margin_top = 10
	scroll.content_margin_bottom = 10
	th.set_stylebox("scroll", "VScrollBar", scroll)
	th.set_stylebox("scroll", "HScrollBar", scroll)
	
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = color_gold_dark
	grabber.corner_radius_top_left = 4
	grabber.corner_radius_top_right = 4
	grabber.corner_radius_bottom_left = 4
	grabber.corner_radius_bottom_right = 4
	th.set_stylebox("grabber", "VScrollBar", grabber)
	th.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	th.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	
	# Progress Bar
	var prog_bg = StyleBoxFlat.new()
	prog_bg.bg_color = color_wood_dark
	prog_bg.border_width_left = 2
	prog_bg.border_width_top = 2
	prog_bg.border_width_right = 2
	prog_bg.border_width_bottom = 2
	prog_bg.border_color = color_gold_dark
	th.set_stylebox("background", "ProgressBar", prog_bg)
	
	var prog_fg = StyleBoxFlat.new()
	prog_fg.bg_color = color_gold
	th.set_stylebox("fill", "ProgressBar", prog_fg)
	
	# Labels
	th.set_color("font_color", "Label", color_text_light)
	
	self.theme = th
	
	# Global Background (LeftPanel)
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#1A110B") # very dark wood / stone
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)
	move_child(bg, 0)
