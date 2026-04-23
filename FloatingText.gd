extends Label

var speed := 50.0
var lifetime := 0.5


func _ready():
	# случайный небольшой сдвиг (чтобы выглядело живее)
	position.x += randf_range(-10, 10)


func _process(delta):
	# движение вверх
	position.y -= speed * delta
	
	# таймер жизни
	lifetime -= delta
	
	# плавное исчезновение
	modulate.a = lifetime / 0.5
	
	if lifetime <= 0:
		queue_free()
