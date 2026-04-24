extends Control

var gold: float = 0.0
var gold_boost_cost: int = 10
var ui_update_timer := 0.0
var buildings = []

@onready var gold_label = $GoldLabel
@onready var gold_button = $GoldButton
@onready var buildings_container = $BuildingsContainer

var building_scene = preload("res://BuildingItem.tscn")
var floating_text_scene = preload("res://FloatingText.tscn")

func _ready():
	await ready
	
	gold_button.pivot_offset = gold_button.size / 2
	
	buildings.append(BuildingData.new("Ферма", 10, 1))
	buildings.append(BuildingData.new("Шахта", 50, 5))
	buildings.append(BuildingData.new("Лесопилка", 30, 3))

	create_building_ui()
	start_button_pulse()
	
	gold_button.pressed.connect(_on_gold_button_pressed)
	gold_button.mouse_entered.connect(_on_button_hover)
	gold_button.mouse_exited.connect(_on_button_exit)
	
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
	gold_button.scale = Vector2(1, 1)
	var click_value = 1
	
	gold += click_value
	
	animate_button_press(gold_button) 
	spawn_floating_text(click_value)
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
