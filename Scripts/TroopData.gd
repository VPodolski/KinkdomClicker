class_name TroopData

var id: String
var name: String
var description: String
var base_power: float
var base_cost: float
var base_time: float

# Нанятое количество и прогресс текущего найма
var count: int = 0
var is_training: bool = false
var training_progress: float = 0.0
var training_amount: int = 0 # сколько отрядов сейчас тренируется

# Множители для будущего возвышения
var power_multiplier: float = 1.0
var cost_multiplier: float = 1.0
var speed_multiplier: float = 1.0

func _init(_id: String, _name: String, _desc: String, _power: float, _cost: float, _time: float):
	id = _id
	name = _name
	description = _desc
	base_power = _power
	base_cost = _cost
	base_time = _time

# Прогрессивная стоимость (множитель 1.02 для массового найма)
func get_cost_for(amount: int) -> float:
	var total = 0.0
	for i in range(amount):
		total += int(base_cost * cost_multiplier * pow(1.02, count + training_amount + i))
	return total

func get_max_affordable(current_gold: float) -> int:
	var affordable = 0
	var total_cost = 0.0
	while true:
		var next_cost = int(base_cost * cost_multiplier * pow(1.02, count + training_amount + affordable))
		if total_cost + next_cost > current_gold:
			break
		total_cost += next_cost
		affordable += 1
		if affordable > 10000: # Safe guard
			break
	return affordable

# Общая сила этого типа войск
func get_total_power() -> float:
	return base_power * power_multiplier * count

# Начать тренировку
func start_training(amount: int) -> void:
	training_amount += amount
	is_training = true
	# Если мы уже тренировались, просто добавляем количество в очередь, 
	# время продлевать не будем, но время зависит от количества. 
	# Для простоты: base_time * training_amount.
	# Но лучше не усложнять и просто использовать один таймер на всю партию.
	
# Завершить тренировку
func finish_training() -> void:
	count += training_amount
	training_amount = 0
	is_training = false
	training_progress = 0.0
