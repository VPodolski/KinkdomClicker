class_name Economy

var gold: float = 0.0
var gold_per_click: float = 1
var click_income_ratio: float = 0.0
var global_income_multiplier: float = 1.0
var prestige_multiplier: float = 1.0
var times_ascended: int = 0
var forge_speed_multiplier: float = 0.0

var prayers: float = 0.0
var lifetime_prayers: float = 0.0
var prayer_multiplier: float = 1.0
var upkeep_reduction_multiplier: float = 1.0

var ui_update_timer := 0.0

func add_gold(amount: float):
	gold += amount

func spend_gold(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func add_prayers(amount: float):
	if amount > 0:
		prayers += amount
		lifetime_prayers += amount

func spend_prayers(amount: float) -> bool:
	if prayers >= amount:
		prayers -= amount
		return true
	return false
