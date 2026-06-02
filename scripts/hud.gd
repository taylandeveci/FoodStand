extends CanvasLayer

const PHASE_DAYTIME_TEXTURE: Texture2D = preload("res://assets/props/props_daytime/prop_daytime.png")
const PHASE_NIGHTTIME_TEXTURE: Texture2D = preload("res://assets/props/props_nighttime/prop_nighttime.png")
const PHASE_DAYTIME_FRAMES: int = 30
const PHASE_NIGHTTIME_FRAMES: int = 30
const PHASE_ANIMATION_DURATION: float = 4.0
const PHASE_ANIMATION_END_HOLD: float = 0.32

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
@onready var phase_animation: Sprite2D = $HUDRoot/PhaseAnimation

# SHOP PANEL
@onready var shop_panel: Panel = $HUDRoot/ShopPanel
@onready var shop_title_label: Label = $HUDRoot/ShopPanel/ShopTitleLabel
@onready var shop_money_label: Label = $HUDRoot/ShopPanel/ShopMoneyLabel
@onready var shop_mode_label: Label = $HUDRoot/ShopPanel/ShopModeLabel
@onready var upgrade_list: VBoxContainer = $HUDRoot/ShopPanel/UpgradeList
@onready var upgrade_button_1: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton1
@onready var upgrade_button_2: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton2
@onready var upgrade_button_3: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton3
@onready var continue_button: Button = $HUDRoot/ShopPanel/ContinueButton

var phase_animation_tween: Tween

func _ready() -> void:
	clear_feedback()
	hide_service_panel()
	hide_shop_panel()
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

	if phase_animation:
		phase_animation.position = Vector2(576, 140)
		phase_animation.scale = Vector2(4.0, 4.0)
		phase_animation.centered = true
		phase_animation.visible = false


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
# SHOP PANEL
# -------------------------

func show_shop_panel(
	title_text: String,
	mode_text: String,
	current_money: int,
	upgrade_1_text: String,
	upgrade_2_text: String,
	upgrade_3_text: String
) -> void:
	shop_panel.visible = true

	shop_title_label.text = title_text
	shop_mode_label.text = mode_text
	shop_money_label.text = "Money: " + str(current_money)

	upgrade_button_1.text = upgrade_1_text
	upgrade_button_2.text = upgrade_2_text
	upgrade_button_3.text = upgrade_3_text

	upgrade_button_1.disabled = false
	upgrade_button_2.disabled = false
	upgrade_button_3.disabled = false
	continue_button.disabled = false


func hide_shop_panel() -> void:
	shop_panel.visible = false


func update_shop_money(current_money: int) -> void:
	shop_money_label.text = "Money: " + str(current_money)


func set_shop_buttons_enabled(enabled: bool) -> void:
	upgrade_button_1.disabled = not enabled
	upgrade_button_2.disabled = not enabled
	upgrade_button_3.disabled = not enabled
	continue_button.disabled = not enabled


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
	hide_phase_animation()
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

func show_phase_animation(texture: Texture2D, frame_count: int, duration: float = PHASE_ANIMATION_DURATION) -> void:
	if phase_animation == null:
		return

	phase_label.visible = false
	phase_label.text = ""

	hide_phase_animation()

	phase_animation.texture = texture
	phase_animation.hframes = max(frame_count, 1)
	phase_animation.frame = 0
	phase_animation.visible = true

	var tween := create_tween()
	phase_animation_tween = tween
	tween.tween_method(_set_phase_animation_progress.bind(frame_count), 0.0, 1.0, duration)
	tween.tween_interval(PHASE_ANIMATION_END_HOLD)

	await tween.finished

	if phase_animation_tween == tween:
		phase_animation.visible = false
		phase_animation_tween = null

func hide_phase_animation() -> void:
	if phase_animation_tween:
		phase_animation_tween.kill()
		phase_animation_tween = null

	if phase_animation:
		phase_animation.visible = false
		phase_animation.frame = 0

func set_phase_animation_position(screen_position: Vector2) -> void:
	if phase_animation == null:
		return
	phase_animation.position = screen_position

func is_phase_animation_visible() -> bool:
	return phase_animation != null and phase_animation.visible

func _set_phase_animation_progress(progress: float, frame_count: int) -> void:
	if phase_animation == null:
		return

	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	phase_animation.frame = mini(int(clamped_progress * float(frame_count - 1)), frame_count - 1)


func show_phase_morning_prep() -> void:
	show_phase_animation(PHASE_DAYTIME_TEXTURE, PHASE_DAYTIME_FRAMES)


func show_phase_night_started() -> void:
	show_phase_animation(PHASE_NIGHTTIME_TEXTURE, PHASE_NIGHTTIME_FRAMES)


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

	hide_phase_animation()
