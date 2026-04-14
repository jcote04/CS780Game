extends Area2D

@export var speed := 700.0
@export var damage := 1
@export var lifetime := 2.0

var direction := Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullet")

func _physics_process(delta):
	global_position += direction * speed * delta

	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemy_hurtbox"):
		var boss = area.get_parent()
		if boss and boss.has_method("take_damage"):
			boss.take_damage(damage)
		queue_free()
