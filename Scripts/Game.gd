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

func start_upgrade(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return

	# Защита от повторной покупки
	if not upgrades.upgrades.has(upgrade):
		return

	if economy.spend_gold(upgrade.cost):
		upgrade.is_crafting = true
		gold_changed.emit(economy.gold)
		upgrades_changed.emit()

func _process(delta):
	var income = buildings.get_total_income(economy.global_income_multiplier)
	economy.add_gold(income * delta)
	var speed = get_forge_speed_multiplier();
	
	upgrades.update_crafting(delta, speed)


func get_forge_speed_multiplier():
	var forge = buildings.get_building_by_name("Кузница")
	return 1.0 + (forge.count * 0.01)  # +1% за кузницу

func format_number(value: float) -> String:
	# Простое красивое форматирование без лишних нулей.
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	elif value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	elif value == floor(value):
		return str(int(value))
	else:
		return "%.2f" % value
