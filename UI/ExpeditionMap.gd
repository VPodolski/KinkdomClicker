extends Control
class_name ExpeditionMap

@onready var camps_container = $CampsContainer

var deployment_window: DeploymentWindow

var selected_camp: CampData

func _ready():
	GameLogic.expeditions.camp_spawned.connect(_on_camp_spawned)
	GameLogic.expeditions.camp_removed.connect(_on_camp_removed)
	GameLogic.expeditions.camp_updated.connect(_on_camp_updated)
	
	deployment_window = preload("res://UI/DeploymentWindow.tscn").instantiate()
	add_child(deployment_window)
	
	deployment_window.attack_requested.connect(_on_deployment_attack)
	deployment_window.cancelled.connect(func(): selected_camp = null)
	
	# Создаем уже существующие лагеря
	for c in GameLogic.expeditions.camps:
		_on_camp_spawned(c)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if deployment_window:
			deployment_window.hide()
		selected_camp = null

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
		deployment_window.hide()
		selected_camp = null

func _on_camp_updated(camp: CampData):
	var node = camps_container.get_node_or_null(camp.id)
	if node:
		if camp.is_defeated:
			node.queue_free()
			if selected_camp == camp:
				deployment_window.hide()
				selected_camp = null
		else:
			node.update_visuals()
	if selected_camp == camp and deployment_window.visible:
		deployment_window.setup(camp, GameLogic)

func _on_camp_clicked(camp: CampData):
	selected_camp = camp
	if camp.status == CampData.Status.IDLE:
		deployment_window.setup(camp, GameLogic)


func _on_deployment_attack(camp: CampData, army: ArmyGroup):
	GameLogic.expeditions.start_expedition(camp, army)
	GameLogic.war.recalculate_power()
	GameLogic.war.troops_changed.emit()
	selected_camp = null
