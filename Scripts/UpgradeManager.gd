class_name UpgradeManager

var upgrades = []
var active_upgrades = []

var economy
var buildings

func _init(_economy, _buildings):
	economy = _economy
	buildings = _buildings
	_init_upgrades()

func _init_upgrades():
	var file = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for u in data:
				var target = u.get("target", "")
				var source_building = u.get("source_building", "")
				upgrades.append(UpgradeData.new(
					u["name"], u["description"], float(u["cost"]), float(u["base_time"]),
					u["effect_type"], float(u["effect_value"]), target, source_building
				))
		else:
			print("Error parsing upgrades.json: ", json.get_error_message())
	else:
		print("Failed to open upgrades.json")

func reset():
	active_upgrades.clear()
	_init_upgrades()

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
