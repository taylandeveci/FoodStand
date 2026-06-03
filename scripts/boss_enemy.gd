extends CharacterBody2D

signal died

@export var speed: float = 30.0
@export var max_hp: int = 20
@export var contact_damage: int = 3
@export var attack_interval: float = 0.9
@export var hurt_duration: float = 0.25
@export var aggro_range: float = 100.0
@export var attack_range: float = 48.0
@export var coin_drop: int = 7

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_hp: int = 0

var stand_ref: Node2D = null
var player_ref: Node2D = null
var current_target: Node2D = null

var is_dead: bool = false
var is_hurt: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemy")

	stand_ref = get_tree().get_first_node_in_group("Stand")
	player_ref = get_tree().get_first_node_in_group("player")

	attack_timer.one_shot = false
	attack_timer.autostart = false
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	play_idle()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_hurt:
		move_and_slide()
		return

	choose_target()

	if current_target == null or not is_instance_valid(current_target):
		velocity.x = 0.0
		move_and_slide()
		play_idle()
		return

	var dx: float = current_target.global_position.x - global_position.x
	var abs_dx: float = absf(dx)
	var dist: float = global_position.distance_to(current_target.global_position)

	var close_enough_to_attack: bool = abs_dx <= attack_range

	if current_target.is_in_group("barricade"):
		close_enough_to_attack = is_on_wall() or dist <= attack_range + 72.0

	if not close_enough_to_attack:
		velocity.x = sign(dx) * speed
		sprite.flip_h = velocity.x < 0.0
		move_and_slide()
		play_walk()

		if not attack_timer.is_stopped():
			attack_timer.stop()
	else:
		velocity.x = 0.0
		move_and_slide()
		play_attack()

		if attack_timer.is_stopped():
			attack_timer.start()

func get_priority_barricade() -> Node2D:
	var barricades = get_tree().get_nodes_in_group("barricade")
	var best_barricade: Node2D = null
	var best_distance: float = 260.0

	for barricade in barricades:
		if not (barricade is Node2D):
			continue

		var barricade_node: Node2D = barricade
		var dist: float = global_position.distance_to(barricade_node.global_position)

		if dist < best_distance:
			best_distance = dist
			best_barricade = barricade_node

	return best_barricade

func choose_target() -> void:
	var barricade_target := get_priority_barricade()
	if barricade_target != null:
		current_target = barricade_target
		return

	current_target = stand_ref

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var player_targetable: bool = false
	if player_ref.has_method("can_be_targeted"):
		player_targetable = bool(player_ref.call("can_be_targeted"))

	if not player_targetable:
		return

	if not is_player_between_enemy_and_stand():
		return

	var player_dx: float = absf(player_ref.global_position.x - global_position.x)
	if player_dx <= aggro_range:
		current_target = player_ref

func is_player_between_enemy_and_stand() -> bool:
	if stand_ref == null or not is_instance_valid(stand_ref):
		return false
	if player_ref == null or not is_instance_valid(player_ref):
		return false

	var stand_dx: float = stand_ref.global_position.x - global_position.x
	var player_dx: float = player_ref.global_position.x - global_position.x

	if signf(stand_dx) != signf(player_dx):
		return false

	return absf(player_dx) < absf(stand_dx)

func _on_attack_timer_timeout() -> void:
	if is_dead or is_hurt:
		return

	if current_target == null or not is_instance_valid(current_target):
		return

	if current_target.is_in_group("barricade"):
		if current_target.has_method("take_damage"):
			current_target.take_damage(contact_damage)
		play_attack()
		return

	var dx: float = absf(current_target.global_position.x - global_position.x)
	if dx <= attack_range + 4.0:
		if current_target.has_method("take_damage"):
			current_target.take_damage(contact_damage)
		play_attack()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount

	if current_hp <= 0:
		die()
		return

	show_hurt()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	died.emit()
	queue_free()

func show_hurt() -> void:
	is_hurt = true
	velocity.x = 0.0

	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

	if not attack_timer.is_stopped():
		attack_timer.stop()

	_end_hurt_after_delay()

func _end_hurt_after_delay() -> void:
	await get_tree().create_timer(hurt_duration).timeout
	is_hurt = false

func play_idle() -> void:
	if is_hurt or is_dead:
		return
	if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")

func play_walk() -> void:
	if is_hurt or is_dead:
		return
	if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
		sprite.play("walk")

func play_attack() -> void:
	if is_hurt or is_dead:
		return
	if sprite.sprite_frames.has_animation("attack") and sprite.animation != "attack":
		sprite.play("attack")

func get_kill_reward() -> int:
	return coin_drop
