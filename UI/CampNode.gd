extends Button
class_name CampNode

signal camp_clicked(camp: CampData)

var camp: CampData

func setup(_camp: CampData):
	camp = _camp
	
	# Используем координаты как проценты (anchors), чтобы масштабировалось под любой экран
	anchor_left = camp.position.x
	anchor_top = camp.position.y
	anchor_right = camp.position.x
	anchor_bottom = camp.position.y
	
	grow_horizontal = 2
	grow_vertical = 2
	
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	pressed.connect(_on_pressed)
	update_visuals()

func _process(delta):
	if camp.status == CampData.Status.TRAVELING or camp.status == CampData.Status.RETURNING or camp.status == CampData.Status.SCOUTING:
		update_visuals()

func update_visuals():
	var txt = "Camp: " + camp.get_display_power()
	if camp.status == CampData.Status.SCOUTING:
		txt += "\nScouting: %.1fs" % camp.timer
	elif camp.status == CampData.Status.TRAVELING:
		txt += "\nTraveling: %.1fs" % camp.timer
	elif camp.status == CampData.Status.RETURNING:
		txt += "\nReturning: %.1fs" % camp.timer
		
	text = txt

func _on_pressed():
	camp_clicked.emit(camp)
