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
		var path = "res://assets/buildings/%s.jpg" % building.id
		if ResourceLoader.exists(path):
			icon_rect.texture = load(path)
			
	update_ui(0)

func _on_buy_pressed(amount: int):
	emit_signal("buy_pressed", index, amount)

func update_ui(current_gold: float):
	current_gold_cache = current_gold
	if building == null:
		return
	
	if building.is_masked:
		name_label.text = "???"
		icon_rect.texture = null
		info_label.text = "Кол-во: 0\nДоход: ???\nЦена: %s" % _format_number(building.cost)
		buy1_button.disabled = true
		buy10_button.disabled = true
		buymax_button.disabled = true
		buy10_button.visible = false
		buymax_button.visible = false
		return
		
	name_label.text = building.name
	
	if icon_rect.texture == null:
		var path = "res://assets/buildings/%s.jpg" % building.id
		if ResourceLoader.exists(path):
			icon_rect.texture = load(path)
	
	var max_affordable = building.get_max_affordable(current_gold)
	if max_affordable == 0:
		max_affordable = 1 # Show cost for 1 if can't afford any

	var global_mult = GameLogic.economy.global_income_multiplier * GameLogic.get_achievement_multiplier() * GameLogic.economy.prestige_multiplier
	var upkeep_mult = GameLogic.economy.upkeep_reduction_multiplier
		
	var actual_income = building.get_income_per_unit() * global_mult

	var income_str = "+%s 🪙/сек" % _format_number(actual_income)
	if building.count > 0:
		income_str += " (Всего: %s)" % _format_number(actual_income * building.count)
		
	if building.prayer_income > 0:
		var prayer_mult = GameLogic.economy.prayer_multiplier
		var actual_prayer = building.get_prayer_income_per_unit() * prayer_mult
		var actual_upkeep = building.get_upkeep_per_unit() * upkeep_mult
		
		income_str = "+%s 🙏/сек" % _format_number(actual_prayer)
		if building.count > 0:
			income_str += " (Всего: %s)" % _format_number(actual_prayer * building.count)
			
		income_str += "\nРасход: -%s 🪙/сек" % _format_number(actual_upkeep)
		if building.count > 0:
			income_str += " (Всего: -%s)" % _format_number(actual_upkeep * building.count)
		
	info_label.text = "Кол-во: %d\nДоход: %s\nЦена: %s" % [
		building.count,
		income_str,
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

	var has_buy_max = GameLogic.ascension.has_skill("buy_max")
	
	buy10_button.visible = has_buy_max
	buymax_button.visible = has_buy_max

func _format_number(value: float) -> String:
	return GameLogic.format_number(value)
