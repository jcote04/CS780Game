extends Node

var camera: Camera2D

func init(cam: Camera2D):
	camera = cam

func shake(strength: float = 10.0, duration: float = 0.3):
	if not camera:
		return
	var tween = create_tween()
	var steps := 6
	for i in steps:
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", offset, duration / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
