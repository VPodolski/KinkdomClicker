extends Control
class_name ExpeditionMap

@onready var camps_container = $CampsContainer
@onready var info_panel = $InfoPanel
@onready var power_label = $InfoPanel/VBoxContainer/PowerLabel
@onready var status_label = $InfoPanel/VBoxContainer/StatusLabel
@onready var scout_button = $InfoPanel/VBoxContainer/ScoutButton
@onready var attack_button = $InfoPanel/VBoxContainer/AttackButton
@onready var close_button = $InfoPanel/VBoxContainer/CloseButton

var selected_camp: CampData

func _ready():
	GameLogic.expeditions.camp_spawned.connect(_on_camp_spawned)
	GameLogic.expeditions.camp_removed.connect(_on_camp_removed)
	GameLogic.expeditions.camp_updated.connect(_on_camp_updated)
	
	scout_button.pressed.connect(_on_scout_pressed)
	attack_button.pressed.connect(_on_attack_pressed)
	close_button.pressed.connect(func(): info_panel.hide())
	
	info_panel.hide()
	
	# Создаем уже существующие лагеря
	for c in GameLogic.expeditions.camps:
		_on_camp_spawned(c)

func _on_camp_spawned(camp: CampData):
	var node = CampNode.new()
	node.name = camp.id
	node.setup(camp)
	node.camp_clicked.connect(_on_camp_clicked)
	camps_container.add_child(node)

func _on_camp_removed(camp_id: String):
	var node = camps_container.get_node_or_null(camp_id)
	if node:
		node.queue_free()
		if selected_camp and selected_camp.id == camp_id:
			info_panel.hide()

func _on_camp_updated(camp: CampData):
	var node = camps_container.get_node_or_null(camp.id)
	if node:
		node.update_visuals()
	if selected_camp == camp:
		update_info_panel()

func _on_camp_clicked(camp: CampData):
	selected_camp = camp
	update_info_panel()
	info_panel.show()

func update_info_panel():
	if not selected_camp:
		return
		
	power_label.text = "Сила Врага: " + selected_camp.get_display_power()
	
	match selected_camp.status:
		CampData.Status.IDLE:
			status_label.text = "Статус: Ожидает"
			scout_button.disabled = selected_camp.is_scouted
			attack_button.disabled = false
		CampData.Status.SCOUTING:
			status_label.text = "Статус: Разведка (%.1fs)" % selected_camp.timer
			scout_button.disabled = true
			attack_button.disabled = true
		CampData.Status.TRAVELING:
			status_label.text = "Статус: Войска в пути (%.1fs)" % selected_camp.timer
			scout_button.disabled = true
			attack_button.disabled = true
		CampData.Status.RETURNING:
			status_label.text = "Статус: Возвращение (%.1fs)" % selected_camp.timer
			scout_button.disabled = true
			attack_button.disabled = true

func _on_scout_pressed():
	if selected_camp:
		# Например, стоит 100 золота
		if GameLogic.economy.spend_gold(100):
			GameLogic.expeditions.start_scouting(selected_camp)

func _on_attack_pressed():
	if selected_camp:
		# Здесь мы должны открыть окно настройки отряда (DeploymentUI)
		# Для простоты пока отправляем всех свободных юнитов:
		var army = ArmyGroup.new()
		for t in GameLogic.war.troops:
			if t.count > 0:
				army.add_troops(t.id, t.count, t.get_total_power() / t.count if t.count > 0 else 0)
				t.count = 0 # Забираем их в поход
		
		# Снабжение по умолчанию
		army.morale_multiplier = 1.0
		army.commander_level = GameLogic.expeditions.commander_level
		
		GameLogic.expeditions.start_expedition(selected_camp, army)
		GameLogic.war.troops_changed.emit()
