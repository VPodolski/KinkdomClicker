class_name UpgradeData

var name: String
var description: String
var cost: float
var base_time: float

var effect_type: String
var effect_value: float
var target: String = ""
var source_building: String = ""

var is_crafting: bool = false
var progress: float = 0.0


func _init(
	_name: String,
	_description: String,
	_cost: float,
	_base_time: float,
	_effect_type: String,
	_effect_value: float,
	_target: String = "",
	_source_building: String = ""
):
	name = _name
	description = _description
	cost = _cost
	base_time = _base_time
	effect_type = _effect_type
	effect_value = _effect_value
	target = _target
	source_building = _source_building

func get_preview_text(game) -> String:
	match effect_type:
		"click_bonus":
			var before = game.economy.gold_per_click
			var after = before + effect_value
			return "Клик: %s → %s" % [
				game.format_number(before),
				game.format_number(after)
			]

		"click_from_income":
			var total_income = game.buildings.get_total_income(
				game.economy.global_income_multiplier
			)

			var before = game.economy.gold_per_click + \
				total_income * game.economy.click_income_ratio

			var after = game.economy.gold_per_click + \
				total_income * (
					game.economy.click_income_ratio + effect_value
				)

			return "Клик: %s → %s" % [
				game.format_number(before),
				game.format_number(after)
			]

		"income_multiplier":
			var building = game.buildings.get_building_by_name(target)
			if building == null:
				return ""

			var before = building.get_income_per_unit()
			var after = building.income * (
				building.income_multiplier +
				building.synergy_bonus +
				effect_value
			)

			return "%s: %s → %s за шт." % [
				building.name,
				game.format_number(before),
				game.format_number(after)
			]

		"global_multiplier":
			var before = game.buildings.get_total_income(
				game.economy.global_income_multiplier
			)

			var after = game.buildings.get_total_income(
				game.economy.global_income_multiplier + effect_value
			)

			return "Доход: %s/с → %s/с" % [
				game.format_number(before),
				game.format_number(after)
			]

		"forge_speed":
			var before = game.get_forge_speed_multiplier()
			var after = before + effect_value

			return "Скорость кузницы: x%s → x%s" % [
				game.format_number(before),
				game.format_number(after)
			]

		"building_synergy":
			var source = game.buildings.get_building_by_name(source_building)
			var target_building = game.buildings.get_building_by_name(target)

			if source == null or target_building == null:
				return ""

			var current_bonus = source.count * effect_value * 100.0

			return "Каждая %s даёт +%s%% к %s\nСейчас бонус: +%s%%" % [
				source.name,
				game.format_number(effect_value * 100.0),
				target_building.name,
				game.format_number(current_bonus)
			]

	return ""
