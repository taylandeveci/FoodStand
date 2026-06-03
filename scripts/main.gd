extends Node2D

const MissionPanelScript = preload("res://scripts/mission_panel.gd")

const MISSION_COLLECT_TRASH := "collect_trash"
const MISSION_GO_FOOD_CART := "go_food_cart"
const FOOD_TRUCK_HEALTH_ENGINE_WORLD_OFFSET := Vector2(30.0, -118.0)

enum GameState {
	CLEANING,
	OPEN_CART,
	CUSTOMER_WALKING,
	CUSTOMER_WAITING,
	SERVING,
	CUSTOMER_LEAVING,
	SHOP,
	NIGHT,
	NIGHT_WON,
	NIGHT_FAILED
}

@export var trash_scene: PackedScene
@export var customer_scene: PackedScene
@export var enemy_scene: PackedScene
@export var tank_scene: PackedScene
@export var thief_scene: PackedScene
@export var boss_scene: PackedScene
@export var barricade_scene: PackedScene

@export var min_trash_count: int = 1
@export var max_trash_count: int = 3
@export var service_bar_speed: float = 140.0
@export var interact_hold_duration: float = 1.0

@export var night_duration: float = 60.0
@export var enemy_spawn_interval: float = 4.0
@export var max_enemies_alive: int = 5
@export var thief_spawn_chance: float = 0.20
@export var tank_spawn_chance: float = 0.20
@export var boss_spawn_side_left: bool = false

@export var customers_per_day: int = 3

# Survival item effects
@export var medkit_heal_amount: int = 3
@export var repair_kit_amount: int = 6
@export var repair_use_distance: float = 110.0
@export var barricade_place_distance: float = 120.0

var customers_served_today: int = 0
var customer_queue: Array[Node2D] = []
var queue_spacing: float = 65.0
var total_customers_today: int = 0

var money: int = 0
var local_appeal: int = 0
var game_state: int = GameState.CLEANING

var active_customer: Node2D = null
var current_order: String = ""
var timing_value: float = 0.0
var timing_direction: float = 1.0
var service_hold_time: float = 0.0
var service_hold_active: bool = false
var service_hold_locked_value: float = 0.0
var service_session_started: bool = false

# Recipe system
var current_recipe_sequence: Array = []
var player_recipe_input: Array = []
var recipe_input_active: bool = false

# Shop system
var shop_open: bool = false
var current_shop_mode: String = ""
var current_shop_section: String = "upgrade"
var shop_upgrade_bought_this_visit: Array[bool] = [false, false, false, false]

# Final night / boss
var final_night_active: bool = false
var boss_spawned_this_night: bool = false
var boss_alive: bool = false
var active_boss: Node2D = null

# Base stats
var base_food_cart_max_hp: int = 0
var base_player_attack_damage: int = 0
var base_player_recover_health: int = 0

# Recipe data
var recipes := {
	"BURGER": {
		"display_name": "Burger",
		"combo": ["A", "A"],
		"base_coin": 4,
		"base_appeal": 1
	},
	"HOTDOG": {
		"display_name": "Hotdog",
		"combo": ["A", "B"],
		"base_coin": 4,
		"base_appeal": 1
	},
	"TOAST": {
		"display_name": "Toast",
		"combo": ["B", "A"],
		"base_coin": 5,
		"base_appeal": 1
	},
	"SOUP": {
		"display_name": "Soup",
		"combo": ["B", "B"],
		"base_coin": 6,
		"base_appeal": 2
	},
	"MEATBALL": {
		"display_name": "Meatball",
		"combo": ["A", "B", "A"],
		"base_coin": 8,
		"base_appeal": 3
	}
}

var recipe_display_map := {
	"A": "J",
	"B": "K"
}

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const REWARD_SELECT_SCENE_PATH := "res://scenes/reward_select.tscn"

@onready var day_background: Sprite2D = $DayBackground
@onready var night_background: Sprite2D = $NightBackground

@onready var player = $Player
@onready var player_camera: Camera2D = get_node_or_null("Player/Camera2D") as Camera2D
@onready var hud = get_node_or_null("HUD")
@onready var trash_points: Node2D = $TrashPoints
@onready var trash_container: Node2D = $TrashContainer
@onready var food_cart = $FoodCart

@onready var customer_spawn_point: Marker2D = $CustomerSpawnPoint
@onready var customer_stop_point: Marker2D = $CustomerStopPoint
@onready var customer_exit_point: Marker2D = $CustomerExitPoint
@onready var customer_container: Node2D = $CustomerContainer

@onready var enemy_container: Node2D = $EnemyContainer
@onready var enemy_spawn_left: Marker2D = $EnemySpawnLeft
@onready var enemy_spawn_right: Marker2D = $EnemySpawnRight
@onready var night_timer: Timer = $NightTimer
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

@onready var barricade_points: Node2D = $BarricadePoints
@onready var barricade_container: Node2D = $BarricadeContainer

@onready var coin_label: Label = get_node_or_null("HUD/HUDRoot/CoinLabel") as Label
@onready var appeal_label: Label = get_node_or_null("HUD/HUDRoot/AppealLabel") as Label
@onready var trash_label: Label = get_node_or_null("HUD/HUDRoot/TrashLabel") as Label
@onready var stand_hp_label: Label = get_node_or_null("HUD/HUDRoot/StandHpLabel") as Label
@onready var health_bar: TextureProgressBar = get_node_or_null("HUD/HUDRoot/HealthBar") as TextureProgressBar
@onready var hud_root: Control = get_node_or_null("HUD/HUDRoot") as Control
@onready var status_label: Label = get_node_or_null("HUD/HUDRoot/StatusLabel") as Label
@onready var result_label: Label = get_node_or_null("HUD/HUDRoot/ResultLabel") as Label

@onready var service_panel: Panel = get_node_or_null("HUD/HUDRoot/ServicePanel") as Panel
@onready var order_label: Label = get_node_or_null("HUD/HUDRoot/ServicePanel/OrderLabel") as Label
@onready var hint_label: Label = get_node_or_null("HUD/HUDRoot/ServicePanel/HintLabel") as Label
@onready var timing_bar: ProgressBar = get_node_or_null("HUD/HUDRoot/ServicePanel/TimingBar") as ProgressBar
@onready var service_prompt: Sprite2D = get_node_or_null("HUD/HUDRoot/ServicePanel/PressEPrompt") as Sprite2D

# Shop button refs
@onready var shop_button_1: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/UpgradeList/UpgradeButton1") as Button
@onready var shop_button_2: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/UpgradeList/UpgradeButton2") as Button
@onready var shop_button_3: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/UpgradeList/UpgradeButton3") as Button
@onready var shop_button_4: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/UpgradeList/UpgradeButton4") as Button
@onready var shop_continue_button: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/ContinueButton") as Button
@onready var switch_market_button: Button = get_node_or_null("HUD/HUDRoot/ShopPanel/SwitchMarketButton") as Button

var mission_panel = null

func _ready() -> void:
	randomize()

	set_day_background()
	local_appeal = RunManager.permanent_appeal_bonus

	if food_cart:
		base_food_cart_max_hp = food_cart.max_hp
	if player:
		base_player_attack_damage = player.attack_damage
		base_player_recover_health = player.recover_health

	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

	if player and player.has_signal("down_started"):
		player.down_started.connect(_on_player_down_started)

	if player and player.has_signal("recovered"):
		player.recovered.connect(_on_player_recovered)

	if food_cart and food_cart.has_signal("interacted"):
		food_cart.interacted.connect(_on_food_cart_interacted)

	if food_cart and food_cart.has_signal("hp_changed"):
		food_cart.hp_changed.connect(_on_food_cart_hp_changed)

	if food_cart and food_cart.has_signal("destroyed"):
		food_cart.destroyed.connect(_on_food_cart_destroyed)

	if food_cart:
		sync_food_cart_health_display(food_cart.current_hp, food_cart.max_hp, false)

	night_timer.one_shot = true
	night_timer.autostart = false
	night_timer.timeout.connect(_on_night_timer_timeout)

	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.autostart = false
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)

	if shop_button_1:
		shop_button_1.pressed.connect(_on_shop_upgrade_1_pressed)
	if shop_button_2:
		shop_button_2.pressed.connect(_on_shop_upgrade_2_pressed)
	if shop_button_3:
		shop_button_3.pressed.connect(_on_shop_upgrade_3_pressed)
	if shop_button_4:
		shop_button_4.pressed.connect(_on_shop_upgrade_4_pressed)
	if shop_continue_button:
		shop_continue_button.pressed.connect(_on_shop_continue_pressed)
	if switch_market_button:
		switch_market_button.pressed.connect(_on_switch_market_pressed)

	if service_panel:
		service_panel.visible = false
	if service_prompt:
		hide_service_prompt()

	if result_label:
		result_label.text = ""

	if hud and hud.has_method("hide_shop_panel"):
		hud.hide_shop_panel()

	setup_mission_panel()

	start_morning_phase()
	update_ui()

func _process(delta: float) -> void:
	update_food_cart_interaction_enabled()
	update_phase_animation_anchor()
	update_food_truck_health_engine_anchor()

	if game_state == GameState.SERVING:
		update_service_hold(delta)
		if game_state == GameState.SERVING and not service_hold_active:
			update_service_bar(delta)
	else:
		reset_service_hold()
		hide_service_prompt()

	if game_state == GameState.CUSTOMER_WALKING:
		try_activate_front_customer()

	if recipe_input_active:
		handle_recipe_input()

	if game_state == GameState.NIGHT:
		if Input.is_action_just_pressed("use_medkit"):
			try_use_medkit()

		if Input.is_action_just_pressed("use_repair_kit"):
			try_use_repair_kit()

		if Input.is_action_just_pressed("use_barricade"):
			try_place_barricade()

		update_barricade_prompt()
	else:
		if hud and hud.has_method("hide_barricade_prompt"):
			hud.hide_barricade_prompt()

func set_day_background() -> void:
	if day_background:
		day_background.visible = true
	if night_background:
		night_background.visible = false

func set_night_background() -> void:
	if day_background:
		day_background.visible = false
	if night_background:
		night_background.visible = true

func is_final_night_today() -> bool:
	return RunManager.get_current_day() >= RunManager.DAYS_PER_DISTRICT

func get_recipe_data(recipe_name: String) -> Dictionary:
	if recipes.has(recipe_name):
		return recipes[recipe_name]
	return {
		"display_name": recipe_name,
		"combo": ["A", "A"],
		"base_coin": 1,
		"base_appeal": 0
	}

func get_recipe_combo(recipe_name: String) -> Array:
	var recipe_data: Dictionary = get_recipe_data(recipe_name)
	return recipe_data.get("combo", ["A", "A"])

func get_recipe_display_name(recipe_name: String) -> String:
	var recipe_data: Dictionary = get_recipe_data(recipe_name)
	return str(recipe_data.get("display_name", recipe_name))

func get_survival_inventory_text() -> String:
	return "Medkit %d/%d | Repair %d/%d | Barricade %d/%d | Bag Lv.%d" % [
		RunManager.get_survival_item_count("medkit"),
		RunManager.get_survival_item_max_stack("medkit"),
		RunManager.get_survival_item_count("repair_kit"),
		RunManager.get_survival_item_max_stack("repair_kit"),
		RunManager.get_survival_item_count("barricade"),
		RunManager.get_survival_item_max_stack("barricade"),
		RunManager.bag_upgrade_level
	]

func refresh_shop_inventory_text_if_needed() -> void:
	if shop_open and hud and hud.has_method("update_shop_inventory"):
		hud.update_shop_inventory(get_survival_inventory_text())

func try_use_medkit() -> void:
	if player == null:
		return

	if not RunManager.can_use_survival_item("medkit"):
		set_status("No Medkit left.")
		set_result("Buy Medkit from Survival Market.")
		return

	if player.current_health >= player.max_health:
		set_status("HP is already full.")
		set_result("Medkit not used.")
		return

	if player.has_method("heal"):
		var healed: bool = player.heal(medkit_heal_amount)
		if healed:
			RunManager.use_survival_item("medkit", 1)
			refresh_shop_inventory_text_if_needed()

			set_status("Medkit used!")
			set_result("+%d HP | Medkit left: %d" % [
				medkit_heal_amount,
				RunManager.get_survival_item_count("medkit")
			])

func try_use_repair_kit() -> void:
	if player == null or food_cart == null:
		return

	if not RunManager.can_use_survival_item("repair_kit"):
		set_status("No Repair Kit left.")
		set_result("Buy Repair Kit from Survival Market.")
		return

	if food_cart.current_hp >= food_cart.max_hp:
		set_status("Stand HP is already full.")
		set_result("Repair Kit not used.")
		return

	var dist_to_cart: float = player.global_position.distance_to(food_cart.global_position)
	if dist_to_cart > repair_use_distance:
		set_status("Go near the stand.")
		set_result("Repair Kit can only be used near the cart.")
		return

	if food_cart.has_method("repair"):
		var repaired: bool = food_cart.repair(repair_kit_amount)
		if repaired:
			RunManager.use_survival_item("repair_kit", 1)
			refresh_shop_inventory_text_if_needed()

			set_status("Repair Kit used!")
			set_result("+%d Stand HP | Repair left: %d" % [
				repair_kit_amount,
				RunManager.get_survival_item_count("repair_kit")
			])

func get_nearest_free_barricade_point() -> Marker2D:
	if player == null or barricade_points == null:
		return null

	var nearest_point: Marker2D = null
	var nearest_distance: float = barricade_place_distance

	for child in barricade_points.get_children():
		if not child is Marker2D:
			continue

		var point: Marker2D = child

		if is_barricade_point_occupied(point):
			continue

		var dist: float = player.global_position.distance_to(point.global_position)
		if dist <= nearest_distance:
			nearest_distance = dist
			nearest_point = point

	return nearest_point

func is_barricade_point_occupied(point: Marker2D) -> bool:
	for child in barricade_container.get_children():
		if child.global_position.distance_to(point.global_position) < 8.0:
			return true
	return false

func try_place_barricade() -> void:
	if barricade_scene == null:
		set_status("Barricade scene missing.")
		return

	if not RunManager.can_use_survival_item("barricade"):
		set_status("No Barricade left.")
		set_result("Buy Barricade from Survival Market.")
		return

	var point: Marker2D = get_nearest_free_barricade_point()
	if point == null:
		set_status("No free barricade point nearby.")
		set_result("Go near a barricade point.")
		return

	var barricade_instance = barricade_scene.instantiate()
	barricade_container.add_child(barricade_instance)
	barricade_instance.global_position = point.global_position

	RunManager.use_survival_item("barricade", 1)
	refresh_shop_inventory_text_if_needed()

	set_status("Barricade placed!")
	set_result("Barricade left: %d" % RunManager.get_survival_item_count("barricade"))

	update_barricade_prompt()

func update_barricade_prompt() -> void:
	if hud == null or not hud.has_method("show_barricade_prompt") or not hud.has_method("hide_barricade_prompt"):
		return

	if game_state != GameState.NIGHT:
		hud.hide_barricade_prompt()
		return

	if not RunManager.can_use_survival_item("barricade"):
		hud.hide_barricade_prompt()
		return

	var point: Marker2D = get_nearest_free_barricade_point()
	if point == null:
		hud.hide_barricade_prompt()
		return

	hud.show_barricade_prompt("Press 3 to place Barricade")

func can_switch_market() -> bool:
	return current_shop_mode == "night"

func get_switch_market_button_text() -> String:
	if current_shop_section == "upgrade":
		return "Go To Survival"
	return "Go To Upgrades"

func get_available_order_pool() -> Array:
	var unlocked_recipes: Array = RunManager.get_unlocked_recipe_names()
	var pool: Array = []
	var profile: Dictionary = RunManager.get_current_district_profile()
	var favored_recipes: Array = profile.get("favored_recipes", [])

	for recipe_name in unlocked_recipes:
		if recipes.has(recipe_name):
			pool.append(recipe_name)

			if recipe_name in favored_recipes:
				pool.append(recipe_name)
				pool.append(recipe_name)

	if pool.is_empty():
		pool = ["BURGER", "HOTDOG"]

	return pool

func apply_run_upgrades() -> void:
	if food_cart:
		var new_max_hp: int = base_food_cart_max_hp + RunManager.night_stand_hp_bonus
		food_cart.max_hp = new_max_hp
		food_cart.current_hp = new_max_hp
		food_cart.hp_changed.emit(food_cart.current_hp, food_cart.max_hp)

	if player:
		player.attack_damage = base_player_attack_damage + RunManager.night_player_damage_bonus
		player.recover_health = base_player_recover_health + RunManager.night_recover_health_bonus

func start_morning_phase() -> void:
	game_state = GameState.CLEANING

	current_order = ""
	timing_value = 0.0
	timing_direction = 1.0

	recipe_input_active = false
	player_recipe_input.clear()
	current_recipe_sequence.clear()

	customers_served_today = 0
	total_customers_today = 0
	active_customer = null

	shop_open = false
	current_shop_mode = ""
	current_shop_section = "upgrade"
	shop_upgrade_bought_this_visit = [false, false, false, false]
	service_session_started = false

	final_night_active = false
	boss_spawned_this_night = false
	boss_alive = false
	active_boss = null

	set_day_background()
	apply_run_upgrades()

	clear_old_trash()
	clear_customer()
	clear_enemies()
	clear_barricades()

	if hud and hud.has_method("hide_shop_panel"):
		hud.hide_shop_panel()

	if food_cart and food_cart.has_method("reset_hp"):
		food_cart.reset_hp()

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "")

	if hud and hud.has_method("hide_barricade_prompt"):
		hud.hide_barricade_prompt()

	night_timer.stop()
	enemy_spawn_timer.stop()

	if service_panel:
		service_panel.visible = false

	reset_mission_panel()
	add_mission(MISSION_COLLECT_TRASH)
	clear_status()
	set_result("")
	if hud and hud.has_method("show_day_banner"):
		hud.show_day_banner("District %d - Day %d" % [RunManager.current_district + 1, RunManager.get_current_day()])

	if hud and hud.has_method("show_phase_morning_prep"):
		position_phase_animation_above_food_cart()
		hud.show_phase_morning_prep()

	spawn_random_trash()
	update_ui()

func clear_old_trash() -> void:
	for child in trash_container.get_children():
		child.queue_free()

func clear_customer() -> void:
	for child in customer_container.get_children():
		child.queue_free()
	active_customer = null
	customer_queue.clear()

func clear_enemies() -> void:
	for child in enemy_container.get_children():
		child.queue_free()

	boss_alive = false
	active_boss = null

func clear_barricades() -> void:
	for child in barricade_container.get_children():
		child.queue_free()

func spawn_random_trash() -> void:
	if trash_scene == null:
		push_error("trash_scene atanmamis. Main node'unda Trash.tscn bagla.")
		return

	var points: Array[Node] = []
	for child in trash_points.get_children():
		if child is Marker2D:
			points.append(child)

	if points.is_empty():
		push_error("TrashPoints altinda hic Marker2D spawn noktasi yok.")
		return

	points.shuffle()

	var real_min: int = min(min_trash_count, points.size())
	var real_max: int = min(max_trash_count, points.size())

	if real_min > real_max:
		real_min = real_max

	var spawn_count: int = randi_range(real_min, real_max)

	for i in range(spawn_count):
		var point: Marker2D = points[i] as Marker2D
		if point == null:
			continue

		var trash_instance = trash_scene.instantiate()
		trash_container.add_child(trash_instance)
		trash_instance.global_position = point.global_position

		if trash_instance.has_signal("collected"):
			trash_instance.collected.connect(_on_trash_collected)

	update_ui()

func _on_trash_collected(money_gain: int, appeal_gain: int) -> void:
	money += money_gain
	local_appeal += appeal_gain
	_check_trash_after_removal()

func _check_trash_after_removal() -> void:
	await get_tree().process_frame
	update_ui()

	if game_state == GameState.CLEANING and trash_container.get_child_count() == 0:
		game_state = GameState.OPEN_CART
		complete_mission(MISSION_COLLECT_TRASH)
		add_mission(MISSION_GO_FOOD_CART)
		clear_status()
		set_result("")

func _on_food_cart_interacted() -> void:
	match game_state:
		GameState.OPEN_CART:
			open_cart()

		GameState.CUSTOMER_WAITING:
			if not recipe_input_active:
				if not service_session_started:
					reset_mission_panel()
				service_session_started = true
				start_recipe_input_phase()

		GameState.CLEANING:
			clear_status()
			set_result("Trash left: %d" % trash_container.get_child_count())

		_:
			pass

func open_cart() -> void:
	game_state = GameState.CUSTOMER_WALKING
	service_session_started = false
	complete_mission(MISSION_GO_FOOD_CART)
	set_status("Stand opened. Customers are coming!")
	set_result("Stand opened!")
	spawn_customer_queue()

func spawn_customer_queue() -> void:
	if customer_scene == null:
		push_error("customer_scene atanmamis.")
		return

	clear_customer()
	customers_served_today = 0

	var dir = sign(customer_spawn_point.global_position.x - customer_stop_point.global_position.x)
	if dir == 0:
		dir = 1

	var district_profile: Dictionary = RunManager.get_current_district_profile()
	var total_customers: int = customers_per_day + int(district_profile.get("customer_count_bonus", 0))
	total_customers = max(total_customers, 1)
	total_customers_today = total_customers

	for i in range(total_customers):
		var customer = customer_scene.instantiate()
		customer_container.add_child(customer)
		customer.global_position = customer_spawn_point.global_position + Vector2(i * queue_spacing * dir, 0)

		customer.max_patience += RunManager.day_patience_bonus
		customer.max_patience += float(district_profile.get("patience_bonus", 0.0))
		customer.max_patience = max(customer.max_patience, 20.0)

		if customer.has_signal("arrived"):
			customer.arrived.connect(_on_customer_arrived.bind(customer))
		if customer.has_signal("exited"):
			customer.exited.connect(_on_customer_exited.bind(customer))
		if customer.has_signal("patience_ran_out"):
			customer.patience_ran_out.connect(_on_customer_patience_ran_out.bind(customer))

		customer_queue.append(customer)

	update_queue_positions()

func update_queue_positions() -> void:
	var dir = sign(customer_spawn_point.global_position.x - customer_stop_point.global_position.x)
	if dir == 0:
		dir = 1

	for i in range(customer_queue.size()):
		var customer = customer_queue[i]
		var target_pos = customer_stop_point.global_position
		target_pos.x += i * queue_spacing * dir

		if customer.has_method("set_target"):
			customer.call("set_target", target_pos)

func activate_front_customer(customer: Node2D) -> void:
	active_customer = customer
	game_state = GameState.CUSTOMER_WAITING

	var order_pool: Array = get_available_order_pool()
	current_order = order_pool[randi() % order_pool.size()]
	current_recipe_sequence = get_recipe_combo(current_order)
	player_recipe_input.clear()
	recipe_input_active = false

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "")

	if customer.has_method("set_order_text"):
		customer.call("set_order_text", get_recipe_display_name(current_order))
	if customer.has_method("show_order"):
		customer.call("show_order")

	if service_session_started:
		start_recipe_input_phase()
	else:
		set_status("Customer ready. Hold to start cooking.")
		set_result("Order: %s" % get_recipe_display_name(current_order))


func try_activate_front_customer() -> void:
	if active_customer != null:
		return
	if customer_queue.is_empty():
		return

	var front_customer: Node2D = customer_queue[0]
	if front_customer == null or not is_instance_valid(front_customer):
		return

	var dist: float = front_customer.global_position.distance_to(customer_stop_point.global_position)
	if dist <= 12.0:
		activate_front_customer(front_customer)

func _on_customer_arrived(customer: Node2D) -> void:
	if customer_queue.size() > 0 and customer_queue[0] == customer:
		activate_front_customer(customer)
	else:
		if customer.has_method("stop_patience"):
			customer.call_deferred("stop_patience")
		if customer.has_method("hide_order"):
			customer.call_deferred("hide_order")

func advance_queue() -> void:
	if customer_queue.size() > 0:
		customer_queue.pop_front()

	customers_served_today += 1
	active_customer = null

	if customers_served_today >= total_customers_today:
		set_status("Day over. Waiting for customers to leave...")
	else:
		game_state = GameState.CUSTOMER_WALKING
		update_queue_positions()

func _on_customer_patience_ran_out(customer: Node2D) -> void:
	if customer != active_customer:
		return

	recipe_input_active = false
	player_recipe_input.clear()

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "")

	if service_panel:
		service_panel.visible = false

	set_status("Customer lost patience.")
	set_result("No coin earned.")

	game_state = GameState.CUSTOMER_LEAVING

	if customer.has_method("leave_to"):
		customer.call("leave_to", customer_exit_point.global_position, false)

	advance_queue()

func _on_customer_exited(_customer: Node2D) -> void:
	await get_tree().process_frame

	if customers_served_today >= total_customers_today and customer_container.get_child_count() == 0:
		open_shop("night")

func start_recipe_input_phase() -> void:
	recipe_input_active = true
	player_recipe_input.clear()

	var combo_parts: Array = []
	for key in current_recipe_sequence:
		combo_parts.append(recipe_display_map.get(key, str(key)))

	var combo_text = " + ".join(combo_parts)

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "Recipe: " + combo_text)

	set_status("Enter recipe for %s" % get_recipe_display_name(current_order))
	set_result("Use recipe keys.")

func handle_recipe_input() -> void:
	if Input.is_action_just_pressed("recipe_a"):
		register_recipe_input("A")

	if Input.is_action_just_pressed("recipe_b"):
		register_recipe_input("B")

func register_recipe_input(value: String) -> void:
	if not recipe_input_active:
		return

	player_recipe_input.append(value)

	var current_index: int = player_recipe_input.size() - 1

	if current_index >= current_recipe_sequence.size():
		fail_recipe_input()
		return

	if player_recipe_input[current_index] != current_recipe_sequence[current_index]:
		fail_recipe_input()
		return

	var display_parts: Array = []
	for key in player_recipe_input:
		display_parts.append(recipe_display_map.get(key, str(key)))

	set_result("Recipe Input: %s" % " + ".join(display_parts))

	if player_recipe_input.size() == current_recipe_sequence.size():
		recipe_input_active = false

		if food_cart and food_cart.has_method("set_recipe_hint"):
			food_cart.call("set_recipe_hint", "")

		complete_customer_service_from_recipe()

func fail_recipe_input() -> void:
	recipe_input_active = false
	player_recipe_input.clear()

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "")

	set_status("Wrong recipe.")
	set_result("Customer left without paying.")

	game_state = GameState.CUSTOMER_LEAVING

	if active_customer and active_customer.has_method("leave_to"):
		active_customer.call("leave_to", customer_exit_point.global_position)

	advance_queue()

func complete_customer_service_from_recipe() -> void:
	player_recipe_input.clear()

	if service_panel:
		service_panel.visible = false

	hide_service_prompt()
	reset_service_hold()

	var district_profile: Dictionary = RunManager.get_current_district_profile()
	var district_coin_bonus: int = int(district_profile.get("serve_coin_bonus", 0))

	var recipe_data: Dictionary = get_recipe_data(current_order)
	var base_coin: int = int(recipe_data.get("base_coin", 1))
	var base_appeal: int = int(recipe_data.get("base_appeal", 0))

	var coin_gain: int = base_coin + RunManager.day_coin_bonus + district_coin_bonus
	var appeal_gain: int = base_appeal

	money += coin_gain
	local_appeal += appeal_gain
	game_state = GameState.CUSTOMER_LEAVING

	if active_customer and active_customer.has_method("leave_to"):
		active_customer.call("leave_to", customer_exit_point.global_position)

	set_status("%s served. Next customer coming." % get_recipe_display_name(current_order))
	set_result("Served | +%d coin | +%d appeal" % [coin_gain, appeal_gain])

	update_ui()
	advance_queue()

func start_service_phase() -> void:
	game_state = GameState.SERVING
	timing_value = 0.0
	timing_direction = 1.0
	reset_service_hold()

	if active_customer and active_customer.has_method("stop_patience"):
		active_customer.call("stop_patience")

	if service_panel:
		service_panel.visible = true

	if order_label:
		order_label.text = "Order: %s" % get_recipe_display_name(current_order)

	if hint_label:
		hint_label.text = "Hold near the center."

	show_service_prompt_idle()

	if timing_bar:
		timing_bar.min_value = 0.0
		timing_bar.max_value = 100.0
		timing_bar.value = 0.0

	set_status("Service phase: hold at the right moment.")
	set_result("")

func update_service_bar(delta: float) -> void:
	timing_value += timing_direction * service_bar_speed * delta

	if timing_value >= 100.0:
		timing_value = 100.0
		timing_direction = -1.0
	elif timing_value <= 0.0:
		timing_value = 0.0
		timing_direction = 1.0

	if timing_bar:
		timing_bar.value = timing_value

func finish_service_phase(timing_snapshot: float = -1.0) -> void:
	if service_panel:
		service_panel.visible = false
	hide_service_prompt()

	var district_profile: Dictionary = RunManager.get_current_district_profile()
	var district_coin_bonus: int = int(district_profile.get("serve_coin_bonus", 0))

	var recipe_data: Dictionary = get_recipe_data(current_order)
	var base_coin: int = int(recipe_data.get("base_coin", 1))
	var base_appeal: int = int(recipe_data.get("base_appeal", 0))

	var perfect_min: float = clamp(45.0 - RunManager.day_timing_bonus, 0.0, 100.0)
	var perfect_max: float = clamp(55.0 + RunManager.day_timing_bonus, 0.0, 100.0)
	var nice_min: float = clamp(30.0 - RunManager.day_timing_bonus, 0.0, 100.0)
	var nice_max: float = clamp(70.0 + RunManager.day_timing_bonus, 0.0, 100.0)
	var serve_timing: float = timing_snapshot if timing_snapshot >= 0.0 else timing_value

	var result_text: String = "Bad Serve"
	var coin_gain: int = max(1, int(round(base_coin * 0.7))) + RunManager.day_coin_bonus + district_coin_bonus
	var appeal_gain: int = 0

	if serve_timing >= perfect_min and serve_timing <= perfect_max:
		result_text = "Perfect Serve"
		coin_gain = base_coin + 2 + RunManager.day_coin_bonus + district_coin_bonus
		appeal_gain = base_appeal + 1
	elif serve_timing >= nice_min and serve_timing <= nice_max:
		result_text = "Nice Serve"
		coin_gain = base_coin + RunManager.day_coin_bonus + district_coin_bonus
		appeal_gain = base_appeal

	money += coin_gain
	local_appeal += appeal_gain

	game_state = GameState.CUSTOMER_LEAVING

	if active_customer and active_customer.has_method("leave_to"):
		active_customer.call("leave_to", customer_exit_point.global_position)

	set_status("%s served. Next customer coming." % get_recipe_display_name(current_order))
	set_result("%s | +%d coin | +%d appeal" % [result_text, coin_gain, appeal_gain])

	update_ui()
	advance_queue()

func update_food_cart_interaction_enabled() -> void:
	if food_cart == null or not food_cart.has_method("set_interaction_enabled"):
		return

	var can_interact: bool = game_state == GameState.OPEN_CART or (
		game_state == GameState.CUSTOMER_WAITING
		and not service_session_started
		and not recipe_input_active
	)
	food_cart.call("set_interaction_enabled", can_interact)

func update_service_hold(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		if not service_hold_active:
			service_hold_active = true
			service_hold_locked_value = timing_value

		service_hold_time = min(service_hold_time + delta, interact_hold_duration)
		show_service_prompt_progress(service_hold_time / max(interact_hold_duration, 0.001))

		if service_hold_time >= interact_hold_duration:
			var locked_timing: float = service_hold_locked_value
			reset_service_hold()
			hide_service_prompt()
			finish_service_phase(locked_timing)
	else:
		if service_hold_active or service_hold_time > 0.0:
			reset_service_hold()
		show_service_prompt_idle()

func reset_service_hold() -> void:
	service_hold_time = 0.0
	service_hold_active = false
	service_hold_locked_value = 0.0

func show_service_prompt_idle() -> void:
	if service_prompt == null:
		return
	service_prompt.visible = true
	service_prompt.frame = 0

func show_service_prompt_progress(progress: float) -> void:
	if service_prompt == null:
		return
	var frame_count: int = max(service_prompt.hframes, 1)
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	service_prompt.visible = true
	service_prompt.frame = mini(int(clamped_progress * float(frame_count - 1)), frame_count - 1)

func hide_service_prompt() -> void:
	if service_prompt == null:
		return
	service_prompt.visible = false
	service_prompt.frame = 0

func open_shop(mode: String) -> void:
	shop_open = true
	current_shop_mode = mode
	current_shop_section = "upgrade"
	game_state = GameState.SHOP
	shop_upgrade_bought_this_visit = [false, false, false, false]
	service_session_started = false

	refresh_shop_ui()
	set_status("Choose what to buy, then continue.")
	set_result("")

func refresh_shop_ui() -> void:
	var item_texts: Array = get_shop_item_texts(current_shop_mode, current_shop_section)
	var title_text := ""
	var mode_text := ""
	var market_type_text := ""
	var inventory_text := get_survival_inventory_text()

	if current_shop_mode == "night":
		title_text = "NIGHT MARKET"
		mode_text = "Prepare for tonight"
	else:
		title_text = "DAY MARKET"
		mode_text = "Prepare for tomorrow"

	if current_shop_section == "upgrade":
		market_type_text = "UPGRADES"
	else:
		market_type_text = "SURVIVAL"

	if hud and hud.has_method("show_shop_panel"):
		hud.show_shop_panel(
			title_text,
			mode_text,
			money,
			item_texts[0],
			item_texts[1],
			item_texts[2],
			item_texts[3],
			market_type_text,
			inventory_text,
			can_switch_market()
		)

	if hud and hud.has_method("update_switch_market_button_text"):
		hud.update_switch_market_button_text(get_switch_market_button_text())

	update_shop_buttons()

func close_shop() -> void:
	shop_open = false
	current_shop_mode = ""
	current_shop_section = "upgrade"

	if hud and hud.has_method("hide_shop_panel"):
		hud.hide_shop_panel()

func get_shop_item_texts(mode: String, section: String) -> Array:
	if mode == "day":
		return [
			"Better Ingredients\n+1 Coin per Serve ($6)",
			"Customer Charm\n+20 Patience ($7)",
			"Steady Hands\n+5 Timing Zone ($7)",
			""
		]

	if mode == "night" and section == "upgrade":
		var bag_text := ""
		if RunManager.can_upgrade_bag():
			bag_text = "Bag Upgrade\nIncrease item stacks ($%d)" % RunManager.get_bag_upgrade_cost()
		else:
			bag_text = "Bag Upgrade\nMAX LEVEL"

		return [
			"Reinforced Cart\n+5 Stand HP ($7)",
			"Sharper Knife\n+1 Attack Damage ($8)",
			"Emergency Training\n+1 Recover HP ($6)",
			bag_text
		]

	if mode == "night" and section == "survival":
		return [
			"Medkit\n+1 Stack ($5)",
			"Repair Kit\n+1 Stack ($6)",
			"Barricade\n+1 Stack ($8)",
			""
		]

	return ["", "", "", ""]

func get_shop_item_cost(mode: String, section: String, index: int) -> int:
	if mode == "day":
		match index:
			0:
				return 6
			1:
				return 7
			2:
				return 7
			_:
				return 999

	if mode == "night" and section == "upgrade":
		match index:
			0:
				return 7
			1:
				return 8
			2:
				return 6
			3:
				return RunManager.get_bag_upgrade_cost()
			_:
				return 999

	if mode == "night" and section == "survival":
		match index:
			0:
				return 5
			1:
				return 6
			2:
				return 8
			_:
				return 999

	return 999

func can_buy_shop_item(mode: String, section: String, index: int) -> bool:
	if mode == "night" and section == "upgrade":
		match index:
			3:
				return RunManager.can_upgrade_bag()
			_:
				return true

	if mode == "night" and section == "survival":
		match index:
			0:
				return not RunManager.is_survival_item_full("medkit")
			1:
				return not RunManager.is_survival_item_full("repair_kit")
			2:
				return not RunManager.is_survival_item_full("barricade")
			_:
				return false

	return true

func apply_shop_item(mode: String, section: String, index: int) -> void:
	if mode == "day":
		match index:
			0:
				RunManager.day_coin_bonus += 1
			1:
				RunManager.day_patience_bonus += 20.0
			2:
				RunManager.day_timing_bonus += 5.0
		return

	if mode == "night" and section == "upgrade":
		match index:
			0:
				RunManager.night_stand_hp_bonus += 5
				apply_run_upgrades()
			1:
				RunManager.night_player_damage_bonus += 1
			2:
				RunManager.night_recover_health_bonus += 1
			3:
				RunManager.upgrade_bag()
		return

	if mode == "night" and section == "survival":
		match index:
			0:
				RunManager.add_survival_item("medkit", 1)
			1:
				RunManager.add_survival_item("repair_kit", 1)
			2:
				RunManager.add_survival_item("barricade", 1)

func get_shop_item_name(mode: String, section: String, index: int) -> String:
	if mode == "day":
		match index:
			0:
				return "Better Ingredients"
			1:
				return "Customer Charm"
			2:
				return "Steady Hands"
			_:
				return "Unknown"

	if mode == "night" and section == "upgrade":
		match index:
			0:
				return "Reinforced Cart"
			1:
				return "Sharper Knife"
			2:
				return "Emergency Training"
			3:
				return "Bag Upgrade"
			_:
				return "Unknown"

	if mode == "night" and section == "survival":
		match index:
			0:
				return "Medkit"
			1:
				return "Repair Kit"
			2:
				return "Barricade"
			_:
				return "Unknown"

	return "Unknown"

func update_shop_buttons() -> void:
	if hud and hud.has_method("update_shop_money"):
		hud.update_shop_money(money)

	if hud and hud.has_method("update_shop_inventory"):
		hud.update_shop_inventory(get_survival_inventory_text())

	for i in range(4):
		var button: Button = null
		match i:
			0:
				button = shop_button_1
			1:
				button = shop_button_2
			2:
				button = shop_button_3
			3:
				button = shop_button_4

		if button == null or not button.visible:
			continue

		var cost := get_shop_item_cost(current_shop_mode, current_shop_section, i)
		var can_buy := can_buy_shop_item(current_shop_mode, current_shop_section, i)

		if current_shop_section == "upgrade":
			button.disabled = shop_upgrade_bought_this_visit[i] or money < cost or not can_buy
		else:
			button.disabled = money < cost or not can_buy

	if shop_continue_button:
		shop_continue_button.disabled = false

func buy_shop_item(index: int) -> void:
	if not shop_open:
		return

	var cost := get_shop_item_cost(current_shop_mode, current_shop_section, index)
	if money < cost:
		set_result("Not enough money.")
		return

	if current_shop_section == "upgrade":
		if shop_upgrade_bought_this_visit[index]:
			return

	if not can_buy_shop_item(current_shop_mode, current_shop_section, index):
		set_result("Cannot buy this item right now.")
		return

	money -= cost
	apply_shop_item(current_shop_mode, current_shop_section, index)

	if current_shop_section == "upgrade":
		shop_upgrade_bought_this_visit[index] = true

	refresh_shop_ui()
	update_ui()

	set_result("Purchased: %s" % get_shop_item_name(current_shop_mode, current_shop_section, index))

func continue_after_shop() -> void:
	var mode := current_shop_mode
	close_shop()

	if mode == "night":
		start_night_phase()
	else:
		start_morning_phase()

func _on_shop_upgrade_1_pressed() -> void:
	buy_shop_item(0)

func _on_shop_upgrade_2_pressed() -> void:
	buy_shop_item(1)

func _on_shop_upgrade_3_pressed() -> void:
	buy_shop_item(2)

func _on_shop_upgrade_4_pressed() -> void:
	buy_shop_item(3)

func _on_switch_market_pressed() -> void:
	if not can_switch_market():
		return

	if current_shop_section == "upgrade":
		current_shop_section = "survival"
	else:
		current_shop_section = "upgrade"

	refresh_shop_ui()

func _on_shop_continue_pressed() -> void:
	continue_after_shop()

func start_night_phase() -> void:
	game_state = GameState.NIGHT
	clear_enemies()

	set_night_background()
	apply_run_upgrades()

	final_night_active = is_final_night_today()
	boss_spawned_this_night = false
	boss_alive = false
	active_boss = null

	night_timer.stop()
	enemy_spawn_timer.stop()

	night_timer.wait_time = night_duration
	enemy_spawn_timer.wait_time = enemy_spawn_interval

	night_timer.start()
	enemy_spawn_timer.start()

	clear_status()
	if final_night_active:
		set_result("Day 7 Boss Night")
	else:
		set_result("Survive until dawn.")

	if hud and hud.has_method("show_phase_night_started"):
		position_phase_animation_above_food_cart()
		hud.show_phase_night_started()

func update_phase_animation_anchor() -> void:
	if hud == null or not hud.has_method("is_phase_animation_visible"):
		return

	if not bool(hud.call("is_phase_animation_visible")):
		return

	position_phase_animation_above_food_cart()

func position_phase_animation_above_food_cart() -> void:
	if hud == null or not hud.has_method("set_phase_animation_position"):
		return

	hud.call("set_phase_animation_position", get_food_cart_phase_animation_screen_position())

func get_food_cart_phase_animation_screen_position() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var fallback_position := Vector2(viewport_size.x * 0.5, 92.0)
	if food_cart == null or player_camera == null:
		return fallback_position

	var anchor_node: Node2D = food_cart.get_node_or_null("InteractPrompt") as Node2D
	var anchor_world_x: float = food_cart.global_position.x + 30.0
	if anchor_node:
		anchor_world_x = anchor_node.global_position.x

	var screen_x: float = viewport_size.x * 0.5 + (anchor_world_x - player_camera.global_position.x)
	return Vector2(screen_x, 92.0)

func update_food_truck_health_engine_anchor() -> void:
	if hud == null:
		return

	if not hud.has_method("show_food_truck_health_engine") or not hud.has_method("hide_food_truck_health_engine") or not hud.has_method("set_food_truck_health_engine_position"):
		return

	if game_state != GameState.NIGHT:
		hud.call("hide_food_truck_health_engine")
		return

	hud.call("show_food_truck_health_engine")
	hud.call("set_food_truck_health_engine_position", get_food_truck_health_engine_screen_position())

func get_food_truck_health_engine_screen_position() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var fallback_position := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
	if food_cart == null or player_camera == null:
		return fallback_position

	var anchor_world_position: Vector2 = food_cart.global_position + FOOD_TRUCK_HEALTH_ENGINE_WORLD_OFFSET
	player_camera.force_update_scroll()
	var camera_zoom := player_camera.zoom
	var zoom_x: float = max(camera_zoom.x, 0.001)
	var zoom_y: float = max(camera_zoom.y, 0.001)
	var screen_center_world: Vector2 = player_camera.get_screen_center_position()
	var screen_offset := Vector2(
		(anchor_world_position.x - screen_center_world.x) / zoom_x,
		(anchor_world_position.y - screen_center_world.y) / zoom_y
	)
	return (viewport_size * 0.5) + screen_offset

func _on_enemy_spawn_timer_timeout() -> void:
	if game_state != GameState.NIGHT:
		return

	if enemy_container.get_child_count() >= max_enemies_alive:
		return

	var enemy_instance = null
	var roll: float = randf()

	if thief_scene != null and roll < thief_spawn_chance:
		enemy_instance = thief_scene.instantiate()
	elif tank_scene != null and roll < thief_spawn_chance + tank_spawn_chance:
		enemy_instance = tank_scene.instantiate()
	else:
		if enemy_scene == null:
			push_error("enemy_scene atanmamis.")
			return
		enemy_instance = enemy_scene.instantiate()

	enemy_container.add_child(enemy_instance)

	var spawned_left: bool = randi() % 2 == 0

	if spawned_left:
		enemy_instance.global_position = enemy_spawn_left.global_position
	else:
		enemy_instance.global_position = enemy_spawn_right.global_position

	enemy_instance.stand_ref = food_cart
	enemy_instance.player_ref = player

	if enemy_instance.has_signal("died"):
		enemy_instance.died.connect(_on_enemy_died.bind(enemy_instance))

	if enemy_instance.has_signal("escaped_with_money"):
		enemy_instance.escaped_with_money.connect(_on_thief_escaped_with_money)

func spawn_boss_enemy() -> void:
	if boss_scene == null:
		push_error("boss_scene atanmamis.")
		return

	if boss_alive:
		return

	var boss_instance = boss_scene.instantiate()
	enemy_container.add_child(boss_instance)

	if boss_spawn_side_left:
		boss_instance.global_position = enemy_spawn_left.global_position
	else:
		boss_instance.global_position = enemy_spawn_right.global_position

	boss_instance.stand_ref = food_cart
	boss_instance.player_ref = player

	if boss_instance.has_signal("died"):
		boss_instance.died.connect(_on_boss_died)
		boss_instance.died.connect(_on_enemy_died.bind(boss_instance))

	active_boss = boss_instance
	boss_alive = true
	boss_spawned_this_night = true

	set_status("Boss arrived!")
	set_result("Defeat the Boss to survive the final night.")

func _on_thief_escaped_with_money(amount: int) -> void:
	var stolen_amount: int = min(amount, money)
	money -= stolen_amount
	update_ui()

	set_status("A thief escaped!")
	set_result("Thief stole %d coin!" % stolen_amount)

func _on_night_timer_timeout() -> void:
	if game_state != GameState.NIGHT:
		return

	if food_cart and food_cart.current_hp <= 0:
		return

	enemy_spawn_timer.stop()

	if final_night_active and not boss_spawned_this_night:
		clear_enemies()
		spawn_boss_enemy()
		return

	if boss_alive:
		return

	clear_enemies()
	game_state = GameState.NIGHT_WON

	set_status("Night survived!")
	set_result("You protected the stand.")

	if hud and hud.has_method("show_phase_night_survived"):
		hud.show_phase_night_survived()

	var run_result := RunManager.register_night_won()

	match run_result:
		"next_day":
			await get_tree().create_timer(1.5).timeout
			open_shop("day")

		"district_complete":
			RunManager.prepare_current_district_reward_selection()
			set_status("%s completed!" % RunManager.get_current_district_name())
			set_result("Choose 1 district reward.")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file(REWARD_SELECT_SCENE_PATH)

		"all_complete":
			RunManager.prepare_current_district_reward_selection()
			set_status("Final district completed!")
			set_result("Choose your final reward.")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file(REWARD_SELECT_SCENE_PATH)

func _on_boss_died() -> void:
	boss_alive = false
	active_boss = null

	if game_state != GameState.NIGHT:
		return

	clear_enemies()
	game_state = GameState.NIGHT_WON

	set_status("Boss defeated! Night survived!")
	set_result("You defeated the Boss.")

	if hud and hud.has_method("show_phase_night_survived"):
		hud.show_phase_night_survived()

	var run_result := RunManager.register_night_won()

	match run_result:
		"next_day":
			await get_tree().create_timer(1.5).timeout
			open_shop("day")

		"district_complete":
			RunManager.prepare_current_district_reward_selection()
			set_status("%s completed!" % RunManager.get_current_district_name())
			set_result("Choose 1 district reward.")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file(REWARD_SELECT_SCENE_PATH)

		"all_complete":
			RunManager.prepare_current_district_reward_selection()
			set_status("Final district completed!")
			set_result("Choose your final reward.")
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file(REWARD_SELECT_SCENE_PATH)

func _on_food_cart_destroyed() -> void:
	if game_state != GameState.NIGHT:
		return

	night_timer.stop()
	enemy_spawn_timer.stop()
	clear_enemies()
	clear_barricades()
	game_state = GameState.NIGHT_FAILED

	set_status("Stand destroyed!")
	set_result("Run reset. Returning to main menu.")

	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()

	RunManager.reset_run()

	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _on_player_down_started() -> void:
	if game_state == GameState.NIGHT:
		set_status("You are down! Enemies are attacking the stand.")

		if hud and hud.has_method("show_player_down"):
			hud.show_player_down()

func _on_player_recovered() -> void:
	if game_state == GameState.NIGHT:
		set_status("You recovered. Defend the stand!")

func _on_food_cart_hp_changed(current_hp: int, max_hp: int) -> void:
	sync_food_cart_health_display(current_hp, max_hp)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func set_status(text_value: String) -> void:
	if status_label:
		status_label.text = text_value

func clear_status() -> void:
	set_status("")

func add_money(amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	update_ui()

func lose_money(amount: int) -> void:
	if amount <= 0:
		return

	var lost: int = min(amount, money)
	money -= lost
	update_ui()

	set_status("A thief stole your money!")
	set_result("-%d coin" % lost)

func _on_enemy_died(enemy: Node2D) -> void:
	if enemy == null:
		return

	var reward: int = 0
	var recovered: int = 0

	if enemy.has_method("get_kill_reward"):
		reward += int(enemy.call("get_kill_reward"))

	if enemy.has_method("did_steal_money") and bool(enemy.call("did_steal_money")):
		if enemy.has_method("get_stolen_amount"):
			recovered = int(enemy.call("get_stolen_amount"))
			reward += recovered

	if reward > 0:
		add_money(reward)

		if recovered > 0:
			set_status("Thief defeated!")
			set_result("+%d coin (%d recovered)" % [reward, recovered])
		else:
			set_result("+%d coin" % reward)

func set_result(text_value: String) -> void:
	if result_label:
		result_label.text = text_value

func setup_mission_panel() -> void:
	if hud_root == null:
		return

	if mission_panel == null:
		mission_panel = MissionPanelScript.new()
		hud_root.add_child(mission_panel)

func reset_mission_panel() -> void:
	if mission_panel and mission_panel.has_method("reset_missions"):
		mission_panel.call("reset_missions")

func add_mission(mission_id: String) -> void:
	if mission_panel and mission_panel.has_method("add_mission"):
		mission_panel.call("add_mission", mission_id)

func complete_mission(mission_id: String) -> void:
	if mission_panel and mission_panel.has_method("complete_mission"):
		mission_panel.call("complete_mission", mission_id)

func update_ui() -> void:
	if coin_label:
		coin_label.text = "%d" % money

	if appeal_label:
		appeal_label.text = "%d" % local_appeal

	if trash_label:
		trash_label.text = "%d" % trash_container.get_child_count()

	if food_cart:
		sync_food_cart_health_display(food_cart.current_hp, food_cart.max_hp, false)

	if health_bar and player:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health

	if hud and hud.has_method("update_survival_inventory"):
		hud.update_survival_inventory(
			RunManager.get_survival_item_count("medkit"),
			RunManager.get_survival_item_count("repair_kit"),
			RunManager.get_survival_item_count("barricade")
		)

func sync_food_cart_health_display(current_hp: int, max_hp: int, emit_warning: bool = true) -> void:
	if hud and hud.has_method("update_stand_hp"):
		hud.update_stand_hp(current_hp, max_hp, emit_warning)
		return

	if stand_hp_label:
		stand_hp_label.text = ""
