extends Node2D

signal arrived
signal exited
signal patience_ran_out

@export var speed: float = 80.0
@export var max_patience: float = 100.0
@export var patience_drain_speed: float = 12.0

var target_position: Vector2 = Vector2.ZERO
var has_target: bool = false
var has_arrived: bool = false
var is_leaving: bool = false

var patience: float = 100.0
var patience_active: bool = false
var order_name: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var order_label: Label = $OrderBubble/Label
@onready var patience_bar: ProgressBar = $PatienceBar

func _ready() -> void:
	patience = max_patience
	patience_bar.max_value = max_patience
	patience_bar.value = patience
	play_idle()

func _process(delta: float) -> void:
	update_patience(delta)

	if not has_target:
		play_idle()
		return

	if has_arrived and not is_leaving:
		play_idle()
		return

	var old_position: Vector2 = global_position
	global_position = global_position.move_toward(target_position, speed * delta)

	var moving: bool = global_position.distance_to(old_position) > 0.01

	if moving:
		play_walk()

		if target_position.x < global_position.x:
			sprite.flip_h = true
		elif target_position.x > global_position.x:
			sprite.flip_h = false
	else:
		play_idle()

	if global_position.distance_to(target_position) <= 4.0:
		global_position = target_position
		has_target = false

		if is_leaving:
			exited.emit()
			queue_free()
		else:
			has_arrived = true
			arrived.emit()
			play_idle()
			start_patience()

func update_patience(delta: float) -> void:
	if not patience_active:
		return

	patience -= patience_drain_speed * delta
	patience = max(patience, 0.0)
	patience_bar.value = patience

	if patience <= 0.0:
		patience_active = false
		patience_ran_out.emit()

func set_target(pos: Vector2) -> void:
	target_position = pos
	has_target = true
	has_arrived = false
	is_leaving = false
	play_walk()

func leave_to(pos: Vector2) -> void:
	target_position = pos
	has_target = true
	has_arrived = false
	is_leaving = true
	stop_patience()
	hide_order()
	play_walk()

func set_order_text(text_value: String) -> void:
	order_name = text_value
	order_label.text = text_value

func hide_order() -> void:
	$OrderBubble.visible = false

func show_order() -> void:
	$OrderBubble.visible = true

func start_patience() -> void:
	patience = max_patience
	patience_bar.max_value = max_patience
	patience_bar.value = patience
	patience_active = true
	patience_bar.visible = true

func stop_patience() -> void:
	patience_active = false
	patience_bar.visible = false

func play_idle() -> void:
	if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")

func play_walk() -> void:
	if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
		sprite.play("walk")
