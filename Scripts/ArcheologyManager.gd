class_name ArcheologyManager
extends Node

signal archeologists_changed
signal artifacts_changed
signal expedition_updated(exp_id)
signal expedition_completed(result)
signal archeologists_trained(amount)

var game: Node
var archeology_unlocked_by_combat: bool = false

# Archeologists
var archeologists_count: int = 0
var archeologists_training: int = 0
var training_progress: float = 0.0
var training_time_per_unit: float = 5.0 # 5 seconds
var base_archeologist_cost: float = 50000.0 # 50k gold

# Inventory
var inventory_artifacts: Array[int] = [] # list of levels
var kingdom_artifacts: Array[int] = [] # equipped to kingdom

# Active Expeditions
var active_expeditions: Array[Dictionary] = []

var next_exp_id: int = 1

func _init(_game: Node):
	game = _game

func reset():
	archeologists_count = 0
	archeologists_training = 0
	training_progress = 0.0
	archeology_unlocked_by_combat = false
	inventory_artifacts.clear()
	kingdom_artifacts.clear()
	active_expeditions.clear()
	archeologists_changed.emit()
	artifacts_changed.emit()

func get_max_archeologists() -> int:
	var b = game.buildings.get_building_by_id("archeology_guild")
	if not b or b.count == 0:
		return 0
	
	var cap_per_guild = 50 + (game.ascension.get_skill_level("arch_guild_capacity") * 25)
	return b.count * cap_per_guild

func start_training(amount: int) -> bool:
	var current_total = archeologists_count + archeologists_training
	var max_cap = get_max_archeologists()
	var allowed = min(amount, max_cap - current_total)
	
	if allowed <= 0:
		return false
		
	var total_cost = BigNum.from(base_archeologist_cost).mul(allowed)
	if game.economy.spend_gold(total_cost):
		archeologists_training += allowed
		archeologists_changed.emit()
		return true
	return false

func get_max_expeditions() -> int:
	return 1 + game.ascension.get_skill_level("arch_max_expeditions")

func get_max_kingdom_artifacts() -> int:
	return 1 + game.ascension.get_skill_level("arch_max_artifacts")

func get_max_duration_minutes() -> int:
	return 60 + (game.ascension.get_skill_level("arch_max_duration") * 60)

func get_unlocked_difficulties() -> Array[String]:
	var diffs: Array[String] = ["easy", "medium"]
	var level = game.ascension.get_skill_level("arch_unlock_difficulty")
	if level >= 1: diffs.append("hard")
	if level >= 2: diffs.append("impossible")
	if level >= 3: diffs.append("legendary")
	return diffs

func get_difficulty_data(diff: String) -> Dictionary:
	match diff:
		"easy": return {"min_danger": 0.10, "max_danger": 0.30, "gold": 1000, "levels": [1, 2]}
		"medium": return {"min_danger": 0.30, "max_danger": 0.50, "gold": 5000, "levels": [2, 3]}
		"hard": return {"min_danger": 0.50, "max_danger": 0.70, "gold": 50000, "levels": [3, 4]}
		"impossible": return {"min_danger": 0.60, "max_danger": 0.80, "gold": 200000, "levels": [4, 5]}
		"legendary": return {"min_danger": 0.70, "max_danger": 0.90, "gold": 1000000, "levels": [5, 8]}
	return {"min_danger": 0.10, "max_danger": 0.30, "gold": 1000, "levels": [1, 2]}

func start_expedition(archeologists: int, duration_minutes: int, difficulty: String) -> bool:
	if archeologists <= 0 or archeologists > archeologists_count: return false
	if active_expeditions.size() >= get_max_expeditions(): return false
	if duration_minutes < 5 or duration_minutes > get_max_duration_minutes(): return false
	
	var data = get_difficulty_data(difficulty)
	var danger_reduction = game.ascension.get_skill_level("arch_danger_reduction") * 0.01
	
	var actual_min_danger = max(0.01, data.min_danger - danger_reduction)
	var actual_max_danger = max(0.02, data.max_danger - danger_reduction)
	var total_danger_percent = randf_range(actual_min_danger, actual_max_danger)
	
	var safe_danger = min(0.999, total_danger_percent)
	var survival_chance_total = 1.0 - safe_danger
	var survival_chance_per_min = pow(survival_chance_total, 1.0 / float(duration_minutes))
	var death_chance_per_min = min(1.0, (1.0 - survival_chance_per_min) * 5.0)
	
	archeologists_count -= archeologists
	
	var exp_dict = {
		"id": next_exp_id,
		"difficulty": difficulty,
		"initial_archeologists": archeologists,
		"current_archeologists": archeologists,
		"total_duration": duration_minutes * 60.0,
		"remaining_duration": duration_minutes * 60.0,
		"minute_timer": 0.0,
		"total_danger_percent": total_danger_percent,
		"death_chance_per_min": death_chance_per_min,
		"gold_per_alive": data.gold,
		"loot_gold": BigNum.new(0.0),
		"loot_artifacts": []
	}
	next_exp_id += 1
	active_expeditions.append(exp_dict)
	archeologists_changed.emit()
	return true

func update(delta: float):
	if archeologists_training > 0:
		var speed = 1.0
		var b = game.buildings.get_building_by_id("archeology_guild")
		if b and b.count > 0:
			speed += (b.count * 0.05)
			
		training_progress += delta * speed
		if training_progress >= training_time_per_unit:
			training_progress -= training_time_per_unit
			archeologists_training -= 1
			archeologists_count += 1
			archeologists_trained.emit(1)
			archeologists_changed.emit()

	var i = active_expeditions.size() - 1
	while i >= 0:
		var exp_dict = active_expeditions[i]
		exp_dict.remaining_duration -= delta
		exp_dict.minute_timer += delta
		
		# Process each minute
		if exp_dict.minute_timer >= 60.0:
			exp_dict.minute_timer -= 60.0
			process_expedition_minute(exp_dict)
		
		if exp_dict.current_archeologists <= 0:
			# All died
			finish_expedition(exp_dict, false)
			active_expeditions.remove_at(i)
		elif exp_dict.remaining_duration <= 0:
			# Success
			process_expedition_minute(exp_dict) # process remaining fractional minute if any? Actually minute_timer handled it mostly.
			finish_expedition(exp_dict, true)
			active_expeditions.remove_at(i)
		else:
			expedition_updated.emit(exp_dict.id)
			
		i -= 1

func process_expedition_minute(exp_dict: Dictionary):
	if exp_dict.current_archeologists <= 0: return
	
	if not exp_dict.has("death_chance_per_min"):
		var dur_m = exp_dict.total_duration / 60.0
		var surv = max(0.001, 1.0 - exp_dict.total_danger_percent)
		exp_dict["death_chance_per_min"] = min(1.0, (1.0 - pow(surv, 1.0 / dur_m)) * 5.0)
		
	var expected_deaths = float(exp_dict.current_archeologists) * float(exp_dict.death_chance_per_min)
	var dead_this_min = int(floor(expected_deaths))
	var fraction = expected_deaths - float(dead_this_min)
	
	if randf() < fraction:
		dead_this_min += 1
		
	exp_dict.current_archeologists -= dead_this_min
	if exp_dict.current_archeologists < 0:
		exp_dict.current_archeologists = 0
		
	if exp_dict.current_archeologists > 0:
		var find_chance_per_unit = 0.0001 + (game.ascension.get_skill_level("arch_find_chance") * 0.0001)
		var total_find_chance = exp_dict.current_archeologists * find_chance_per_unit
		
		if randf() < total_find_chance:
			# Found artifact
			var diff_data = get_difficulty_data(exp_dict.difficulty)
			var level = 1
			if exp_dict.difficulty == "legendary":
				var r = randf()
				if r < 0.05: level = 8
				elif r < 0.20: level = 7
				elif r < 0.40: level = 6
				else: level = 5
			else:
				if randf() < 0.30:
					level = diff_data.levels[1]
				else:
					level = diff_data.levels[0]
			
			var art_list: Array = exp_dict.loot_artifacts
			art_list.append(level)
			
		var gold_cap_mult = 1.0 + (game.ascension.get_skill_level("arch_gold_capacity") * 0.05)
		var added_gold = BigNum.from(exp_dict.gold_per_alive).mul(float(exp_dict.current_archeologists)).mul(gold_cap_mult)
		exp_dict.loot_gold = exp_dict.loot_gold.add(added_gold)

func finish_expedition(exp_dict: Dictionary, success: bool):
	if success:
		archeologists_count += exp_dict.current_archeologists
		game.economy.add_gold(exp_dict.loot_gold)
		for level in exp_dict.loot_artifacts:
			inventory_artifacts.append(level)
		inventory_artifacts.sort_custom(func(a, b): return a > b)
		artifacts_changed.emit()
		archeologists_changed.emit()
	
	expedition_completed.emit({
		"success": success,
		"difficulty": exp_dict.difficulty,
		"survivors": exp_dict.current_archeologists,
		"dead": exp_dict.initial_archeologists - exp_dict.current_archeologists,
		"gold": exp_dict.loot_gold if success else BigNum.new(0.0),
		"artifacts": exp_dict.loot_artifacts if success else []
	})

func merge_artifacts(index1: int, index2: int) -> bool:
	if index1 < 0 or index1 >= inventory_artifacts.size(): return false
	if index2 < 0 or index2 >= inventory_artifacts.size(): return false
	if index1 == index2: return false
	
	var lvl1 = inventory_artifacts[index1]
	var lvl2 = inventory_artifacts[index2]
	
	if lvl1 == lvl2 and lvl1 < 10:
		# Remove larger index first to not mess up smaller index
		if index1 > index2:
			inventory_artifacts.remove_at(index1)
			inventory_artifacts.remove_at(index2)
		else:
			inventory_artifacts.remove_at(index2)
			inventory_artifacts.remove_at(index1)
			
		inventory_artifacts.append(lvl1 + 1)
		inventory_artifacts.sort_custom(func(a, b): return a > b)
		artifacts_changed.emit()
		game.recalculate_income()
		return true
	return false

func equip_kingdom_artifact(inventory_index: int) -> bool:
	if kingdom_artifacts.size() >= get_max_kingdom_artifacts(): return false
	if inventory_index < 0 or inventory_index >= inventory_artifacts.size(): return false
	
	var lvl = inventory_artifacts[inventory_index]
	inventory_artifacts.remove_at(inventory_index)
	kingdom_artifacts.append(lvl)
	artifacts_changed.emit()
	game.recalculate_income()
	return true

func unequip_kingdom_artifact(kingdom_index: int) -> bool:
	if kingdom_index < 0 or kingdom_index >= kingdom_artifacts.size(): return false
	
	var lvl = kingdom_artifacts[kingdom_index]
	kingdom_artifacts.remove_at(kingdom_index)
	inventory_artifacts.append(lvl)
	inventory_artifacts.sort_custom(func(a, b): return a > b)
	artifacts_changed.emit()
	game.recalculate_income()
	return true

func equip_commander_artifact(commander_id: String, inventory_index: int) -> bool:
	if not game.ascension.has_skill("arch_commander_artifact"): return false
	if inventory_index < 0 or inventory_index >= inventory_artifacts.size(): return false
	
	var troop = game.war.get_troop_by_id(commander_id)
	if not troop or not troop.commander or not troop.commander.is_unlocked: return false
	
	var lvl = inventory_artifacts[inventory_index]
	
	# If already equipped, unequip first
	if troop.commander.equipped_artifact_level > 0:
		inventory_artifacts.append(troop.commander.equipped_artifact_level)
		
	inventory_artifacts.remove_at(inventory_index)
	troop.commander.equipped_artifact_level = lvl
	inventory_artifacts.sort_custom(func(a, b): return a > b)
	artifacts_changed.emit()
	game.war.update_troops_multipliers()
	game.war.recalculate_power()
	return true

func unequip_commander_artifact(commander_id: String) -> bool:
	var troop = game.war.get_troop_by_id(commander_id)
	if not troop or not troop.commander or troop.commander.equipped_artifact_level == 0: return false
	
	var lvl = troop.commander.equipped_artifact_level
	troop.commander.equipped_artifact_level = 0
	inventory_artifacts.append(lvl)
	inventory_artifacts.sort_custom(func(a, b): return a > b)
	artifacts_changed.emit()
	game.war.update_troops_multipliers()
	game.war.recalculate_power()
	return true

# Buff logic
func get_kingdom_gold_multiplier() -> float:
	var mult = 1.0
	for lvl in kingdom_artifacts:
		mult += 0.02 * pow(3, lvl - 1)
	return mult

func get_kingdom_building_cost_multiplier() -> float:
	var mult = 1.0
	for lvl in kingdom_artifacts:
		var red = 0.02 * pow(3, lvl - 1)
		mult -= red
	return max(0.1, mult) # cap at 90% reduction

func get_kingdom_army_power_multiplier() -> float:
	var mult = 1.0
	for lvl in kingdom_artifacts:
		mult += 0.02 * pow(3, lvl - 1)
	return mult

func get_kingdom_army_upkeep_multiplier() -> float:
	var mult = 1.0
	for lvl in kingdom_artifacts:
		var red = 0.02 * pow(3, lvl - 1)
		mult -= red
	return max(0.0, mult)

func to_dict() -> Dictionary:
	return {
		"archeology_unlocked_by_combat": archeology_unlocked_by_combat,
		"archeologists_count": archeologists_count,
		"archeologists_training": archeologists_training,
		"training_progress": training_progress,
		"inventory_artifacts": inventory_artifacts,
		"kingdom_artifacts": kingdom_artifacts,
		"active_expeditions": active_expeditions,
		"next_exp_id": next_exp_id
	}

func from_dict(dict: Dictionary) -> void:
	archeology_unlocked_by_combat = dict.get("archeology_unlocked_by_combat", false)
	archeologists_count = dict.get("archeologists_count", 0)
	archeologists_training = dict.get("archeologists_training", 0)
	training_progress = dict.get("training_progress", 0.0)
	next_exp_id = dict.get("next_exp_id", 1)
	
	if dict.has("inventory_artifacts"):
		inventory_artifacts.clear()
		for lvl in dict["inventory_artifacts"]:
			inventory_artifacts.append(lvl)
			
	if dict.has("kingdom_artifacts"):
		kingdom_artifacts.clear()
		for lvl in dict["kingdom_artifacts"]:
			kingdom_artifacts.append(lvl)
			
	if dict.has("active_expeditions"):
		active_expeditions.clear()
		for e in dict["active_expeditions"]:
			if typeof(e.get("loot_gold")) == TYPE_STRING or typeof(e.get("loot_gold")) == TYPE_DICTIONARY:
				e["loot_gold"] = BigNum.from(e["loot_gold"])
			active_expeditions.append(e)
