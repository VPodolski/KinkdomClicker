extends PanelContainer

var building
var index

@onready var icon_rect = $HBoxContainer/IconRect
@onready var name_label = $HBoxContainer/TextVBox/NameLabel
@onready var info_label = $HBoxContainer/TextVBox/InfoLabel
@onready var buy1_button = $HBoxContainer/TextVBox/ActionHBox/Buy1Button
@onready var buy10_button = $HBoxContainer/TextVBox/ActionHBox/Buy10Button
@onready var buymax_button = $HBoxContainer/TextVBox/ActionHBox/BuyMaxButton

var current_gold_cache: float = 0.0

signal buy_pressed(index, amount)

func _ready():
	buy1_button.pressed.connect(_on_buy_pressed.bind(1))
	buy10_button.pressed.connect(_on_buy_pressed.bind(10))
	buymax_button.pressed.connect(func(): _on_buy_pressed(building.get_max_affordable(current_gold_cache)))

func setup(_building, _index):
	building = _building
	index = _index
	
	if building != null:
		var tex = load("res://assets/buildings/%s.jpg" % building.id)
		if tex:
			icon_rect.texture = tex
			
	update_ui(0)

func _on_buy_pressed(amount: int):
	emit_signal("buy_pressed", index, amount)

func update_ui(current_gold: float):
	current_gold_cache = current_gold
	if building == null:
		return
	
	name_label.text = building.name
	
	var max_affordable = building.get_max_affordable(current_gold)
	if max_affordable == 0:
		max_affordable = 1 # Show cost for 1 if can't afford any

	info_label.text = "Кол-во: %d\nДоход: +%s/сек\nЦена: %s" % [
		building.count,
		_format_number(building.income * building.income_multiplier),
		_format_number(building.cost)
	]
	
	buy1_button.disabled = current_gold < building.cost
	buy10_button.disabled = current_gold < building.get_cost_for(10)
	
	var actual_max = building.get_max_affordable(current_gold)
	if actual_max > 0:
		buymax_button.text = "Макс (%d)" % actual_max
		buymax_button.disabled = false
	else:
		buymax_button.text = "Макс"
		buymax_button.disabled = true

func _format_number(value: float) -> String:
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	elif value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	elif value == floor(value):
		return str(int(value))
	else:
		return "%.2f" % value
