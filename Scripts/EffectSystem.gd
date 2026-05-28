class_name EffectSystem

static func apply(game: Node, upgrade: UpgradeData) -> void:
	var val = upgrade.effect_value
	var target = upgrade.target
	var _source = upgrade.source_building
	
	match upgrade.effect_type:
		"click_bonus":
			game.economy.gold_per_click += val
		"click_from_income":
			game.economy.click_income_ratio += val
		"income_multiplier":
			var b = game.buildings.get_building_by_name(target)
			if b:
				b.income_multiplier += val
		"global_multiplier":
			game.economy.global_income_multiplier += val
		"forge_speed":
			game.economy.forge_speed_multiplier += val
		"building_synergy":
			# Synergy is calculated dynamically in BuildingManager.update_synergies
			pass
		"building_discount":
			var b = game.buildings.get_building_by_name(target)
			if b:
				b.cost_multiplier -= val
		_:
			print("Unknown effect type: ", upgrade.effect_type)

static func get_text(game: Node, upgrade: UpgradeData) -> String:
	var val = upgrade.effect_value
	var target = upgrade.target
	var source = upgrade.source_building
	
	var global_mult = 1.0
	var ach_mult = 1.0
	var pres_mult = 1.0
	
	if game.has_method("get_achievement_multiplier"):
		ach_mult = game.get_achievement_multiplier()
	elif game.get("achievements"):
		ach_mult = game.achievements.get_income_multiplier()
		
	if game.get("economy"):
		pres_mult = game.economy.prestige_multiplier
		global_mult = game.economy.global_income_multiplier
		
	var total_global_mult = global_mult * ach_mult * pres_mult
	
	match upgrade.effect_type:
		"click_bonus":
			var b = game.get_click_value() if game.has_method("get_click_value") else game.economy.gold_per_click
			var a = b + val
			return "Клик: %s → %s" % [game.format_number(b), game.format_number(a)]
		"click_from_income":
			var b = game.get_click_value() if game.has_method("get_click_value") else 0.0
			var total_income = game.buildings.get_total_income(1.0) * total_global_mult
			var a = b + (total_income * val)
			return "Клик: %s → %s" % [game.format_number(b), game.format_number(a)]
		"income_multiplier":
			var b = game.buildings.get_building_by_name(target)
			if not b:
				return ""
			var before = b.get_income_per_unit() * total_global_mult
			var after = b.income * (b.income_multiplier + b.synergy_bonus + val) * total_global_mult
			return "%s: %s → %s за шт." % [b.name, game.format_number(before), game.format_number(after)]
		"global_multiplier":
			var total_income = game.buildings.get_total_income(1.0)
			var before = total_income * total_global_mult
			var after = total_income * (global_mult + val) * ach_mult * pres_mult
			return "Доход: %s/с → %s/с" % [game.format_number(before), game.format_number(after)]
		"forge_speed":
			var before = game.get_forge_speed_multiplier()
			var after = before + val
			return "Скорость кузницы: x%s → x%s" % [game.format_number(before), game.format_number(after)]
		"building_synergy":
			var s_b = game.buildings.get_building_by_name(source)
			var t_b = game.buildings.get_building_by_name(target)
			if not s_b or not t_b:
				return ""
			var current_bonus = s_b.count * val * 100.0
			return "Каждая %s даёт +%s%% к %s\nСейчас бонус: +%s%%" % [s_b.name, game.format_number(val * 100.0), t_b.name, game.format_number(current_bonus)]
		"building_discount":
			return "Снижает цену на %s на %s%%" % [target, game.format_number(val * 100.0)]
	
	return "Неизвестный эффект"
