class_name AscensionManager
extends RefCounted

var unlocked_skills: Array = []

var skills = {
	"buy_all": { "name": "Купить все улучшения", "cost": 10, "category": "general" },
	"buy_max": { "name": "Покупка Макс. зданий", "cost": 50, "category": "general" },
	"gold_multiplier": { "name": "Множитель золота x2", "cost": 100, "repeatable": true, "cost_mult": 2.0, "category": "general" },
	"forge_speed": { "name": "Скорость кузницы x2", "cost": 75, "repeatable": true, "cost_mult": 1.5, "category": "general", "related_building": "forge" },
	"upkeep_reduction": { "name": "Снижение расхода 10%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 10, "category": "general" },
	
	"keep_commanders": { "name": "Полководцы остаются", "cost": 100, "category": "commanders", "related_building": "barracks" },
	"commander_xp": { "name": "Опыт полководцев +20%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 10, "category": "commanders", "requires": "keep_commanders", "related_building": "barracks" },
	"commander_power": { "name": "Сила полководцев +10%", "cost": 75, "repeatable": true, "cost_mult": 1.5, "max_levels": 10, "category": "commanders", "requires": "keep_commanders", "related_building": "barracks" },
	"commander_regen": { "name": "Скорость лечения полководцев +20%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "commanders", "requires": "keep_commanders", "related_building": "barracks" },
	"captives_bonus": { "name": "Бонус от пленников (+0.1%)", "cost": 50, "repeatable": true, "cost_mult": 1.5, "category": "commanders", "requires": "keep_commanders", "related_building": "barracks" },

	"troop_power": { "name": "Сила войск +50%", "cost": 100, "repeatable": true, "cost_mult": 1.5, "category": "troops", "related_building": "barracks" },
	"troop_cost": { "name": "Удешевление найма войск 10%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "related_building": "barracks" },
	"troop_speed": { "name": "Скорость найма +50%", "cost": 75, "repeatable": true, "cost_mult": 1.5, "category": "troops", "related_building": "barracks" },
	"upkeep_militia": { "name": "Содержание (Ополченцы) -10%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "militia" },
	"upkeep_pikeman": { "name": "Содержание (Копейщики) -10%", "cost": 75, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "pikeman" },
	"upkeep_swordsman": { "name": "Содержание (Мечники) -10%", "cost": 100, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "swordsman" },
	"upkeep_archer": { "name": "Содержание (Лучники) -10%", "cost": 150, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "archer" },
	"upkeep_cavalry": { "name": "Содержание (Конница) -10%", "cost": 200, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "cavalry" },
	"upkeep_knight": { "name": "Содержание (Рыцари) -10%", "cost": 250, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "knight" },
	"upkeep_paladin": { "name": "Содержание (Паладины) -10%", "cost": 300, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "paladin" },
	"upkeep_griffon_rider": { "name": "Содержание (Грифоны) -10%", "cost": 500, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "troops", "requires": "upkeep_reduction", "related_troop": "griffon_rider" },

	"war_artifact_chance": { "name": "Шанс артефакта за войну +5%", "cost": 150, "repeatable": true, "cost_mult": 1.5, "max_levels": 4, "category": "troops", "related_building": "archeology_guild" },

	"arch_commander_artifact": { "name": "Полководцы носят артефакт", "cost": 50, "category": "archeology", "related_building": "archeology_guild" },
	"arch_max_expeditions": { "name": "Макс. экспедиций +1", "cost": 100, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "archeology", "related_building": "archeology_guild" },
	"arch_max_artifacts": { "name": "Макс. артефактов королевства +1", "cost": 200, "repeatable": true, "cost_mult": 2.0, "max_levels": 3, "category": "archeology", "related_building": "archeology_guild" },
	"arch_guild_capacity": { "name": "Вместимость гильдии +25", "cost": 100, "repeatable": true, "cost_mult": 1.5, "max_levels": 4, "category": "archeology", "related_building": "archeology_guild" },
	"arch_danger_reduction": { "name": "Опасность экспедиций -1%", "cost": 100, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "archeology", "related_building": "archeology_guild" },
	"arch_gold_capacity": { "name": "Добыча золота археологом +5%", "cost": 50, "repeatable": true, "cost_mult": 1.5, "max_levels": 5, "category": "archeology", "related_building": "archeology_guild" },
	"arch_find_chance": { "name": "Шанс артефакта +0.01%", "cost": 150, "repeatable": true, "cost_mult": 2.0, "max_levels": 5, "category": "archeology", "related_building": "archeology_guild" },
	"arch_unlock_difficulty": { "name": "Новая сложность экспедиций", "cost": 200, "repeatable": true, "cost_mult": 2.0, "max_levels": 3, "category": "archeology", "related_building": "archeology_guild" },
	"arch_max_duration": { "name": "Длительность экспедиций +1 час", "cost": 100, "repeatable": true, "cost_mult": 1.2, "max_levels": 11, "category": "archeology", "related_building": "archeology_guild" }
}

var skill_levels = {
	"keep_commanders": 0,
	"commander_xp": 0,
	"commander_power": 0,
	"commander_regen": 0,
	"captives_bonus": 0,
	"gold_multiplier": 0,
	"forge_speed": 0,
	"upkeep_reduction": 0,
	"troop_power": 0,
	"troop_cost": 0,
	"troop_speed": 0,
	"upkeep_militia": 0,
	"upkeep_pikeman": 0,
	"upkeep_swordsman": 0,
	"upkeep_archer": 0,
	"upkeep_cavalry": 0,
	"upkeep_knight": 0,
	"upkeep_paladin": 0,
	"upkeep_griffon_rider": 0,
	"war_artifact_chance": 0,
	"arch_commander_artifact": 0,
	"arch_max_expeditions": 0,
	"arch_max_artifacts": 0,
	"arch_guild_capacity": 0,
	"arch_danger_reduction": 0,
	"arch_gold_capacity": 0,
	"arch_find_chance": 0,
	"arch_unlock_difficulty": 0,
	"arch_max_duration": 0
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
		"troop_power":
			economy.troop_power_multiplier += 0.5
		"troop_cost":
			economy.troop_cost_multiplier = max(0.1, economy.troop_cost_multiplier - 0.1)
		"troop_speed":
			economy.troop_speed_multiplier += 0.5
		"upkeep_militia", "upkeep_pikeman", "upkeep_swordsman", "upkeep_archer", "upkeep_cavalry", "upkeep_knight", "upkeep_paladin", "upkeep_griffon_rider":
			var troop_id = skill_id.replace("upkeep_", "")
			var current = economy.troop_upkeep_multipliers.get(troop_id, 1.0)
			economy.troop_upkeep_multipliers[troop_id] = max(0.0, current - 0.1)

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
		
	economy.troop_power_multiplier = 1.0 + (0.5 * skill_levels["troop_power"])
	economy.troop_cost_multiplier = max(0.1, 1.0 - (0.1 * skill_levels["troop_cost"]))
	economy.troop_speed_multiplier = 1.0 + (0.5 * skill_levels["troop_speed"])
	
	economy.troop_upkeep_multipliers.clear()
	for troop_id in ["militia", "pikeman", "swordsman", "archer", "cavalry", "knight", "paladin", "griffon_rider"]:
		var skill = "upkeep_" + troop_id
		var level = skill_levels[skill]
		if level > 0:
			economy.troop_upkeep_multipliers[troop_id] = max(0.0, 1.0 - 0.1 * level)

func to_dict() -> Dictionary:
	return {
		"unlocked_skills": unlocked_skills,
		"skill_levels": skill_levels
	}

func from_dict(dict: Dictionary) -> void:
	if dict.has("unlocked_skills"):
		unlocked_skills = dict["unlocked_skills"]
	if dict.has("skill_levels"):
		var sl = dict["skill_levels"]
		for k in sl.keys():
			if skill_levels.has(k):
				skill_levels[k] = sl[k]

