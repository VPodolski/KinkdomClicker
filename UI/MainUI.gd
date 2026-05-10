extends Control

@onready var game = GameLogic  # если добавишь Game в AutoLoad

# UI элементы
@onready var gold_label = $HBoxContainer/LeftPanel/GoldLabel
@onready var gold_button = $HBoxContainer/LeftPanel/GoldButton

@onready var right_panel = $HBoxContainer/RightPanel
@onready var buildings_container = $HBoxContainer/RightPanel/BuildingTab/Buildings/BuildingsContainer
@onready var upgrades_container = $HBoxContainer/RightPanel/ForgeTab/Upgrades/UpgradesContainer

var building_item_scene = preload("res://ui/BuildingItem.tscn")
var upgrade_item_scene = preload("res://ui/UpgradeItem.tscn")
var floating_text_scene = preload("res://ui/FloatingText.tscn")

var ui_update_timer = 0.0

func _ready():
	await get_tree().process_frame
	# подписки на события
	game.gold_changed.connect(update_gold)
	game.buildings_changed.connect(update_buildings_ui)
	game.upgrades_changed.connect(update_upgrades_ui)
	
	# первичная инициализация
	update_gold(game.economy.gold)
	create_buildings_ui()
	create_upgrades_ui()

	right_panel.set_tab_title(0, "Постройки")
	right_panel.set_tab_title(1, "Кузница")

func _process(delta):
	ui_update_timer += delta
	
	if ui_update_timer >= 0.05: # 20 раз в секунду
			update_gold(game.economy.gold)
			update_upgrades_ui()
			update_buildings_ui()
			update_visibility()

# =========================
# 🖱️ INPUT
# =========================

func _on_gold_button_pressed():
	var click_amount = game.economy.gold_per_click

	var total_income = game.buildings.get_total_income(
		game.economy.global_income_multiplier
	)

	click_amount += total_income * game.economy.click_income_ratio

	# Выполняем сам клик
	game.on_click()

	# Визуальные эффекты
	spawn_floating_text(click_amount)
	animate_button_press(gold_button)


func _on_building_pressed(index):
	game.buy_building(index)


func _on_upgrade_pressed(upgrade: UpgradeData) -> void:
	game.start_upgrade(upgrade)


# =========================
# 💰 UI ОБНОВЛЕНИЕ
# =========================

func update_gold(value):
	var text ="Золото: %.1f" % value + \
	"\n(+" + str(game.buildings.get_total_income(game.economy.global_income_multiplier)) + "/сек)"
	
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
	#sort_upgrade_items()
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
