extends Node2D

var hover_sound: AudioStreamPlayer

func _ready():
	# Music
	MusicManager.play_menu()
	
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://audio/ui_mouse_hover.wav")
	hover_sound.volume_db = -5.0
	add_child(hover_sound)

	# Connect hover signals for each button
	$Button_manager/Start.mouse_entered.connect(_on_button_hover)
	$Button_manager/Shop.mouse_entered.connect(_on_button_hover)
	$Button_manager/Options.mouse_entered.connect(_on_button_hover)
	$Button_manager/Quit.mouse_entered.connect(_on_button_hover)
	
	var bg = $Background
	bg.size = get_viewport().get_visible_rect().size
	bg.position = Vector2.ZERO
	
	for button in $Button_manager.get_children():
		if button is Button:
			button.add_theme_color_override("font_hover_color", Color(0.07, 0.592, 0.522, 1.0)) # yellow on hover
	
	
func _on_button_hover():
	hover_sound.play()


func _on_start_pressed() -> void:
	MusicManager.stop()
	MusicManager.play_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_shop_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
