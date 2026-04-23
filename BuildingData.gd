class_name BuildingData
extends RefCounted

var name: String
var base_cost: int
var cost: int
var income: int
var count: int = 0

func _init(_name, _base_cost, _income):
	name = _name
	base_cost = _base_cost
	cost = _base_cost
	income = _income

func buy():
	count += 1
	cost = int(base_cost * pow(1.2, count))

func get_income():
	return income * count
