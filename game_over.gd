extends Node2D

func _ready():
	$RetryButton.pressed.connect(_on_retry)
	$MenuButton.pressed.connect(_on_menu)

func _on_retry():
	MusicManager.stop()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_menu():
	MusicManager.stop()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
