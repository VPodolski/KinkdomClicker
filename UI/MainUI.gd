extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $HBoxContainer/LeftPanel/GoldLabel
@onready var gold_button = $HBoxContainer/LeftPanel/GoldButton

@onready var right_panel = $HBoxContainer/RightPanel
@onready var buildings_container = $HBoxContainer/RightPanel/BuildingTab/Buildings/BuildingsContainer
@onready var upgrades_container = $HBoxContainer/RightPanel/ForgeTab/Upgrades/UpgradesContainer

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

func _ready():
	await get_tree().process_frame
	achievements_tab.visible = false
	
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	game.achievement_unlocked.connect(_on_achievement_unlocked)
	ascend_button.pressed.connect(_on_ascend_pressed)

	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()
	update_achievements_ui()
	update_prestige_ui()

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


func _on_building_pressed(index):
	game.buy_building(index)


func _on_upgrade_pressed(upgrade: UpgradeData) -> void:
	game.start_upgrade(upgrade)


func _on_achievement_unlocked(_achievement) -> void:
	achievements_tab.visible = true
	update_achievements_ui()

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

	update_visibility()
	
func update_achievements_ui() -> void:
	var unlocked = game.achievements.get_unlocked_achievements()
	print("Unlocked achievements: ", unlocked.size())
	# Скрываем вкладку, если достижений нет
	if unlocked.is_empty():
		achievements_tab.visible = false
		return

	# Показываем вкладку
	achievements_tab.visible = true

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
		
func update_achievements_tab_visibility() -> void:
	var tab_index = achievements_tab.get_index()
	var has_achievements = game.get_unlocked_achievement_count() > 0

	right_panel.set_tab_hidden(tab_index, not has_achievements)
# =========================
# 👁️ VISIBILITY
# =========================

func update_visibility() -> void:
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

		# Если пока нельзя купить — делаем полупрозрачным.
		if upgrade.cost > current_gold:
			child.modulate.a = 0.5
		else:
			child.modulate.a = 1.0

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
