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
		
	var cat_labels = {
		"general": "Общие улучшения",
		"troops": "Улучшения Армии",
		"commanders": "Улучшения Полководцев"
	}
	
	for cat_id in ["general", "troops", "commanders"]:
		var title = Label.new()
		title.text = "=== " + cat_labels[cat_id] + " ==="
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.modulate = Color(1.0, 0.9, 0.5)
		skills_container.add_child(title)
		
		_add_ascension_skills_for_category(cat_id)
		
		if cat_id == "commanders":
			var has_visible_commanders = false
			for troop in game.war.troops:
				if troop.commander != null and game.war.is_troop_unlocked(troop):
					_create_commander_ui(troop)
					has_visible_commanders = true
					
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 20)
		skills_container.add_child(sep)

func _on_buy_skill_pressed(skill_id):
	game.ascension.buy_skill(skill_id, game.economy)
	game.recalculate_income()
	update_ui()

func _add_ascension_skills_for_category(cat: String):
	var cat_skills = []
	for skill_id in game.ascension.skills:
		var data = game.ascension.skills[skill_id]
		if data.get("category", "general") == cat:
			cat_skills.append(skill_id)
			
	var sorted_skills = []
	var remaining = cat_skills.duplicate()
	while remaining.size() > 0:
		var added_any = false
		for i in range(remaining.size() - 1, -1, -1):
			var sid = remaining[i]
			var req = game.ascension.skills[sid].get("requires", "")
			if req == "" or sorted_skills.has(req):
				sorted_skills.append(sid)
				remaining.remove_at(i)
				added_any = true
		if not added_any:
			for sid in remaining:
				sorted_skills.append(sid)
			break
			
	for skill_id in sorted_skills:
		var data = game.ascension.skills[skill_id]
		var req = data.get("requires", "")
		
		var hbox = HBoxContainer.new()
		
		if req != "":
			var indent = Control.new()
			indent.custom_minimum_size = Vector2(30, 0)
			hbox.add_child(indent)
			
			var arrow = Label.new()
			arrow.text = "↳"
			arrow.modulate = Color(0.6, 0.6, 0.6)
			hbox.add_child(arrow)
			
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
		
		if req != "" and not game.ascension.has_skill(req) and game.ascension.get_skill_level(req) == 0:
			btn.text = "Требует: " + game.ascension.skills[req]["name"]
			btn.disabled = true
		elif maxed:
			btn.text = "МАКС"
			btn.disabled = true
		elif game.ascension.has_skill(skill_id) and not data.get("repeatable", false):
			btn.text = "Куплено"
			btn.disabled = true
		else:
			btn.text = "Купить (" + game.format_number(cost) + " 🙏)"
			btn.disabled = game.economy.prayers.is_less_than(cost)
			btn.pressed.connect(_on_buy_skill_pressed.bind(skill_id))
			
		hbox.add_child(label)
		hbox.add_child(btn)
		skills_container.add_child(hbox)

func _create_commander_ui(troop):
	var commander = troop.commander
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	var label = Label.new()
	label.text = troop.name
	label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.9))
	vbox.add_child(label)
	
	var hbox = HBoxContainer.new()
	_add_comm_btn(hbox, commander, "hp", "Макс HP")
	_add_comm_btn(hbox, commander, "luck", "Шанс Крита")
	_add_comm_btn(hbox, commander, "loot", "Добыча")
	_add_comm_btn(hbox, commander, "power", "Сила")
	_add_comm_btn(hbox, commander, "speed", "Скорость")
	
	vbox.add_child(hbox)
	skills_container.add_child(vbox)

func _add_comm_btn(parent, commander, type, label):
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var prayers = game.economy.prayers
	
	if type == "luck" and commander.luck_level >= commander.max_luck_level:
		btn.text = label + "\n(Макс)"
		btn.disabled = true
	else:
		var cost = commander.get_upgrade_cost(type)
		btn.text = "%s\n%s 🙏" % [label, game.format_number(cost)]
		btn.disabled = prayers.is_less_than(cost)
		btn.pressed.connect(func():
			if commander.buy_upgrade(type, game.economy):
				update_ui()
		)
	parent.add_child(btn)

func _on_confirm_pressed():
	game.perform_rebirth()
	get_tree().paused = false
	get_parent()._on_rebirth_completed()
	hide()
