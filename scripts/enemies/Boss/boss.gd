extends Node2D

@onready var boss_anim: AnimatedSprite2D = $AnimatedSprite2D

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
@export var attack_length := 1200.0
@export var blink_duration := 0.2
@onready var hurtbox: Area2D = $Hurtbox

signal health_changed(current: int, maximum: int)
@export var max_health := 100
var health := 0
var is_dead := false

# Charge attack
@export var charge_warn_color := Color(1, 0.5, 0, 0.45)
@export var charge_speed := 450.0
@export var charge_duration := 1.1
@export var return_speed := 700.0
@export var laser_attack_chance := 0.5   # 0.5 = 50% laser, 50% charge

# Projectile attack
@export var projectile_template_node: NodePath
@export var projectile_count := 3
@export var projectile_delay := 0.3
@export var projectile_spread_angle := 15.0
@export var projectile_speed := 400.0
@export var projectile_duration := 1.0

var proj_dir
var base_angle
var half_spread
var proj_angle

var template_projectile

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

var laser_line: Line2D
var laser_line_core: Line2D
var laser_has_hit := false
var charge_has_hit := false

# Audio
var audio_laser: AudioStreamPlayer2D
var audio_charge: AudioStreamPlayer2D
var audio_slam: AudioStreamPlayer2D

var player_node
var grid_node

var attack_rect: ColorRect
var attack_rect_projectile: ColorRect

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
	
	health = max_health
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	emit_signal("health_changed", health, max_health)
	
	laser_line = $LaserLine
	laser_line_core = $LaserLineCore
	laser_line.visible = false
	laser_line_core.visible = false

	#projectile
	template_projectile = $"../Projectile"
	template_projectile.monitoring = false

	audio_laser = AudioStreamPlayer2D.new()
	audio_laser.stream = preload("res://audio/boss_laser.wav")
	audio_laser.bus = "SFX"
	add_child(audio_laser)

	audio_charge = AudioStreamPlayer2D.new()
	audio_charge.stream = preload("res://audio/boss_charge.wav")
	audio_charge.bus = "SFX"
	add_child(audio_charge)

	audio_slam = AudioStreamPlayer2D.new()
	#audio_slam.stream = preload("res://audio/boss_slam.ogg")
	audio_slam.bus = "SFX"
	add_child(audio_slam)

	player_node = get_node(player)
	grid_node = get_node(grid)
	grid_center = grid_node.global_position

	current_speed = move_speed
	target_speed = move_speed
	timer = idle_duration

	boss_anim.play("idle")

	attack_rect = ColorRect.new()
	attack_rect_projectile = ColorRect.new()
	
	attack_rect.visible = false
	attack_rect_projectile.visible = false
	
	add_child(attack_rect)
	add_child(attack_rect_projectile)

	global_position = grid_center + Vector2.RIGHT * orbit_radius


func _process(delta):
	
	if not is_instance_valid(player_node):
		return
	
	# If the grid can move, keep updating the center
	grid_center = grid_node.global_position

	match state:
		"idle":
			current_speed = lerp(current_speed, target_speed, delta * 1.5)
			angle += current_speed * delta
			global_position = grid_center + Vector2(cos(angle), sin(angle)) * orbit_radius

			# Face toward center
			var to_center = (grid_center - global_position).normalized()
			boss_anim.flip_h = to_center.x < 0

			timer -= delta
			if timer <= 0:
				locked_player_pos = player_node.global_position

				# Optional direction flip before attack
				if randf() > 0.5:
					target_speed *= -1

				# Pick attack
				var r = randf()

				if r < 0.3:
					start_laser_warning()
				elif r < 0.6:
					start_projectile_warning()
				else:
					start_charge_warning()

				if !quadrant_disabled:
					quadrant_disabled = true
					if randf() < 0.5:
						#grid_node.heal_random_cell()
						start_disable_grid_warning()
					else:
						grid_node.heal_random_cell()
					await get_tree().create_timer(10, false, false, true).timeout
					quadrant_disabled = false
						

		"warn":
			timer -= delta
			if timer <= 0:
				if attack_type == "laser":
					attack_rect.visible = !attack_rect.visible
				if attack_type == "projectile":
					attack_rect_projectile.visible = !attack_rect_projectile.visible
				blink_count += 1
				timer = blink_duration

				if blink_count >= 4:
					if attack_type == "laser":
						state = "attack"
						timer = attack_duration
						update_attack_rect(attack_color)
						attack_rect.visible = false
						var dir = (locked_player_pos - global_position).normalized()
						var end_point = dir * attack_length
						CameraManager.shake(13.0, 0.5)
						laser_line.points = [Vector2.ZERO, end_point]
						laser_line_core.points = [Vector2.ZERO, end_point]
						show_laser()
					elif attack_type == "charge":
						state = "charge"
						timer = charge_duration
						charge_dir = (locked_player_pos - global_position).normalized()
						attack_rect.visible = false
						boss_anim.modulate = Color(1.0, 0.4, 0.2)
					elif attack_type == "projectile":
						state = "projectile"
						timer = projectile_duration
						CameraManager.shake(13.0, 0.5)
						attack_rect_projectile.visible = false
						await perform_projectile_burst()  # fires 3 projectiles with delay
		"attack":
			if !laser_has_hit and is_player_in_laser():
				player_node.take_damage(contact_damage)
				laser_has_hit = true

			timer -= delta
			if timer <= 0:
				hide_laser()
				state = "idle"
				timer = idle_duration

		"charge":
			timer -= delta
			global_position += charge_dir * charge_speed * delta

			boss_anim.play("move")

			if !charge_has_hit and global_position.distance_to(player_node.global_position) <= charge_hit_radius:
				player_node.take_damage(contact_damage)
				charge_has_hit = true

			if timer <= 0:
				boss_anim.modulate = Color(1, 1, 1)

				angle = (global_position - grid_center).angle()
				return_target = grid_center + Vector2(cos(angle), sin(angle)) * orbit_radius
				state = "return"

		"projectile":
			timer -= delta
			if timer <= 0:
				state = "idle"
				timer = idle_duration

		"return":
			global_position = global_position.move_toward(return_target, return_speed * delta)

			if global_position.distance_to(return_target) <= 4.0:
				global_position = return_target
				state = "idle"
				timer = idle_duration
				
func is_player_in_laser() -> bool:
	if not is_instance_valid(player_node):
		return false
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
	audio_laser.play()

func start_projectile_warning():
	attack_type = "projectile"
	state = "warn"
	blink_count = 0
	timer = blink_duration

	locked_player_pos = player_node.global_position

	# Clear old warning visuals
	for child in attack_rect_projectile.get_children():
		child.queue_free()

	# Direction toward player
	proj_dir = (locked_player_pos - global_position).normalized()
	base_angle = proj_dir.angle()
	half_spread = deg_to_rad(projectile_spread_angle * (projectile_count - 1) / 2)

	# Create one rectangle per projectile
	for i in range(projectile_count):
		proj_angle = base_angle - half_spread + deg_to_rad(projectile_spread_angle * i)

		var rect = ColorRect.new()
		rect.color = warn_color
		rect.size = Vector2(attack_length, attack_width)

		# Position + rotation setup
		rect.position = Vector2(0, -attack_width / 2)
		rect.pivot_offset = Vector2(0, attack_width / 2)
		rect.rotation = proj_angle

		attack_rect_projectile.add_child(rect)

	# Place attack_rect at boss position
	attack_rect_projectile.global_position = global_position
	attack_rect_projectile.visible = true
	audio_laser.play()
	
func start_charge_warning():
	attack_type = "charge"
	charge_has_hit = false
	locked_player_pos = player_node.global_position
	charge_dir = (locked_player_pos - global_position).normalized()
	state = "charge"
	timer = charge_duration
	attack_rect.visible = false
	boss_anim.modulate = Color(1.0, 0.4, 0.2)
	audio_charge.pitch_scale = randf_range(0.9, 1.1)
	audio_charge.play()

func start_disable_grid_warning():

	var q = randi() % 9
	var selected = grid_node.quadrants[q]

	for b in range(warn_blinks):

		for i in selected:
			grid_node.cells[i].modulate = warn_color

		await get_tree().create_timer(blink_time, false, false, true).timeout

		for i in selected:
			grid_node.cells[i].modulate = normal_color

		await get_tree().create_timer(blink_time, false, false, true).timeout

	grid_node.disable_quadrant(q)

func perform_projectile_burst():
	if not is_instance_valid(player_node):
		return false
	template_projectile.monitoring = true
	for i in range(projectile_count):
		proj_angle = base_angle - half_spread + deg_to_rad(projectile_spread_angle * i)
		var proj_dirs = Vector2(cos(proj_angle), sin(proj_angle))
		# Duplicate the template node
		var projectile = template_projectile.duplicate()
		projectile.global_position = global_position
		projectile.direction = proj_dirs
		projectile.speed = projectile_speed
		projectile.shooter = self
		projectile.visible = true  # make sure the duplicated node is visible
		get_parent().add_child(projectile)
		
		projectile.get_tree().create_timer(3.0, false, false, true).timeout.connect(func():
			if is_instance_valid(projectile):
				projectile.queue_free()
		)
		
		# Wait before firing the next projectile
		await get_tree().create_timer(projectile_delay, false, false, true).timeout

func update_attack_rect(color: Color):
	var world_pos = global_position
	var dir = (locked_player_pos - world_pos).normalized()
	var attack_angle = dir.angle()

	attack_rect.color = color
	attack_rect.size = Vector2(attack_length, attack_width)
	attack_rect.position = Vector2(0, -attack_width / 2)
	attack_rect.pivot_offset = Vector2(0, attack_width / 2)
	attack_rect.rotation = attack_angle

func show_laser():
	laser_line.visible = true
	laser_line_core.visible = true
	laser_line.modulate.a = 0.0
	laser_line_core.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(laser_line, "modulate:a", 1.0, 0.1)
	tween.tween_property(laser_line_core, "modulate:a", 1.0, 0.1)

func hide_laser():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(laser_line, "modulate:a", 0.0, 0.15)
	tween.tween_property(laser_line_core, "modulate:a", 0.0, 0.15)
	await tween.finished
	laser_line.visible = false
	laser_line_core.visible = false
	
func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()

func take_damage(damage: int):
	if is_dead:
		return
	
	health -= damage
	print("boss health:  ", health)
	if health < 0:
		health = 0
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		die()
		
func die():
	if is_dead:
		return

	is_dead = true
	print("Boss died")

	set_process(false)
	hide_laser()
	queue_free()
