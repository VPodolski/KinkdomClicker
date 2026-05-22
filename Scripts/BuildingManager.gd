class_name BuildingManager

var buildings = []

func _init():
	buildings.append(BuildingData.new("farm", "Ферма", 10, 1))
	buildings.append(BuildingData.new("sawmill", "Лесопилка", 50, 5))
	buildings.append(BuildingData.new("quarry", "Каменоломня", 150, 15))
	buildings.append(BuildingData.new("forge", "Кузница", 10, 50))
	buildings.append(BuildingData.new("market", "Рынок", 1500, 150))
	buildings.append(BuildingData.new("guild", "Гильдия", 5000, 500))
	buildings.append(BuildingData.new("bank", "Банк", 20000, 2000))
	buildings.append(BuildingData.new("castle", "Замок", 100000, 10000))

func get_building_by_name(name):
	for b in buildings:
		if b.name == name:
			return b
	return null

func get_total_income(global_multiplier):
	var total = 0.0
	for b in buildings:
		total += b.get_income()
	return total * global_multiplier

func buy_building(index, economy, amount = 1):
	var b = buildings[index]
	var total_cost = b.get_cost_for(amount)
	
	if economy.spend_gold(total_cost):
		b.buy_multiple(amount)
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
