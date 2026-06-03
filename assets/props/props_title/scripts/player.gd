extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal down_started
signal recovered

@export var speed: float = 220.0
@export var jump_velocity: float = -350.0
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var punch_damage: int = 2
@export var down_duration: float = 5.0
@export var recover_health: int = 3
@export var hurt_duration: float = 0.25

# Combo / saldırı süreleri
@export var jab_duration: float = 0.25
@export var punch_duration: float = 0.35
@export var combo_window_duration: float = 0.30

# Kamera sınırları
@export var camera_min_x: float = 0.0
@export var camera_max_x: float = 3000.0
@export var camera_min_y: float = 0.0
@export var camera_max_y: float = 720.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing: int = 1
var is_attacking: bool = false
var is_down: bool = false
var is_hurt: bool = false
var current_health: int = 0

var current_attack: String = ""
var combo_window_open: bool = false
var punch_queued: bool = false
var attack_requested: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var down_timer: Timer = $DownTimer
@onready var hurt_timer: Timer = $HurtTimer
@onready var combo_timer: Timer = $ComboTimer
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	attack_shape.disabled = true

	attack_timer.one_shot = true
	attack_timer.autostart = false
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	down_timer.one_shot = true
	down_timer.autostart = false
	down_timer.wait_time = down_duration
	down_timer.timeout.connect(_on_down_timer_timeout)

	hurt_timer.one_shot = true
	hurt_timer.autostart = false
	hurt_timer.wait_time = hurt_duration
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)

	combo_timer.one_shot = true
	combo_timer.autostart = false
	combo_timer.wait_time = combo_window_duration
	combo_timer.timeout.connect(_on_combo_timer_timeout)

	# Kamera ayarı
	camera.enabled = true
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.offset = Vector2.ZERO

	health_changed.emit(current_health, max_health)

func _process(_delta: float) -> void:
	update_camera_position()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack_requested = true
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			attack_requested = true

func update_camera_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_size: Vector2 = viewport_size * 0.5

	var target_x: float = clamp(global_position.x, camera_min_x + half_size.x, camera_max_x - half_size.x)
	var target_y: float = clamp(global_position.y, camera_min_y + half_size.y, camera_max_y - half_size.y)

	camera.global_position = Vector2(target_x, target_y)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_down:
		velocity.x = 0.0
		move_and_slide()
		play_down()
		return

	if is_hurt:
		velocity.x = 0.0
		move_and_slide()
		play_hurt()
		return

	var direction: float = Input.get_axis("move_left", "move_right")

	if not is_attacking:
		velocity.x = direction * speed
	else:
		velocity.x = 0.0

	if direction < 0.0:
		facing = -1
		sprite.flip_h = true
	elif direction > 0.0:
		facing = 1
		sprite.flip_h = false

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	if attack_requested:
		attack_requested = false
		handle_attack_input()

	move_and_slide()
	update_animation(direction)

func handle_attack_input() -> void:
	if is_down or is_hurt:
		return
	
	if current_attack == "jab" and combo_window_open:
		punch_queued = true
		combo_window_open = false
		combo_timer.stop()
		return
	
	if not is_attacking and combo_window_open and current_attack == "":
		combo_window_open = false
		combo_timer.stop()
		start_punch()
		return

	if not is_attacking:
		start_attack()

func start_attack() -> void:
	if is_down or is_hurt:
		return

	is_attacking = true
	current_attack = "jab"
	punch_queued = false
	combo_window_open = true

	attack_area.position.x = 20.0 * facing
	attack_shape.disabled = false

	combo_timer.start(combo_window_duration)

	if sprite.sprite_frames.has_animation("jab"):
		sprite.play("jab")

	hit_nearest_enemy(attack_damage)
	attack_timer.start(jab_duration)

func start_punch() -> void:
	if is_down or is_hurt:
		end_attack()
		return

	is_attacking = true
	current_attack = "punch"
	punch_queued = false
	combo_window_open = false
	combo_timer.stop()

	attack_area.position.x = 26.0 * facing
	attack_shape.disabled = false

	if sprite.sprite_frames.has_animation("punch"):
		sprite.play("punch")

	hit_nearest_enemy(punch_damage)
	attack_timer.start(punch_duration)

func end_attack() -> void:
	is_attacking = false
	current_attack = ""
	punch_queued = false
	combo_window_open = false
	attack_shape.disabled = true
	combo_timer.stop()

func hit_nearest_enemy(damage: int) -> void:
	var bodies: Array[Node2D] = attack_area.get_overlapping_bodies()
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF

	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			var dist: float = global_position.distance_to(body.global_position)
			if dist < nearest_distance:
				nearest_distance = dist
				nearest_enemy = body

	if nearest_enemy != null:
		nearest_enemy.take_damage(damage)

func _on_attack_timer_timeout() -> void:
	attack_shape.disabled = true
	
	if current_attack == "jab" and punch_queued:
		start_punch()
		return

	if current_attack == "jab" and combo_window_open:
		is_attacking = false
		current_attack = ""
		return
	
	end_attack()

func _on_combo_timer_timeout() -> void:
	combo_window_open = false

func take_damage(amount: int) -> void:
	if is_down:
		return

	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		enter_down_state()
		return

	enter_hurt_state()

func enter_hurt_state() -> void:
	if is_down:
		return

	is_hurt = true
	end_attack()
	velocity.x = 0.0
	play_hurt()
	hurt_timer.start()

func _on_hurt_timer_timeout() -> void:
	is_hurt = false

func enter_down_state() -> void:
	is_down = true
	is_hurt = false
	end_attack()
	velocity = Vector2.ZERO
	down_started.emit()
	play_down()
	down_timer.start()

func _on_down_timer_timeout() -> void:
	is_down = false
	current_health = min(recover_health, max_health)
	health_changed.emit(current_health, max_health)
	recovered.emit()

func can_be_targeted() -> bool:
	return not is_down

func update_animation(direction: float) -> void:
	if is_down:
		play_down()
		return

	if is_hurt:
		play_hurt()
		return

	if is_attacking:
		return

	if not is_on_floor():
		if sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")
	elif direction != 0.0 and sprite.sprite_frames.has_animation("run"):
		sprite.play("run")
	else:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func play_hurt() -> void:
	if sprite.sprite_frames.has_animation("hurt") and sprite.animation != "hurt":
		sprite.play("hurt")

func play_down() -> void:
	if sprite.sprite_frames.has_animation("down") and sprite.animation != "down":
		sprite.play("down")
	elif sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")
