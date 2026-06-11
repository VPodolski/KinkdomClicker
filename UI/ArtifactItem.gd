extends Button
class_name ArtifactItem

var artifact_level: int
var inventory_index: int
var main_ui: Node

func setup(level: int, index: int, ui: Node):
	artifact_level = level
	inventory_index = index
	main_ui = ui
	text = "Арт Ур.%d" % level
	
func _get_drag_data(at_position: Vector2):
	var data = {
		"type": "artifact",
		"inventory_index": inventory_index,
		"level": artifact_level
	}
	
	var preview = Button.new()
	preview.text = text
	preview.custom_minimum_size = custom_minimum_size
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	
	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "artifact":
		if data["inventory_index"] != inventory_index:
			if data["level"] == artifact_level and data["level"] < 10:
				return true
	return false

func _drop_data(at_position: Vector2, data: Variant):
	main_ui.game.archeology.merge_artifacts(data["inventory_index"], inventory_index)
