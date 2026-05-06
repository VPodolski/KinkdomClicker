extends HBoxContainer

var building
var index

@onready var name_label = $NameLabel
@onready var info_label = $InfoLabel
@onready var buy_button = $BuyButton

signal buy_pressed(index)

func _ready():
	buy_button.pressed.connect(_on_buy_pressed)

func setup(_building, _index):
	building = _building
	index = _index
	
	update_ui(0)

func _on_buy_pressed():
	emit_signal("buy_pressed", index)

func update_ui(current_gold: int):
	if building == null:
		return
	
	name_label.text = building.name
	
	info_label.text = "Кол-во: " + str(building.count) + \
	" | Цена: " + str(building.cost) + \
	" | +" + str(building.income * building.income_multiplier) + "/сек"
	
	buy_button.disabled = current_gold < building.cost
