extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal down_started
signal recovered
signal dash_used(cooldown: float)
signal skill_used(cooldown: float)

@export var speed: float = 200.0
@export var jump_velocity: float = -350.0
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var down_duration: float = 5.0
@export var recover_health: int = 3
@export var hurt_duration: float = 0.25

# Dash
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 2.0
@export var dash_invulnerable: bool = true

# Skill 1 - Hot Water Splash
@export var skill_1_damage: int = 2
@export var skill_1_range: float = 120.0
@export var skill_1_cooldown: float = 5.0

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
var is_dashing: bool = false
var current_health: int = 0

var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var skill_1_cooldown_left: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var down_timer: Timer = $DownTimer
@onready var hurt_timer: Timer = $HurtTimer
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

	camera.enabled = true
	camera.top_level = true
	camera.position_smoothing_enabled = false
	camera.offset = Vector2.ZERO

	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	update_camera_position()
	update_cooldowns(delta)
	update_dash_state(delta)

func update_camera_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_size: Vector2 = viewport_size * 0.5

	var target_x: float = clamp(global_position.x, camera_min_x + half_size.x, camera_max_x - half_size.x)
	var target_y: float = clamp(global_position.y, camera_min_y + half_size.y, camera_max_y - half_size.y)

	camera.global_position = Vector2(target_x, target_y)

func update_cooldowns(delta: float) -> void:
	if dash_cooldown_left > 0.0:
		dash_cooldown_left = max(dash_cooldown_left - delta, 0.0)

	if skill_1_cooldown_left > 0.0:
		skill_1_cooldown_left = max(skill_1_cooldown_left - delta, 0.0)

func update_dash_state(delta: float) -> void:
	if not is_dashing:
		return

	dash_time_left -= delta
	if dash_time_left <= 0.0:
		is_dashing = false
		velocity.x = 0.0
		modulate.a = 1.0

func _physics_process(delta: float) -> void:
	if not is_on_floor() and not is_dashing:
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

	if is_dashing:
		move_and_slide()
		play_dash()
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

	if Input.is_action_just_pressed("dash"):
		try_dash(direction)

	if Input.is_action_just_pressed("skill_1"):
		use_skill_1()

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	move_and_slide()
	update_animation(direction)

func try_dash(direction: float) -> void:
	if is_down or is_hurt or is_attacking or is_dashing:
		return

	if dash_cooldown_left > 0.0:
		return

	var dash_direction: int = facing
	if direction < 0.0:
		dash_direction = -1
	elif direction > 0.0:
		dash_direction = 1

	facing = dash_direction
	sprite.flip_h = facing < 0

	is_dashing = true
	dash_time_left = dash_duration
	dash_cooldown_left = dash_cooldown
	velocity.y = 0.0
	velocity.x = dash_speed * facing
	modulate.a = 0.65

	dash_used.emit(dash_cooldown)

func use_skill_1() -> void:
	if is_down or is_hurt or is_dashing:
		return

	if skill_1_cooldown_left > 0.0:
		return

	skill_1_cooldown_left = skill_1_cooldown
	skill_used.emit(skill_1_cooldown)

	play_skill()
	apply_hot_water_splash()

func apply_hot_water_splash() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not enemy.has_method("take_damage"):
			continue

		if not enemy is Node2D:
			continue

		var enemy_node: Node2D = enemy
		var dx: float = enemy_node.global_position.x - global_position.x
		var dist: float = global_position.distance_to(enemy_node.global_position)

		if dist > skill_1_range:
			continue

		if facing == 1 and dx < -12.0:
			continue
		if facing == -1 and dx > 12.0:
			continue

		enemy_node.take_damage(skill_1_damage)

func start_attack() -> void:
	if is_down or is_hurt or is_dashing:
		return

	is_attacking = true
	attack_area.position.x = 20.0 * facing
	attack_shape.disabled = false

	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

	hit_nearest_enemy()
	attack_timer.start(0.2)

func hit_nearest_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var nearest_distance: float = 65.0

	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist: float = global_position.distance_to(enemy.global_position)
			var direction_to_enemy = sign(enemy.global_position.x - global_position.x)

			if direction_to_enemy == facing or dist < 15.0:
				if dist < nearest_distance:
					nearest_distance = dist
					nearest_enemy = enemy

	if nearest_enemy != null:
		nearest_enemy.take_damage(attack_damage)

func _on_attack_timer_timeout() -> void:
	attack_shape.disabled = true
	is_attacking = false

func take_damage(amount: int) -> void:
	if is_down:
		return

	if is_dashing and dash_invulnerable:
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
	is_attacking = false
	is_dashing = false
	attack_shape.disabled = true
	velocity.x = 0.0
	modulate.a = 1.0
	play_hurt()
	hurt_timer.start()

func _on_hurt_timer_timeout() -> void:
	is_hurt = false

func enter_down_state() -> void:
	is_down = true
	is_hurt = false
	is_attacking = false
	is_dashing = false
	attack_shape.disabled = true
	velocity = Vector2.ZERO
	modulate.a = 1.0
	down_started.emit()
	play_down()
	down_timer.start()

func _on_down_timer_timeout() -> void:
	is_down = false
	current_health = min(recover_health, max_health)
	health_changed.emit(current_health, max_health)
	recovered.emit()

func can_be_targeted() -> bool:
	if is_down:
		return false

	if is_dashing and dash_invulnerable:
		return false

	return true

func get_dash_cooldown_left() -> float:
	return dash_cooldown_left

func get_dash_cooldown_total() -> float:
	return dash_cooldown

func get_skill_1_cooldown_left() -> float:
	return skill_1_cooldown_left

func get_skill_1_cooldown_total() -> float:
	return skill_1_cooldown

func update_animation(direction: float) -> void:
	if is_down:
		play_down()
		return

	if is_hurt:
		play_hurt()
		return

	if is_dashing:
		play_dash()
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

func play_dash() -> void:
	if sprite.sprite_frames.has_animation("run") and sprite.animation != "run":
		sprite.play("run")

func play_skill() -> void:
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
