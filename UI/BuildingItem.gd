extends PanelContainer

var building
var index

@onready var icon_rect = $BgIcon
@onready var name_label: Label = $MarginContainer/HBoxContainer/TextPanel/TextVBox/NameLabel
@onready var info_label: Label = $MarginContainer/HBoxContainer/TextPanel/TextVBox/InfoLabel
@onready var buy1_button: Button = $MarginContainer/HBoxContainer/TextPanel/TextVBox/ActionHBox/Buy1Button
@onready var buymax_button: Button = $MarginContainer/HBoxContainer/TextPanel/TextVBox/ActionHBox/BuyMaxButton

var current_gold_cache = null

signal buy_pressed(index, amount)

func _ready():
	buy1_button.pressed.connect(_on_buy_pressed.bind(1))
	buymax_button.pressed.connect(func(): _on_buy_pressed(building.get_max_affordable(current_gold_cache, GameLogic.currentBaseNetIncome, GameLogic.economy.upkeep_reduction_multiplier)))

func setup(_building, _index):
	building = _building
	index = _index
	
	if building != null:
		var path = "res://assets/buildings/%s.jpg" % building.id
		if ResourceLoader.exists(path):
			icon_rect.texture = load(path)
		else:
			icon_rect.texture = load("res://icon.svg")
			
	update_ui(BigNum.new(0.0))

func _on_buy_pressed(amount: int):
	emit_signal("buy_pressed", index, amount)

func update_ui(current_gold):
	current_gold_cache = current_gold
	if building == null:
		return
	
	if building.is_masked:
		name_label.text = "???"
		icon_rect.texture = null
		info_label.text = "Кол-во: 0\nДоход: ???\nЦена: %s" % _format_number(building.cost)
		buy1_button.disabled = true
		buymax_button.disabled = true
		buymax_button.visible = false
		return
		
	name_label.text = building.name
	
	if icon_rect.texture == null:
		var path = "res://assets/buildings/%s.jpg" % building.id
		if ResourceLoader.exists(path):
			icon_rect.texture = load(path)
		else:
			icon_rect.texture = load("res://icon.svg")
	
	var global_mult = GameLogic.economy.global_income_multiplier * GameLogic.get_achievement_multiplier() * GameLogic.economy.prestige_multiplier
	var upkeep_mult = GameLogic.economy.upkeep_reduction_multiplier
		
	var actual_income = building.get_income_per_unit().mul(global_mult)

	var income_str = "+%s 🪙/сек" % _format_number(actual_income)
	if building.count > 0:
		income_str += " (Всего: %s)" % _format_number(actual_income.mul(building.count))
		
	if building.prayer_income.is_greater_than(0.0):
		var prayer_mult = GameLogic.economy.prayer_multiplier
		var actual_prayer = building.get_prayer_income_per_unit().mul(prayer_mult)
		var actual_upkeep = building.get_upkeep_per_unit().mul(upkeep_mult)
		var total_upkeep = building.get_total_upkeep().mul(upkeep_mult)
		
		income_str = "+%s 🙏/сек" % _format_number(actual_prayer)
		if building.count > 0:
			income_str += " (Всего: %s)" % _format_number(actual_prayer.mul(building.count))
			
		if building.gold_upkeep.is_greater_than(0.0):
			income_str += "\nРасход: -%s 🪙/сек" % _format_number(actual_upkeep)
			if building.count > 0:
				income_str += " (Всего: -%s)" % _format_number(total_upkeep)

	var linked_troop = null
	for t in GameLogic.war.troops:
		if t.required_building == building.id:
			linked_troop = t
			break
			
	if linked_troop:
		var troop_upkeep_single = linked_troop.upkeep.mul(upkeep_mult)
		var total_troop_upkeep = linked_troop.get_total_upkeep().mul(upkeep_mult)
		
		income_str = "Производит: %s\nВ армии: %d\nСодержание войск: -%s/ед (-%s всего) 🪙/сек" % [
			linked_troop.name,
			linked_troop.count,
			_format_number(troop_upkeep_single),
			_format_number(total_troop_upkeep)
		]
		
	info_label.text = "Кол-во: %d\n%s\nЦена: %s" % [
		building.count,
		income_str,
		_format_number(building.cost)
	]
	
	var net_income = GameLogic.currentBaseNetIncome
	var can_afford_upkeep_1 = true
	var can_afford_upkeep_10 = true
	
	if building.gold_upkeep.is_greater_than(0.0):
		var up1 = building.get_upkeep_for(1).mul(upkeep_mult)
		if up1.is_greater_equal(net_income):
			can_afford_upkeep_1 = false
		var up10 = building.get_upkeep_for(10).mul(upkeep_mult)
		if up10.is_greater_equal(net_income):
			can_afford_upkeep_10 = false

	buy1_button.disabled = current_gold.is_less_than(building.cost) or not can_afford_upkeep_1
	
	var actual_max = building.get_max_affordable(current_gold, net_income, upkeep_mult)
	if actual_max > 0:
		buymax_button.text = "Макс (%d)" % actual_max
		buymax_button.disabled = false
	else:
		buymax_button.text = "Макс"
		buymax_button.disabled = true

	var has_buy_max = GameLogic.ascension.has_skill("buy_max")
	
	buymax_button.visible = has_buy_max

func _format_number(value) -> String:
	return GameLogic.format_number(value)
