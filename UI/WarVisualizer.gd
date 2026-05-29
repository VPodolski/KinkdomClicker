extends ScrollContainer

@onready var game = GameLogic
@onready var container = $VBoxContainer

var troop_containers = {}
var max_visuals_per_troop = 30 # Limit for performance

func _ready():
	pass

func update_visuals():
	var all_troops = game.war.troops
	for troop in all_troops:
		if troop.count > 0:
			if not troop_containers.has(troop.id):
				_create_troop_container(troop)
			_update_troop_container(troop)
		else:
			if troop_containers.has(troop.id):
				troop_containers[troop.id].queue_free()
				troop_containers.erase(troop.id)

func _create_troop_container(troop: TroopData):
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	
	var label = Label.new()
	label.name = "Header"
	label.add_theme_font_size_override("font_size", 20)
	root.add_child(label)
	
	var grid = HFlowContainer.new()
	grid.name = "Grid"
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	root.add_child(grid)
	
	container.add_child(root)
	troop_containers[troop.id] = root

func _update_troop_container(troop: TroopData):
	var root = troop_containers[troop.id]
	var label = root.get_node("Header") as Label
	var grid = root.get_node("Grid") as HFlowContainer
	
	label.text = "%s: %s | Сила: %s" % [troop.name, game.format_number(troop.count), game.format_number(troop.get_total_power())]
	
	var visuals_needed = min(troop.count, max_visuals_per_troop)
	var current_size = grid.get_child_count()
	
	if current_size > visuals_needed:
		for i in range(current_size - visuals_needed):
			var tile = grid.get_child(grid.get_child_count() - 1)
			grid.remove_child(tile)
			tile.queue_free()
	elif current_size < visuals_needed:
		for i in range(current_size, visuals_needed):
			_spawn_troop_tile(troop, grid)

func _spawn_troop_tile(troop: TroopData, grid: Control):
	var tile = TextureRect.new()
	
	var path_png = "res://assets/troops/%s.png" % troop.id
	
	if ResourceLoader.exists(path_png):
		tile.texture = load(path_png)
	else:
		tile.texture = load("res://icon.svg")
		
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.custom_minimum_size = Vector2(40, 40)
	tile.size = Vector2(40, 40)
	
	grid.add_child(tile)
	
	# Pop in animation
	tile.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(tile, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
