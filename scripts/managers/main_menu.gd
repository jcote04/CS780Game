extends Node2D

var hover_sound: AudioStreamPlayer

func _ready():
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://audio/ui_mouse_hover.wav")
	hover_sound.volume_db = -5.0
	add_child(hover_sound)

	# Connect hover signals for each button
	$Button_manager/Start.mouse_entered.connect(_on_button_hover)
	$Button_manager/Shop.mouse_entered.connect(_on_button_hover)
	$Button_manager/Options.mouse_entered.connect(_on_button_hover)
	$Button_manager/Quit.mouse_entered.connect(_on_button_hover)
	
	
func _on_button_hover():
	hover_sound.play()


func _on_start_pressed() -> void:
	MusicManager.play()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_shop_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
