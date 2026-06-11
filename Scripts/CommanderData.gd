class_name CommanderData
extends RefCounted

var troop_id: String
var is_unlocked: bool = false
var is_training: bool = false
var is_on_expedition: bool = false
var training_progress: float = 0.0
var base_time: float = 600.0

var max_hp_base: float = 100.0
var current_hp: float = 0.0

var hp_level: int = 0
var luck_level: int = 0
var loot_level: int = 0
var power_level: int = 0
var speed_level: int = 0
var equipped_artifact_level: int = 0

var max_luck_level: int = 7

func _init(_troop_id: String, _base_time: float):
	troop_id = _troop_id
	base_time = _base_time

func get_max_hp() -> float:
	return max_hp_base + (hp_level * 50.0)

func get_luck_chance() -> float:
	# Base 3%, max 10% (at level 7)
	return 0.03 + (min(luck_level, max_luck_level) * 0.01)

func get_loot_multiplier() -> float:
	# Base 0% bonus, +10% per level
	return 1.0 + (loot_level * 0.1)

func get_power_multiplier() -> float:
	# Base 0% bonus, +10% per level
	var asc_bonus = GameLogic.ascension.get_skill_level("commander_power") * 0.1
	return (1.0 + (power_level * 0.1)) * (1.0 + asc_bonus)

func get_speed_multiplier() -> float:
	# Base 0% bonus, +10% per level
	return 1.0 + (speed_level * 0.1)

func start_training():
	if not is_unlocked and not is_training:
		is_training = true
		training_progress = 0.0

func finish_training():
	is_training = false
	is_unlocked = true
	current_hp = get_max_hp()
	training_progress = 0.0

func take_damage(amount: float):
	if not is_unlocked: return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		is_unlocked = false
		# Dies, needs retraining

func heal(delta: float, current_speed_mult: float):
	if is_unlocked and current_hp < get_max_hp() and not is_on_expedition:
		var asc_regen = 1.0 + (GameLogic.ascension.get_skill_level("commander_regen") * 0.2)
		var total_heal_time = base_time / (current_speed_mult * 2.0 * asc_regen)
		var heal_rate = get_max_hp() / total_heal_time
		current_hp = min(current_hp + heal_rate * delta, get_max_hp())

# Costs for upgrades
func get_upgrade_cost(type: String) -> BigNum:
	var level = 0
	if type == "hp": level = hp_level
	elif type == "luck": level = luck_level
	elif type == "loot": level = loot_level
	elif type == "power": level = power_level
	elif type == "speed": level = speed_level
	
	# Base 10,000, x2 per level
	return BigNum.from(10000.0).mul(pow(2.0, level))

func buy_upgrade(type: String, economy: Economy) -> bool:
	var cost = get_upgrade_cost(type)
	if type == "luck" and luck_level >= max_luck_level:
		return false
		
	if economy.spend_prayers(cost):
		if type == "hp": 
			hp_level += 1
			current_hp += 50.0 # Heal for the amount gained
		elif type == "luck": luck_level += 1
		elif type == "loot": loot_level += 1
		elif type == "power": power_level += 1
		elif type == "speed": speed_level += 1
		return true
	return false

func reset():
	is_unlocked = false
	is_training = false
	is_on_expedition = false
	training_progress = 0.0
	current_hp = 0.0
	hp_level = 0
	luck_level = 0
	loot_level = 0
	power_level = 0
	speed_level = 0
	equipped_artifact_level = 0
