extends CanvasLayer
class_name DeploymentWindow

signal attack_requested(camp: CampData, army: ArmyGroup)
signal cancelled()

var camp: CampData
var game: Node

@onready var enemy_power_label = $PanelContainer/VBox/MainHBox/LeftPanel/EnemyPowerLabel
@onready var enemy_comp_container = $PanelContainer/VBox/MainHBox/LeftPanel/EnemyScroll/EnemyCompList
@onready var not_scouted_label = $PanelContainer/VBox/MainHBox/LeftPanel/NotScoutedLabel

@onready var troops_list = $PanelContainer/VBox/MainHBox/RightPanel/TroopsScroll/TroopsList

@onready var total_power_label = $PanelContainer/VBox/BottomPanel/AnalyticsHBox/TotalPowerLabel
@onready var chance_label = $PanelContainer/VBox/BottomPanel/AnalyticsHBox/ChanceLabel
@onready var buffs_label = $PanelContainer/VBox/BottomPanel/BuffsLabel

@onready var cancel_button = $PanelContainer/VBox/BottomPanel/ButtonsHBox/CancelButton
@onready var scout_attack_button = $PanelContainer/VBox/BottomPanel/ButtonsHBox/ScoutAttackButton
@onready var attack_button = $PanelContainer/VBox/BottomPanel/ButtonsHBox/AttackButton

var selected_troops: Dictionary = {} # troop_id -> int
var selected_commanders: Dictionary = {} # troop_id -> bool
var troop_buff_labels: Dictionary = {}

func _ready():
	cancel_button.pressed.connect(func():
		visible = false
		cancelled.emit()
	)
	attack_button.pressed.connect(_on_attack_pressed)
	scout_attack_button.pressed.connect(_on_scout_attack_pressed)
	visible = false
	
func setup(_camp: CampData, _game: Node):
	camp = _camp
	game = _game
	
	enemy_power_label.text = "Сила Врага: " + camp.get_display_power()
	
	for child in enemy_comp_container.get_children():
		child.queue_free()
		
	if camp.intel_percent >= 1.0:
		not_scouted_label.text = "Разведка 100%"
		enemy_comp_container.get_parent().show()
		
		for t_id in camp.enemy_troops.keys():
			var count = camp.enemy_troops[t_id]
			if count > 0:
				var t = game.war.get_troop_by_id(t_id)
				var l = Label.new()
				l.text = "- %s: %d" % [t.name, count]
				enemy_comp_container.add_child(l)
	else:
		not_scouted_label.text = "Разведка: %d%%\nСостав неизвестен." % int(camp.intel_percent * 100)
		enemy_comp_container.get_parent().hide()

	# Очищаем старые войска
	for child in troops_list.get_children():
		child.queue_free()
		
	selected_troops.clear()
	selected_commanders.clear()
	troop_buff_labels.clear()
	
	var has_troops = false
	for t in game.war.troops:
		if t.count > 0:
			has_troops = true
			selected_troops[t.id] = t.count # по умолчанию отправляем всех
			if t.commander != null and t.commander.is_unlocked:
				selected_commanders[t.id] = true
			else:
				selected_commanders[t.id] = false
			
			var troop_vbox = VBoxContainer.new()
			troop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var row = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var name_l = Label.new()
			name_l.text = t.name
			name_l.custom_minimum_size = Vector2(100, 0)
			
			var slider = HSlider.new()
			slider.min_value = 0
			slider.max_value = t.count
			slider.value = t.count
			slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			slider.step = 1
			
			var spin = SpinBox.new()
			spin.min_value = 0
			spin.max_value = t.count
			spin.value = t.count
			
			var cb = CheckBox.new()
			if t.commander != null and t.commander.is_on_expedition:
				cb.text = "Полководец (в походе)"
				cb.disabled = true
				cb.button_pressed = false
			else:
				cb.text = "Полководец"
				cb.button_pressed = selected_commanders[t.id]
			cb.visible = (t.commander != null and t.commander.is_unlocked)
			
			var buff_l = Label.new()
			buff_l.add_theme_color_override("font_color", Color("#59C59A"))
			buff_l.add_theme_font_size_override("font_size", 12)
			buff_l.hide()
			troop_buff_labels[t.id] = buff_l
			
			slider.value_changed.connect(func(v):
				if spin.value != v: spin.value = v
				selected_troops[t.id] = int(v)
				_update_analytics()
			)
			spin.value_changed.connect(func(v):
				if slider.value != v: slider.value = v
				selected_troops[t.id] = int(v)
				_update_analytics()
			)
			cb.toggled.connect(func(toggled_on):
				selected_commanders[t.id] = toggled_on
				_update_analytics()
			)
			
			row.add_child(name_l)
			row.add_child(slider)
			row.add_child(spin)
			row.add_child(cb)
			
			troop_vbox.add_child(row)
			troop_vbox.add_child(buff_l)
			troops_list.add_child(troop_vbox)
			
	if not has_troops:
		var l = Label.new()
		l.text = "У вас нет доступных войск."
		troops_list.add_child(l)
		attack_button.disabled = true
	else:
		attack_button.disabled = false

	_update_analytics()
	visible = true

func _update_analytics():
	var total_power = BigNum.new(0.0)
	var player_count = 0
	
	for t_id in selected_troops.keys():
		var count = selected_troops[t_id]
		if count > 0:
			var t = game.war.get_troop_by_id(t_id)
			var power_portion = t.base_power.mul(float(count)).mul(t.power_multiplier)
			if t.commander != null and t.commander.is_unlocked and selected_commanders.get(t_id, false):
				power_portion = power_portion.mul(t.commander.get_power_multiplier())
			total_power = total_power.add(power_portion)
			player_count += count
			
	total_power_label.text = "Выбранная мощь: " + game.format_number(total_power)
	
	var enemy_count = camp.get_total_enemy_count()
	var enemy_power = camp.exact_power
	
	var p_mult = 1.0
	# Считаем эффект толпы
	if enemy_count > 0:
		if player_count >= enemy_count * 10: p_mult = 1.5
		elif player_count >= enemy_count * 5: p_mult = 1.3
		elif player_count >= enemy_count * 2: p_mult = 1.1
		
	var final_p_power = total_power.mul(p_mult)
	
	var ratio = 0.0
	if enemy_power.is_greater_than(0.0):
		ratio = final_p_power.div(enemy_power).to_float()
		
	if ratio >= 2.0:
		chance_label.text = "Шанс: Верная победа"
		chance_label.add_theme_color_override("font_color", Color("#59C59A"))
	elif ratio >= 1.2:
		chance_label.text = "Шанс: Высокий"
		chance_label.add_theme_color_override("font_color", Color("#8CC559"))
	elif ratio >= 0.8:
		chance_label.text = "Шанс: Средний (Рискованно)"
		chance_label.add_theme_color_override("font_color", Color("#C5A059"))
	elif ratio >= 0.4:
		chance_label.text = "Шанс: Низкий"
		chance_label.add_theme_color_override("font_color", Color("#C55959"))
	else:
		chance_label.text = "Шанс: Самоубийство"
		chance_label.add_theme_color_override("font_color", Color("#8B0000"))
		
	var buffs_txt = "Активные баффы: "
	var buffs = []
	if p_mult > 1.0:
		buffs.append("Эффект толпы (+%d%%)" % int((p_mult - 1.0)*100))
		
	for t_id in selected_troops.keys():
		var count = selected_troops[t_id]
		var label: Label = troop_buff_labels.get(t_id)
		if label:
			if count > 0 and selected_commanders.get(t_id, false):
				var t = game.war.get_troop_by_id(t_id)
				var comm = t.commander
				if comm and comm.is_unlocked:
					var c_crit = int(comm.get_luck_chance() * 100)
					var c_loot = int((comm.get_loot_multiplier() - 1.0) * 100)
					var c_power = int((comm.get_power_multiplier() - 1.0) * 100)
					var parts = []
					if c_power > 0: parts.append("Сила +%d%%" % c_power)
					if c_crit > 0: parts.append("Крит %d%%" % c_crit)
					if c_loot > 0: parts.append("Добыча +%d%%" % c_loot)
					if parts.is_empty():
						parts.append("Без бонусов")
					label.text = "  ↳ " + ", ".join(parts)
					label.show()
				else:
					label.hide()
			else:
				label.hide()
		
	if buffs.is_empty():
		buffs_txt += "Нет"
	else:
		buffs_txt += ", ".join(buffs)
		
	buffs_label.text = buffs_txt
	
	attack_button.disabled = player_count <= 0
	scout_attack_button.disabled = player_count <= 0

func _on_attack_pressed():
	var army = ArmyGroup.new()
	for t_id in selected_troops.keys():
		var count = selected_troops[t_id]
		if count > 0:
			var t = game.war.get_troop_by_id(t_id)
			army.add_troops(t_id, count, t.base_power)
			t.count -= count # забираем из пула
			if selected_commanders.get(t_id, false):
				army.included_commanders.append(t_id)
			
	army.morale_multiplier = 1.0
	
	visible = false
	attack_requested.emit(camp, army)

func _on_scout_attack_pressed():
	var army = ArmyGroup.new()
	for t_id in selected_troops.keys():
		var count = selected_troops[t_id]
		if count > 0:
			var t = game.war.get_troop_by_id(t_id)
			army.add_troops(t_id, count, t.base_power)
			t.count -= count
			if selected_commanders.get(t_id, false):
				army.included_commanders.append(t_id)
			
	army.morale_multiplier = 1.0
	army.is_scouting_mission = true
	
	visible = false
	attack_requested.emit(camp, army)
