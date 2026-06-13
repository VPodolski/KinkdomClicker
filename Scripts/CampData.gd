class_name CampData
extends RefCounted

enum Status { IDLE, SCOUTING, TRAVELING, FIGHTING, RETURNING, DEFEATED, WAITING_RETURN }

var id: String
var camp_name: String = ""
var status: Status = Status.IDLE
var position: Vector2 # Для 2D карты
var is_boss: bool = false
var is_unlocked: bool = false

# Время в секундах
var distance_time: float = 60.0
var timer: float = 0.0

# Сила врага
var initial_power: float
var exact_power: BigNum
var min_power_display: BigNum
var max_power_display: BigNum

var enemy_troops: Dictionary = {} # troop_id -> count

var intel_percent: float = 0.0
var enemy_scouts_count: int = 0
var is_defeated: bool = false

# Награды
var gold_reward: BigNum
var captives_reward: int = 0
var casualties_pct_taken: float = 0.0

var pending_gold_reward: BigNum
var pending_captives_reward: int = 0
var pending_commander_xp: float = 0.0
var pending_artifacts_awarded: int = 0
var pending_artifact_level: int = 1

# Данные для окна результатов
var last_combat_losses: Dictionary = {}
var last_commander_losses: Dictionary = {}
var last_enemy_killed: int = 0

# Текущий отряд игрока, отправленный сюда
var player_army: ArmyGroup = null

func _init(_id: String, _name: String, _pos: Vector2, _power: float, _time: float, _is_boss: bool = false, _is_unlocked: bool = false):
	id = _id
	camp_name = _name
	position = _pos
	initial_power = _power
	exact_power = BigNum.from(_power)
	is_boss = _is_boss
	is_unlocked = _is_unlocked
	
	# Разброс +- 30% для неразведанной силы
	min_power_display = exact_power.mul(0.7).max(BigNum.from(1.0))
	max_power_display = exact_power.mul(1.3)
	
	distance_time = _time
	timer = 0.0
	
	# Генерация наград
	if is_boss:
		gold_reward = exact_power.mul(500.0) # x10 gold for boss
		captives_reward = max(10, int(_power / 10.0))
	else:
		gold_reward = exact_power.mul(50.0)
		captives_reward = max(1, int(_power / 100.0))

func get_display_power() -> String:
	if intel_percent >= 1.0:
		return exact_power.format()
	
	# lerp for BigNum is tricky, we can just mix them manually
	# min_p * (1-intel) + exact_p * intel
	var current_min = min_power_display.mul(1.0 - intel_percent).add(exact_power.mul(intel_percent))
	var current_max = max_power_display.mul(1.0 - intel_percent).add(exact_power.mul(intel_percent))
	return "%s - %s" % [current_min.format(), current_max.format()]

func add_intel(amount: float):
	intel_percent += amount
	if intel_percent > 1.0:
		intel_percent = 1.0

func get_total_enemy_count() -> int:
	var total = 0
	for count in enemy_troops.values():
		total += count
	return total
