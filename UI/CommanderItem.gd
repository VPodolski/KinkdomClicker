extends PanelContainer
class_name CommanderItem

var troop: TroopData
var commander: CommanderData

signal equip_requested(troop_id)

@onready var artifact_slot = $MarginContainer/VBox/HeaderHBox/ArtifactSlot
@onready var artifact_level_label = $MarginContainer/VBox/HeaderHBox/ArtifactSlot/LevelLabel

@onready var name_label = $MarginContainer/VBox/HeaderHBox/NameLabel
@onready var train_button = $MarginContainer/VBox/HeaderHBox/TrainButton
@onready var stats_label = $MarginContainer/VBox/StatsLabel
@onready var progress_bar = $MarginContainer/VBox/ProgressBar

func _ready():
	train_button.pressed.connect(_on_train_pressed)
	artifact_slot.pressed.connect(func(): equip_requested.emit(troop.id))
	artifact_slot.visible = false

func setup(_troop: TroopData):
	troop = _troop
	commander = troop.commander
	name_label.text = "Полководец: " + troop.name

func update_ui(current_speed: float, has_arch_skill: bool = false):
	if commander == null: return
	
	if commander.is_training:
		train_button.visible = false
		progress_bar.visible = true
		progress_bar.max_value = commander.base_time
		progress_bar.value = commander.training_progress
		
		var comm_speed = current_speed * commander.get_speed_multiplier()
		var remaining = max(0.0, (commander.base_time - commander.training_progress) / comm_speed)
		stats_label.text = "Обучается... Осталось: %.1f сек" % remaining
	elif not commander.is_unlocked:
		train_button.visible = true
		progress_bar.visible = false
		
		var comm_speed = current_speed * commander.get_speed_multiplier()
		var total_time = commander.base_time / comm_speed
		stats_label.text = "Мертв / Не нанят. Время обучения: %.1f сек" % total_time
	else:
		train_button.visible = false
		progress_bar.visible = true
		progress_bar.max_value = commander.get_max_hp()
		progress_bar.value = commander.current_hp
		
		var hp_perc = (commander.current_hp / commander.get_max_hp()) * 100.0
		stats_label.text = "HP: %d / %d (%.1f%%)\n" % [int(commander.current_hp), int(commander.get_max_hp()), hp_perc]
		stats_label.text += "Крит: %d%% | Добыча: +%d%% | Сила: +%d%% | Скор. обуч.: +%d%%" % [
			int(commander.get_luck_chance() * 100),
			int((commander.get_loot_multiplier() - 1.0) * 100),
			int((commander.get_power_multiplier() - 1.0) * 100),
			int((commander.get_speed_multiplier() - 1.0) * 100)
		]
		if commander.equipped_artifact_level > 0:
			var lvl = commander.equipped_artifact_level
			var art_pow = int((0.02 * pow(3, lvl - 1)) * 100)
			var art_upk = int((0.02 * pow(3, lvl - 1)) * 100)
			stats_label.text += "\n[Арт] Сила армии: +%d%% | Содержание: -%d%%" % [art_pow, art_upk]
		
		if commander.current_hp < commander.get_max_hp():
			var comm_speed = current_speed * commander.get_speed_multiplier()
			var total_heal_time = (commander.base_time / commander.get_speed_multiplier()) / (comm_speed * 2.0)
			var heal_rate = commander.get_max_hp() / total_heal_time
			var remaining_hp = commander.get_max_hp() - commander.current_hp
			var remaining_time = max(0.0, remaining_hp / heal_rate)
			var m = int(remaining_time / 60.0)
			var s = int(remaining_time) % 60
			stats_label.text += "\nЛечение: +%.1f HP/сек | Здоров будет через: %02d:%02d" % [heal_rate, m, s]
			
	if commander.is_unlocked and has_arch_skill:
		artifact_slot.visible = true
		artifact_slot.modulate = Color(1, 1, 1, 1)
		if commander.equipped_artifact_level > 0:
			artifact_level_label.text = "Ур." + str(commander.equipped_artifact_level)
		else:
			artifact_level_label.text = ""
	else:
		artifact_slot.visible = false

func _on_train_pressed():
	if commander and not commander.is_unlocked and not commander.is_training:
		commander.start_training()
