extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $RootVBox/TopPanel/TopVBox/TopHBox/GoldLabel

@onready var right_panel = $RootVBox/HBoxContainer/RightPanel
@onready var upgrades_container = $RootVBox/HBoxContainer/RightPanel/ForgeTab/Upgrades/UpgradesContainer
@onready var buy_all_upgrades_button = $RootVBox/HBoxContainer/RightPanel/ForgeTab/BuyAllUpgradesButton

@onready var achievements_tab = $RootVBox/HBoxContainer/RightPanel/AchievementsTab
@onready var multiplier_label = $RootVBox/HBoxContainer/RightPanel/AchievementsTab/MultiplierLabel
@onready var achievements_container = $RootVBox/HBoxContainer/RightPanel/AchievementsTab/ScrollContainer/AchievementsContainer

var building_containers = {}
var popup_forge: Control
var popup_ach: Control
var forge_btn: Button
var ach_btn: Button
var wipe_btn: Button

@onready var ascension_tab = $RootVBox/TopPanel/TopVBox/TopHBox/AscensionPanel
@onready var prestige_label = $RootVBox/TopPanel/TopVBox/TopHBox/AscensionPanel/PrestigeLabel
@onready var ascend_button = $RootVBox/TopPanel/TopVBox/TopHBox/AscensionPanel/AscendButton

@onready var confirm_dialog = $AscensionConfirmDialog

@onready var kingdom_btn = $RootVBox/TopPanel/TopVBox/NavHBox/KingdomBtn
@onready var war_btn = $RootVBox/TopPanel/TopVBox/NavHBox/WarBtn
@onready var archeology_btn = $RootVBox/TopPanel/TopVBox/NavHBox/ArcheologyBtn

@onready var kingdom_screen = $RootVBox/HBoxContainer
@onready var war_screen = $RootVBox/WarScreen
@onready var archeology_screen = $RootVBox/ArcheologyScreen

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
var exp_result_scene = preload("res://UI/ExpeditionResultWindow.tscn")
var artifact_item_scene = preload("res://UI/ArtifactItem.tscn")
var kingdom_artifact_slot_scene = preload("res://UI/KingdomArtifactSlot.tscn")

var ui_update_timer = 0.0
var notifications_container: VBoxContainer
var battle_results_window: BattleResultsWindow
var exp_result_window: ExpeditionResultWindow

func _ready():
	apply_tabular_fonts()
	
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.buildings_changed.connect(update_troops_ui)
	game.buildings_changed.connect(update_archeology_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	game.achievement_unlocked.connect(_on_achievement_unlocked)
	if game.has_signal("upgrade_completed"):
		game.upgrade_completed.connect(_on_upgrade_completed)
		
	kingdom_btn.pressed.connect(func(): _on_mode_selected(0))
	war_btn.pressed.connect(func(): _on_mode_selected(1))
	archeology_btn.pressed.connect(func(): _on_mode_selected(2))
	
	game.war.military_power_changed.connect(update_war_info)
	game.war.troops_changed.connect(update_troops_ui)
	game.war.troops_changed.connect(update_commanders_ui)
	game.war.troops_changed.connect(war_visualizer.update_visuals)
	game.expeditions.expedition_finished.connect(_on_expedition_finished)
	
	game.archeology.archeologists_changed.connect(update_archeology_ui)
	game.archeology.artifacts_changed.connect(update_artifacts_ui)
	game.archeology.expedition_updated.connect(_on_arch_expedition_updated)
	game.archeology.expedition_completed.connect(_on_arch_expedition_completed)
	
	game.developer_mode_toggled.connect(func(is_active): if wipe_btn: wipe_btn.visible = is_active)
	
	_setup_archeology_ui()
		
	if not ascend_button.pressed.is_connected(_on_ascend_pressed):
		ascend_button.pressed.connect(_on_ascend_pressed)
	buy_all_upgrades_button.pressed.connect(_on_buy_all_upgrades_pressed)

	battle_results_window = battle_results_scene.instantiate()
	add_child(battle_results_window)
	
	exp_result_window = exp_result_scene.instantiate()
	add_child(exp_result_window)

	var war_tabs = war_screen.get_node("RightPanel")
	if war_tabs is TabContainer:
		war_tabs.tab_changed.connect(func(_tab): reset_all_scrolls())
		
	right_panel.tab_changed.connect(func(_tab): reset_all_scrolls())

	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()
	update_achievements_ui()
	update_prestige_ui()
	check_modes_unlock()
	create_troops_ui()
	create_commanders_ui()
	check_modes_unlock()
	update_war_info(game.war.total_military_power)
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
	
	if game.offline_report and not game.offline_report.is_empty():
		call_deferred("show_offline_popup")

func show_offline_popup():
	var report = game.offline_report
	game.offline_report = {} # clear
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)
	
	var time_sec = int(report.get("time", 0))
	var hours = time_sec / 3600
	var minutes = (time_sec % 3600) / 60
	var secs = time_sec % 60
	var time_str = ""
	if hours > 0: time_str += str(hours) + " ч. "
	if minutes > 0: time_str += str(minutes) + " мин. "
	time_str += str(secs) + " сек."
	
	var time_lbl = Label.new()
	time_lbl.text = "⏳ Вас не было: " + time_str
	time_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(time_lbl)
	vbox.add_child(HSeparator.new())
	
	var gold_lbl = Label.new()
	gold_lbl.text = "🪙 Золота добыто: " + game.format_number(report.get("gold_earned", 0.0))
	vbox.add_child(gold_lbl)
	
	var prayers = report.get("prayers_earned", BigNum.new(0.0))
	if prayers.is_greater_than(0.0):
		var pray_lbl = Label.new()
		pray_lbl.text = "🙏 Молитв получено: " + game.format_number(prayers)
		vbox.add_child(pray_lbl)
		
	var upgrades = report.get("upgrades", [])
	if upgrades.size() > 0:
		vbox.add_child(HSeparator.new())
		var upg_lbl = Label.new()
		upg_lbl.text = "🔨 Завершено улучшений: " + str(upgrades.size())
		upg_lbl.add_theme_color_override("font_color", Color("#59C59A"))
		vbox.add_child(upg_lbl)
		for u in upgrades:
			var l = Label.new()
			l.text = " - " + str(u)
			vbox.add_child(l)
			
	var expeditions = report.get("expeditions", [])
	if expeditions.size() > 0:
		vbox.add_child(HSeparator.new())
		var exp_lbl = Label.new()
		exp_lbl.text = "⚔️ Завершено походов: " + str(expeditions.size())
		exp_lbl.add_theme_color_override("font_color", Color("#C55959"))
		vbox.add_child(exp_lbl)
		for res in expeditions:
			var l = Label.new()
			if res.get("won", false):
				l.text = " - Победа! Добыто: " + game.format_number(res.get("gold_reward", 0.0)) + " 🪙"
			elif res.get("is_scout_mission", false):
				l.text = " - Разведка завершена."
			else:
				l.text = " - Поражение."
			vbox.add_child(l)
			
	var archeology = report.get("archeology", [])
	if archeology.size() > 0:
		vbox.add_child(HSeparator.new())
		var arch_lbl = Label.new()
		arch_lbl.text = "🗺️ Археологических экспедиций: " + str(archeology.size())
		arch_lbl.add_theme_color_override("font_color", Color("#C5A059"))
		vbox.add_child(arch_lbl)
		for res in archeology:
			var l = Label.new()
			if res.get("success", false):
				l.text = " - Успех! Добыто: " + game.format_number(res.get("gold", 0.0)) + " 🪙. Артефактов: " + str(res.get("artifacts", []).size())
			else:
				l.text = " - Экспедиция провалена. Погибло археологов: " + str(res.get("dead", 0))
			vbox.add_child(l)
			
	var troops = report.get("troops", {})
	if troops.size() > 0:
		vbox.add_child(HSeparator.new())
		var troop_lbl = Label.new()
		troop_lbl.text = "⚔️ Обучено войск: "
		troop_lbl.add_theme_color_override("font_color", Color("#5981C5"))
		vbox.add_child(troop_lbl)
		for t_name in troops.keys():
			var l = Label.new()
			l.text = " - " + t_name + ": " + str(troops[t_name])
			vbox.add_child(l)
			
	var arch_trained = report.get("archeologists_trained", 0)
	if arch_trained > 0:
		vbox.add_child(HSeparator.new())
		var l = Label.new()
		l.text = "⛺ Нанято археологов: " + str(arch_trained)
		l.add_theme_color_override("font_color", Color("#C8A252"))
		vbox.add_child(l)
		
	var commanders = report.get("commanders", [])
	if commanders.size() > 0:
		vbox.add_child(HSeparator.new())
		var comm_lbl = Label.new()
		comm_lbl.text = "🎖️ Полководцы: "
		comm_lbl.add_theme_color_override("font_color", Color("#B052C8"))
		vbox.add_child(comm_lbl)
		for msg in commanders:
			var l = Label.new()
			l.text = " - " + msg
			vbox.add_child(l)
	
	var popup = _create_popup(margin, "Офлайн Прогресс")
	popup.show()

func _process(delta):
	ui_update_timer += delta
	
	if ui_update_timer >= 0.1: # 10 раз в секунду
		ui_update_timer = 0.0
		check_modes_unlock()
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
	if notifications_container.get_child_count() < 5:
		show_upgrade_notification(upgrade)

# =========================
# ⚔️ ВОЙНА UI
# =========================

func reset_all_scrolls():
	var scrolls = [
		upgrades_container.get_parent(),
		achievements_container.get_parent(),
		troops_container.get_parent(),
		commanders_container.get_parent(),
		archeology_screen.get_node_or_null("RightPanel/InventoryPanel/VBox/ScrollContainer")
	]
	for cat in building_containers.values():
		scrolls.append(cat.get_parent())
	for s in scrolls:
		if s and s is ScrollContainer:
			s.scroll_vertical = 0

func _on_mode_selected(index):
	kingdom_screen.visible = (index == 0)
	war_screen.visible = (index == 1)
	archeology_screen.visible = (index == 2)
	
	kingdom_btn.modulate = Color(1.5, 1.5, 1.5) if index == 0 else Color(1, 1, 1)
	war_btn.modulate = Color(1.5, 1.5, 1.5) if index == 1 else Color(1, 1, 1)
	archeology_btn.modulate = Color(1.5, 1.5, 1.5) if index == 2 else Color(1, 1, 1)
	
	if index == 1:
		war_visualizer.update_visuals()
		
	reset_all_scrolls()

func check_modes_unlock():
	var barracks = game.buildings.get_building_by_name("Казармы")
	var arch_guild = game.buildings.get_building_by_name("Гильдия археологов")
	
	var has_war = false
	if barracks and barracks.count > 0: has_war = true
	
	var has_arch = false
	if arch_guild and arch_guild.count > 0: has_arch = true
	if game.archeology and game.archeology.archeology_unlocked_by_combat: has_arch = true
	
	if war_btn: war_btn.visible = has_war
	if archeology_btn: archeology_btn.visible = has_arch

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
		item.equip_requested.connect(_on_commander_equip_requested)
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
				var has_arch_skill = game.ascension.has_skill("arch_commander_artifact")
				child.update_ui(speed, has_arch_skill)

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

func _create_popup(content: Control, title: String, header_actions: Array = []) -> Control:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(700, 600)
	center.add_child(popup)
	
	var vbox = VBoxContainer.new()
	var header = HBoxContainer.new()
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 24)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(func(): overlay.hide())
	
	header.add_child(label)
	
	for action in header_actions:
		var p = action.get_parent()
		if p: p.remove_child(action)
		header.add_child(action)
		
	header.add_child(close_btn)
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())
	
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)
	
	popup.add_child(vbox)
	add_child(overlay)
	return overlay

func create_buildings_ui():
	if building_containers.is_empty():
		var building_tab = right_panel.get_node("BuildingTab")
		var military_tab = building_tab.duplicate()
		military_tab.name = "MilitaryTab"
		right_panel.add_child(military_tab)
		var religion_tab = building_tab.duplicate()
		religion_tab.name = "ReligionTab"
		right_panel.add_child(religion_tab)
		var arch_tab = building_tab.duplicate()
		arch_tab.name = "ArcheologyTab"
		right_panel.add_child(arch_tab)
		
		building_containers["general"] = building_tab.get_node("Buildings/BuildingsContainer")
		building_containers["military"] = military_tab.get_node("Buildings/BuildingsContainer")
		building_containers["religion"] = religion_tab.get_node("Buildings/BuildingsContainer")
		building_containers["archeology"] = arch_tab.get_node("Buildings/BuildingsContainer")
		
		# Reparent Forge and Ach
		var forge_tab = right_panel.get_node("ForgeTab")
		var ach_tab = right_panel.get_node("AchievementsTab")
		right_panel.remove_child(forge_tab)
		right_panel.remove_child(ach_tab)
		forge_tab.show() 
		ach_tab.show()
		
		var f_title = forge_tab.get_node_or_null("ForgeTitle")
		if f_title: f_title.queue_free()
		var f_queue = forge_tab.get_node_or_null("Queue")
		if f_queue: f_queue.queue_free()
		
		popup_forge = _create_popup(forge_tab, "Кузница", [buy_all_upgrades_button])
		popup_ach = _create_popup(ach_tab, "Достижения")
		
		var nav_hbox = $RootVBox/TopPanel/TopVBox/NavHBox
		forge_btn = Button.new()
		forge_btn.text = "🔨 Кузница"
		forge_btn.pressed.connect(func(): popup_forge.show())
		nav_hbox.add_child(forge_btn)
		
		ach_btn = Button.new()
		ach_btn.text = "🏆 Достижения"
		ach_btn.pressed.connect(func(): popup_ach.show())
		nav_hbox.add_child(ach_btn)
		
		wipe_btn = Button.new()
		wipe_btn.text = "⚠️ Вайп прогресса"
		wipe_btn.modulate = Color(1.0, 0.2, 0.2)
		wipe_btn.pressed.connect(func(): SaveManager.wipe_save())
		wipe_btn.visible = game.developer_mode_active
		nav_hbox.add_child(wipe_btn)
		
		right_panel.set_tab_title(0, "Общие")
		right_panel.set_tab_title(1, "Военные")
		right_panel.set_tab_title(2, "Религия")
		right_panel.set_tab_title(3, "Археология")

	for cat in building_containers:
		for child in building_containers[cat].get_children():
			child.queue_free()
	
	for i in range(game.buildings.buildings.size()):
		var b = game.buildings.buildings[i]
		
		var cat = "military"
		if b.id == "archeology_guild":
			cat = "archeology"
		elif b.prayer_income.is_greater_than(0):
			cat = "religion"
		elif b.income.is_greater_than(0) or b.id == "forge":
			cat = "general"
			
		var item = building_item_scene.instantiate()
		building_containers[cat].add_child(item)
		
		item.setup(b, i)
		item.buy_pressed.connect(_on_building_pressed)


func update_buildings_ui():
	if building_containers.is_empty(): return
	for cat in building_containers:
		for child in building_containers[cat].get_children():
			child.update_ui(game.economy.gold)
	check_modes_unlock()


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
	
	if forge_btn:
		if available_upgrades_count > 0:
			forge_btn.text = "🔨 Кузница (%d)" % available_upgrades_count
		else:
			forge_btn.text = "🔨 Кузница"
		
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
	panel.custom_minimum_size = Vector2(200, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2C1E16")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color("#C5A059")
	style.shadow_color = Color(0,0,0, 0.7)
	style.shadow_size = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏆 " + achievement.title
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = achievement.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc)
	
	notifications_container.add_child(panel)
	
	panel.modulate.a = 0.0
	var tween = create_tween()
	var ts = Engine.time_scale
	if ts <= 0.0: ts = 1.0
	tween.tween_property(panel, "modulate:a", 1.0, 0.5 * ts)
	tween.tween_interval(4.0 * ts)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5 * ts)
	tween.tween_callback(panel.queue_free)
		
func show_upgrade_notification(upgrade) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1E2C28")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color("#59C59A")
	style.shadow_color = Color(0,0,0, 0.7)
	style.shadow_size = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🔨 Улучшение: " + upgrade.name
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.8))
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = upgrade.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc)
	
	notifications_container.add_child(panel)
	
	panel.modulate.a = 0.0
	var tween = create_tween()
	var ts = Engine.time_scale
	if ts <= 0.0: ts = 1.0
	tween.tween_property(panel, "modulate:a", 1.0, 0.5 * ts)
	tween.tween_interval(4.0 * ts)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5 * ts)
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
			
		var req_met = true
		if upgrade.req_building != "":
			var req_b = game.buildings.get_building_by_id(upgrade.req_building)
			if not req_b or req_b.count < upgrade.req_count:
				req_met = false
				
		if not req_met:
			child.visible = false
			continue

		if upgrade.has_been_seen:
			child.visible = true
			upgrade.is_masked = false
			visible_upgrades += 1
			if upgrade.cost.is_greater_than(current_gold):
				child.modulate.a = 0.5
			else:
				child.modulate.a = 1.0
		elif upgrade.cost.is_less_equal(max_visible_cost):
			upgrade.has_been_seen = true
			upgrade.is_masked = false
			child.visible = true
			visible_upgrades += 1
			if upgrade.cost.is_greater_than(current_gold):
				child.modulate.a = 0.5
			else:
				child.modulate.a = 1.0
		else:
			if not first_unseen_upgrade_found:
				child.visible = true
				if not upgrade.has_been_seen:
					upgrade.is_masked = true
				else:
					upgrade.is_masked = false
				first_unseen_upgrade_found = true
				visible_upgrades += 1
				child.modulate.a = 0.5
			else:
				child.visible = false

	var first_unseen_found = false
	
	var cat_info = {
		"general": {"visible_count": 0, "new_count": 0, "base_name": "Общие"},
		"military": {"visible_count": 0, "new_count": 0, "base_name": "Военные"},
		"religion": {"visible_count": 0, "new_count": 0, "base_name": "Религия"},
		"archeology": {"visible_count": 0, "new_count": 0, "base_name": "Археология"}
	}

	for cat in building_containers:
		var tab_node = building_containers[cat].get_parent().get_parent()
		cat_info[cat]["tab_index"] = tab_node.get_index()
		
		for child in building_containers[cat].get_children():
			var b = child.building
			
			if b.has_been_seen:
				child.visible = true
				b.is_masked = false
				cat_info[cat].visible_count += 1
				if b.count == 0:
					cat_info[cat].new_count += 1
				if b.cost.is_greater_than(current_gold) and b.count == 0:
					child.modulate.a = 0.5
				else:
					child.modulate.a = 1.0
			elif b.cost.is_less_equal(max_visible_cost):
				b.has_been_seen = true
				b.is_masked = false
				child.visible = true
				cat_info[cat].visible_count += 1
				if b.count == 0:
					cat_info[cat].new_count += 1
				if b.cost.is_greater_than(current_gold) and b.count == 0:
					child.modulate.a = 0.5
				else:
					child.modulate.a = 1.0
			else:
				if not first_unseen_found:
					child.visible = true
					b.is_masked = not game.economy.lifetime_unlocked_buildings.has(b.id)
					first_unseen_found = true
					cat_info[cat].visible_count += 1
					child.modulate.a = 0.5
				else:
					child.visible = false

	var active_tab = right_panel.current_tab
	for cat in cat_info:
		var info = cat_info[cat]
		if info.visible_count == 0:
			right_panel.set_tab_hidden(info.tab_index, true)
		else:
			right_panel.set_tab_hidden(info.tab_index, false)
			
			var tab_name = info.base_name
			if info.new_count > 0 and active_tab != info.tab_index:
				tab_name += " *"
			right_panel.set_tab_title(info.tab_index, tab_name)
			
	if forge_btn:
		var forge = game.buildings.get_building_by_name("Кузница")
		var has_forge = forge != null and forge.count > 0
		forge_btn.visible = has_forge or visible_upgrades == 0



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
	if battle_results_window: battle_results_window.hide()
	if exp_result_window: exp_result_window.hide()
	
	var exp_map = get_node_or_null("RootVBox/WarScreen/RightPanel/Походы/ExpeditionMap")
	if exp_map and exp_map.deployment_window:
		exp_map.deployment_window.hide()
		
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
	archeology_screen.visible = false
	_on_mode_selected(0)
	check_modes_unlock()
	
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

# =========================
# 🏺 ARCHEOLOGY UI
# =========================

func _setup_archeology_ui():
	var diff_opt = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox/DiffOption")
	
	var arch_slider = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox/ArchSlider")
	arch_slider.value_changed.connect(func(_v):
		arch_slider.set_meta("user_interacted", true)
	)
	
	archeology_screen.get_node("LeftPanel/TrainingPanel/VBox/TrainButton").pressed.connect(func(): game.archeology.start_training(1))
	archeology_screen.get_node("LeftPanel/TrainingPanel/VBox/TrainMaxButton").pressed.connect(func(): game.archeology.start_training(game.archeology.get_max_archeologists()))
	
	var mid_panel = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox")
	var slider = mid_panel.get_node("TimeSlider")
	
	slider.value_changed.connect(func(val): mid_panel.get_node("TimeLabel").text = "Время: %d мин" % val)
	arch_slider.value_changed.connect(func(val): mid_panel.get_node("ArchLabel").text = "🏺 Археологов: %d" % val)
	mid_panel.get_node("StartButton").pressed.connect(func():
		var duration = int(slider.value)
		var arch_count = int(arch_slider.value)
		var diff = diff_opt.get_item_text(diff_opt.selected)
		var diff_map = {"Легкая": "easy", "Средняя": "medium", "Тяжелая": "hard", "Невозможная": "impossible", "Легендарная": "legendary"}
		if diff_map.has(diff): diff = diff_map[diff]
		game.archeology.start_expedition(arch_count, duration, diff)
	)
	
func update_archeology_ui():
	check_modes_unlock()
	var am = game.archeology
	var arch_guild = game.buildings.get_building_by_name("Гильдия археологов")
	var has_guild = arch_guild and arch_guild.count > 0
	
	if archeology_screen.has_node("LeftPanel"):
		archeology_screen.get_node("LeftPanel").visible = has_guild
	if archeology_screen.has_node("MiddlePanel"):
		archeology_screen.get_node("MiddlePanel").visible = has_guild
	
	var left_panel = archeology_screen.get_node("LeftPanel/TrainingPanel/VBox")
	var max_arch = am.get_max_archeologists()
	var current_total = am.archeologists_count + am.archeologists_training
	
	left_panel.get_node("TrainInfo").text = "🏺 Археологи: %d / %d (Обучается: %d)" % [am.archeologists_count, max_arch, am.archeologists_training]
	
	var can_train = current_total < max_arch and max_arch > 0
	var train_btn = left_panel.get_node("TrainButton")
	var trainmax_btn = left_panel.get_node("TrainMaxButton")
	
	train_btn.visible = true
	trainmax_btn.visible = true
	
	train_btn.disabled = not can_train or game.economy.gold.is_less_than(BigNum.from(am.base_archeologist_cost))
	trainmax_btn.disabled = not can_train or game.economy.gold.is_less_than(BigNum.from(am.base_archeologist_cost))
	
	var mid_panel = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox")
	var diff_opt = mid_panel.get_node("DiffOption")
	var unlocked = am.get_unlocked_difficulties()
	
	var diff_names = {"easy": "Легкая", "medium": "Средняя", "hard": "Тяжелая", "impossible": "Невозможная", "legendary": "Легендарная"}
	if diff_opt.item_count != unlocked.size():
		diff_opt.clear()
		for d in unlocked:
			diff_opt.add_item(diff_names.get(d, d))
	
	var arch_slider = mid_panel.get_node("ArchSlider")
	arch_slider.min_value = 0 if am.archeologists_count == 0 else 1
	arch_slider.max_value = max(arch_slider.min_value, am.archeologists_count)
	
	# Default to max value if user hasn't touched it, or if it was at previous max
	if not arch_slider.has_meta("user_interacted") or arch_slider.value > arch_slider.max_value:
		arch_slider.value = arch_slider.max_value
	
	var time_slider = mid_panel.get_node("TimeSlider")
	time_slider.max_value = am.get_max_duration_minutes()
	
	var start_btn = mid_panel.get_node("StartButton")
	start_btn.disabled = am.archeologists_count <= 0 or am.active_expeditions.size() >= am.get_max_expeditions()
	
	var exp_label = archeology_screen.get_node("MiddlePanel/ExpeditionsLabel")
	exp_label.text = "Активные экспедиции: %d / %d" % [am.active_expeditions.size(), am.get_max_expeditions()]
	
	var exp_list = archeology_screen.get_node("MiddlePanel/ExpeditionsList")
	for c in exp_list.get_children(): c.queue_free()
	
	for expedition in am.active_expeditions:
		var lbl = Label.new()
		var rem_min = int(expedition.remaining_duration / 60)
		var rem_sec = int(expedition.remaining_duration) % 60
		lbl.text = "[%s] 🏺 Археологов: %d | Ост: %02d:%02d" % [diff_names.get(expedition.difficulty, expedition.difficulty), expedition.current_archeologists, rem_min, rem_sec]
		exp_list.add_child(lbl)
	
func update_artifacts_ui():
	var am = game.archeology
	var inv_grid = archeology_screen.get_node("RightPanel/InventoryPanel/VBox/ScrollContainer/InventoryGrid")
	for c in inv_grid.get_children(): c.queue_free()
	
	for i in range(am.inventory_artifacts.size()):
		var lvl = am.inventory_artifacts[i]
		var item = artifact_item_scene.instantiate()
		inv_grid.add_child(item)
		item.setup(lvl, i, self)
		if selected_inventory_index == i:
			item.modulate = Color(1.5, 1.5, 0.5)
			
	var equipped_idx_start = am.inventory_artifacts.size()
	var curr_idx = equipped_idx_start
	for troop in game.war.troops:
		if troop.commander and troop.commander.equipped_artifact_level > 0:
			var lvl = troop.commander.equipped_artifact_level
			var item = artifact_item_scene.instantiate()
			inv_grid.add_child(item)
			item.setup(lvl, curr_idx, self, troop.name)
			curr_idx += 1
	
	var king_list = archeology_screen.get_node("RightPanel/KingdomArtifactPanel/VBox/KingdomArtifactsList")
	for c in king_list.get_children(): c.queue_free()
	
	var max_kingdom_artifacts = am.get_max_kingdom_artifacts()
	for i in range(max_kingdom_artifacts):
		var slot = kingdom_artifact_slot_scene.instantiate()
		king_list.add_child(slot)
		var lvl = 0
		if i < am.kingdom_artifacts.size():
			lvl = am.kingdom_artifacts[i]
		slot.setup(i, self, lvl)
	
var selected_inventory_index = -1
func _on_inventory_artifact_clicked(index):
	# Игнорируем клики по надетым артефактам
	if index >= game.archeology.inventory_artifacts.size():
		return
		
	if selected_inventory_index == index:
		game.archeology.equip_kingdom_artifact(index)
		selected_inventory_index = -1
	elif selected_inventory_index != -1:
		if game.archeology.merge_artifacts(selected_inventory_index, index):
			selected_inventory_index = -1
		else:
			selected_inventory_index = index
	else:
		selected_inventory_index = index
	update_artifacts_ui()
	
func _on_arch_expedition_updated(_exp_id):
	update_archeology_ui()

func _on_arch_expedition_completed(result):
	if exp_result_window:
		exp_result_window.setup(result, game)

var current_commander_for_artifact: String = ""
var artifact_popup_overlay: Control = null

func _on_commander_equip_requested(troop_id):
	var troop = game.war.get_troop_by_id(troop_id)
	if not troop or not troop.commander: return
	
	current_commander_for_artifact = troop_id
	
	if artifact_popup_overlay != null and is_instance_valid(artifact_popup_overlay):
		artifact_popup_overlay.queue_free()
		
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	
	if troop.commander.equipped_artifact_level > 0:
		var unequip_btn = Button.new()
		unequip_btn.text = "Снять артефакт (Ур. %d)" % troop.commander.equipped_artifact_level
		unequip_btn.pressed.connect(func():
			game.archeology.unequip_commander_artifact(current_commander_for_artifact)
			update_artifacts_ui()
			update_commanders_ui()
			artifact_popup_overlay.hide()
			artifact_popup_overlay.queue_free()
		)
		content.add_child(unequip_btn)
		content.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	content.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 5
	scroll.add_child(grid)
	
	var inv = game.archeology.inventory_artifacts
	if inv.size() == 0:
		var no_art = Label.new()
		no_art.text = "Нет доступных артефактов в инвентаре."
		grid.add_child(no_art)
	else:
		for i in range(inv.size()):
			var lvl = inv[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(80, 80)
			btn.text = "Арт Ур." + str(lvl)
			var index = i
			btn.pressed.connect(func():
				game.archeology.equip_commander_artifact(current_commander_for_artifact, index)
				update_artifacts_ui()
				update_commanders_ui()
				artifact_popup_overlay.hide()
				artifact_popup_overlay.queue_free()
			)
			grid.add_child(btn)
			
	artifact_popup_overlay = _create_popup(content, "Выберите артефакт")
	artifact_popup_overlay.show()
