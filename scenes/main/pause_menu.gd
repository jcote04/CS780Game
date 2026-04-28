extends CanvasLayer

var hover_sound: AudioStreamPlayer

func _ready():
	visible = false
	
	$ResumeButton.pressed.connect(_on_resume)
	$QuitButton.pressed.connect(_on_menu)
	
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://audio/ui_mouse_hover.wav")
	hover_sound.volume_db = -5.0
	hover_sound.bus = "SFX"
	add_child(hover_sound)
	
	for button in get_children():
		if button is Button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	hover_sound.play()
	button.add_theme_font_size_override("font_size", 38)

func _on_button_unhover(button: Button):
	button.add_theme_font_size_override("font_size", 32)

func show_screen():
	visible = true
	
	$ColorRect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($ColorRect, "modulate:a", 1.0, 0.25)
	
	get_tree().paused = true

func _on_resume():
	get_tree().paused = false
	visible = false

func _on_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
