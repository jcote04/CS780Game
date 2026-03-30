extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func play_game():
	music_player.stream = preload("res://audio/game_music.wav")
	music_player.volume_db = -10.0
	if not music_player.playing:
		music_player.play()

func play_menu():
	music_player.stream = preload("res://audio/menu_music.wav")
	music_player.volume_db = -10.0
	if not music_player.playing:
		music_player.play()

func stop():
	music_player.stop()
