extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.stream = preload("res://audio/game_music.wav")
	music_player.volume_db = -10.0
	add_child(music_player)

func play():
	if not music_player.playing:
		music_player.play()

func stop():
	music_player.stop()
