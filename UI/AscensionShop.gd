extends PanelContainer

@onready var game = GameLogic
@onready var prayers_label = $VBox/PrayersLabel
@onready var skills_container = $VBox/Scroll/SkillsContainer
@onready var confirm_button = $VBox/ConfirmButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	
func open():
	show()
	update_ui()
	get_tree().paused = true
	
func update_ui():
	prayers_label.text = "Молитвы: " + game.format_number(game.economy.prayers)
	
	for child in skills_container.get_children():
		child.queue_free()
		
	for skill_id in game.ascension.skills:
		var data = game.ascension.skills[skill_id]
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var level_text = ""
		if data.get("repeatable", false):
			level_text = " (Ур. " + str(game.ascension.get_skill_level(skill_id))
			if data.has("max_levels"):
				level_text += "/" + str(data["max_levels"])
			level_text += ")"
		
		label.text = data["name"] + level_text
		
		var cost = game.ascension.get_skill_cost(skill_id)
		
		var btn = Button.new()
		var maxed = data.get("max_levels", -1) != -1 and game.ascension.get_skill_level(skill_id) >= data["max_levels"]
		
		if maxed:
			btn.text = "МАКС"
			btn.disabled = true
		elif game.ascension.has_skill(skill_id) and not data.get("repeatable", false):
			btn.text = "Куплено"
			btn.disabled = true
		else:
			btn.text = "Купить (" + game.format_number(cost) + " М)"
			btn.disabled = game.economy.prayers < cost
			btn.pressed.connect(func():
				game.ascension.buy_skill(skill_id, game.economy)
				update_ui()
			)
			
		hbox.add_child(label)
		hbox.add_child(btn)
		skills_container.add_child(hbox)

func _on_confirm_pressed():
	game.perform_rebirth()
	get_tree().paused = false
	get_parent()._on_rebirth_completed()
	hide()
