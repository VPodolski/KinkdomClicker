class_name AchievementManager

signal achievement_unlocked(achievement)

var achievements: Array[AchievementData] = []


func _init():
	var file = FileAccess.open("res://data/achievements.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for a in data:
				achievements.append(AchievementData.new(a["id"], a["title"], a["description"]))
		else:
			print("Error parsing achievements.json: ", json.get_error_message())
	else:
		print("Failed to open achievements.json")


func check(game: Node) -> void:
	_unlock_if("first_click", game.economy.gold.is_greater_than(0))
	_unlock_if("100_gold", game.economy.gold.is_greater_equal(100))
	_unlock_if("10k_gold", game.economy.gold.is_greater_equal(10_000))
	_unlock_if("1M_gold", game.economy.gold.is_greater_equal(1_000_000))
	_unlock_if("1B_gold", game.economy.gold.is_greater_equal(1_000_000_000))
	_unlock_if("1T_gold", game.economy.gold.is_greater_equal(1_000_000_000_000))
	_unlock_if("1Qa_gold", game.economy.gold.is_greater_equal(1_000_000_000_000_000))
	
	var farm = game.buildings.get_building_by_name("Ферма")
	if farm: _unlock_if("first_farm", farm.count >= 1)
	_unlock_if("first_upgrade", game.upgrades.active_upgrades.size() >= 1)
	
	for count in [10, 50, 100]:
		if farm: _unlock_if("farms_" + str(count), farm.count >= count)
		var sawmill = game.buildings.get_building_by_name("Лесопилка")
		if sawmill: _unlock_if("sawmills_" + str(count), sawmill.count >= count)
		var quarry = game.buildings.get_building_by_name("Каменоломня")
		if quarry: _unlock_if("quarries_" + str(count), quarry.count >= count)

	var all_10 = true
	for b in game.buildings.buildings:
		if b.count < 10:
			all_10 = false
			break
	_unlock_if("all_buildings_10", all_10)


func _unlock_if(id: String, condition: bool) -> void:
	if not condition:
		return

	var achievement = get_by_id(id)
	if achievement == null:
		return

	if achievement.unlocked:
		return

	achievement.unlocked = true
	achievement_unlocked.emit(achievement)


func get_by_id(id: String) -> AchievementData:
	for achievement in achievements:
		if achievement.id == id:
			return achievement
	return null


func get_unlocked_count() -> int:
	var count := 0
	for achievement in achievements:
		if achievement.unlocked:
			count += 1
	return count


func get_income_multiplier() -> float:
	return 1.0 + get_unlocked_count() * 0.1


func get_unlocked_achievements() -> Array[AchievementData]:
	var result: Array[AchievementData] = []

	for achievement in achievements:
		if achievement.unlocked:
			result.append(achievement)

	return result
