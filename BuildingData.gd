class_name BuildingData

var name: String
var base_cost: float
var cost: float

# Базовый доход одного здания
var income: float

# Количество купленных зданий
var count: int = 0

# Множители
var income_multiplier: float = 1.0
var synergy_bonus: float = 0.0


func _init(_name: String, _base_cost: float, _income: float):
	name = _name
	base_cost = _base_cost
	cost = _base_cost
	income = _income


func buy() -> void:
	count += 1
	cost = int(base_cost * pow(1.2, count))


# Доход одного здания с учётом всех бонусов
func get_income_per_unit() -> float:
	return income * (income_multiplier + synergy_bonus)


# Общий доход всех купленных зданий
func get_income() -> float:
	return get_income_per_unit() * count
