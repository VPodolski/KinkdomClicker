extends SceneTree

func _init():
	var file = FileAccess.open("res://data/buildings.json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data = json.data
		for b in data:
			if b["name"] == "Гильдия археологов":
				print("FOUND BY NAME! id: '" + b["id"] + "'")
			if b["id"] == "archeology_guild":
				print("FOUND BY ID! name: '" + b["name"] + "'")
	quit()
