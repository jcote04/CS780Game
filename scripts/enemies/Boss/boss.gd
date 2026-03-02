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

var player_node
var attack_rect: ColorRect
var boss_visual: ColorRect

var state := "idle"
var timer := 0.0
var blink_count := 0

var angle := 0.0
var current_speed := 1.5
var target_speed := 1.5  # positive = clockwise, negative = counter
var locked_player_pos := Vector2.ZERO

func _ready():
	player_node = get_node(player)
	grid_center = get_node(grid).position
	
	boss_visual = ColorRect.new()
	boss_visual.size = Vector2(60, 60)
	boss_visual.color = Color(0.8, 0.1, 0.1)
	boss_visual.position = -boss_visual.size / 2
	add_child(boss_visual)
	
	attack_rect = ColorRect.new()
	attack_rect.visible = false
	add_child(attack_rect)

func _process(delta):
	if state == "idle":
		current_speed = lerp(current_speed, target_speed, delta * 1.5)
		angle += current_speed * delta
		position = grid_center + Vector2(cos(angle), sin(angle)) * orbit_radius

	timer -= delta

	match state:
		"idle":
			if timer <= 0:
				# Snapshot player position right now
				locked_player_pos = player_node.position
				# Maybe flip direction smoothly
				if randf() > 0.5:
					target_speed *= -1
				state = "warn"
				blink_count = 0
				timer = blink_duration
				update_attack_rect(warn_color)
				attack_rect.visible = true

		"warn":
			if timer <= 0:
				attack_rect.visible = !attack_rect.visible
				blink_count += 1
				timer = blink_duration
				if blink_count >= 4:
					state = "attack"
					timer = attack_duration
					update_attack_rect(attack_color)
					attack_rect.visible = true

		"attack":
			if timer <= 0:
				attack_rect.visible = false
				state = "idle"
				timer = idle_duration

func update_attack_rect(color: Color):
	# Direction from boss WORLD position to locked player position
	var world_pos = global_position
	var dir = (locked_player_pos - world_pos).normalized()
	var attack_angle = dir.angle()
	
	attack_rect.color = color
	attack_rect.size = Vector2(attack_length, attack_width)
	# Offset so attack starts at boss center
	attack_rect.position = Vector2(0, -attack_width / 2)
	attack_rect.pivot_offset = Vector2(0, attack_width / 2)
	attack_rect.rotation = attack_angle
