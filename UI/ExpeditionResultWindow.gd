extends PanelContainer
class_name ExpeditionResultWindow

@onready var title_label = $VBoxContainer/TitleLabel
@onready var status_label = $VBoxContainer/StatusLabel
@onready var losses_label = $VBoxContainer/LossesTitle
@onready var gold_label = $VBoxContainer/RewardsContainer/GoldLabel
@onready var artifacts_list = $VBoxContainer/RewardsContainer/ScrollContainer/ArtifactsList
@onready var ok_button = $VBoxContainer/OkButton

func _ready():
	hide()
	ok_button.pressed.connect(func(): hide())

func setup(result: Dictionary, game: Node):
	show()
	
	losses_label.text = "Погибло археологов: %d" % result.dead
	
	if not result.success:
		status_label.text = "Экспедиция погибла!"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		gold_label.text = "🪙 Золото: 0"
		for c in artifacts_list.get_children():
			c.queue_free()
		var l = Label.new()
		l.text = "Ничего не найдено..."
		artifacts_list.add_child(l)
	else:
		status_label.text = "Успех!"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		gold_label.text = "🪙 Золото: +" + game.format_number(result.gold)
		
		for c in artifacts_list.get_children():
			c.queue_free()
			
		if result.artifacts.size() == 0:
			var l = Label.new()
			l.text = "Артефактов не найдено"
			artifacts_list.add_child(l)
		else:
			var counts = {}
			for level in result.artifacts:
				counts[level] = counts.get(level, 0) + 1
				
			var levels = counts.keys()
			levels.sort_custom(func(a, b): return a > b)
			
			for level in levels:
				var l = Label.new()
				if counts[level] > 1:
					l.text = "🏺 Артефакт (Ур. %d) x%d" % [level, counts[level]]
				else:
					l.text = "🏺 Артефакт (Ур. %d)" % level
				artifacts_list.add_child(l)
