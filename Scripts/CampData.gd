class_name CampData
extends RefCounted

enum Status { IDLE, SCOUTING, TRAVELING, FIGHTING, RETURNING, DEFEATED }

var id: String
var status: Status = Status.IDLE
var position: Vector2 # Для 2D карты

# Время в секундах
var distance_time: float = 60.0
var timer: float = 0.0

# Сила врага
var exact_power: float = 0.0
var min_power_display: float = 0.0
var max_power_display: float = 0.0

var is_scouted: bool = false
var is_defeated: bool = false

# Награды
var gold_reward: float = 0.0
var captives_reward: int = 0

# Текущий отряд игрока, отправленный сюда
var player_army: ArmyGroup = null

func _init(_id: String, _pos: Vector2, _power: float, _time: float):
	id = _id
	position = _pos
	exact_power = _power
	
	# Разброс +- 30% для неразведанной силы
	min_power_display = max(1.0, exact_power * 0.7)
	max_power_display = exact_power * 1.3
	
	distance_time = _time
	timer = 0.0
	
	# Генерация наград
	gold_reward = exact_power * 50.0
	captives_reward = max(1, int(exact_power / 100.0))

func get_display_power() -> String:
	if is_scouted:
		return str(int(exact_power))
	return "%d - %d" % [int(min_power_display), int(max_power_display)]
