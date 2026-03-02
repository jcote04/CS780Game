extends CharacterBody2D

@export var grid_node: NodePath
@export var move_speed := 500.0

var grid_positions = []
var current_index = 5
var target_position: Vector2
var moving := false

var key_map = {
	KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
	KEY_Q: 4, KEY_W: 5, KEY_E: 6, KEY_R: 7,
	KEY_A: 8, KEY_S: 9, KEY_D: 10, KEY_F: 11,
	KEY_Z: 12, KEY_X: 13, KEY_C: 14, KEY_V: 15
}

func _ready():
	z_index = 1
	var grid = get_node(grid_node)
	for child in grid.get_children():
		grid_positions.append(child.global_position + child.size / 2)

	position = grid_positions[current_index]
	target_position = position


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode in key_map:
			current_index = key_map[event.keycode]
			target_position = grid_positions[current_index]
			moving = true


func _physics_process(_delta):
	if moving:
		var direction = (target_position - position).normalized()
		velocity = direction * move_speed
		move_and_slide()

		# Stop when close enough
		if position.distance_to(target_position) < 5:
			position = target_position
			velocity = Vector2.ZERO
			moving = false
