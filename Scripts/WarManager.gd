class_name WarManager
extends Node

signal military_power_changed(new_power)
signal troops_changed
signal troop_training_completed(troop)

var troops: Array[TroopData] = []
var game: Node

var total_military_power: float = 0.0

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
					float(t["base_power"]), float(t["base_cost"]), float(t["base_time"])
				))
		else:
			print("Error parsing troops.json: ", json.get_error_message())
	else:
		print("Failed to open troops.json")

func reset():
	troops.clear()
	_init_troops()
	recalculate_power()

func recalculate_power():
	total_military_power = 0.0
	for t in troops:
		total_military_power += t.get_total_power()
	military_power_changed.emit(total_military_power)

func get_troop_by_id(id: String):
	for t in troops:
		if t.id == id:
			return t
	return null

func start_training(troop: TroopData, amount: int) -> bool:
	var cost = troop.get_cost_for(amount)
	if game.economy.spend_gold(cost):
		troop.start_training(amount)
		troops_changed.emit()
		return true
	return false

func update_training(delta: float):
	var changed = false
	for troop in troops:
		if troop.is_training:
			# Время обучения. Можно зависеть от кол-ва или быть фиксированным.
			# Сделаем фиксированное время партии на основе base_time.
			var speed = troop.speed_multiplier
			troop.training_progress += delta * speed
			
			if troop.training_progress >= troop.base_time:
				troop.finish_training()
				troop_training_completed.emit(troop)
				changed = true
	
	if changed:
		recalculate_power()
		troops_changed.emit()
