class_name AscensionManager
extends RefCounted

var unlocked_skills: Array = []

var skills = {
	"buy_all": { "name": "Купить все улучшения", "cost": 10 },
	"buy_max": { "name": "Покупка Макс. зданий", "cost": 50 },
	"gold_multiplier": { "name": "Множитель золота x2", "cost": 100, "repeatable": true, "cost_mult": 2.0 },
	"forge_speed": { "name": "Скорость кузницы x2", "cost": 75, "repeatable": true, "cost_mult": 1.5 },
	"upkeep_reduction": { "name": "Снижение расхода 10%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 10 }
}

var skill_levels = {
	"gold_multiplier": 0,
	"forge_speed": 0,
	"upkeep_reduction": 0
}

func has_skill(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)

func get_skill_level(skill_id: String) -> int:
	if skill_levels.has(skill_id):
		return skill_levels[skill_id]
	return 1 if has_skill(skill_id) else 0

func get_skill_cost(skill_id: String) -> float:
	var data = skills[skill_id]
	var cost = float(data["cost"])
	if data.get("repeatable", false):
		var level = skill_levels[skill_id]
		cost = cost * pow(float(data.get("cost_mult", 2.0)), level)
	return cost

func buy_skill(skill_id: String, economy) -> bool:
	if not skills.has(skill_id): return false
	
	var data = skills[skill_id]
	
	if data.get("max_levels", -1) != -1 and get_skill_level(skill_id) >= data["max_levels"]:
		return false
		
	var cost = get_skill_cost(skill_id)
	
	if economy.spend_prayers(cost):
		if data.get("repeatable", false):
			skill_levels[skill_id] += 1
			if not unlocked_skills.has(skill_id):
				unlocked_skills.append(skill_id)
		else:
			unlocked_skills.append(skill_id)
		
		apply_skill(skill_id, economy)
		return true
	
	return false

func apply_skill(skill_id: String, economy):
	match skill_id:
		"gold_multiplier":
			economy.prestige_multiplier *= 2.0
		"forge_speed":
			economy.forge_speed_multiplier += 1.0
		"upkeep_reduction":
			economy.upkeep_reduction_multiplier -= 0.1
			if economy.upkeep_reduction_multiplier < 0.0:
				economy.upkeep_reduction_multiplier = 0.0

func reapply_all_skills(economy):
	economy.prestige_multiplier = 1.0
	economy.forge_speed_multiplier = 0.0
	economy.upkeep_reduction_multiplier = 1.0
	
	for i in range(skill_levels["gold_multiplier"]):
		economy.prestige_multiplier *= 2.0
	for i in range(skill_levels["forge_speed"]):
		economy.forge_speed_multiplier += 1.0
	for i in range(skill_levels["upkeep_reduction"]):
		economy.upkeep_reduction_multiplier -= 0.1
		
	if economy.upkeep_reduction_multiplier < 0.0:
		economy.upkeep_reduction_multiplier = 0.0
