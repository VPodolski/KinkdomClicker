extends Control

var progress = []
var scene_path = "res://main.tscn"
var timer = 0.0
var min_load_time = 2.0

var progress_bar: ProgressBar

func _ready():
	var bg = ColorRect.new()
	bg.color = Color("#111111")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.set_anchor(SIDE_LEFT, 0.5)
	vbox.set_anchor(SIDE_TOP, 0.5)
	vbox.set_anchor(SIDE_RIGHT, 0.5)
	vbox.set_anchor(SIDE_BOTTOM, 0.5)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)
	
	var banner = TextureRect.new()
	banner.texture = load("res://assets/startup_banner.jpg")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.custom_minimum_size = Vector2(800, 450)
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(banner)
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(600, 30)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color("#222222")
	sb_bg.corner_radius_top_left = 5
	sb_bg.corner_radius_top_right = 5
	sb_bg.corner_radius_bottom_left = 5
	sb_bg.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color("#C5A059")
	sb_fg.corner_radius_top_left = 5
	sb_fg.corner_radius_top_right = 5
	sb_fg.corner_radius_bottom_left = 5
	sb_fg.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("fill", sb_fg)
	
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	vbox.add_child(progress_bar)
	
	if SaveManager.load_game():
		var current_time = Time.get_unix_time_from_system()
		var offline_seconds = current_time - SaveManager.last_played_time
		if offline_seconds > 5.0:
			GameLogic.simulate_offline(offline_seconds)
	
	ResourceLoader.load_threaded_request(scene_path)

func _process(delta):
	timer += delta
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		progress_bar.value = progress[0] * 100.0
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		if timer < min_load_time:
			var fake_progress = (timer / min_load_time) * 100.0
			progress_bar.value = max(progress_bar.value, fake_progress)
		else:
			progress_bar.value = 100.0
			set_process(false)
			var next_scene = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(next_scene)
	else:
		print("Error loading scene: ", status)
