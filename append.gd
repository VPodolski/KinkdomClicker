
# =========================
# 🏺 ARCHEOLOGY UI
# =========================

func _setup_archeology_ui():
	var left_panel = archeology_screen.get_node("LeftPanel/TrainingPanel/VBox")
	left_panel.get_node("TrainButton").pressed.connect(func(): game.archeology.start_training(1))
	left_panel.get_node("Train10Button").pressed.connect(func(): game.archeology.start_training(10))
	left_panel.get_node("TrainMaxButton").pressed.connect(func(): game.archeology.start_training(game.archeology.get_max_archeologists()))
	
	var mid_panel = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox")
	var slider = mid_panel.get_node("TimeSlider")
	var arch_slider = mid_panel.get_node("ArchSlider")
	var diff_opt = mid_panel.get_node("DiffOption")
	
	slider.value_changed.connect(func(val): mid_panel.get_node("TimeLabel").text = "Время: %d мин" % val)
	arch_slider.value_changed.connect(func(val): mid_panel.get_node("ArchLabel").text = "Археологов: %d" % val)
	mid_panel.get_node("StartButton").pressed.connect(func():
		var duration = int(slider.value)
		var arch_count = int(arch_slider.value)
		var diff = diff_opt.get_item_text(diff_opt.selected)
		# translation map
		var diff_map = {"Легкая": "easy", "Средняя": "medium", "Тяжелая": "hard", "Невозможная": "impossible", "Легендарная": "legendary"}
		if diff_map.has(diff): diff = diff_map[diff]
		game.archeology.start_expedition(arch_count, duration, diff)
	)
	
func update_archeology_ui():
	var am = game.archeology
	var left_panel = archeology_screen.get_node("LeftPanel/TrainingPanel/VBox")
	left_panel.get_node("TrainInfo").text = "Археологи: %d / %d (Обучается: %d)" % [am.archeologists_count, am.get_max_archeologists(), am.archeologists_training]
	
	var mid_panel = archeology_screen.get_node("MiddlePanel/StartExpeditionPanel/VBox")
	var diff_opt = mid_panel.get_node("DiffOption")
	var unlocked = am.get_unlocked_difficulties()
	
	var diff_names = {"easy": "Легкая", "medium": "Средняя", "hard": "Тяжелая", "impossible": "Невозможная", "legendary": "Легендарная"}
	if diff_opt.item_count != unlocked.size():
		diff_opt.clear()
		for d in unlocked:
			diff_opt.add_item(diff_names.get(d, d))
	
	var arch_slider = mid_panel.get_node("ArchSlider")
	arch_slider.max_value = max(1, am.archeologists_count)
	
	var time_slider = mid_panel.get_node("TimeSlider")
	time_slider.max_value = am.get_max_duration_minutes()
	
	var exp_label = archeology_screen.get_node("MiddlePanel/ExpeditionsLabel")
	exp_label.text = "Активные экспедиции: %d / %d" % [am.active_expeditions.size(), am.get_max_expeditions()]
	
	# Update active expeditions list
	var exp_list = archeology_screen.get_node("MiddlePanel/ExpeditionsList")
	for c in exp_list.get_children(): c.queue_free()
	
	for exp in am.active_expeditions:
		var lbl = Label.new()
		var rem_min = int(exp.remaining_duration / 60)
		var rem_sec = int(exp.remaining_duration) % 60
		lbl.text = "[%s] Археологов: %d | Ост: %02d:%02d" % [diff_names.get(exp.difficulty, exp.difficulty), exp.current_archeologists, rem_min, rem_sec]
		exp_list.add_child(lbl)
	
func update_artifacts_ui():
	var am = game.archeology
	var inv_grid = archeology_screen.get_node("RightPanel/InventoryPanel/VBox/ScrollContainer/InventoryGrid")
	for c in inv_grid.get_children(): c.queue_free()
	
	for i in range(am.inventory_artifacts.size()):
		var btn = Button.new()
		var lvl = am.inventory_artifacts[i]
		btn.text = "Арт Ур.%d" % lvl
		btn.custom_minimum_size = Vector2(80, 80)
		if selected_inventory_index == i:
			btn.modulate = Color(1.5, 1.5, 0.5)
		btn.pressed.connect(func(): _on_inventory_artifact_clicked(i))
		inv_grid.add_child(btn)
	
	var king_list = archeology_screen.get_node("RightPanel/KingdomArtifactPanel/VBox/KingdomArtifactsList")
	for c in king_list.get_children(): c.queue_free()
	
	for i in range(am.kingdom_artifacts.size()):
		var btn = Button.new()
		var lvl = am.kingdom_artifacts[i]
		btn.text = "Арт Ур.%d" % lvl
		btn.custom_minimum_size = Vector2(80, 80)
		btn.pressed.connect(func(): game.archeology.unequip_kingdom_artifact(i))
		king_list.add_child(btn)
	
var selected_inventory_index = -1
func _on_inventory_artifact_clicked(index):
	if selected_inventory_index == index:
		# Equip
		game.archeology.equip_kingdom_artifact(index)
		selected_inventory_index = -1
	elif selected_inventory_index != -1:
		# Try merge
		if game.archeology.merge_artifacts(selected_inventory_index, index):
			selected_inventory_index = -1
		else:
			selected_inventory_index = index
	else:
		selected_inventory_index = index
	update_artifacts_ui()
	
func _on_arch_expedition_updated(exp_id):
	update_archeology_ui()

func _on_arch_expedition_completed(result):
	print("Expedition completed: ", result)
	var msg = "Экспедиция завершена!"
	if not result.success:
		msg = "Экспедиция погибла... Потери: %d" % result.dead
	else:
		msg = "Успех! Потери: %d, Добыто золота: %s, Артефактов: %d" % [result.dead, game.format_number(result.gold), result.artifacts.size()]
	
	var d = AcceptDialog.new()
	d.dialog_text = msg
	add_child(d)
	d.popup_centered()
