extends PanelContainer
class_name BattleResultsWindow

@onready var title_label = $VBoxContainer/TitleLabel
@onready var intel_label = $VBoxContainer/IntelLabel
@onready var power_label = $VBoxContainer/StatsContainer/PowerLabel
@onready var enemy_killed_label = $VBoxContainer/StatsContainer/EnemyKilledLabel
@onready var losses_list = $VBoxContainer/StatsContainer/ScrollContainer/LossesList
@onready var gold_label = $VBoxContainer/RewardsContainer/GoldLabel
@onready var captives_label = $VBoxContainer/RewardsContainer/CaptivesLabel
@onready var ok_button = $VBoxContainer/OkButton
@onready var rewards_container = $VBoxContainer/RewardsContainer

func _ready():
	ok_button.pressed.connect(_on_ok_pressed)
	hide()

func setup(data: Dictionary, game: Node):
	var is_scout = data.get("is_scout_mission", false)
	
	if is_scout:
		title_label.text = "Разведка завершена"
		title_label.add_theme_color_override("font_color", Color("#59A0C5"))
		rewards_container.hide()
	elif data.won:
		title_label.text = "Победа!"
		title_label.add_theme_color_override("font_color", Color("#59C59A"))
		rewards_container.show()
	else:
		title_label.text = "Поражение"
		title_label.add_theme_color_override("font_color", Color("#C55959"))
		rewards_container.hide()
		
	intel_label.visible = data.get("gathered_intel", false)
		
	if is_scout:
		power_label.text = "Обнаруженная сила: " + str(int(data.enemy_power))
		enemy_killed_label.text = "Вражеских шпионов устранено: " + str(data.get("enemy_killed", 0))
	else:
		power_label.text = "Сила оставшегося врага: " + str(int(data.enemy_power))
		enemy_killed_label.text = "Врагов убито: " + str(data.get("enemy_killed", 0))
	
	# Очищаем список потерь
	for child in losses_list.get_children():
		child.queue_free()
		
	var losses = data.get("player_losses", {})
	var total_dead = 0
	var total_troops = 0
	for t_id in losses.keys():
		var info = losses[t_id]
		if info.dead > 0 or info.fled > 0:
			var t = game.war.get_troop_by_id(t_id)
			var row = Label.new()
			row.text = "%s - Убито: %d | Сбежало: %d" % [t.name, info.dead, info.fled]
			if info.dead > 0:
				row.add_theme_color_override("font_color", Color("#C55959"))
			losses_list.add_child(row)
			total_dead += info.dead
			total_troops += 1
			
	if total_dead == 0 and total_troops > 0:
		var row = Label.new()
		row.text = "Без потерь!"
		row.add_theme_color_override("font_color", Color("#59C59A"))
		losses_list.add_child(row)
	elif losses.size() == 0:
		var row = Label.new()
		row.text = "Никто не был отправлен в бой."
		losses_list.add_child(row)
	
	gold_label.text = "Золото: +" + game.format_number(data.gold_reward)
	captives_label.text = "Пленники: +" + str(data.captives_reward)
	
	show()

func _on_ok_pressed():
	hide()
