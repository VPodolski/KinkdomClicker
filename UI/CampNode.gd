extends MarginContainer
class_name CampNode

signal camp_clicked(camp: CampData)

var camp: CampData
var btn: Button

func setup(_camp: CampData):
	camp = _camp
	
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	var img = TextureRect.new()
	img.custom_minimum_size = Vector2(64, 64)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(64, 64)
	img.texture = placeholder
	hbox.add_child(img)
	
	btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_on_pressed)
	hbox.add_child(btn)
	
	# Zig-zag effect based on camp id
	var idx = int(camp.id.replace("camp_", ""))
	if idx % 2 == 0:
		add_theme_constant_override("margin_left", 20)
		add_theme_constant_override("margin_right", 80)
	else:
		add_theme_constant_override("margin_left", 80)
		add_theme_constant_override("margin_right", 20)
		
	update_visuals()

func _process(delta):
	if camp.status == CampData.Status.TRAVELING or camp.status == CampData.Status.RETURNING or camp.status == CampData.Status.SCOUTING:
		update_visuals()

func update_visuals():
	var txt = ""
	if camp.is_unlocked:
		txt = camp.camp_name + "\nСила: " + camp.get_display_power()
		btn.modulate = Color(1, 1, 1, 1)
	else:
		txt = camp.camp_name + "\n(Недоступно)"
		btn.modulate = Color(0.3, 0.3, 0.3, 0.5)
		
	if camp.is_defeated:
		txt += "\n[Побежден]"
		btn.modulate = Color(0.5, 0.5, 0.5, 0.8)
		
	if camp.status == CampData.Status.SCOUTING:
		txt += "\nРазведка: %.1fs" % camp.timer
	elif camp.status == CampData.Status.TRAVELING:
		txt += "\nВ пути: %.1fs" % camp.timer
	elif camp.status == CampData.Status.RETURNING:
		txt += "\nВозврат: %.1fs" % camp.timer
		
	btn.text = txt

func _on_pressed():
	if camp.is_unlocked and not camp.is_defeated:
		camp_clicked.emit(camp)
