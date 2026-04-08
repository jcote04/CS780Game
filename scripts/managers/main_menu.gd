extends Node2D

var hover_sound: AudioStreamPlayer

func _ready():
	# Music
	MusicManager.play_menu()
	
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://audio/ui_mouse_hover.wav")
	hover_sound.volume_db = -5.0
	hover_sound.bus = "SFX"
	add_child(hover_sound)
	
	var bg = $Background
	bg.size = get_viewport().get_visible_rect().size
	bg.position = Vector2.ZERO
	
	for button in $MenuCanvasLayer/Button_manager.get_children():
		if button is Button:
			button.add_theme_color_override("font_hover_color", Color(0.07, 0.592, 0.522, 1.0))
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	$OptionsCanvasLayer/BackButton.add_theme_color_override("font_hover_color", Color(0.07, 0.592, 0.522, 1.0))
	$OptionsCanvasLayer/BackButton.mouse_entered.connect(_on_button_hover.bind($OptionsCanvasLayer/BackButton))
	$OptionsCanvasLayer/BackButton.mouse_exited.connect(_on_button_unhover.bind($OptionsCanvasLayer/BackButton))
	
func _on_button_hover(button: Button):
	hover_sound.play()
	button.add_theme_font_size_override("font_size", 38)

func _on_button_unhover(button: Button):
	button.add_theme_font_size_override("font_size", 32)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_shop_pressed() -> void:
	pass # Replace with function body.

func _on_options_pressed() -> void:
	$MenuCanvasLayer.visible = false
	$OptionsCanvasLayer.visible = true

func _on_options_back_pressed():
	$OptionsCanvasLayer.visible = false
	$MenuCanvasLayer.visible = true

func _on_master_slider_value_changed(value: float):
	# value 0..1 from slider
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _on_quit_pressed() -> void:
	get_tree().quit()
