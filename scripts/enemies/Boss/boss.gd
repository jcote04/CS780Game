extends Node2D

@export var player: NodePath
@export var grid: NodePath
@export var grid_center := Vector2(0, 0)
@export var orbit_radius := 300.0
@export var move_speed := 1.5
@export var attack_color := Color(1, 0, 0, 0.8)
@export var warn_color := Color(1, 1, 0, 0.4)
@export var idle_duration := 2.0
@export var attack_duration := 0.5
@export var attack_width := 40.0
@export var attack_length := 800.0
@export var blink_duration := 0.2

# Charge attack
@export var charge_warn_color := Color(1, 0.5, 0, 0.45)
@export var charge_speed := 450.0
@export var charge_duration := 1.1
@export var return_speed := 700.0
@export var laser_attack_chance := 0.5   # 0.5 = 50% laser, 50% charge

# Disable Grid attack
@export var disable_duration := 5.0
@export var disable_warn_color := Color(0.8,0,0,0.5)
@export var disabled_color := Color(0.6,0,0)
@export var normal_color := Color(0.2,0.2,0.2)
@export var warn_blinks := 4
@export var blink_time := 0.2
@export var quadrant_disabled := false

@export var contact_damage := 1
@export var charge_hit_radius := 45.0

var laser_has_hit := false
var charge_has_hit := false

var player_node
var grid_node
var attack_rect: ColorRect
var boss_visual: ColorRect

var state := "idle"
var attack_type := ""
var timer := 0.0
var blink_count := 0

var angle := 0.0
var current_speed := 1.5
var target_speed := 1.5
var locked_player_pos := Vector2.ZERO

var charge_dir := Vector2.ZERO
var return_target := Vector2.ZERO

func _ready():
	randomize()

	player_node = get_node(player)
	grid_node = get_node(grid)
	grid_center = grid_node.global_position

	current_speed = move_speed
	target_speed = move_speed
	timer = idle_duration

	boss_visual = ColorRect.new()
	boss_visual.size = Vector2(60, 60)
	boss_visual.color = Color(0.8, 0.1, 0.1)
	boss_visual.position = -boss_visual.size / 2
	add_child(boss_visual)

	attack_rect = ColorRect.new()
	attack_rect.visible = false
	add_child(attack_rect)

	global_position = grid_center + Vector2.RIGHT * orbit_radius


func _process(delta):
	# If the grid can move, keep updating the center
	grid_center = grid_node.global_position

	match state:
		"idle":
			current_speed = lerp(current_speed, target_speed, delta * 1.5)
			angle += current_speed * delta
			global_position = grid_center + Vector2(cos(angle), sin(angle)) * orbit_radius

			timer -= delta
			if timer <= 0:
				locked_player_pos = player_node.global_position

				# Optional direction flip before attack
				if randf() > 0.5:
					target_speed *= -1

				# Pick attack
				var r = randf()

				if r < 0.5:
					start_laser_warning()
				else:
					start_charge_warning()

				# Try grid attack once
				if !quadrant_disabled and randf() < 0.25:
					quadrant_disabled = true
					start_disable_grid_warning()
					await get_tree().create_timer(10).timeout
					quadrant_disabled = false

		"warn":
			timer -= delta
			if timer <= 0:
				attack_rect.visible = !attack_rect.visible
				blink_count += 1
				timer = blink_duration

				if blink_count >= 4:
					if attack_type == "laser":
						state = "attack"
						timer = attack_duration
						update_attack_rect(attack_color)
						attack_rect.visible = true
					elif attack_type == "charge":
						state = "charge"
						timer = charge_duration
						charge_dir = (locked_player_pos - global_position).normalized()
						attack_rect.visible = false
						boss_visual.color = Color(1.0, 0.4, 0.2)

		"attack":
			if !laser_has_hit and is_player_in_laser():
				player_node.take_damage(contact_damage)
				laser_has_hit = true

			timer -= delta
			if timer <= 0:
				attack_rect.visible = false
				state = "idle"
				timer = idle_duration

		"charge":
			timer -= delta
			global_position += charge_dir * charge_speed * delta

			if !charge_has_hit and global_position.distance_to(player_node.global_position) <= charge_hit_radius:
				player_node.take_damage(contact_damage)
				charge_has_hit = true

			if timer <= 0:
				boss_visual.color = Color(0.8, 0.1, 0.1)

				angle = (global_position - grid_center).angle()
				return_target = grid_center + Vector2(cos(angle), sin(angle)) * orbit_radius
				state = "return"

		"return":
			global_position = global_position.move_toward(return_target, return_speed * delta)

			if global_position.distance_to(return_target) <= 4.0:
				global_position = return_target
				state = "idle"
				timer = idle_duration
				
func is_player_in_laser() -> bool:
	var dir = (locked_player_pos - global_position).normalized()
	var to_player = player_node.global_position - global_position

	var forward_dist = to_player.dot(dir)
	var side_dist = abs(to_player.dot(dir.orthogonal()))

	return forward_dist >= 0.0 \
		and forward_dist <= attack_length \
		and side_dist <= attack_width * 0.5

func start_laser_warning():
	attack_type = "laser"
	laser_has_hit = false
	state = "warn"
	blink_count = 0
	timer = blink_duration
	update_attack_rect(warn_color)
	attack_rect.visible = true


func start_charge_warning():
	attack_type = "charge"
	charge_has_hit = false
	locked_player_pos = player_node.global_position
	charge_dir = (locked_player_pos - global_position).normalized()
	state = "charge"
	timer = charge_duration
	attack_rect.visible = false
	boss_visual.color = Color(1.0, 0.4, 0.2)

func start_disable_grid_warning():

	var q = randi() % 4
	var selected = grid_node.quadrants[q]

	for b in range(warn_blinks):

		for i in selected:
			grid_node.cells[i].color = warn_color

		await get_tree().create_timer(blink_time).timeout

		for i in selected:
			grid_node.cells[i].color = normal_color

		await get_tree().create_timer(blink_time).timeout

	grid_node.disable_quadrant(q)

func update_attack_rect(color: Color):
	var world_pos = global_position
	var dir = (locked_player_pos - world_pos).normalized()
	var attack_angle = dir.angle()

	attack_rect.color = color
	attack_rect.size = Vector2(attack_length, attack_width)
	attack_rect.position = Vector2(0, -attack_width / 2)
	attack_rect.pivot_offset = Vector2(0, attack_width / 2)
	attack_rect.rotation = attack_angle
	
