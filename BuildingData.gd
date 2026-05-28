class_name BuildingData

var id: String
var name: String
var base_cost: float
var cost: float

# Базовый доход одного здания
var income: float
var prayer_income: float
var gold_upkeep: float

# Количество купленных зданий
var count: int = 0

# Множители
var income_multiplier: float = 1.0
var synergy_bonus: float = 0.0
var cost_multiplier: float = 1.0

var has_been_seen: bool = false
var is_masked: bool = false

func _init(_id: String, _name: String, _base_cost: float, _income: float, _prayer_income: float = 0.0, _gold_upkeep: float = 0.0):
	id = _id
	name = _name
	base_cost = _base_cost
	cost = _base_cost
	income = _income
	prayer_income = _prayer_income
	gold_upkeep = _gold_upkeep


func buy() -> void:
	buy_multiple(1)

func buy_multiple(amount: int) -> void:
	count += amount
	cost = int(base_cost * cost_multiplier * pow(1.2, count))

func get_cost_for(amount: int) -> float:
	var total = 0.0
	for i in range(amount):
		total += int(base_cost * cost_multiplier * pow(1.2, count + i))
	return total

func get_max_affordable(current_gold: float) -> int:
	var affordable = 0
	var total_cost = 0.0
	while true:
		var next_cost = int(base_cost * cost_multiplier * pow(1.2, count + affordable))
		if total_cost + next_cost > current_gold:
			break
		total_cost += next_cost
		affordable += 1
		if affordable > 10000: # Safe guard
			break
	return affordable


# Доход одного здания с учётом всех бонусов
func get_income_per_unit() -> float:
	return income * (income_multiplier + synergy_bonus)


# Общий доход всех купленных зданий
func get_income() -> float:
	return get_income_per_unit() * count

# Доход молитв с одного здания
func get_prayer_income_per_unit() -> float:
	return prayer_income

# Общий доход молитв
func get_prayer_income() -> float:
	return get_prayer_income_per_unit() * count

# Стоимость обслуживания одного здания
func get_upkeep_per_unit() -> float:
	return gold_upkeep

# Общая стоимость обслуживания
func get_total_upkeep() -> float:
	return get_upkeep_per_unit() * count
