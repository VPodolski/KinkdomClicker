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
	update_ui(0, false, "", "")
	button.pressed.connect(_on_pressed)


func _on_pressed():
	emit_signal("craft_pressed", index)

func update_ui(current_gold, is_unlocked, preview_text, remaining_text):
	name_label.text = upgrade.name
	
	var effect_text = upgrade.get_effect_description()
	
	if not is_unlocked:
		info_label.text = "🔒 Требуется: %s x%d\n%s\n%s" % [
			upgrade.required_building,
			upgrade.required_count,
			effect_text,
			remaining_text
		]
		button.disabled = true
		progress_bar.visible = false
		return
	
	if upgrade.is_crafting:
		var percent = upgrade.progress / upgrade.base_time
		
		progress_bar.value = percent
		progress_bar.visible = true
		
		info_label.text = "%s \nОсталось: %s" % [
			effect_text,
			remaining_text
		]
		
		button.disabled = true
	else:
		progress_bar.visible = false
		
		info_label.text = "Цена: %d\n%s\n%s\n%s" % [
			upgrade.cost,
			effect_text,
			preview_text,
			remaining_text
		]
		
		button.disabled = current_gold < upgrade.cost
