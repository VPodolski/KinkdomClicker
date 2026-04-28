extends Control

var gold: float = 0.0
var gold_per_click = 1
var gold_boost_cost: int = 10
var ui_update_timer := 0.0
var buildings = []
var upgrades = []

@onready var gold_button = $TabContainer/MainTab/GoldButton
@onready var gold_label = $TabContainer/MainTab/GoldLabel
@onready var buildings_container = $TabContainer/MainTab/BuildingsContainer
@onready var upgrades_container = $TabContainer/ForgeTab/UpgradesContainer
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
	buildings.append(BuildingData.new("Кузница", 500, 50))
	buildings.append(BuildingData.new("Рынок", 1500, 150))
	buildings.append(BuildingData.new("Гильдия", 5000, 500))
	buildings.append(BuildingData.new("Банк", 20000, 2000))
	buildings.append(BuildingData.new("Замок", 100000, 10000))
	
	upgrades.append(UpgradeData.new("Улучшенные инструменты", 100, 5))
	upgrades.append(UpgradeData.new("Закалённая сталь", 500, 10))
	upgrades.append(UpgradeData.new("Мастерская ковка", 1500, 20))

	create_building_ui()
	create_upgrades_ui()
	start_button_pulse()
	
	gold_button.pressed.connect(_on_gold_button_pressed)
	gold_button.mouse_entered.connect(_on_button_hover)
	gold_button.mouse_exited.connect(_on_button_exit)
	
	var index = tab_container.get_tab_idx_from_control(forge_tab)
	tab_container.set_tab_hidden(index, true)
	
	update_ui()
	print("upgrades count: ", upgrades.size())
	
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

func update_buildings_ui():
	for child in buildings_container.get_children():
		child.update_ui(gold)

func get_total_income():
	var total = 0
	for b in buildings:
		total += b.get_income()
	return total

func _on_gold_button_pressed():
	gold_button.scale = Vector2(1, 1)
	
	gold += gold_per_click
	
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
	for upgrade in upgrades:
		if upgrade.is_crafting:
			var speed = get_forge_speed_multiplier()
			upgrade.progress += delta * speed
			
			if upgrade.progress >= upgrade.base_time:
				complete_upgrade(upgrade)
	update_upgrades_ui() 

func update_upgrades_ui():
	for child in upgrades_container.get_children():
		child.update_ui()

func start_upgrade(index):
	var u = upgrades[index]
	
	if gold >= u.cost and not u.is_crafting:
		gold -= u.cost
		u.is_crafting = true

func complete_upgrade(upgrade):
	upgrade.is_crafting = false
	upgrade.progress = 0
	
	# пример эффекта
	gold_per_click += 1

func get_building_by_name(name):
	for b in buildings:
		if b.name == name:
			return b
	return null
	
