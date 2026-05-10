class_name BuildingManager

var buildings = []

func _init():
	buildings.append(BuildingData.new("Ферма", 10, 1))
	buildings.append(BuildingData.new("Лесопилка", 50, 5))
	buildings.append(BuildingData.new("Каменоломня", 150, 15))
	buildings.append(BuildingData.new("Кузница", 10, 50))
	buildings.append(BuildingData.new("Рынок", 1500, 150))
	buildings.append(BuildingData.new("Гильдия", 5000, 500))
	buildings.append(BuildingData.new("Банк", 20000, 2000))
	buildings.append(BuildingData.new("Замок", 100000, 10000))

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

func buy_building(index, economy):
	var b = buildings[index]
	
	if economy.spend_gold(b.cost):
		b.buy()
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
