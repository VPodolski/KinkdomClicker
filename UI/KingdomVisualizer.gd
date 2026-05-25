extends Control

@onready var game = GameLogic
@onready var canvas = $Canvas
@onready var citadel_button = $Canvas/CitadelButton

var building_nodes = {}
var max_visuals_per_building = 3 # Keep it low so the screen doesn't clutter too fast
var current_angle = 0.0
var current_radius = 160.0

func _ready():
	citadel_button.pressed.connect(_on_citadel_pressed)
	game.buildings_changed.connect(_on_buildings_changed)
	
	# Initial populate with slight delay to ensure UI is ready
	await get_tree().process_frame
	_on_buildings_changed()

func _on_citadel_pressed():
	var click_value = game.get_click_value()
	game.on_click()
	
	# Bounce animation
	var tween = create_tween()
	tween.tween_property(citadel_button, "scale", Vector2(1.1, 1.1), 0.05)
	tween.tween_property(citadel_button, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Create floating text
	var floating_text_scene = load("res://UI/FloatingText.tscn")
	if floating_text_scene:
		var floating_text = floating_text_scene.instantiate()
		floating_text.text = "+" + game.format_number(click_value)
		# Add to global scene so it doesn't get clipped
		get_tree().current_scene.add_child(floating_text)
		floating_text.global_position = citadel_button.global_position + citadel_button.size / 2.0

func _on_buildings_changed():
	var all_buildings = game.buildings.buildings
	for b in all_buildings:
		if b.count > 0:
			var visuals_needed = min(b.count, max_visuals_per_building)
			if not building_nodes.has(b.id):
				building_nodes[b.id] = []
			
			while building_nodes[b.id].size() < visuals_needed:
				_spawn_building_tile(b)

func _spawn_building_tile(building_data):
	var tile = TextureRect.new()
	var path_jpg = "res://assets/buildings/%s.jpg" % building_data.id
	var path_png = "res://assets/buildings/%s.png" % building_data.id
	
	if ResourceLoader.exists(path_jpg):
		tile.texture = load(path_jpg)
	elif ResourceLoader.exists(path_png):
		tile.texture = load(path_png)
	else:
		return # No texture found
			
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.custom_minimum_size = Vector2(120, 120)
	tile.size = Vector2(120, 120)
	
	var pos = _get_next_grid_position()
	tile.position = pos - tile.size / 2.0
	tile.pivot_offset = tile.size / 2.0
	
	canvas.add_child(tile)
	# Move citadel to front so it's always on top
	canvas.move_child(citadel_button, -1)
	
	building_nodes[building_data.id].append(tile)
	
	# Pop in animation
	tile.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(tile, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _get_next_grid_position() -> Vector2:
	# Archimedean spiral around the center
	var pos = Vector2(cos(current_angle), sin(current_angle)) * current_radius
	
	current_angle += PI / 4.0 # 45 degrees
	if current_angle >= PI * 2:
		current_angle -= PI * 2
		current_radius += 140.0
		current_angle += (PI / 8.0) # offset to stagger the grid
		
	return pos
