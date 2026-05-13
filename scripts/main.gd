extends Node2D

enum GameState {
	CLEANING,
	OPEN_CART,
	CUSTOMER_WALKING,
	CUSTOMER_WAITING,
	SERVING,
	CUSTOMER_LEAVING,
	NIGHT,
	NIGHT_WON,
	NIGHT_FAILED
}

@export var trash_scene: PackedScene
@export var customer_scene: PackedScene
@export var enemy_scene: PackedScene
@export var tank_scene: PackedScene

@export var min_trash_count: int = 1
@export var max_trash_count: int = 3
@export var service_bar_speed: float = 140.0

@export var night_duration: float = 60.0
@export var enemy_spawn_interval: float = 4.0
@export var max_enemies_alive: int = 5

@export var customers_per_day: int = 3
var customers_served_today: int = 0
var customer_queue: Array[Node2D] = []
var queue_spacing: float = 65.0

var money: int = 0
var local_appeal: int = 0
var game_state: int = GameState.CLEANING

var active_customer: Node2D = null
var current_order: String = ""
var timing_value: float = 0.0
var timing_direction: float = 1.0

# Recipe system
var current_recipe_sequence: Array = []
var player_recipe_input: Array = []
var recipe_input_active: bool = false

var recipes := {
	"BURGER": ["A", "A"],
	"HOTDOG": ["A", "B"]
}

@onready var player = $Player
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

@onready var coin_label: Label = get_node_or_null("HUD/HUDRoot/CoinLabel") as Label
@onready var appeal_label: Label = get_node_or_null("HUD/HUDRoot/AppealLabel") as Label
@onready var trash_label: Label = get_node_or_null("HUD/HUDRoot/TrashLabel") as Label
@onready var stand_hp_label: Label = get_node_or_null("HUD/HUDRoot/StandHpLabel") as Label
@onready var health_bar: TextureProgressBar = get_node_or_null("HUD/HUDRoot/HealthBar") as TextureProgressBar
@onready var status_label: Label = get_node_or_null("HUD/HUDRoot/StatusLabel") as Label
@onready var result_label: Label = get_node_or_null("HUD/HUDRoot/ResultLabel") as Label

@onready var service_panel: Panel = get_node_or_null("HUD/HUDRoot/ServicePanel") as Panel
@onready var order_label: Label = get_node_or_null("HUD/HUDRoot/ServicePanel/OrderLabel") as Label
@onready var hint_label: Label = get_node_or_null("HUD/HUDRoot/ServicePanel/HintLabel") as Label
@onready var timing_bar: ProgressBar = get_node_or_null("HUD/HUDRoot/ServicePanel/TimingBar") as ProgressBar

func _ready() -> void:
	randomize()

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

	night_timer.one_shot = true
	night_timer.autostart = false
	night_timer.timeout.connect(_on_night_timer_timeout)

	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.autostart = false
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)

	if service_panel:
		service_panel.visible = false

	if result_label:
		result_label.text = ""

	start_morning_phase()
	update_ui()

func _process(delta: float) -> void:
	if game_state == GameState.SERVING:
		update_service_bar(delta)

		if Input.is_action_just_pressed("interact"):
			finish_service_phase()

	if recipe_input_active:
		handle_recipe_input()

func start_morning_phase() -> void:
	game_state = GameState.CLEANING
	current_order = ""
	timing_value = 0.0
	timing_direction = 1.0
	recipe_input_active = false
	player_recipe_input.clear()
	current_recipe_sequence.clear()
	customers_served_today = 0

	clear_old_trash()
	clear_customer()
	clear_enemies()

	if food_cart and food_cart.has_method("reset_hp"):
		food_cart.reset_hp()

	night_timer.stop()
	enemy_spawn_timer.stop()

	if service_panel:
		service_panel.visible = false

	set_status("Morning Prep: collect the trash.")
	set_result("")

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

func spawn_random_trash() -> void:
	if trash_scene == null:
		push_error("trash_scene atanmamis. Main node'unda Trash.tscn bagla.")
		return

	var points: Array = trash_points.get_children()

	if points.is_empty():
		push_error("TrashPoints altinda hic spawn noktasi yok.")
		return

	points.shuffle()

	var real_min: int = min(min_trash_count, points.size())
	var real_max: int = min(max_trash_count, points.size())

	if real_min > real_max:
		real_min = real_max

	var spawn_count: int = randi_range(real_min, real_max)

	for i in range(spawn_count):
		var point = points[i]
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
		set_status("All trash collected. Go to the food cart and press E.")
		set_result("Area cleaned!")

func _on_food_cart_interacted() -> void:
	match game_state:
		GameState.OPEN_CART:
			open_cart()

		GameState.CUSTOMER_WAITING:
			if not recipe_input_active:
				start_recipe_input_phase()

		GameState.CLEANING:
			set_status("Collect all trash first.")
			set_result("Trash left: %d" % trash_container.get_child_count())

		_:
			pass

func open_cart() -> void:
	game_state = GameState.CUSTOMER_WALKING
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

	for i in range(customers_per_day):
		var customer = customer_scene.instantiate()
		customer_container.add_child(customer)
		customer.global_position = customer_spawn_point.global_position + Vector2(i * queue_spacing * dir, 0)

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

func _on_customer_arrived(customer: Node2D) -> void:
	if customer_queue.size() > 0 and customer_queue[0] == customer:
		active_customer = customer
		game_state = GameState.CUSTOMER_WAITING

		var order_keys: Array = recipes.keys()
		current_order = order_keys[randi() % order_keys.size()]
		current_recipe_sequence = recipes[current_order]
		player_recipe_input.clear()
		recipe_input_active = false

		if customer.has_method("set_order_text"):
			customer.call("set_order_text", current_order)
		if customer.has_method("show_order"):
			customer.call("show_order")

		set_status("Customer ready. Press E to start cooking.")
		set_result("Order: %s" % current_order)
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

	if customers_served_today >= customers_per_day:
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
		customer.call("leave_to", customer_exit_point.global_position)

	advance_queue()

func _on_customer_exited(_customer: Node2D) -> void:
	await get_tree().process_frame

	if customers_served_today >= customers_per_day and customer_container.get_child_count() == 0:
		set_status("Day over. Get ready for the night!")
		await get_tree().create_timer(1.0).timeout
		start_night_phase()

func start_recipe_input_phase() -> void:
	recipe_input_active = true
	player_recipe_input.clear()

	var combo_text = " + ".join(current_recipe_sequence)

	if food_cart and food_cart.has_method("set_recipe_hint"):
		food_cart.call("set_recipe_hint", "Recipe: " + combo_text)

	set_status("Enter recipe for %s" % current_order)
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

	set_result("Recipe Input: %s" % str(player_recipe_input))

	if player_recipe_input.size() == current_recipe_sequence.size():
		recipe_input_active = false

		if food_cart and food_cart.has_method("set_recipe_hint"):
			food_cart.call("set_recipe_hint", "")

		set_status("Correct recipe! Now serve it.")
		start_service_phase()

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

func start_service_phase() -> void:
	game_state = GameState.SERVING
	timing_value = 0.0
	timing_direction = 1.0

	if active_customer and active_customer.has_method("stop_patience"):
		active_customer.call("stop_patience")

	if service_panel:
		service_panel.visible = true

	if order_label:
		order_label.text = "Order: %s" % current_order

	if hint_label:
		hint_label.text = "Press E near the center."

	if timing_bar:
		timing_bar.min_value = 0.0
		timing_bar.max_value = 100.0
		timing_bar.value = 0.0

	set_status("Service phase: press E at the right moment.")
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

func finish_service_phase() -> void:
	if service_panel:
		service_panel.visible = false

	var result_text: String = "Bad Serve"
	var coin_gain: int = 1
	var appeal_gain: int = 0

	if timing_value >= 45.0 and timing_value <= 55.0:
		result_text = "Perfect Serve"
		coin_gain = 5
		appeal_gain = 2
	elif timing_value >= 30.0 and timing_value <= 70.0:
		result_text = "Nice Serve"
		coin_gain = 3
		appeal_gain = 1

	money += coin_gain
	local_appeal += appeal_gain

	game_state = GameState.CUSTOMER_LEAVING

	if active_customer and active_customer.has_method("leave_to"):
		active_customer.call("leave_to", customer_exit_point.global_position)

	set_status("Customer is leaving. Next one coming.")
	set_result("%s | +%d coin" % [result_text, coin_gain])

	update_ui()
	advance_queue()

func start_night_phase() -> void:
	game_state = GameState.NIGHT
	clear_enemies()

	night_timer.stop()
	enemy_spawn_timer.stop()

	night_timer.wait_time = night_duration
	enemy_spawn_timer.wait_time = enemy_spawn_interval

	night_timer.start()
	enemy_spawn_timer.start()

	set_status("Night started! Protect the stand.")
	set_result("Survive until dawn.")

func _on_enemy_spawn_timer_timeout() -> void:
	if game_state != GameState.NIGHT:
		return

	if enemy_container.get_child_count() >= max_enemies_alive:
		return

	var enemy_instance = null
	
	# YENİ MANTIK: Eğer tank sahnesi atanmışsa ve atılan zar %20'den küçükse TANK doğur
	if tank_scene != null and randf() < 0.2:
		enemy_instance = tank_scene.instantiate()
		print("DİKKAT: TANK SPAWN OLDU!")
	else:
		# Değilse normal düşman doğur
		if enemy_scene == null:
			push_error("enemy_scene atanmamis.")
			return
		enemy_instance = enemy_scene.instantiate()

	enemy_container.add_child(enemy_instance)

	if randi() % 2 == 0:
		enemy_instance.global_position = enemy_spawn_left.global_position
	else:
		enemy_instance.global_position = enemy_spawn_right.global_position

	enemy_instance.stand_ref = food_cart
	enemy_instance.player_ref = player


func _on_night_timer_timeout() -> void:
	if game_state != GameState.NIGHT:
		return

	if food_cart and food_cart.current_hp <= 0:
		return

	enemy_spawn_timer.stop()
	clear_enemies()
	game_state = GameState.NIGHT_WON

	set_status("Night survived!")
	set_result("You protected the stand.")

	await get_tree().create_timer(2.0).timeout
	start_morning_phase()

func _on_food_cart_destroyed() -> void:
	if game_state != GameState.NIGHT:
		return

	night_timer.stop()
	enemy_spawn_timer.stop()
	clear_enemies()
	game_state = GameState.NIGHT_FAILED

	set_status("Stand destroyed!")
	set_result("Game Over")

func _on_player_down_started() -> void:
	if game_state == GameState.NIGHT:
		set_status("You are down! Enemies are attacking the stand.")

func _on_player_recovered() -> void:
	if game_state == GameState.NIGHT:
		set_status("You recovered. Defend the stand!")

func _on_food_cart_hp_changed(current_hp: int, max_hp: int) -> void:
	if stand_hp_label:
		stand_hp_label.text = "Stand HP: %d / %d" % [current_hp, max_hp]

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func set_status(text_value: String) -> void:
	if status_label:
		status_label.text = text_value

func set_result(text_value: String) -> void:
	if result_label:
		result_label.text = text_value

func update_ui() -> void:
	if coin_label:
		coin_label.text = "%d" % money

	if appeal_label:
		appeal_label.text = "Appeal: %d" % local_appeal

	if trash_label:
		trash_label.text = "Trash Left: %d" % trash_container.get_child_count()

	if stand_hp_label and food_cart:
		stand_hp_label.text = "Stand HP: %d / %d" % [food_cart.current_hp, food_cart.max_hp]

	if health_bar and player:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
