class_name AchievementManager

signal achievement_unlocked(achievement)

var achievements: Array[AchievementData] = []


func _init():
	achievements = [
		AchievementData.new(
			"first_click",
			"Первый клик",
			"Соберите первое золото."
		),
		AchievementData.new(
			"first_farm",
			"Первый фермер",
			"Постройте первую ферму."
		),
		AchievementData.new(
			"100_gold",
			"Сотня золота",
			"Накопите 100 золота."
		),
		AchievementData.new(
			"1000_gold",
			"Богач",
			"Накопите 1000 золота."
		),
		AchievementData.new(
			"first_upgrade",
			"Изобретатель",
			"Создайте первое улучшение."
		)
	]


func check(game: Game) -> void:
	_unlock_if("first_click", game.economy.gold > 0)
	_unlock_if(
		"first_farm",
		game.buildings.get_building_by_name("Ферма").count >= 1
	)
	_unlock_if("100_gold", game.economy.gold >= 100)
	_unlock_if("1000_gold", game.economy.gold >= 1000)
	_unlock_if("first_upgrade", game.upgrades.active_upgrades.size() >= 1)


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
