class_name BuildingManager

var buildings: Array[BuildingData] = []

func _init():
	var file = FileAccess.open("res://data/buildings.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for b in data:
				buildings.append(BuildingData.new(b["id"], b["name"], float(b["base_cost"]), float(b.get("income", 0.0)), float(b.get("prayer_income", 0.0)), float(b.get("gold_upkeep", 0.0))))
		else:
			print("Error parsing buildings.json: ", json.get_error_message())
	else:
		print("Failed to open buildings.json")

func get_building_by_name(name):
	for b in buildings:
		if b.name == name:
			return b
	return null

func get_building_by_id(id: String):
	for b in buildings:
		if b.id == id:
			return b
	return null

func get_total_income(global_multiplier: float) -> BigNum:
	var total = BigNum.new(0.0)
	for b in buildings:
		total = total.add(b.get_income())
	return total.mul(global_multiplier)

func get_total_prayer_income(prayer_multiplier: float) -> BigNum:
	var total = BigNum.new(0.0)
	for b in buildings:
		total = total.add(b.get_prayer_income())
	return total.mul(prayer_multiplier)

func get_total_upkeep(upkeep_reduction_multiplier: float) -> BigNum:
	var total = BigNum.new(0.0)
	for b in buildings:
		total = total.add(b.get_total_upkeep())
	return total.mul(upkeep_reduction_multiplier)

func buy_building(index, economy, net_income: BigNum, amount = 1):
	var b = buildings[index]
	var total_cost = b.get_cost_for(amount)
	
	if b.gold_upkeep.is_greater_than(0.0):
		var additional_upkeep = b.get_upkeep_for(amount).mul(economy.upkeep_reduction_multiplier)
		if net_income != null and additional_upkeep.is_greater_equal(net_income):
			return false
	
	if economy.spend_gold(total_cost):
		b.buy_multiple(amount)
		economy.lifetime_unlocked_buildings[b.id] = true
		return true
	
	return false

func update_synergies(active_upgrades):
	for b in buildings:
		b.synergy_bonus = 0.0
	
	for upgrade in active_upgrades:
		if upgrade.effect_type == "building_synergy":
			var source = get_building_by_name(upgrade.source_building)
			var target = get_building_by_name(upgrade.target)
			
			if source and target:
				target.synergy_bonus += source.count * upgrade.effect_value

func reset():
	for b in buildings:
		b.count = 0
		b.cost = b.base_cost
		b.income_multiplier = 1.0
		b.synergy_bonus = 0.0
		b.cost_multiplier = 1.0
		b.has_been_seen = false

func to_dict() -> Dictionary:
	var b_dict = {}
	for b in buildings:
		b_dict[b.id] = {
			"count": b.count,
			"cost": b.cost._to_string(),
			"income_multiplier": b.income_multiplier,
			"synergy_bonus": b.synergy_bonus,
			"cost_multiplier": b.cost_multiplier,
			"has_been_seen": b.has_been_seen,
			"is_masked": b.is_masked
		}
	return {"buildings": b_dict}

func from_dict(dict: Dictionary) -> void:
	if dict.has("buildings"):
		var b_dict = dict["buildings"]
		for b in buildings:
			if b_dict.has(b.id):
				var data = b_dict[b.id]
				b.count = data.get("count", 0)
				b.cost = BigNum.from(data.get("cost", b.base_cost._to_string()))
				b.income_multiplier = data.get("income_multiplier", 1.0)
				b.synergy_bonus = data.get("synergy_bonus", 0.0)
				b.cost_multiplier = data.get("cost_multiplier", 1.0)
				b.has_been_seen = data.get("has_been_seen", false)
				b.is_masked = data.get("is_masked", false)
