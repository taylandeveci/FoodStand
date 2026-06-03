extends Node

const INTRO_MUSIC: AudioStream = preload("res://sounds/musics/intro.mp3")
const DAY_MUSIC: AudioStream = preload("res://sounds/musics/day.mp3")
const NIGHT_MUSIC: AudioStream = preload("res://sounds/musics/night.mp3")

var music_player: AudioStreamPlayer = null
var current_music_key: StringName = &""

func _ready() -> void:
	setup_music_player()

func play_intro_music() -> void:
	play_music(INTRO_MUSIC, &"intro")

func play_day_music() -> void:
	play_music(DAY_MUSIC, &"day")

func play_night_music() -> void:
	play_music(NIGHT_MUSIC, &"night")

func stop_music() -> void:
	current_music_key = &""

	if music_player and music_player.playing:
		music_player.stop()

func setup_music_player() -> void:
	if music_player != null:
		return

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = &"Music"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

func play_music(stream: AudioStream, music_key: StringName) -> void:
	setup_music_player()

	if stream == null:
		return

	current_music_key = music_key
	music_player.stream = stream

	if music_player.playing:
		music_player.stop()

	music_player.play()

func _on_music_finished() -> void:
	if music_player == null:
		return

	if current_music_key == &"" or music_player.stream == null:
		return

	music_player.play()
