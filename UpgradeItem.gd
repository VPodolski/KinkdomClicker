extends VBoxContainer

var upgrade
var index

signal craft_pressed(index)

@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var name_label = $VBoxContainer/NameLabel
@onready var info_label = $VBoxContainer/InfoLabel
@onready var button = $CraftButton


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
		var percent = upgrade.progress / upgrade.base_time
		
		progress_bar.value = lerp(progress_bar.value, percent, 0.2)
		progress_bar.visible = true
		
		info_label.text = str(int(percent * 100)) + "%"
		button.disabled = true
	else:
		progress_bar.visible = false
		info_label.text = "Цена: " + str(upgrade.cost)
		button.disabled = false
