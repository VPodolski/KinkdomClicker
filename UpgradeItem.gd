extends HBoxContainer

var upgrade
var index

signal craft_pressed(index)

@onready var name_label = $NameLabel
@onready var info_label = $InfoLabel
@onready var button = $Button


func setup(_upgrade, _index):
	upgrade = _upgrade
	index = _index
	update_ui()
	button.pressed.connect(_on_pressed)


func _on_pressed():
	emit_signal("craft_pressed", index)


func update_ui():
	name_label.text = upgrade.name
	
	if upgrade.is_crafting:
		var percent = upgrade.progress / upgrade.base_time * 100
		info_label.text = "Готово: " + str(int(percent)) + "%"
		button.disabled = true
	else:
		info_label.text = "Цена: " + str(upgrade.cost)
		button.disabled = false
