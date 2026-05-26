extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var info_label: Label = $Panel/InfoLabel
@onready var district_grid: GridContainer = $Panel/DistrictGrid
@onready var back_button: Button = $Panel/BackButton

const GAME_SCENE_PATH: String = "res://scenes/main.tscn"
const MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	build_district_buttons()
	update_info_text()

func build_district_buttons() -> void:
	for child in district_grid.get_children():
		child.queue_free()

	for i in range(RunManager.DISTRICT_COUNT):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(260, 100)

		var district_name: String = str(RunManager.DISTRICT_NAMES[i])
		var progress: int = int(RunManager.get_day_progress_for(i))
		var unlocked: bool = bool(RunManager.is_district_unlocked(i))

		var text: String = "%d. %s" % [i + 1, district_name]

		if unlocked:
			if progress >= RunManager.DAYS_PER_DISTRICT:
				text += "\nCompleted"
			else:
				text += "\nDay %d / %d" % [progress + 1, RunManager.DAYS_PER_DISTRICT]

			button.disabled = false
			button.pressed.connect(_on_district_pressed.bind(i))
		else:
			text += "\nLocked"
			button.disabled = true

		button.text = text
		district_grid.add_child(button)

func update_info_text() -> void:
	info_label.text = "Unlocked Districts: %d / %d" % [
		RunManager.unlocked_district_count,
		RunManager.DISTRICT_COUNT
	]

func _on_district_pressed(index: int) -> void:
	if RunManager.select_district(index):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
