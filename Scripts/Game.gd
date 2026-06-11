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
var war: WarManager
var expeditions: ExpeditionManager
var archeology: ArcheologyManager
	

var currentGoldPerSecond: BigNum = BigNum.new(0.0)
var currentBaseNetIncome: BigNum = BigNum.new(0.0)
var currentPrayerIncome: BigNum = BigNum.new(0.0)

func recalculate_income():
	var achievement_multiplier = achievements.get_income_multiplier()

	var income = buildings.get_total_income(economy.global_income_multiplier)
	income = income.mul(achievement_multiplier)
	income = income.mul(economy.prestige_multiplier)
	if archeology:
		var arch_mult = archeology.get_kingdom_gold_multiplier()
		income = income.mul(arch_mult)
	
	
	var upkeep = buildings.get_total_upkeep(economy.upkeep_reduction_multiplier)
	if archeology:
		var arch_upkeep_mult = archeology.get_kingdom_army_upkeep_multiplier()
		upkeep = upkeep.mul(arch_upkeep_mult)
	if war:
		var war_upkeep = war.get_total_upkeep().mul(economy.upkeep_reduction_multiplier)
		if archeology:
			war_upkeep = war_upkeep.mul(archeology.get_kingdom_army_upkeep_multiplier())
		upkeep = upkeep.add(war_upkeep)
	var final_income = income.sub(upkeep)
	currentBaseNetIncome = final_income
	
	var captive_skill = ascension.get_skill_level("captives_bonus")
	if expeditions and captive_skill > 0:
		var bonus_per_captive = captive_skill * 0.001
		final_income = final_income.mul(1.0 + expeditions.total_captives * bonus_per_captive)

	currentGoldPerSecond = final_income
	currentPrayerIncome = buildings.get_total_prayer_income(economy.prayer_multiplier)
	
	var building_cost_mult = 1.0
	if archeology:
		building_cost_mult = archeology.get_kingdom_building_cost_multiplier()
	for b in buildings.buildings:
		b.cost_multiplier = building_cost_mult
		b.cost = b._calc_cost(b.count)
func _ready():
	economy = Economy.new()
	buildings = BuildingManager.new()
	upgrades = UpgradeManager.new(self)
	achievements = AchievementManager.new()
	achievements.achievement_unlocked.connect(_on_achievement_unlocked)
	ascension = AscensionManager.new()
	war = WarManager.new(self)
	war.troops_changed.connect(recalculate_income)
	expeditions = ExpeditionManager.new(self)
	archeology = ArcheologyManager.new(self)
	recalculate_income()
	
	Engine.time_scale = 1000.0
	print("Developer Mode: ON by default (Speed x1000)")

func get_click_value() -> BigNum:
	var achievement_multiplier = achievements.get_income_multiplier()
	var income = buildings.get_total_income(economy.global_income_multiplier)
	income = income.mul(achievement_multiplier)
	income = income.mul(economy.prestige_multiplier)
	if archeology:
		income = income.mul(archeology.get_kingdom_gold_multiplier())
	var click_income = income.mul(economy.click_income_ratio)
	var final_click = economy.gold_per_click.add(click_income)
	
	if Engine.time_scale > 1.0:
		final_click = final_click.mul(Engine.time_scale)
		
	return final_click

func on_click():
	var value = get_click_value()
	achievements.check(self)
	economy.add_gold(value)
	emit_signal("gold_changed", economy.gold)

func buy_building(index, amount = 1):
	if buildings.buy_building(index, economy, currentBaseNetIncome, amount):
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
	economy.add_gold(currentGoldPerSecond.mul(delta))
	if economy.gold.is_less_than(0.0):
		economy.gold = BigNum.new(0.0)
		
	economy.add_prayers(currentPrayerIncome.mul(delta))

	var speed = get_forge_speed_multiplier()
	upgrades.update_crafting(delta, speed)
	war.update_training(delta)
	expeditions.update(delta)
	archeology.update(delta)

	achievements.check(self)


func _on_achievement_unlocked(achievement: AchievementData) -> void:
	recalculate_income()
	achievement_unlocked.emit(achievement)
	gold_changed.emit(economy.gold)

func emit_upgrade_completed(upgrade) -> void:
	upgrade_completed.emit(upgrade)

func get_unlocked_achievement_count() -> int:
	return achievements.get_unlocked_count()
	
func get_achievement_multiplier() -> float:
	return achievements.get_income_multiplier()

func get_forge_speed_multiplier():
	var forge = buildings.get_building_by_name("Кузница")
	return 1.0 + economy.forge_speed_multiplier + (forge.count * 0.01)

func format_number(value) -> String:
	if value is BigNum:
		return value.format()
	else:
		return BigNum.from(value).format()

func perform_rebirth() -> bool:
	economy.gold = BigNum.new(0.0)
	economy.gold_per_click = BigNum.new(1.0)
	economy.click_income_ratio = 0.0
	economy.global_income_multiplier = 1.0
	
	# Применяем скиллы возвышения
	ascension.reapply_all_skills(economy)
	
	buildings.reset()
	upgrades.reset()
	war.reset(ascension.has_skill("keep_commanders"))
	archeology.reset()
	
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
			
	available.sort_custom(func(a, b): return a.cost.is_less_than(b.cost))
	
	var affordable = []
	var temp_gold = BigNum.from(economy.gold)
	for u in available:
		if temp_gold.is_greater_equal(u.cost):
			affordable.append(u)
			temp_gold = temp_gold.sub(u.cost)
			
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

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			if Engine.time_scale == 1.0:
				Engine.time_scale = 1000.0
				print("Developer Mode: ON (Speed x1000)")
			else:
				Engine.time_scale = 1.0
				print("Developer Mode: OFF (Speed x1)")
