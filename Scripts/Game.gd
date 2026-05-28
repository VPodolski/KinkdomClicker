class_name Game
extends Node

signal gold_changed
signal upgrades_changed
signal buildings_changed
signal achievement_unlocked
signal upgrade_completed

var economy: Economy
var buildings: BuildingManager
var upgrades: UpgradeManager
var achievements: AchievementManager
var ascension: AscensionManager

var currentGoldPerSecond = 0.0
var currentPrayerIncome = 0.0

func recalculate_income():
	var achievement_multiplier = achievements.get_income_multiplier()

	var income = buildings.get_total_income(economy.global_income_multiplier)
	income *= achievement_multiplier
	income *= economy.prestige_multiplier
	
	var upkeep = buildings.get_total_upkeep(economy.upkeep_reduction_multiplier)
	var final_income = income - upkeep

	currentGoldPerSecond = final_income
	currentPrayerIncome = buildings.get_total_prayer_income(economy.prayer_multiplier)
func _ready():
	economy = Economy.new()
	buildings = BuildingManager.new()
	upgrades = UpgradeManager.new(self)
	achievements = AchievementManager.new()
	achievements.achievement_unlocked.connect(_on_achievement_unlocked)
	ascension = AscensionManager.new()
	recalculate_income()

func get_click_value() -> float:
	var achievement_multiplier = achievements.get_income_multiplier()
	var income = buildings.get_total_income(economy.global_income_multiplier)
	income *= achievement_multiplier
	income *= economy.prestige_multiplier
	return economy.gold_per_click + income * economy.click_income_ratio

func on_click():
	var value = get_click_value()
	achievements.check(self)
	economy.add_gold(value)
	emit_signal("gold_changed", economy.gold)

func buy_building(index, amount = 1):
	if buildings.buy_building(index, economy, currentGoldPerSecond, amount):
		buildings.update_synergies(upgrades.active_upgrades)
		
		achievements.check(self)
		
		recalculate_income()
		
		emit_signal("buildings_changed")
		emit_signal("gold_changed", economy.gold)

func start_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return

	# Защита от повторной покупки
	if not upgrades.upgrades.has(upgrade):
		return

	if economy.spend_gold(upgrade.cost):
		achievements.check(self)
		upgrade.is_crafting = true
		gold_changed.emit(economy.gold)
		upgrades_changed.emit()

func _process(delta):
	economy.add_gold(currentGoldPerSecond * delta)
	if economy.gold < 0.0:
		economy.gold = 0.0
		
	economy.add_prayers(currentPrayerIncome * delta)

	var speed = get_forge_speed_multiplier()
	upgrades.update_crafting(delta, speed)

	achievements.check(self)


func _on_achievement_unlocked(achievement: AchievementData) -> void:
	recalculate_income()
	achievement_unlocked.emit(achievement)
	gold_changed.emit(economy.gold)

func get_unlocked_achievement_count() -> int:
	return achievements.get_unlocked_count()
	
func get_achievement_multiplier() -> float:
	return achievements.get_income_multiplier()

func get_forge_speed_multiplier():
	var forge = buildings.get_building_by_name("Кузница")
	return 1.0 + economy.forge_speed_multiplier + (forge.count * 0.01)

func format_number(value: float) -> String:
	if value < 1000.0:
		return "%.1f" % value
			
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index = 0
	var temp = value
	
	while temp >= 1000.0 and suffix_index < suffixes.size() - 1:
		temp /= 1000.0
		suffix_index += 1
		
	return "%.2f%s" % [temp, suffixes[suffix_index]]

func perform_rebirth() -> bool:
	economy.gold = 0.0
	economy.gold_per_click = 1.0
	economy.click_income_ratio = 0.0
	economy.global_income_multiplier = 1.0
	
	# Применяем скиллы возвышения
	ascension.reapply_all_skills(economy)
	
	buildings.reset()
	upgrades.reset()
	
	recalculate_income()
	
	gold_changed.emit(economy.gold)
	buildings_changed.emit()
	upgrades_changed.emit()
	
	return true

func get_affordable_upgrades() -> Array:
	var available = []
	for u in upgrades.upgrades:
		if not u.is_crafting and not upgrades.active_upgrades.has(u):
			available.append(u)
			
	available.sort_custom(func(a, b): return a.cost < b.cost)
	
	var affordable = []
	var temp_gold = economy.gold
	for u in available:
		if temp_gold >= u.cost:
			affordable.append(u)
			temp_gold -= u.cost
			
	return affordable

func buy_all_affordable_upgrades() -> void:
	var list = get_affordable_upgrades()
	if list.is_empty():
		return
		
	for u in list:
		if economy.spend_gold(u.cost):
			u.is_crafting = true
			
	achievements.check(self)
	gold_changed.emit(economy.gold)
	upgrades_changed.emit()
