class_name UpgradeData
extends RefCounted

var name: String
var cost: int
var base_time: float
var is_crafting: bool = false
var progress: float = 0.0


func _init(_name, _cost, _time):
	name = _name
	cost = _cost
	base_time = _time
