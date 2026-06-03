extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var start_game: Panel = $"Start Game"

const DISTRICT_SELECT_SCENE_PATH := "res://scenes/district_select.tscn"

func _ready() -> void:
	MusicManager.play_intro_music()
	show_main_menu()

func show_main_menu() -> void:
	main_buttons.visible = true
	options.visible = false
	start_game.visible = false

func _on_start_pressed() -> void:
	main_buttons.visible = false
	options.visible = false
	start_game.visible = true

func _on_options_pressed() -> void:
	main_buttons.visible = false
	start_game.visible = false
	options.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_options_pressed() -> void:
	show_main_menu()

func _on_back_start_pressed() -> void:
	show_main_menu()

func _on_continue_pressed() -> void:
	RunManager.load_meta()
	RunManager.load_run()
	get_tree().change_scene_to_file(DISTRICT_SELECT_SCENE_PATH)

func _on_restart_pressed() -> void:
	RunManager.load_meta()
	RunManager.reset_run()
	RunManager.save_run()
	get_tree().change_scene_to_file(DISTRICT_SELECT_SCENE_PATH)
	
func _on_new_game_pressed() -> void:
	RunManager.load_meta()
	RunManager.create_new_slot()
	get_tree().change_scene_to_file(DISTRICT_SELECT_SCENE_PATH)
