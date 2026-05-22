class_name Game
extends Node

signal gold_changed
signal upgrades_changed
signal buildings_changed
signal achievement_unlocked

var economy: Economy
var buildings: BuildingManager
var upgrades: UpgradeManager
var achievements: AchievementManager

var currentGoldPerSecond = 0.0

func _ready():
	economy = Economy.new()
	buildings = BuildingManager.new()
	upgrades = UpgradeManager.new(economy, buildings)
	achievements = AchievementManager.new()
	achievements.achievement_unlocked.connect(_on_achievement_unlocked)

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
	if buildings.buy_building(index, economy, amount):
		buildings.update_synergies(upgrades.active_upgrades)
		
		achievements.check(self)
		
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
	var achievement_multiplier = achievements.get_income_multiplier()

	var income = buildings.get_total_income(
		economy.global_income_multiplier
	)

	income *= achievement_multiplier
	income *= economy.prestige_multiplier

	currentGoldPerSecond = income

	economy.add_gold(income * delta)

	var speed = get_forge_speed_multiplier()
	upgrades.update_crafting(delta, speed)

	achievements.check(self)


func _on_achievement_unlocked(achievement: AchievementData) -> void:
	achievement_unlocked.emit(achievement)
	gold_changed.emit(economy.gold)

func get_unlocked_achievement_count() -> int:
	return achievements.get_unlocked_count()
	
func get_achievement_multiplier() -> float:
	return achievements.get_income_multiplier()

func get_forge_speed_multiplier():
	var forge = buildings.get_building_by_name("Кузница")
	return 1.0 + (forge.count * 0.01)  # +1% за кузницу

func format_number(value: float) -> String:
	# Простое красивое форматирование без лишних нулей.
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	elif value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	elif value == floor(value):
		return str(int(value))
	else:
		return "%.2f" % value

func get_expected_prestige_bonus(gold_amount: float) -> float:
	return (gold_amount / 500000.0) * 0.1

func ascend() -> bool:
	if economy.gold < 500000.0:
		return false
	
	var bonus = get_expected_prestige_bonus(economy.gold)
	economy.prestige_multiplier += bonus
	economy.times_ascended += 1
	
	# Reset economy
	economy.gold = 0.0
	economy.gold_per_click = 1.0
	economy.click_income_ratio = 0.0
	economy.global_income_multiplier = 1.0
	
	# Reset systems
	buildings.reset()
	upgrades.reset()
	
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
