extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var start_game: Panel = $"Start Game"
@onready var how_to_play_button: Button = $Panel/HowToPlay
@onready var how_to_play_panel: Panel = $HowToPlayPanel
@onready var close_button: Button = $HowToPlayPanel/CloseButton
@onready var left_arrow_button: Button = $HowToPlayPanel/LeftArrowButton
@onready var right_arrow_button: Button = $HowToPlayPanel/RightArrowButton
@onready var page_1: Panel = $HowToPlayPanel/Page1
@onready var page_2: Panel = $HowToPlayPanel/Page2

var current_tutorial_page := 0


const DISTRICT_SELECT_SCENE_PATH := "res://scenes/district_select.tscn"

func _ready() -> void:
	MusicManager.play_intro_music()
	show_main_menu()
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	close_button.pressed.connect(_on_close_how_to_play_pressed)
	left_arrow_button.pressed.connect(_on_left_arrow_pressed)
	right_arrow_button.pressed.connect(_on_right_arrow_pressed)
	update_tutorial_pages()

func show_main_menu() -> void:
	set_main_menu_buttons_visible(true)
	options.visible = false
	start_game.visible = false
	how_to_play_panel.visible = false

func _on_start_pressed() -> void:
	set_main_menu_buttons_visible(false)
	options.visible = false
	start_game.visible = true
	how_to_play_panel.visible = false

func _on_options_pressed() -> void:
	set_main_menu_buttons_visible(false)
	start_game.visible = false
	options.visible = true
	how_to_play_panel.visible = false

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
	
func _on_how_to_play_pressed() -> void:
	set_main_menu_buttons_visible(false)
	options.visible = false
	start_game.visible = false
	how_to_play_panel.visible = true
	current_tutorial_page = 0
	update_tutorial_pages()

func _on_close_how_to_play_pressed() -> void:
	how_to_play_panel.visible = false
	set_main_menu_buttons_visible(true)
	
func set_main_menu_buttons_visible(value: bool) -> void:
	main_buttons.visible = value

	if how_to_play_button:
		how_to_play_button.visible = value
		
func _on_right_arrow_pressed() -> void:
	if current_tutorial_page < 1:
		current_tutorial_page += 1
		update_tutorial_pages()

func _on_left_arrow_pressed() -> void:
	if current_tutorial_page > 0:
		current_tutorial_page -= 1
		update_tutorial_pages()
	
func update_tutorial_pages() -> void:
	page_1.visible = current_tutorial_page == 0
	page_2.visible = current_tutorial_page == 1

	left_arrow_button.visible = current_tutorial_page > 0
	right_arrow_button.visible = current_tutorial_page < 1
