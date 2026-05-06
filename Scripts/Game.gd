class_name Game
extends Node

signal gold_changed
signal upgrades_changed
signal buildings_changed

var economy: Economy
var buildings: BuildingManager
var upgrades: UpgradeManager

func _ready():
	economy = Economy.new()
	buildings = BuildingManager.new()
	upgrades = UpgradeManager.new(economy, buildings)

func on_click():
	var income = buildings.get_total_income(economy.global_income_multiplier)
	var value = economy.gold_per_click + income * economy.click_income_ratio
	
	economy.add_gold(value)
	emit_signal("gold_changed", economy.gold)

func buy_building(index):
	if buildings.buy_building(index, economy):
		buildings.update_synergies(upgrades.active_upgrades)
		
		emit_signal("buildings_changed")
		emit_signal("gold_changed", economy.gold)

func start_upgrade(index):
	var u = upgrades.upgrades[index]
	
	if economy.spend_gold(u.cost):
		u.is_crafting = true
		emit_signal("gold_changed", economy.gold)

func _process(delta):
	var income = buildings.get_total_income(economy.global_income_multiplier)
	economy.add_gold(income * delta)

	var forge = buildings.get_building_by_name("Кузница")
	var speed = 1.0 + forge.count * 0.01
	
	upgrades.update_crafting(delta, speed)
