extends Control

var gold: float = 0.0
var gold_boost_cost: int = 10
var ui_update_timer := 0.0
var buildings = []

@onready var gold_label = $GoldLabel
@onready var gold_button = $GoldButton
@onready var buildings_container = $BuildingsContainer

var building_scene = preload("res://BuildingItem.tscn")


func _ready():
	buildings.append(BuildingData.new("Ферма", 10, 1))
	buildings.append(BuildingData.new("Шахта", 50, 5))
	buildings.append(BuildingData.new("Лесопилка", 30, 3))

	create_building_ui()

	gold_button.pressed.connect(_on_gold_button_pressed)
	update_ui()
	
func create_building_ui():
	for i in range(buildings.size()):
		var item = building_scene.instantiate()
		item.setup(buildings[i], i)	
		item.buy_pressed.connect(_on_building_buy)
		buildings_container.add_child(item)

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
	gold += 1
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

func buy_building(index):
	var b = buildings[index]
	
	if gold >= b.cost:
		gold -= b.cost
		b.buy()
		update_ui()
