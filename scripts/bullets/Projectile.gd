extends Area2D

@export var speed := 400.0
var direction := Vector2.ZERO
var shooter = null

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body == shooter:
		return

	if body.has_method("take_damage"):
		body.take_damage(1)
