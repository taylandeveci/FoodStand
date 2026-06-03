extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var info_label: Label = $Panel/InfoLabel
@onready var district_grid: GridContainer = $Panel/DistrictGrid
@onready var back_button: Button = $Panel/BackButton

const GAME_SCENE_PATH: String = "res://scenes/main.tscn"
const MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const DISTRICT_FONT: Font = preload("res://Fonts/ThaleahFat.ttf")

func _ready() -> void:
	var back_pressed_callable := Callable(self, "_on_back_pressed")
	if back_button and not back_button.pressed.is_connected(back_pressed_callable):
		back_button.pressed.connect(back_pressed_callable)

	call_deferred("_setup_screen")

func _setup_screen() -> void:
	build_district_buttons()
	update_info_text()

func build_district_buttons() -> void:
	if district_grid == null:
		return

	for child in district_grid.get_children():
		child.queue_free()

	for i in range(RunManager.DISTRICT_COUNT):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(360, 170)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if DISTRICT_FONT != null:
			button.add_theme_font_override("font", DISTRICT_FONT)
		button.add_theme_font_size_override("font_size", 20)

		var district_name: String = str(RunManager.DISTRICT_NAMES[i])
		var progress: int = int(RunManager.get_day_progress_for(i))
		var unlocked: bool = bool(RunManager.is_district_unlocked(i))
		var completed: bool = progress >= RunManager.DAYS_PER_DISTRICT
		var claimed_reward_title: String = RunManager.get_claimed_reward_title(i)

		var text: String = "%d. %s\n" % [i + 1, district_name]

		if unlocked:
			if completed:
				text += "Status: Completed\n"
			else:
				text += "Status: Unlocked\n"
				text += "Day %d / %d\n" % [progress + 1, RunManager.DAYS_PER_DISTRICT]
		else:
			text += "Status: Locked\n"

		text += "\nPossible Rewards:\n"
		text += build_reward_preview_text(i)

		if claimed_reward_title != "":
			text += "\nClaimed Reward:\n- " + claimed_reward_title

		if unlocked:
			button.disabled = false
			button.pressed.connect(_on_district_pressed.bind(i))
		else:
			button.disabled = true

		button.text = text
		district_grid.add_child(button)

func build_reward_preview_text(index: int) -> String:
	var options: Array = RunManager.build_reward_options_for_district(index)

	if options.is_empty():
		return "- No reward data"

	var lines: Array = []

	for option in options:
		var option_title: String = str(option.get("title", "Reward"))
		lines.append("- " + option_title)

	return "\n".join(lines)

func update_info_text() -> void:
	if info_label == null:
		return

	var unlocked_recipes_text: String = ", ".join(RunManager.get_unlocked_recipe_names())

	info_label.text = "Unlocked Districts: %d / %d\nUnlocked Recipes: %s" % [
		RunManager.unlocked_district_count,
		RunManager.DISTRICT_COUNT,
		unlocked_recipes_text
	]

func _on_district_pressed(index: int) -> void:
	if RunManager.select_district(index):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
