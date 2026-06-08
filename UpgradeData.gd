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
var has_been_seen: bool = false
var is_masked: bool = false


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
	return EffectSystem.get_text(game, self)
