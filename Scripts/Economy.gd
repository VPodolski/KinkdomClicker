class_name Economy

var gold: BigNum = BigNum.new(0.0)
var gold_per_click: BigNum = BigNum.new(1.0)
var click_income_ratio: float = 0.0
var global_income_multiplier: float = 1.0
var prestige_multiplier: float = 1.0
var times_ascended: int = 0
var forge_speed_multiplier: float = 0.0

var prayers: BigNum = BigNum.new(0.0)
var lifetime_prayers: BigNum = BigNum.new(0.0)
var prayer_multiplier: float = 1.0
var upkeep_reduction_multiplier: float = 1.0

var troop_power_multiplier: float = 1.0
var troop_cost_multiplier: float = 1.0
var troop_speed_multiplier: float = 1.0
var troop_upkeep_multipliers: Dictionary = {}

func get_troop_upkeep_multiplier(troop_id: String) -> float:
	return troop_upkeep_multipliers.get(troop_id, 1.0)

var ui_update_timer := 0.0

func add_gold(amount) -> void:
	gold = gold.add(amount)

func spend_gold(amount) -> bool:
	var a = BigNum.from(amount)
	if gold.is_greater_equal(a):
		gold = gold.sub(a)
		return true
	return false

func add_prayers(amount) -> void:
	var a = BigNum.from(amount)
	if a.is_greater_than(0.0):
		prayers = prayers.add(a)
		lifetime_prayers = lifetime_prayers.add(a)

func spend_prayers(amount) -> bool:
	var a = BigNum.from(amount)
	if prayers.is_greater_equal(a):
		prayers = prayers.sub(a)
		return true
	return false
