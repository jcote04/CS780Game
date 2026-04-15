extends Node

# Player stats
var max_health = 5
var bullet_damage = 1
var fire_rate = 1

# Current upgrade levels
var health_level = 0
var damage_level = 0
var fire_rate_level = 0

# Upgrade costs
var health_cost = 10
var damage_cost = 10
var fire_rate_cost = 10

var player_node = null

func register_player(player):
	player_node = player
	apply_upgrades_to_player()

func upgrade_health():
	health_level += 1
	max_health += 1
	health_cost = int(health_cost * 1.5)
	apply_upgrades_to_player()

func upgrade_damage():
	damage_level += 1
	bullet_damage += 1
	damage_cost = int(damage_cost * 1.5)
	apply_upgrades_to_player()

func upgrade_fire_rate():
	fire_rate_level += 1
	fire_rate -= 0.1
	fire_rate = max(fire_rate, 0.05)
	fire_rate_cost = int(fire_rate_cost * 1.5)
	apply_upgrades_to_player()

func apply_upgrades_to_player():
	if player_node:
		player_node.max_health = max_health
		player_node.bullet_damage = bullet_damage
		player_node.shoot_cooldown = fire_rate
		
		# If player is at full health, increase to new max
		if player_node.health == player_node.max_health - 1:
			player_node.health = max_health
		
		player_node.emit_signal("health_changed", player_node.health, player_node.max_health)
