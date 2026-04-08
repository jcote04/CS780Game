extends CharacterBody2D

signal health_changed(current: int, maximum: int)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: AnimatedSprite2D = $AnimatedSprite2D/Shadow

@onready var grid_ = get_node("/root/Main/Grid")

@export var grid_node: NodePath
@export var move_speed := 400.0
@export var max_health := 1
@export var invincible_time := 0.4

var audio_hurt: AudioStreamPlayer

var camera: Camera2D
var shake_strength := 17.0
var shake_duration := 0.3

var grid_positions = []
var current_index = 5
var target_position: Vector2
var moving := false

var health := 0
var dead := false
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
	
	# Sprite
	anim.play("idle")
	
	# Shadow
	shadow.sprite_frames = anim.sprite_frames  
	shadow.modulate = Color(0, 0, 0, 0.5)    
	shadow.position = Vector2(7, 7)             
	shadow.scale = Vector2(1, 1)               
	shadow.z_index = -1 
	
	z_index = 1
	health = max_health
	emit_signal("health_changed", health, max_health)

	var grid = get_node(grid_node)
	for child in grid.get_children():
		if child is Node2D and not child is Camera2D:
			grid_positions.append(child.global_position)

	global_position = grid_positions[current_index]
	target_position = global_position

	# Hurtbox
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	# Camera
	camera = get_tree().get_first_node_in_group("camera")
	CameraManager.init(camera)
	
	# Audio
	audio_hurt = AudioStreamPlayer.new()
	audio_hurt.stream = preload("res://audio/player_damage.wav")
	audio_hurt.volume_db = -5.0
	audio_hurt.bus = "SFX"
	add_child(audio_hurt)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode in key_map:
			current_index = key_map[event.keycode]
			if grid_.disabled_cells.has(current_index):
				return
			target_position = grid_positions[current_index]
			moving = true
			
			# Face toward target
			var dir = (target_position - global_position).normalized()
			anim.rotation = dir.angle() + deg_to_rad(90)
			

func _physics_process(delta):
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
			shadow.animation = anim.animation
			shadow.frame = anim.frame          
			shadow.rotation = 0

	if moving:
		anim.play("move")
		shadow.visible = false
		var direction = (target_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()

		if global_position.distance_to(target_position) < 5:
			global_position = target_position
			velocity = Vector2.ZERO
			moving = false
	else:
		anim.play("idle")
		shadow.visible = true
		velocity = Vector2.ZERO

func take_damage(amount: int):
	if invincible or dead:
		return
	
	# Flash red
	anim.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	anim.modulate = Color(1, 1, 1)
	
	health -= amount
	if health < 0:
		health = 0

	invincible = true
	invincible_timer = invincible_time

	emit_signal("health_changed", health, max_health)
	CameraManager.shake(17.0, 0.3)
	audio_hurt.pitch_scale = randf_range(0.9, 1.1)
	audio_hurt.play()
	print("Player HP: ", health)

	if health <= 0:
		die()

func heal(amount: int):
	health += amount
	if health > max_health:
		health = max_health

	emit_signal("health_changed", health, max_health)

func die():
	print("Player died")
	dead = true
	
	moving = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)
	MusicManager.fade_out(1.0)
	
	Engine.time_scale = 0.3
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(anim, "modulate:a", 0.0, 0.5)
	tween.tween_property(anim, "rotation", anim.rotation + deg_to_rad(360), 1.0)
	tween.tween_property(anim, "scale", Vector2(0.1, 0.1), 1.0)
	
	CameraManager.shake(30.0, 0.8)
	
	# true = ignore time scale
	await get_tree().create_timer(1.5, false, false, true).timeout
	Engine.time_scale = 1.0
	get_node("/root/Main/GameOverScreen").show_screen()
	
func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("enemy_attack"):
		take_damage(1)

func _on_hurtbox_body_entered(body: Node):
	if body.is_in_group("enemy"):
		take_damage(1)
