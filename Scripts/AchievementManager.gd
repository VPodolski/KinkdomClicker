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
	# 1. Gold
	var thresholds_gold = {
		"first_click": BigNum.from(1),
		"100_gold": BigNum.from(100),
		"10k_gold": BigNum.from(10000),
		"1M_gold": BigNum.from(1000000),
		"1B_gold": BigNum.from(1000000000),
		"1T_gold": BigNum.from(1000000000000),
		"1Qa_gold": BigNum.from(1000000000000000),
		"1Qi_gold": BigNum.from("1000000000000000000"),
		"1Sx_gold": BigNum.from("1000000000000000000000"),
		"1Sp_gold": BigNum.from("1000000000000000000000000"),
	}
	for k in thresholds_gold.keys():
		_unlock_if(k, game.economy.gold.is_greater_equal(thresholds_gold[k]))
		
	# 2. Buildings
	var b_thresholds = [1, 10, 50, 100, 250, 500]
	for b in game.buildings.buildings:
		for t in b_thresholds:
			if b.count >= t:
				_unlock_if("build_%s_%d" % [b.id, t], true)
				
	# 3. Upgrades
	var upg_count = game.upgrades.active_upgrades.size()
	for t in [1, 10, 25, 50, 100, 150]:
		_unlock_if("upgrades_%d" % t, upg_count >= t)
		
	# 4. Troops & Commanders
	var troops_count = 0.0
	var cmd_count = 0
	for t in game.war.troops:
		troops_count += t.count
		if t.commander and t.commander.is_unlocked:
			cmd_count += 1
	
	_unlock_if("troops_1000", troops_count >= 1000)
	_unlock_if("troops_1000000", troops_count >= 1000000)
	_unlock_if("troops_1000000000", troops_count >= 1000000000)
	
	for t in [1, 5, 10, 15]:
		_unlock_if("cmd_%d" % t, cmd_count >= t)
		
	# 5. Expeditions
	var tier = game.expeditions.map_tier
	for t in [2, 5, 10, 25, 50]:
		_unlock_if("map_tier_%d" % t, tier >= t)
		
	# 6. Archeology
	if game.archeology:
		var arts_inv = game.archeology.inventory_artifacts.size()
		var arts_king = game.archeology.kingdom_artifacts.size()
		var archs = game.archeology.archeologists_count
		
		for t in [1, 10, 50]:
			_unlock_if("arts_inv_%d" % t, arts_inv >= t)
		for t in [1, 5, 10]:
			_unlock_if("arts_king_%d" % t, arts_king >= t)
		for t in [10, 50, 100]:
			_unlock_if("archs_%d" % t, archs >= t)
			
		var has_lvl_10 = false
		for a in game.archeology.inventory_artifacts:
			if a >= 10: has_lvl_10 = true
		for a in game.archeology.kingdom_artifacts:
			if a >= 10: has_lvl_10 = true
		_unlock_if("art_lvl_10", has_lvl_10)

	# 7. Ascension
	var prayers = game.economy.lifetime_prayers
	for t in [100, 1000, 10000, 100000]:
		_unlock_if("prayers_%d" % t, prayers.is_greater_equal(t))
	
	if game.economy.times_ascended > 0:
		_unlock_if("first_ascension", true)


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
