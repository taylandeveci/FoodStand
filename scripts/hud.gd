extends CanvasLayer

@onready var hud_root = $HUDRoot

@onready var coin_icon = $HUDRoot/CoinIcon
@onready var coin_label: Label = $HUDRoot/CoinLabel
@onready var appeal_label: Label = $HUDRoot/AppealLabel
@onready var trash_label: Label = $HUDRoot/TrashLabel
@onready var health_bar: TextureProgressBar = $HUDRoot/HealthBar
@onready var status_label: Label = $HUDRoot/StatusLabel
@onready var result_label: Label = $HUDRoot/ResultLabel
@onready var stand_hp_label: Label = $HUDRoot/StandHpLabel

@onready var service_panel: Control = $HUDRoot/ServicePanel
@onready var order_label: Label = $HUDRoot/ServicePanel/OrderLabel
@onready var hint_label: Label = $HUDRoot/ServicePanel/HintLabel
@onready var timing_bar: ProgressBar = $HUDRoot/ServicePanel/TimingBar

@onready var phase_label: Label = $HUDRoot/PhaseLabel


func _ready() -> void:
	clear_feedback()
	hide_service_panel()
	apply_default_layout()
	


# -------------------------
# DEFAULT HUD LAYOUT
# -------------------------

func apply_default_layout() -> void:
	coin_icon.position = Vector2(32, 108)
	coin_label.position = Vector2(64, 108)

	appeal_label.position = Vector2(38, 138)
	trash_label.position = Vector2(38, 168)
	stand_hp_label.position = Vector2(38, 198)

	status_label.position = Vector2(320, 80)
	status_label.size = Vector2(600, 90)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD

	if phase_label:
		phase_label.position = Vector2(0, 260)
		phase_label.size = Vector2(1152, 140)
		phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		phase_label.visible = false


# -------------------------
# BASIC HUD VALUES
# -------------------------

func update_coin(amount: int) -> void:
	coin_label.text = str(amount)


func update_appeal(amount: int) -> void:
	appeal_label.text = "Appeal: " + str(amount)


func update_trash(amount: int) -> void:
	trash_label.text = "Trash Left: " + str(amount)


func update_player_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

	if current <= maximum * 0.25:
		show_warning("PLAYER LOW HP!")


func update_stand_hp(current: int, maximum: int) -> void:
	stand_hp_label.text = "Stand HP: " + str(current) + " / " + str(maximum)

	if current <= maximum * 0.25:
		show_warning("STAND CRITICAL!")


# -------------------------
# SERVICE PANEL
# -------------------------

func show_service_panel(order_text: String, hint_text: String = "") -> void:
	service_panel.visible = true
	order_label.text = order_text
	hint_label.text = hint_text


func hide_service_panel() -> void:
	service_panel.visible = false


func update_timing_bar(value: float, maximum: float = 100.0) -> void:
	timing_bar.max_value = maximum
	timing_bar.value = value


# -------------------------
# STATUS / RESULT
# -------------------------

func show_status(text: String) -> void:
	status_label.text = text
	status_label.visible = true
	status_label.modulate.a = 1.0


func show_result(text: String) -> void:
	result_label.text = text
	result_label.visible = true
	result_label.modulate.a = 1.0
	result_label.scale = Vector2(0.9, 0.9)

	var tween := create_tween()
	tween.tween_property(result_label, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.12)
	tween.tween_interval(0.7)
	tween.tween_property(result_label, "modulate:a", 0.0, 0.25)


func show_warning(text: String) -> void:
	status_label.text = text
	status_label.visible = true
	status_label.modulate.a = 1.0

	var original_position := status_label.position
	var tween := create_tween()

	tween.tween_property(status_label, "position", original_position + Vector2(8, 0), 0.05)
	tween.tween_property(status_label, "position", original_position - Vector2(8, 0), 0.05)
	tween.tween_property(status_label, "position", original_position, 0.05)


# -------------------------
# PHASE TEXTS
# -------------------------

func show_phase_text(text: String) -> void:
	phase_label.text = text
	phase_label.visible = true
	phase_label.modulate.a = 0.0
	phase_label.scale = Vector2(0.5, 0.5)

	var tween := create_tween()

	tween.tween_property(phase_label, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(
		phase_label,
		"scale",
		Vector2(1.0, 1.0),
		0.25
	)

	tween.tween_interval(1.5)
	tween.tween_property(phase_label, "modulate:a", 0.0, 0.4)

	await tween.finished
	phase_label.visible = false


func show_phase_morning_prep() -> void:
	show_phase_text("MORNING PREP")


func show_phase_night_started() -> void:
	show_phase_text("NIGHT STARTED")


func show_phase_night_survived() -> void:
	show_phase_text("NIGHT SURVIVED")


func show_game_over() -> void:
	show_phase_text("GAME OVER")
	show_result("Run ended!")


# -------------------------
# GAMEPLAY FEEDBACK HELPERS
# -------------------------

func show_correct_recipe() -> void:
	show_result("Correct Recipe!")


func show_wrong_recipe() -> void:
	show_result("Wrong Recipe!")


func show_perfect_serve() -> void:
	show_result("PERFECT SERVE!")


func show_nice_serve() -> void:
	show_result("Nice Serve")


func show_bad_serve() -> void:
	show_result("Bad Serve!")


func show_player_down() -> void:
	show_warning("PLAYER DOWN!")


func show_stand_damage() -> void:
	show_warning("STAND DAMAGED!")


func clear_feedback() -> void:
	status_label.text = ""
	result_label.text = ""

	status_label.visible = true
	result_label.visible = true

	status_label.modulate.a = 1.0
	result_label.modulate.a = 1.0

	if phase_label:
		phase_label.text = ""
		phase_label.visible = false
