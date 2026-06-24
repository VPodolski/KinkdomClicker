extends Control

@onready var game = GameLogic
@onready var canvas = $Canvas
@onready var citadel_button = $Canvas/CitadelButton

var building_nodes = {}
var current_angle = 0.0
var current_radius = 160.0
var is_dragging = false
var zoom_step = 0.1
var min_zoom = 0.2
var max_zoom = 3.0

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_map(zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_map(-zoom_step, event.position)
	elif event is InputEventMouseMotion:
		if is_dragging:
			canvas.position += event.relative
			_clamp_camera()

func _zoom_map(zoom_change: float, mouse_pos: Vector2):
	var previous_zoom = canvas.scale.x
	var new_zoom = clamp(previous_zoom + zoom_change, min_zoom, max_zoom)
	
	if new_zoom == previous_zoom:
		return
		
	var zoom_factor = new_zoom / previous_zoom
	var local_mouse_pos = mouse_pos - canvas.position
	
	canvas.scale = Vector2(new_zoom, new_zoom)
	canvas.position = mouse_pos - local_mouse_pos * zoom_factor
	_clamp_camera()

func _clamp_camera():
	var map_extents = Vector2(1536.0, 1536.0) * canvas.scale
	
	var min_x = size.x - map_extents.x
	var max_x = map_extents.x
	var min_y = size.y - map_extents.y
	var max_y = map_extents.y
	
	canvas.position.x = clamp(canvas.position.x, min_x, max_x)
	canvas.position.y = clamp(canvas.position.y, min_y, max_y)

func _on_resized():
	min_zoom = max(size.x / 3072.0, size.y / 3072.0)
	if canvas.scale.x < min_zoom:
		var previous_zoom = canvas.scale.x
		canvas.scale = Vector2(min_zoom, min_zoom)
		var center = size / 2.0
		if previous_zoom > 0:
			var local_mouse_pos = center - canvas.position
			var zoom_factor = min_zoom / previous_zoom
			canvas.position = center - local_mouse_pos * zoom_factor
	_clamp_camera()

func _ready():
	resized.connect(_on_resized)
	_on_resized()
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
		var visuals_needed = 0
		if b.count >= 500: visuals_needed = 6
		elif b.count >= 250: visuals_needed = 5
		elif b.count >= 100: visuals_needed = 4
		elif b.count >= 50: visuals_needed = 3
		elif b.count >= 10: visuals_needed = 2
		elif b.count >= 1: visuals_needed = 1
		
		if not building_nodes.has(b.id):
			building_nodes[b.id] = []
		
		var current_size = building_nodes[b.id].size()
		if current_size > visuals_needed:
			for i in range(current_size - visuals_needed):
				var tile = building_nodes[b.id].pop_back()
				tile.queue_free()
		elif current_size < visuals_needed:
			for i in range(current_size, visuals_needed):
				_spawn_building_tile(b, i)

func _spawn_building_tile(building_data, index):
	var tile = TextureRect.new()
	var path_jpg = "res://assets/buildings/%s.jpg" % building_data.id
	var path_png = "res://assets/buildings/%s.png" % building_data.id
	
	if ResourceLoader.exists(path_jpg):
		tile.texture = load(path_jpg)
	elif ResourceLoader.exists(path_png):
		tile.texture = load(path_png)
	else:
		tile.texture = load("res://icon.svg") # Fallback texture

			
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.custom_minimum_size = Vector2(120, 120)
	tile.size = Vector2(120, 120)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var pos = Vector2.ZERO
	var spawn_point = canvas.get_node_or_null("SpawnPoints/" + building_data.id + "_" + str(index))
	if spawn_point:
		pos = spawn_point.position
	else:
		pos = _get_next_grid_position()
		
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
