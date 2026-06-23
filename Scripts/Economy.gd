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

var lifetime_unlocked_buildings: Dictionary = {}
var lifetime_unlocked_troops: Dictionary = {}


var troop_power_multiplier: float = 1.0
var troop_cost_multiplier: float = 1.0
var troop_speed_multiplier: float = 1.0
var troop_upkeep_multipliers: Dictionary = {}

func get_troop_upkeep_multiplier(troop_id: String) -> float:
	return troop_upkeep_multipliers.get(troop_id, 1.0)

var ui_update_timer := 0.0

func add_gold(amount) -> void:
	gold = gold.add(amount)

func add_gold_mul(amount_bignum: BigNum, factor: float) -> void:
	gold.add_mut_mul(amount_bignum, factor)

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

func add_prayers_mul(amount_bignum: BigNum, factor: float) -> void:
	if amount_bignum.m > 0.0 and factor > 0.0:
		prayers.add_mut_mul(amount_bignum, factor)
		lifetime_prayers.add_mut_mul(amount_bignum, factor)

func spend_prayers(amount) -> bool:
	var a = BigNum.from(amount)
	if prayers.is_greater_equal(a):
		prayers = prayers.sub(a)
		return true
	return false

func to_dict() -> Dictionary:
	return {
		"gold": gold._to_string(),
		"gold_per_click": gold_per_click._to_string(),
		"click_income_ratio": click_income_ratio,
		"global_income_multiplier": global_income_multiplier,
		"prestige_multiplier": prestige_multiplier,
		"times_ascended": times_ascended,
		"forge_speed_multiplier": forge_speed_multiplier,
		"prayers": prayers._to_string(),
		"lifetime_prayers": lifetime_prayers._to_string(),
		"prayer_multiplier": prayer_multiplier,
		"upkeep_reduction_multiplier": upkeep_reduction_multiplier,
		"lifetime_unlocked_buildings": lifetime_unlocked_buildings,
		"lifetime_unlocked_troops": lifetime_unlocked_troops,
		"troop_power_multiplier": troop_power_multiplier,
		"troop_cost_multiplier": troop_cost_multiplier,
		"troop_speed_multiplier": troop_speed_multiplier,
		"troop_upkeep_multipliers": troop_upkeep_multipliers
	}

func from_dict(dict: Dictionary) -> void:
	if dict.has("gold"): gold = BigNum.from(dict["gold"])
	if dict.has("gold_per_click"): gold_per_click = BigNum.from(dict["gold_per_click"])
	if dict.has("click_income_ratio"): click_income_ratio = dict["click_income_ratio"]
	if dict.has("global_income_multiplier"): global_income_multiplier = dict["global_income_multiplier"]
	if dict.has("prestige_multiplier"): prestige_multiplier = dict["prestige_multiplier"]
	if dict.has("times_ascended"): times_ascended = dict["times_ascended"]
	if dict.has("forge_speed_multiplier"): forge_speed_multiplier = dict["forge_speed_multiplier"]
	if dict.has("prayers"): prayers = BigNum.from(dict["prayers"])
	if dict.has("lifetime_prayers"): lifetime_prayers = BigNum.from(dict["lifetime_prayers"])
	if dict.has("prayer_multiplier"): prayer_multiplier = dict["prayer_multiplier"]
	if dict.has("upkeep_reduction_multiplier"): upkeep_reduction_multiplier = dict["upkeep_reduction_multiplier"]
	if dict.has("lifetime_unlocked_buildings"): lifetime_unlocked_buildings = dict["lifetime_unlocked_buildings"]
	if dict.has("lifetime_unlocked_troops"): lifetime_unlocked_troops = dict["lifetime_unlocked_troops"]
	if dict.has("troop_power_multiplier"): troop_power_multiplier = dict["troop_power_multiplier"]
	if dict.has("troop_cost_multiplier"): troop_cost_multiplier = dict["troop_cost_multiplier"]
	if dict.has("troop_speed_multiplier"): troop_speed_multiplier = dict["troop_speed_multiplier"]
	if dict.has("troop_upkeep_multipliers"): troop_upkeep_multipliers = dict["troop_upkeep_multipliers"]
