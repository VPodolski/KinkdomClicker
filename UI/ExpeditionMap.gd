extends Control
class_name ExpeditionMap

@onready var camps_container = $VBoxContainer/ScrollContainer/CampsContainer
@onready var title_label = $VBoxContainer/TitleLabel

var deployment_window: DeploymentWindow

var selected_camp: CampData

func _ready():
	GameLogic.expeditions.camp_spawned.connect(_on_camp_spawned)
	GameLogic.expeditions.camp_updated.connect(_on_camp_updated)
	GameLogic.expeditions.map_regenerated.connect(func():
		for child in camps_container.get_children():
			child.queue_free()
	)
	
	deployment_window = preload("res://UI/DeploymentWindow.tscn").instantiate()
	add_child(deployment_window)
	
	deployment_window.attack_requested.connect(_on_deployment_attack)
	deployment_window.cancelled.connect(func(): selected_camp = null)
	
	# Создаем уже существующие лагеря
	for c in GameLogic.expeditions.camps:
		_on_camp_spawned(c)
		
	update_title()

func update_title():
	if title_label and GameLogic.expeditions:
		title_label.text = "Варварские земли (Уровень %d)" % GameLogic.expeditions.map_tier

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if deployment_window:
			deployment_window.hide()
		selected_camp = null

func _on_camp_spawned(camp: CampData):
	update_title()
	var node = CampNode.new()
	node.name = camp.id
	node.setup(camp)
	node.camp_clicked.connect(_on_camp_clicked)
	camps_container.add_child(node)
	camps_container.move_child(node, 0)

func _on_camp_updated(camp: CampData):
	var node = camps_container.get_node_or_null(camp.id)
	if node:
		node.update_visuals()
		if camp.is_defeated and selected_camp == camp:
			deployment_window.hide()
			selected_camp = null
	if selected_camp == camp and deployment_window.visible:
		deployment_window.setup(camp, GameLogic)

func _on_camp_clicked(camp: CampData):
	if not camp.is_unlocked:
		return
	selected_camp = camp
	if camp.status == CampData.Status.IDLE:
		deployment_window.setup(camp, GameLogic)


func _on_deployment_attack(camp: CampData, army: ArmyGroup):
	GameLogic.expeditions.start_expedition(camp, army)
	GameLogic.war.recalculate_power()
	GameLogic.war.troops_changed.emit()
	selected_camp = null
