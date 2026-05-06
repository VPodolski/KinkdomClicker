class_name UpgradeManager

var upgrades = []
var active_upgrades = []

var economy
var buildings

func _init(_economy, _buildings):
	economy = _economy
	buildings = _buildings

func apply_upgrade(upgrade):
	match upgrade.effect_type:
		"click_bonus":
			economy.gold_per_click += upgrade.effect_value
		
		"click_from_income":
			economy.click_income_ratio += upgrade.effect_value
		
		"income_multiplier":
			var b = buildings.get_building_by_name(upgrade.target)
			if b:
				b.income_multiplier += upgrade.effect_value
		
		"global_multiplier":
			economy.global_income_multiplier += upgrade.effect_value

func update_crafting(delta, forge_speed):
	for upgrade in upgrades:
		if upgrade.is_crafting:
			upgrade.progress += delta * forge_speed
			
			if upgrade.progress >= upgrade.base_time:
				complete_upgrade(upgrade)


func complete_upgrade(upgrade):
	apply_upgrade(upgrade)
	active_upgrades.append(upgrade)
	upgrades.erase(upgrade)
