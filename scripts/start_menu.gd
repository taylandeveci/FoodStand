extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

@onready var play_button: BaseButton = $CenterContainer/VBoxContainer/PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_play_pressed()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
