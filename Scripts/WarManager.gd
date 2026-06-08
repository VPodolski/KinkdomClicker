class_name WarManager
extends Node

signal military_power_changed(new_power)
signal troops_changed
signal troop_training_completed(troop)

var troops: Array[TroopData] = []
var game: Node

var total_military_power: BigNum = BigNum.new(0.0)

func _init(_game: Node):
	game = _game
	_init_troops()

func _init_troops():
	var file = FileAccess.open("res://data/troops.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for t in data:
				troops.append(TroopData.new(
					t["id"], t["name"], t.get("description", ""),
					float(t["base_power"]), float(t["base_cost"]), float(t.get("upkeep", 0.0)), float(t["base_time"]),
					t.get("required_building", "")
				))
		else:
			print("Error parsing troops.json: ", json.get_error_message())
	else:
		print("Failed to open troops.json")
		
	update_troops_multipliers()
	
func update_troops_multipliers():
	for t in troops:
		t.power_multiplier = game.economy.troop_power_multiplier
		t.cost_multiplier = game.economy.troop_cost_multiplier
		t.speed_multiplier = game.economy.troop_speed_multiplier
		t.upkeep_multiplier = game.economy.get_troop_upkeep_multiplier(t.id)

func reset():
	for t in troops:
		t.count = 0
		t.is_training = false
		t.training_progress = 0.0
		t.training_amount = 0
	update_troops_multipliers()
	recalculate_power()
	troops_changed.emit()

func recalculate_power():
	total_military_power = BigNum.new(0.0)
	for t in troops:
		total_military_power = total_military_power.add(t.get_total_power())
	military_power_changed.emit(total_military_power)

func get_total_upkeep() -> BigNum:
	var total = BigNum.new(0.0)
	for t in troops:
		total = total.add(t.get_total_upkeep())
	return total

func get_troop_by_id(id: String):
	for t in troops:
		if t.id == id:
			return t
	return null

func start_training(troop: TroopData, amount: int):
	var total_cost = troop.get_cost_for(amount)
	
	var additional_upkeep = troop.upkeep.mul(float(amount)).mul(game.economy.upkeep_reduction_multiplier)
	if additional_upkeep.is_greater_than(game.currentGoldPerSecond.mul(0.8)):
		return false
	
	if game.economy.spend_gold(total_cost):
		troop.start_training(amount)
		troops_changed.emit()
		return true
	return false

func update_training(delta: float):
	var changed = false
	for troop in troops:
		if troop.is_training:
			# Время обучения.
			var speed = troop.speed_multiplier
			if troop.required_building != "":
				var b = game.buildings.get_building_by_id(troop.required_building)
				if b and b.count > 0:
					# +5% скорости за каждое здание
					speed *= (1.0 + b.count * 0.05)
			troop.training_progress += delta * speed
			
			if troop.training_progress >= troop.base_time:
				troop.finish_training()
				troop_training_completed.emit(troop)
				changed = true
	
	if changed:
		recalculate_power()
		troops_changed.emit()

func is_troop_unlocked(troop: TroopData) -> bool:
	if troop.required_building == "":
		return true
	var b = game.buildings.get_building_by_id(troop.required_building)
	return b != null and b.count > 0
