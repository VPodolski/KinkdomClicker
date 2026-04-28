class_name UpgradeData
extends RefCounted

var name: String
var cost: int
var base_time: float

var required_building: String = ""
var required_count: int = 0

var effect_type: String
var effect_value: float
var target: String  # для зданий (например "Ферма")

var is_crafting: bool = false
var progress: float = 0.0


func _init(_name, _cost, _time, _type, _value, _target="", _req_building="", _req_count=0):
	name = _name
	cost = _cost
	base_time = _time
	effect_type = _type
	effect_value = _value
	target = _target
	required_building = _req_building
	required_count = _req_count


func get_effect_description():
	match effect_type:
		"click_bonus":
			return "+%d к золоту за клик" % effect_value
		
		"income_multiplier":
			return "+%d%% к доходу (%s)" % [int(effect_value * 100), target]
		
		"global_multiplier":
			return "+%d%% ко всему доходу" % int(effect_value * 100)
	
	return ""
