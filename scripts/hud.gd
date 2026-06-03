extends CanvasLayer

const PHASE_DAYTIME_TEXTURE: Texture2D = preload("res://assets/props/props_daytime/prop_daytime.png")
const PHASE_NIGHTTIME_TEXTURE: Texture2D = preload("res://assets/props/props_nighttime/prop_nighttime.png")
const PHASE_DAYTIME_FRAMES: int = 30
const PHASE_NIGHTTIME_FRAMES: int = 30
const PHASE_ANIMATION_DURATION: float = 4.0
const PHASE_ANIMATION_END_HOLD: float = 0.32
const FOOD_TRUCK_HEALTH_ENGINE_SCALE: Vector2 = Vector2(1.2, 1.2)
const FOOD_TRUCK_HEALTH_ENGINE_FRAME_OFFSETS := [
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO,
	Vector2.ZERO,
]

@onready var hud_root = $HUDRoot

@onready var stat_bar_background: TextureRect = $HUDRoot/StatBarBackground
@onready var coin_icon: TextureRect = $HUDRoot/CoinIcon
@onready var fist_icon: TextureRect = $HUDRoot/FistIcon
@onready var trash_icon: TextureRect = $HUDRoot/TrashIcon
@onready var coin_label: Label = $HUDRoot/CoinLabel
@onready var appeal_label: Label = $HUDRoot/AppealLabel
@onready var trash_label: Label = $HUDRoot/TrashLabel
@onready var health_bar: TextureProgressBar = $HUDRoot/HealthBar
@onready var day_banner_label: Label = $HUDRoot/DayBannerLabel
@onready var food_truck_health_engine: Sprite2D = $HUDRoot/FoodTruckHealthEngine
@onready var status_label: Label = $HUDRoot/StatusLabel
@onready var result_label: Label = $HUDRoot/ResultLabel
@onready var stand_hp_label: Label = $HUDRoot/StandHpLabel

@onready var service_panel: Control = $HUDRoot/ServicePanel
@onready var order_label: Label = $HUDRoot/ServicePanel/OrderLabel
@onready var hint_label: Label = $HUDRoot/ServicePanel/HintLabel
@onready var timing_bar: ProgressBar = $HUDRoot/ServicePanel/TimingBar
@onready var barricade_prompt_label: Label = $HUDRoot/BarricadePromptLabel

@onready var phase_label: Label = $HUDRoot/PhaseLabel
@onready var phase_animation: Sprite2D = $HUDRoot/PhaseAnimation

# SHOP PANEL
@onready var shop_panel: Panel = $HUDRoot/ShopPanel
@onready var shop_title_label: Label = $HUDRoot/ShopPanel/ShopTitleLabel
@onready var shop_money_label: Label = $HUDRoot/ShopPanel/ShopMoneyLabel
@onready var shop_mode_label: Label = $HUDRoot/ShopPanel/ShopModeLabel
@onready var market_type_label: Label = $HUDRoot/ShopPanel/MarketTypeLabel
@onready var inventory_label: Label = $HUDRoot/ShopPanel/InventoryLabel
@onready var switch_market_button: Button = $HUDRoot/ShopPanel/SwitchMarketButton

@onready var upgrade_list: VBoxContainer = $HUDRoot/ShopPanel/UpgradeList
@onready var upgrade_button_1: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton1
@onready var upgrade_button_2: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton2
@onready var upgrade_button_3: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton3
@onready var upgrade_button_4: Button = $HUDRoot/ShopPanel/UpgradeList/UpgradeButton4
@onready var continue_button: Button = $HUDRoot/ShopPanel/ContinueButton

var phase_animation_tween: Tween
var day_banner_tween: Tween

# SURVIVAL BAR
@onready var survival_bar: Panel = $HUDRoot/SurvivalBar
@onready var medkit_label: Label = $HUDRoot/SurvivalBar/HBoxContainer/MedkitLabel
@onready var repair_label: Label = $HUDRoot/SurvivalBar/HBoxContainer/RepairLabel
@onready var barricade_label: Label = $HUDRoot/SurvivalBar/HBoxContainer/BarricadeLabel

func _ready() -> void:
	clear_feedback()
	hide_service_panel()
	hide_shop_panel()
	apply_default_layout()
	show_survival_bar()


# -------------------------
# DEFAULT HUD LAYOUT
# -------------------------

func apply_default_layout() -> void:
	if stat_bar_background:
		stat_bar_background.position = Vector2(0, -15)
		stat_bar_background.size = Vector2(192, 64)

	if coin_icon:
		coin_icon.visible = false
	if fist_icon:
		fist_icon.visible = false
	if trash_icon:
		trash_icon.visible = false

	coin_label.position = Vector2(34, -5)
	coin_label.size = Vector2(28, 36)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_label.add_theme_font_size_override("font_size", 18)
	coin_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))

	appeal_label.position = Vector2(98, -5)
	appeal_label.size = Vector2(28, 36)
	appeal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	appeal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	appeal_label.add_theme_font_size_override("font_size", 18)
	appeal_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))

	if trash_label:
		trash_label.visible = true
		trash_label.position = Vector2(162, -5)
		trash_label.size = Vector2(26, 36)
		trash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		trash_label.add_theme_font_size_override("font_size", 18)
		trash_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	if health_bar:
		health_bar.position = Vector2(-22, -80)
	if day_banner_label:
		day_banner_label.position = Vector2(-10, 56)
		day_banner_label.size = Vector2(220, 24)
		day_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day_banner_label.add_theme_font_size_override("font_size", 16)
		day_banner_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
		day_banner_label.visible = false
	if stand_hp_label:
		stand_hp_label.visible = false

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

	if food_truck_health_engine:
		food_truck_health_engine.scale = FOOD_TRUCK_HEALTH_ENGINE_SCALE
		food_truck_health_engine.centered = true
		food_truck_health_engine.visible = false
		set_food_truck_health_engine_frame(0)

	if barricade_prompt_label:
		barricade_prompt_label.position = Vector2(360, 620)
		barricade_prompt_label.size = Vector2(440, 40)
		barricade_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		barricade_prompt_label.visible = false

	if survival_bar:
		survival_bar.position = Vector2(760, 20)
		survival_bar.size = Vector2(360, 44)


func show_survival_bar() -> void:
	if survival_bar:
		survival_bar.visible = true


# -------------------------
# BASIC HUD VALUES
# -------------------------

func update_coin(amount: int) -> void:
	coin_label.text = str(amount)

func update_appeal(amount: int) -> void:
	appeal_label.text = str(amount)

func update_trash(amount: int) -> void:
	if trash_label:
		trash_label.text = str(amount)

func update_player_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

	if current <= maximum * 0.25:
		show_warning("PLAYER LOW HP!")

func update_stand_hp(current: int, maximum: int, emit_warning: bool = true) -> void:
	if stand_hp_label:
		stand_hp_label.text = ""
	update_food_truck_health_engine(current, maximum)

	if emit_warning and maximum > 0 and current <= maximum * 0.25:
		show_warning("STAND CRITICAL!")

func update_food_truck_health_engine(current: int, maximum: int) -> void:
	if food_truck_health_engine == null:
		return

	var frame_count: int = max(food_truck_health_engine.hframes, 1)
	if frame_count == 1:
		set_food_truck_health_engine_frame(0)
		return

	if maximum <= 0:
		set_food_truck_health_engine_frame(frame_count - 1)
		return

	var clamped_current: int = clampi(current, 0, maximum)
	var normalized_damage: float = 1.0 - (float(clamped_current) / float(maximum))
	var target_frame: int = int(normalized_damage * float(frame_count - 1))
	set_food_truck_health_engine_frame(clampi(target_frame, 0, frame_count - 1))

func set_food_truck_health_engine_frame(frame_index: int) -> void:
	if food_truck_health_engine == null:
		return

	food_truck_health_engine.frame = frame_index

	if frame_index >= 0 and frame_index < FOOD_TRUCK_HEALTH_ENGINE_FRAME_OFFSETS.size():
		food_truck_health_engine.offset = FOOD_TRUCK_HEALTH_ENGINE_FRAME_OFFSETS[frame_index]
	else:
		food_truck_health_engine.offset = Vector2.ZERO

func set_food_truck_health_engine_position(screen_position: Vector2) -> void:
	if food_truck_health_engine == null:
		return
	food_truck_health_engine.position = screen_position

func show_food_truck_health_engine() -> void:
	if food_truck_health_engine:
		food_truck_health_engine.visible = true

func hide_food_truck_health_engine() -> void:
	if food_truck_health_engine:
		food_truck_health_engine.visible = false

func update_survival_inventory(medkit_count: int, repair_count: int, barricade_count: int) -> void:
	if medkit_label:
		medkit_label.text = "Medkit: %d" % medkit_count

	if repair_label:
		repair_label.text = "Repair: %d" % repair_count

	if barricade_label:
		barricade_label.text = "Barricade: %d" % barricade_count


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
	money: int,
	item_1: String,
	item_2: String,
	item_3: String,
	item_4: String,
	market_type_text: String,
	inventory_text: String,
	allow_switch: bool
) -> void:
	shop_panel.visible = true

	shop_title_label.text = title_text
	shop_mode_label.text = mode_text
	shop_money_label.text = "Money: %d" % money
	market_type_label.text = market_type_text
	inventory_label.text = inventory_text

	upgrade_button_1.text = item_1
	upgrade_button_2.text = item_2
	upgrade_button_3.text = item_3
	upgrade_button_4.text = item_4

	upgrade_button_1.visible = item_1 != ""
	upgrade_button_2.visible = item_2 != ""
	upgrade_button_3.visible = item_3 != ""
	upgrade_button_4.visible = item_4 != ""

	upgrade_button_1.disabled = false
	upgrade_button_2.disabled = false
	upgrade_button_3.disabled = false
	upgrade_button_4.disabled = false
	continue_button.disabled = false

	switch_market_button.visible = allow_switch

func hide_shop_panel() -> void:
	shop_panel.visible = false

func update_shop_money(current_money: int) -> void:
	shop_money_label.text = "Money: " + str(current_money)

func update_shop_inventory(inventory_text: String) -> void:
	inventory_label.text = inventory_text

func update_shop_market_type(market_type_text: String) -> void:
	market_type_label.text = market_type_text

func update_switch_market_button_text(button_text: String) -> void:
	switch_market_button.text = button_text

func set_shop_buttons_enabled(enabled: bool) -> void:
	upgrade_button_1.disabled = not enabled
	upgrade_button_2.disabled = not enabled
	upgrade_button_3.disabled = not enabled
	upgrade_button_4.disabled = not enabled
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

func show_day_banner(text: String) -> void:
	if day_banner_label == null:
		return

	hide_day_banner()

	day_banner_label.text = text
	day_banner_label.visible = true
	day_banner_label.modulate.a = 0.0

	var tween := create_tween()
	day_banner_tween = tween
	tween.tween_property(day_banner_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.6)
	tween.tween_property(day_banner_label, "modulate:a", 0.0, 0.3)

	await tween.finished
	if day_banner_tween == tween and day_banner_label:
		day_banner_label.visible = false
		day_banner_tween = null

func hide_day_banner() -> void:
	if day_banner_tween:
		day_banner_tween.kill()
		day_banner_tween = null

	if day_banner_label:
		day_banner_label.visible = false
		day_banner_label.text = ""
		day_banner_label.modulate.a = 1.0

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

func show_barricade_prompt(text: String = "Press 3 to place Barricade") -> void:
	if barricade_prompt_label:
		barricade_prompt_label.text = text
		barricade_prompt_label.visible = true

func hide_barricade_prompt() -> void:
	if barricade_prompt_label:
		barricade_prompt_label.visible = false

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

	hide_day_banner()
	hide_phase_animation()
