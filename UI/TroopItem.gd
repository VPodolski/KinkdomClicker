extends PanelContainer
class_name TroopItem

signal train_pressed(troop, amount)

var troop: TroopData

@onready var icon_rect: TextureRect = $BgIcon
@onready var name_label: Label = $MarginContainer/HBoxContainer/TextPanel/MainVBox/VBoxContainer/NameLabel
@onready var description_label: Label = $MarginContainer/HBoxContainer/TextPanel/MainVBox/VBoxContainer/InfoLabel
@onready var stats_label: Label = $MarginContainer/HBoxContainer/TextPanel/MainVBox/VBoxContainer/StatsLabel
@onready var time_label: Label = $MarginContainer/HBoxContainer/TextPanel/MainVBox/VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $MarginContainer/HBoxContainer/TextPanel/MainVBox/VBoxContainer/ProgressBar

@onready var buy1_button: Button = $MarginContainer/HBoxContainer/TextPanel/MainVBox/ActionHBox/Buy1Button
@onready var buy10_button: Button = $MarginContainer/HBoxContainer/TextPanel/MainVBox/ActionHBox/Buy10Button
@onready var buymax_button: Button = $MarginContainer/HBoxContainer/TextPanel/MainVBox/ActionHBox/BuyMaxButton

var current_gold_cache = null

func _ready() -> void:
	buy1_button.pressed.connect(_on_buy_pressed.bind(1))
	buy10_button.pressed.connect(_on_buy_pressed.bind(10))
	buymax_button.pressed.connect(func(): _on_buy_pressed(troop.get_max_affordable(current_gold_cache, GameLogic.currentGoldPerSecond, GameLogic.economy.upkeep_reduction_multiplier)))

func setup(_troop: TroopData) -> void:
	troop = _troop
	name_label.text = troop.name
	description_label.text = troop.description
	
	var path = "res://assets/troops/%s.png" % troop.id
	if ResourceLoader.exists(path):
		icon_rect.texture = load(path)
	else:
		icon_rect.texture = load("res://icon.svg")

func update_ui(current_gold, current_speed: float = 1.0, net_income = null, upkeep_mult: float = 1.0) -> void:
	if troop == null:
		return
		
	current_gold_cache = current_gold

	stats_label.text = "Сила: %s | Кол-во: %d\nСодержание: -%s 🪙/сек на юнита" % [
		GameLogic.format_number(troop.base_power.mul(troop.power_multiplier)), 
		troop.count,
		GameLogic.format_number(troop.upkeep.mul(troop.upkeep_multiplier))
	]
	if troop.training_amount > 0:
		stats_label.text += " (+%d нанимается)" % troop.training_amount

	var max_additional_upkeep = net_income.mul(0.8) if net_income != null else BigNum.new(0.0)
	var can_afford_1 = troop.upkeep.mul(troop.upkeep_multiplier * upkeep_mult).is_less_equal(max_additional_upkeep)
	var can_afford_10 = troop.upkeep.mul(10.0 * troop.upkeep_multiplier * upkeep_mult).is_less_equal(max_additional_upkeep)
	
	buy1_button.disabled = current_gold.is_less_than(troop.get_cost_for(1)) or not can_afford_1
	buy10_button.disabled = current_gold.is_less_than(troop.get_cost_for(10)) or not can_afford_10
	
	var actual_max = troop.get_max_affordable(current_gold, net_income, upkeep_mult) if net_income != null else 0
	if actual_max > 0:
		buymax_button.text = "Макс (%d)" % actual_max
		buymax_button.disabled = false
	else:
		buymax_button.text = "Макс"
		buymax_button.disabled = true
	
	var speed = current_speed
	var duration = troop.base_time / speed

	if troop.is_training:
		time_label.visible = true
		var remaining = max(0.0, (troop.base_time - troop.training_progress) / speed)
		time_label.text = "%.1f сек" % remaining

		progress_bar.modulate.a = 1.0
		progress_bar.max_value = troop.base_time
		progress_bar.value = min(troop.training_progress, troop.base_time)
	else:
		progress_bar.modulate.a = 0.0
		time_label.visible = true
		time_label.text = "Время найма: %.1f сек" % duration

	buy1_button.text = "Нанять (%s)" % GameLogic.format_number(troop.get_cost_for(1))
	
	if troop.is_training:
		buy1_button.disabled = true
		buy10_button.disabled = true
		buymax_button.disabled = true
		
	modulate.a = 1.0 if (not buy1_button.disabled or troop.is_training) else 0.65

func _on_buy_pressed(amount: int) -> void:
	if troop != null and amount > 0:
		train_pressed.emit(troop, amount)
