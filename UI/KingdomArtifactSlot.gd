extends PanelContainer
class_name KingdomArtifactSlot

var slot_index: int
var main_ui: Node
var is_equipped: bool = false
@onready var artifact_button = $ArtifactButton
@onready var empty_label = $EmptyLabel

func setup(index: int, ui: Node, level: int):
	slot_index = index
	main_ui = ui
	if level > 0:
		is_equipped = true
		artifact_button.text = "Арт Ур.%d" % level
		artifact_button.show()
		empty_label.hide()
	else:
		is_equipped = false
		artifact_button.hide()
		empty_label.show()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "artifact":
		return not is_equipped
	return false

func _drop_data(at_position: Vector2, data: Variant):
	if not is_equipped:
		main_ui.game.archeology.equip_kingdom_artifact(data["inventory_index"])

func _ready():
	artifact_button.pressed.connect(func():
		if is_equipped:
			main_ui.game.archeology.unequip_kingdom_artifact(slot_index)
	)
