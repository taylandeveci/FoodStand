extends Control

@export var reward_font: Font

@onready var title_label: Label = $Panel/TitleLabel
@onready var info_label: Label = $Panel/InfoLabel
@onready var reward_button_1: Button = $Panel/RewardList/RewardButton1
@onready var reward_button_2: Button = $Panel/RewardList/RewardButton2
@onready var reward_button_3: Button = $Panel/RewardList/RewardButton3

const DISTRICT_SELECT_SCENE_PATH := "res://scenes/district_select.tscn"

var current_options: Array = []

func _ready() -> void:
	title_label.text = "Choose Your Reward"
	info_label.text = "%s completed! Pick one reward." % RunManager.get_current_district_name()

	current_options = RunManager.get_pending_reward_options()

	reward_button_1.pressed.connect(_on_reward_button_1_pressed)
	reward_button_2.pressed.connect(_on_reward_button_2_pressed)
	reward_button_3.pressed.connect(_on_reward_button_3_pressed)

	setup_button(reward_button_1, 0)
	setup_button(reward_button_2, 1)
	setup_button(reward_button_3, 2)

func setup_button(button: Button, index: int) -> void:
	if index >= current_options.size():
		button.visible = false
		button.disabled = true
		return

	var option: Dictionary = current_options[index]
	var option_title: String = str(option.get("title", "Reward"))
	var option_description: String = str(option.get("description", ""))

	button.text = option_title + "\n" + option_description
	button.disabled = false
	
	button.add_theme_font_override("font", reward_font)
	button.add_theme_font_size_override("font_size", 20)

func choose_reward(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return

	var option: Dictionary = current_options[index]
	var option_id: String = str(option.get("id", ""))

	if option_id == "":
		return

	RunManager.apply_reward_option(option_id)
	get_tree().change_scene_to_file(DISTRICT_SELECT_SCENE_PATH)

func _on_reward_button_1_pressed() -> void:
	choose_reward(0)

func _on_reward_button_2_pressed() -> void:
	choose_reward(1)

func _on_reward_button_3_pressed() -> void:
	choose_reward(2)
