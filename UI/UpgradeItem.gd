extends VBoxContainer
class_name UpgradeItem

signal craft_pressed(upgrade)

var upgrade: UpgradeData

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/InfoLabel
@onready var preview_label: Label = $VBoxContainer/PreviewLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var craft_button: Button = $CraftButton


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
	current_gold: float,
	is_unlocked: bool,
	preview_text: String,
	remaining_text: String
) -> void:
	if upgrade == null:
		return

	# Название и описание могут изменяться, если ты захочешь динамически
	# обновлять description, поэтому обновляем каждый раз.
	name_label.text = upgrade.name
	description_label.text = upgrade.description

	# Предпросмотр эффекта
	preview_label.text = preview_text
	preview_label.visible = preview_text != ""

	# Если апгрейд крафтится
	if upgrade.is_crafting:
		craft_button.disabled = true
		craft_button.text = "Создаётся..."

		time_label.visible = true
		time_label.text = remaining_text

		progress_bar.visible = true
		progress_bar.max_value = upgrade.base_time
		progress_bar.value = min(upgrade.progress, upgrade.base_time)
	else:
		progress_bar.visible = false

		# Показываем длительность крафта
		time_label.visible = true
		time_label.text = "Время: %.1f сек" % upgrade.base_time

		# Кнопка покупки
		craft_button.disabled = not is_unlocked
		craft_button.text = "Создать (%s)" % _format_number(upgrade.cost)

	# Визуально приглушаем недоступные улучшения
	modulate.a = 1.0 if is_unlocked or upgrade.is_crafting else 0.65


func _on_craft_button_pressed() -> void:
	if upgrade != null:
		craft_pressed.emit(upgrade)


func _format_number(value: float) -> String:
	# Простое красивое форматирование без лишних нулей.
	if value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	elif value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	elif value == floor(value):
		return str(int(value))
	else:
		return "%.2f" % value
