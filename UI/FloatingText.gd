extends Label

var speed := 50.0
var lifetime := 0.5

func _ready():
	position.x += randf_range(-10, 10)

func _process(delta):
	position.y -= speed * delta
	
	lifetime -= delta
	
	modulate.a = lifetime / 0.5
	
	if lifetime <= 0:
		queue_free()
