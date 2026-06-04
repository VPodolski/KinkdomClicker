class_name ArmyGroup
extends RefCounted

# Словарь для хранения войск в отряде: id юнита -> количество
var troops: Dictionary = {}

# Суммарная базовая сила отряда на момент выхода (до множителей)
var base_power: float = 0.0

# Мораль (Снабжение): от 0.85 (Low) до 1.15 (High)
var morale_multiplier: float = 1.0

# Уровень полководца
var commander_level: int = 1

var is_scouting_mission: bool = false

func _init():
	troops = {}
	base_power = 0.0
	morale_multiplier = 1.0
	commander_level = 1
	is_scouting_mission = false

func add_troops(troop_id: String, amount: int, power_per_unit: float):
	if not troops.has(troop_id):
		troops[troop_id] = 0
	troops[troop_id] += amount
	base_power += amount * power_per_unit

func get_troop_count(troop_id: String) -> int:
	return troops.get(troop_id, 0)
