extends PanelContainer
class_name TroopItem

signal train_pressed(troop, amount)

var troop: TroopData

@onready var name_label: Label = $HBoxContainer/MainVBox/VBoxContainer/NameLabel
@onready var description_label: Label = $HBoxContainer/MainVBox/VBoxContainer/InfoLabel
@onready var stats_label: Label = $HBoxContainer/MainVBox/VBoxContainer/StatsLabel
@onready var time_label: Label = $HBoxContainer/MainVBox/VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $HBoxContainer/MainVBox/VBoxContainer/ProgressBar

@onready var buy1_button: Button = $HBoxContainer/MainVBox/ActionHBox/Buy1Button
@onready var buy10_button: Button = $HBoxContainer/MainVBox/ActionHBox/Buy10Button
@onready var buymax_button: Button = $HBoxContainer/MainVBox/ActionHBox/BuyMaxButton

var current_gold_cache: float = 0.0

func _ready() -> void:
	buy1_button.pressed.connect(_on_buy_pressed.bind(1))
	buy10_button.pressed.connect(_on_buy_pressed.bind(10))
	buymax_button.pressed.connect(func(): _on_buy_pressed(troop.get_max_affordable(current_gold_cache)))

func setup(_troop: TroopData) -> void:
	troop = _troop
	name_label.text = troop.name
	description_label.text = troop.description

func update_ui(current_gold: float) -> void:
	if troop == null:
		return
		
	current_gold_cache = current_gold

	stats_label.text = "Сила: %s | Кол-во: %d" % [GameLogic.format_number(troop.base_power * troop.power_multiplier), troop.count]
	if troop.training_amount > 0:
		stats_label.text += " (+%d нанимается)" % troop.training_amount

	# Кнопки покупки
	buy1_button.disabled = current_gold < troop.get_cost_for(1)
	buy10_button.disabled = current_gold < troop.get_cost_for(10)
	
	var actual_max = troop.get_max_affordable(current_gold)
	if actual_max > 0:
		buymax_button.text = "Макс (%d)" % actual_max
		buymax_button.disabled = false
	else:
		buymax_button.text = "Макс"
		buymax_button.disabled = true
	
	var speed = troop.speed_multiplier
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

	# Стоимость на кнопках
	buy1_button.text = "Нанять (%s)" % GameLogic.format_number(troop.get_cost_for(1))
	
	# Скрытие кнопок если уже тренируется?
	# Нет, по ТЗ можно добавлять в очередь: "Если мы уже тренировались, просто добавляем количество в очередь".
	# Но чтобы не усложнять очередь таймеров, давайте заблокируем найм пока идет текущий.
	if troop.is_training:
		buy1_button.disabled = true
		buy10_button.disabled = true
		buymax_button.disabled = true
		
	# Приглушаем цвет
	modulate.a = 1.0 if (not buy1_button.disabled or troop.is_training) else 0.65

func _on_buy_pressed(amount: int) -> void:
	if troop != null and amount > 0:
		train_pressed.emit(troop, amount)
