class_name Game
extends Node

signal gold_changed
signal upgrades_changed
signal buildings_changed
signal achievement_unlocked
signal upgrade_completed
signal developer_mode_toggled(is_active)

var economy: Economy
var buildings: BuildingManager
var upgrades: UpgradeManager
var achievements: AchievementManager
var ascension: AscensionManager
var war: WarManager
var expeditions: ExpeditionManager
var archeology: ArcheologyManager
	
var developer_mode_active: bool = false

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
	
	if developer_mode_active:
		Engine.time_scale = 1000.0
		print("Developer Mode: ON by default (Speed x1000, Power x1000)")

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
	
	economy.add_gold_mul(currentGoldPerSecond, delta)
	economy.add_prayers_mul(currentPrayerIncome, delta)

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
			var req_met = true
			if u.req_building != "":
				var req_b = buildings.get_building_by_id(u.req_building)
				if not req_b or req_b.count < u.req_count:
					req_met = false
			if req_met:
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
			developer_mode_active = not developer_mode_active
			if developer_mode_active:
				Engine.time_scale = 1000.0
				print("Developer Mode: ON (Speed x1000, Power x1000)")
			else:
				Engine.time_scale = 1.0
				print("Developer Mode: OFF (Speed x1)")
			war.update_troops_multipliers()
			war.recalculate_power()
			developer_mode_toggled.emit(developer_mode_active)

var offline_report = {}

func simulate_offline(seconds: float):
	if seconds <= 0: return
	
	offline_report = {
		"time": seconds,
		"gold_earned": BigNum.new(0.0),
		"prayers_earned": BigNum.new(0.0),
		"upgrades": [],
		"expeditions": [],
		"archeology": [],
		"troops": {},
		"archeologists_trained": 0
	}
	
	var initial_gold = BigNum.from(economy.gold)
	var initial_prayers = BigNum.from(economy.prayers)
	
	# Temporary disconnect or intercept signals if needed.
	# But since UI is not loaded yet, signals will just fire into the void or we can connect our own temporary ones.
	var on_upg = func(upg): offline_report["upgrades"].append(upg.name)
	var on_exp = func(res): offline_report["expeditions"].append(res)
	var on_arch = func(res): offline_report["archeology"].append(res)
	var on_arch_trained = func(amt): offline_report["archeologists_trained"] += amt
	var on_troop = func(troop, amount):
		if not offline_report["troops"].has(troop.name):
			offline_report["troops"][troop.name] = 0
		offline_report["troops"][troop.name] += amount
	
	upgrade_completed.connect(on_upg)
	expeditions.expedition_finished.connect(on_exp)
	archeology.expedition_completed.connect(on_arch)
	archeology.archeologists_trained.connect(on_arch_trained)
	war.troop_training_completed.connect(on_troop)
	
	var pre_commanders = {}
	for t in war.troops:
		if t.commander:
			pre_commanders[t.id] = {
				"unlocked": t.commander.is_unlocked,
				"hp": t.commander.current_hp
			}
	
	var time_left = seconds
	var tick = max(1.0, seconds / 1000.0) # Simulate in max 1000 ticks to avoid freezes
	while time_left > 0:
		var delta = min(tick, time_left)
		time_left -= delta
		
		economy.add_gold_mul(currentGoldPerSecond, delta)
		if economy.gold.is_less_than(0.0):
			economy.gold = BigNum.new(0.0)
		economy.add_prayers_mul(currentPrayerIncome, delta)
		
		var speed = get_forge_speed_multiplier()
		upgrades.update_crafting(delta, speed)
		war.update_training(delta)
		expeditions.update(delta)
		archeology.update(delta)
		achievements.check(self)
		
	var commanders_report = []
	for t in war.troops:
		if t.commander:
			var pre = pre_commanders[t.id]
			if not pre.unlocked and t.commander.is_unlocked:
				commanders_report.append("Полководец (" + t.name + ") нанят!")
			elif pre.unlocked and t.commander.current_hp > pre.hp:
				var healed = t.commander.current_hp - pre.hp
				if healed > 1.0:
					commanders_report.append("Полководец (" + t.name + ") восстановил " + format_number(healed) + " HP")
	
	offline_report["commanders"] = commanders_report
		
	upgrade_completed.disconnect(on_upg)
	expeditions.expedition_finished.disconnect(on_exp)
	archeology.expedition_completed.disconnect(on_arch)
	archeology.archeologists_trained.disconnect(on_arch_trained)
	war.troop_training_completed.disconnect(on_troop)
	
	achievements.check(self)
	
	offline_report["gold_earned"] = economy.gold.sub(initial_gold)
	if offline_report["gold_earned"].is_less_than(0.0): offline_report["gold_earned"] = BigNum.new(0.0)
	offline_report["prayers_earned"] = economy.prayers.sub(initial_prayers)
