class_name Economy

var gold: float = 0.0
var gold_per_click: float = 1
var click_income_ratio: float = 0.0
var global_income_multiplier: float = 1.0

var ui_update_timer := 0.0

func add_gold(amount: float):
	gold += amount

func spend_gold(amount: float) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false
