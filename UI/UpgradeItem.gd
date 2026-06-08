extends PanelContainer
class_name UpgradeItem

signal craft_pressed(upgrade)

var upgrade: UpgradeData

@onready var name_label: Label = $HBoxContainer/MainVBox/VBoxContainer/NameLabel
@onready var description_label: Label = $HBoxContainer/MainVBox/VBoxContainer/InfoLabel
@onready var preview_label: Label = $HBoxContainer/MainVBox/VBoxContainer/PreviewLabel
@onready var time_label: Label = $HBoxContainer/MainVBox/VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $HBoxContainer/MainVBox/VBoxContainer/ProgressBar
@onready var craft_button: Button = $HBoxContainer/MainVBox/CraftButton


func _ready() -> void:
	# Если сигнал уже подключён в редакторе, эту строку можно убрать.
	if not craft_button.pressed.is_connected(_on_craft_button_pressed):
		craft_button.pressed.connect(_on_craft_button_pressed)


func setup(_upgrade: UpgradeData, _index: int = -1) -> void:
	upgrade = _upgrade

	name_label.text = upgrade.name
	description_label.text = upgrade.description

	update_ui(0.0, false, "", "")


func update_ui(
	_current_gold,
	is_unlocked: bool,
	preview_text: String,
	remaining_text: String
) -> void:
	if upgrade == null:
		return

	if upgrade.is_masked:
		name_label.text = "???"
		description_label.text = "Секретное улучшение"
		preview_label.visible = false
		time_label.visible = false
		progress_bar.modulate.a = 0.0
		craft_button.disabled = true
		craft_button.text = "Создать (???)"
		modulate.a = 0.65
		return

	name_label.text = upgrade.name
	description_label.text = upgrade.description

	preview_label.text = preview_text
	preview_label.visible = preview_text != ""

	if upgrade.is_crafting:
		craft_button.disabled = true
		craft_button.text = "Создаётся..."

		time_label.visible = true
		time_label.text = remaining_text

		progress_bar.modulate.a = 1.0
		progress_bar.max_value = upgrade.base_time
		progress_bar.value = min(upgrade.progress, upgrade.base_time)
	else:
		progress_bar.modulate.a = 0.0

		time_label.visible = true
		var speed = GameLogic.get_forge_speed_multiplier()
		time_label.text = "Время: %.1f сек" % (upgrade.base_time / speed)

		craft_button.disabled = not is_unlocked
		craft_button.text = "Создать (%s)" % _format_number(upgrade.cost)

	modulate.a = 1.0 if is_unlocked or upgrade.is_crafting else 0.65


func _on_craft_button_pressed() -> void:
	if upgrade != null:
		craft_pressed.emit(upgrade)


func _format_number(value) -> String:
	return GameLogic.format_number(value)
