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
			var commander_index = 1
			for t in data:
				var new_troop = TroopData.new(
					t["id"], t["name"], t.get("description", ""),
					float(t["base_power"]), float(t["base_cost"]), float(t.get("upkeep", 0.0)), float(t["base_time"]),
					t.get("required_building", "")
				)
				new_troop.commander = CommanderData.new(new_troop.id, float(commander_index) * 600.0)
				troops.append(new_troop)
				commander_index += 1
		else:
			print("Error parsing troops.json: ", json.get_error_message())
	else:
		print("Failed to open troops.json")
		
	update_troops_multipliers()
	
func update_troops_multipliers():
	for t in troops:
		var art_power = 1.0
		var art_upkeep = 1.0
		if t.commander and t.commander.equipped_artifact_level > 0:
			var lvl = t.commander.equipped_artifact_level
			art_power += 0.02 * pow(3, lvl - 1)
			art_upkeep -= 0.02 * pow(3, lvl - 1)
			art_upkeep = max(0.0, art_upkeep)
			
		t.power_multiplier = game.economy.troop_power_multiplier * art_power
		t.cost_multiplier = game.economy.troop_cost_multiplier
		t.speed_multiplier = game.economy.troop_speed_multiplier
		t.upkeep_multiplier = game.economy.get_troop_upkeep_multiplier(t.id) * art_upkeep

func reset(keep_commanders: bool = false):
	for t in troops:
		t.count = 0
		t.is_training = false
		t.training_progress = 0.0
		t.training_amount = 0
		if t.commander != null and not keep_commanders:
			t.commander.reset()
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
		game.economy.lifetime_unlocked_troops[troop.id] = true
		troops_changed.emit()
		return true
	return false

func update_training(delta: float):
	var changed = false
	for troop in troops:
		var speed = troop.speed_multiplier
		if troop.required_building != "":
			var b = game.buildings.get_building_by_id(troop.required_building)
			if b and b.count > 0:
				# +5% скорости за каждое здание
				speed *= (1.0 + b.count * 0.05)
				
		if troop.is_training:
			# Время обучения.
			troop.training_progress += delta * speed
			
			if troop.training_progress >= troop.base_time:
				troop.finish_training()
				troop_training_completed.emit(troop)
				changed = true
				
		if troop.commander != null:
			if troop.commander.is_training:
				var comm_speed = speed * troop.commander.get_speed_multiplier()
				troop.commander.training_progress += delta * comm_speed
				if troop.commander.training_progress >= troop.commander.base_time:
					troop.commander.finish_training()
					changed = true
			elif troop.commander.is_unlocked and troop.commander.current_hp < troop.commander.get_max_hp():
				var comm_speed = speed * troop.commander.get_speed_multiplier()
				troop.commander.heal(delta, comm_speed)
				# changed = true # Don't trigger full UI refresh every frame for passive healing, handle via specific signals if needed or just let periodic UI updates catch it.
	
	if changed:
		recalculate_power()
		troops_changed.emit()

func is_troop_unlocked(troop: TroopData) -> bool:
	if troop.required_building == "":
		return true
	var b = game.buildings.get_building_by_id(troop.required_building)
	return b != null and b.count > 0
