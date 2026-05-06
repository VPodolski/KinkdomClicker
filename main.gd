extends Control

var gold_boost_cost: int = 10
var ui_update_timer := 0.0
var buildings = []
var active_upgrades = []

var upgrades = [
	UpgradeData.new(
		"Острые инструменты", 50, 3,
		"click_bonus", 1
	),
	UpgradeData.new(
		"Тяжёлый молот", 150, 5,
		"click_bonus", 3
	),
	UpgradeData.new(
		"Золотое касание", 500, 8,
		"click_from_income", 0.01  # 1% от дохода
	),
	UpgradeData.new(
		"Жадность короля", 2000, 12,
		"click_from_income", 0.03  # 3%
	),
	# 🌾 ФЕРМЫ
	UpgradeData.new(
		"Удобрения", 200, 6,
		"income_multiplier", 0.5, "Ферма"
	),
	UpgradeData.new(
		"Железные плуги", 600, 8,
		"income_multiplier", 1.0, "Ферма"
	),
	UpgradeData.new(
		"Фермерская кооперация", 1200, 10,
		"building_synergy", 0.01, "Ферма", "Ферма"
	),
	# 🪵 ЛЕСОПИЛКИ
	UpgradeData.new(
		"Острые пилы", 400, 6,
		"income_multiplier", 0.5, "Лесопилка"
	),
	UpgradeData.new(
		"Массовая заготовка", 1200, 10,
		"income_multiplier", 1.0, "Лесопилка"
	),
	UpgradeData.new(
		"Древесные контракты", 2500, 12,
		"global_multiplier", 0.1
	),
	# 🔨 КУЗНИЦА
	UpgradeData.new(
		"Угольная печь", 800, 8,
		"forge_speed", 0.2
	),
	UpgradeData.new(
		"Мастера кузнецы", 2000, 12,
		"building_synergy", 0.02, "Ферма", "Кузница"
	),
	UpgradeData.new(
		"Гильдия кузнецов", 5000, 15,
		"global_multiplier", 0.15
	),
	# 🏪 РЫНОК / ПОЗДНЯЯ ИГРА
	UpgradeData.new(
		"Торговые пути", 3000, 10,
		"global_multiplier", 0.1
	),
	UpgradeData.new(
		"Королевские налоги", 8000, 15,
		"global_multiplier", 0.25
	),
	# 🔥 СИНЕРГИЯ (ключевая механика)
	UpgradeData.new(
		"Инструменты фермеров", 1000, 10,
		"building_synergy", 0.02, "Ферма", "Кузница"
	),
	UpgradeData.new(
		"Деревянные конструкции", 1500, 10,
		"building_synergy", 0.015, "Кузница", "Лесопилка"
	),
	UpgradeData.new(
		"Городская экономика", 7000, 15,
		"building_synergy", 0.01, "Рынок", "Ферма"
	)
]

@onready var gold_button = $TabContainer/MainTab/GoldButton
@onready var gold_label = $TabContainer/MainTab/GoldLabel
@onready var buildings_container = $TabContainer/MainTab/BuildingsContainer
@onready var upgrades_container = $TabContainer/ForgeTab/ScrollContainer/UpgradesContainer
@onready var tab_container = $TabContainer
@onready var forge_tab = $TabContainer/ForgeTab

var building_scene = preload("res://BuildingItem.tscn")
var upgrade_item_scene = preload("res://UpgradeItem.tscn")
var floating_text_scene = preload("res://FloatingText.tscn")

func _ready():
	await ready
	
	gold_button.pivot_offset = gold_button.size / 2
	
	buildings.append(BuildingData.new("Ферма", 10, 1))
	buildings.append(BuildingData.new("Лесопилка", 50, 5))
	buildings.append(BuildingData.new("Каменоломня", 150, 15))
	buildings.append(BuildingData.new("Кузница", 10, 50))
	buildings.append(BuildingData.new("Рынок", 1500, 150))
	buildings.append(BuildingData.new("Гильдия", 5000, 500))
	buildings.append(BuildingData.new("Банк", 20000, 2000))
	buildings.append(BuildingData.new("Замок", 100000, 10000))

	create_building_ui()
	create_upgrades_ui()
	start_button_pulse()
	
	gold_button.pressed.connect(_on_gold_button_pressed)
	gold_button.mouse_entered.connect(_on_button_hover)
	gold_button.mouse_exited.connect(_on_button_exit)
	
	var index = tab_container.get_tab_idx_from_control(forge_tab)
	tab_container.set_tab_hidden(index, true)
	
	update_ui()
	
func create_building_ui():
	for i in range(buildings.size()):
		var item = building_scene.instantiate()
		item.setup(buildings[i], i)	
		item.buy_pressed.connect(_on_building_buy)
		buildings_container.add_child(item)

func create_upgrades_ui():
	# 🧹 очищаем старые элементы (если перезапуск)
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# 🏗️ создаём новые
	for i in range(upgrades.size()):
		var upgrade = upgrades[i]
		
		var item = upgrade_item_scene.instantiate()
		
		upgrades_container.add_child(item)
		
		item.setup(upgrade, i)
		
		item.craft_pressed.connect(_on_upgrade_pressed)

func _on_upgrade_pressed(index):
	start_upgrade(index)
	update_upgrades_ui()

func _on_building_buy(index):
	buy_building(index)
	update_buildings_ui()

func is_upgrade_unlocked(upgrade):
	if upgrade.required_building == "":
		return true
	
	var b = get_building_by_name(upgrade.required_building)
	if b == null:
		return false
	
	return b.count >= upgrade.required_count

func update_buildings_ui():
	for child in buildings_container.get_children():
		child.update_ui(gold)

func get_total_income():
	var total = 0
	for b in buildings:
		total += b.get_income()
	return total * global_income_multiplier

func _on_gold_button_pressed():
	gold_button.scale = Vector2(1, 1)
	
	var bonus = get_total_income() * click_income_ratio
	gold += gold_per_click + bonus
	
	animate_button_press(gold_button) 
	spawn_floating_text(gold_per_click)
	update_ui()

func update_ui():
	gold_label.text = "Золото: %.1f" % gold + \
	"\n(+" + str(get_total_income()) + "/сек)"
	update_buildings_ui()

func _process(delta):
	var income_per_second = get_total_income()
	gold += income_per_second * delta

	ui_update_timer += delta
	if ui_update_timer >= 0.05: # 20 раз в секунду
		update_ui()
		ui_update_timer = 0.0
		
	update_crafting(delta)

func buy_building(index):
	var b = buildings[index]
	
	if gold >= b.cost:
		gold -= b.cost
		b.buy()
		update_synergies()
		update_ui()
		
	if buildings[index].name == "Кузница" and buildings[index].count == 1:
		unlock_forge()

func unlock_forge():
	var index = tab_container.get_tab_idx_from_control(forge_tab)
	tab_container.set_tab_hidden(index, false)
	create_upgrades_ui()

func spawn_floating_text(amount: int):
	var text = floating_text_scene.instantiate()
	
	text.text = "+" + str(amount)
	
	var mouse_pos = get_viewport().get_mouse_position()
	text.position = mouse_pos
	text.position += Vector2(randf_range(-20, 20), randf_range(-10, 10))
	
	add_child(text)
	
func animate_button_press(button: Control):
	var tween = create_tween()
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1)

func _on_button_hover():
	var tween = create_tween()
	tween.tween_property(gold_button, "scale", Vector2(1.1, 1.1), 0.1)


func _on_button_exit():
	var tween = create_tween()
	tween.tween_property(gold_button, "scale", Vector2(1, 1), 0.1)

func start_button_pulse():
	while true:
		var tween = create_tween()
		
		tween.tween_property(gold_button, "scale", Vector2(1.05, 1.05), 0.6)
		tween.tween_property(gold_button, "scale", Vector2(1, 1), 0.6)
		
		await tween.finished


func get_forge_speed_multiplier():
	var forge = get_building_by_name("Кузница")
	return 1.0 + (forge.count * 0.01)  # +1% за кузницу

func update_crafting(delta):
	var remaining = 0.0
	
	for upgrade in upgrades:
		if upgrade.is_crafting:
			var speed = get_forge_speed_multiplier()
			upgrade.progress += delta * speed
			remaining = (upgrade.base_time - upgrade.progress) / speed
			
			if upgrade.progress >= upgrade.base_time:
				complete_upgrade(upgrade)
	update_upgrades_ui() 


func update_upgrades_ui():
	for child in upgrades_container.get_children():
		var u = child.upgrade
		
		child.update_ui(
			gold,
			is_upgrade_unlocked(u),
			get_upgrade_preview_text(u),
			get_upgrade_remaining_time_text(u)
		)

func start_upgrade(index):
	var u = upgrades[index]
	
	if gold >= u.cost and not u.is_crafting:
		gold -= u.cost
		u.is_crafting = true

func complete_upgrade(upgrade):
	apply_upgrade(upgrade)
	
	active_upgrades.append(upgrade)
	update_synergies()  
	
	upgrades.erase(upgrade)
	
	create_upgrades_ui()
	
func apply_upgrade(upgrade):
	match upgrade.effect_type:
		"click_bonus":
			gold_per_click += upgrade.effect_value
		
		"income_multiplier":
			var b = get_building_by_name(upgrade.target)
			if b:
				b.income_multiplier += upgrade.effect_value
		
		"global_multiplier":
			global_income_multiplier += upgrade.effect_value
			
		"building_synergy":
			var source = get_building_by_name(upgrade.source_building)
			var target = get_building_by_name(upgrade.target)
			
			if source and target:
				target.income_multiplier += source.count * upgrade.effect_value
				
		"click_from_income":
			click_income_ratio += upgrade.effect_value

func update_synergies():
	for b in buildings:
		b.synergy_bonus = 0.0
	
	for upgrade in active_upgrades:
		if upgrade.effect_type == "building_synergy":
			var source = get_building_by_name(upgrade.source_building)
			var target = get_building_by_name(upgrade.target)
			
			if source and target:
				target.synergy_bonus += source.count * upgrade.effect_value

func get_building_by_name(building_name):
	for b in buildings:
		if b.name == building_name:
			return b
	return null
	
func get_upgrade_preview_text(upgrade):
	match upgrade.effect_type:
		
		"click_bonus":
			var before = gold_per_click
			var after = before + upgrade.effect_value
			return "Клик: %d → %d" % [before, after]
		
		"income_multiplier":
			var b = get_building_by_name(upgrade.target)
			if b == null:
				return ""
			
			var before = b.income * b.income_multiplier
			var after = before * (1.0 + upgrade.effect_value)
			
			return "%s: %s → %s за шт." % [
				b.name,
				format_float(before),
				format_float(after)
			]

		"global_multiplier":
			var before = get_total_income()
			var after = float(before * (1.0 + upgrade.effect_value))
			
			return "Доход: %s → %s / сек" % [format_float(before), format_float(after)]
	
	return ""

func get_upgrade_remaining_time(upgrade):
	var speed = get_forge_speed_multiplier()
	var remaining = (upgrade.base_time - upgrade.progress) / speed
	
	return max(0.0, remaining)

func get_upgrade_time_text(upgrade):
	var base = upgrade.base_time
	var current = get_upgrade_time_with_speed(upgrade)
	
	# если ускорения нет — не дублируем
	if abs(base - current) < 0.01:
		return "Время: %s" % format_time(base)
	
	return "Время: %s (сейчас: %s)" % [
		format_time(base),
		format_time(current)
	]

func get_upgrade_time_with_speed(upgrade):
	var speed = get_forge_speed_multiplier()
	return upgrade.base_time / speed

func get_upgrade_remaining_time_text(upgrade):
	return format_time(get_upgrade_remaining_time(upgrade))

func format_float(value: float) -> String:
	var s = "%.2f" % value
	s = s.rstrip("0").rstrip(".")
	return s
	
func format_time(seconds: float) -> String:
	if seconds < 60:
		return "%.1f сек" % seconds
	
	var minutes = int(seconds / 60)
	var sec = int(seconds) % 60
	
	return "%dм %dс" % [minutes, sec]
