extends CharacterBody2D

@export var grid_node: NodePath
@export var move_speed := 500.0
@export var max_health := 5
@export var invincible_time := 0.4

var grid_positions = []
var current_index = 5
var target_position: Vector2
var moving := false

var health := 0
var invincible := false
var invincible_timer := 0.0

var key_map = {
	KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3,
	KEY_Q: 4, KEY_W: 5, KEY_E: 6, KEY_R: 7,
	KEY_A: 8, KEY_S: 9, KEY_D: 10, KEY_F: 11,
	KEY_Z: 12, KEY_X: 13, KEY_C: 14, KEY_V: 15
}

@onready var hurtbox: Area2D = $Hurtbox

func _ready():
	z_index = 1
	health = max_health

	var grid = get_node(grid_node)
	for child in grid.get_children():
		grid_positions.append(child.global_position + child.size / 2)

	global_position = grid_positions[current_index]
	target_position = global_position

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode in key_map:
			current_index = key_map[event.keycode]
			target_position = grid_positions[current_index]
			moving = true


func _physics_process(delta):
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false

	if moving:
		var direction = (target_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()

		if global_position.distance_to(target_position) < 5:
			global_position = target_position
			velocity = Vector2.ZERO
			moving = false
	else:
		velocity = Vector2.ZERO


func take_damage(amount: int):
	if invincible:
		return

	health -= amount
	invincible = true
	invincible_timer = invincible_time

	print("Player HP: ", health)

	if health <= 0:
		die()


func die():
	print("Player died")
	queue_free()


func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("enemy_attack"):
		take_damage(1)


func _on_hurtbox_body_entered(body: Node):
	if body.is_in_group("enemy"):
		take_damage(1)
