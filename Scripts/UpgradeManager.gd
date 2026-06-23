class_name UpgradeManager

var upgrades: Array[UpgradeData] = []
var active_upgrades: Array[UpgradeData] = []

var game: Node

func _init(_game: Node):
	game = _game
	_init_upgrades()

func _init_upgrades():
	var file = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			for u in data:
				var target = u.get("target", "")
				var source_building = u.get("source_building", "")
				upgrades.append(UpgradeData.new(
					u["name"], u["description"], float(u["cost"]), float(u["base_time"]),
					u["effect_type"], float(u["effect_value"]), target, source_building
				))
			upgrades.sort_custom(func(a, b): return a.cost.is_less_than(b.cost))
		else:
			print("Error parsing upgrades.json: ", json.get_error_message())
	else:
		print("Failed to open upgrades.json")

func reset():
	var seen_upgrades = []
	for u in upgrades:
		if u.has_been_seen:
			seen_upgrades.append(u.name)
	for u in active_upgrades:
		if u.has_been_seen:
			seen_upgrades.append(u.name)

	active_upgrades.clear()
	upgrades.clear()
	_init_upgrades()
	
	for u in upgrades:
		if u.name in seen_upgrades:
			u.has_been_seen = true

func apply_upgrade(upgrade):
	EffectSystem.apply(game, upgrade)

func update_crafting(delta, forge_speed):
	for i in range(upgrades.size() - 1, -1, -1):
		var upgrade = upgrades[i]
		if upgrade.is_crafting:
			upgrade.progress += delta * forge_speed
			
			if upgrade.progress >= upgrade.base_time:
				complete_upgrade(upgrade)


func complete_upgrade(upgrade):
	apply_upgrade(upgrade)
	active_upgrades.append(upgrade)
	if game.get("buildings"):
		game.buildings.update_synergies(active_upgrades)
	if game.has_method("recalculate_income"):
		game.recalculate_income()
	if game.has_signal("upgrades_changed"):
		game.upgrades_changed.emit()
	if game.has_method("emit_upgrade_completed"):
		game.emit_upgrade_completed(upgrade)
	upgrades.erase(upgrade)

func to_dict() -> Dictionary:
	var pending_list = []
	for u in upgrades:
		pending_list.append({
			"name": u.name,
			"is_crafting": u.is_crafting,
			"progress": u.progress,
			"has_been_seen": u.has_been_seen,
			"is_masked": u.is_masked
		})
		
	var active_list = []
	for u in active_upgrades:
		active_list.append(u.name)
		
	return {
		"pending_upgrades": pending_list,
		"active_upgrades": active_list
	}

func from_dict(dict: Dictionary) -> void:
	if dict.has("active_upgrades"):
		var act_list = dict["active_upgrades"]
		var to_remove = []
		for u in upgrades:
			if u.name in act_list:
				active_upgrades.append(u)
				apply_upgrade(u)
				to_remove.append(u)
		for u in to_remove:
			upgrades.erase(u)
			
	if dict.has("pending_upgrades"):
		var pend_list = dict["pending_upgrades"]
		for u in upgrades:
			for data in pend_list:
				if u.name == data["name"]:
					u.is_crafting = data.get("is_crafting", false)
					u.progress = data.get("progress", 0.0)
					u.has_been_seen = data.get("has_been_seen", false)
					u.is_masked = data.get("is_masked", false)
					break
