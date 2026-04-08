extends Node

var music_player: AudioStreamPlayer
var is_fading := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func play_game():
	cancel_fade()
	music_player.stop()
	music_player.stream = preload("res://audio/game_music.wav")
	music_player.volume_db = -10.0
	music_player.play()
	print("Playing Game music, volume:", music_player.volume_db)


func play_menu():
	cancel_fade()
	music_player.stop()
	music_player.stream = preload("res://audio/menu_music.wav")
	music_player.volume_db = -10.0
	music_player.play()
	print("Playing Menu music, volume:", music_player.volume_db)


func fade_out(duration):
	is_fading = true
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, duration)
	tween.connect("finished", Callable(self, "_on_fade_complete"))
	
func _on_fade_complete():
	if is_fading:
		music_player.stop()

func cancel_fade():
	is_fading = false

func stop():
	is_fading = false
	music_player.stop()
