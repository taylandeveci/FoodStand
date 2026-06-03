extends Area2D

signal collected(money_gain: int, appeal_gain: int)

const TRASH_PICKUP_SFX: AudioStream = preload("res://sounds/trashpickup/trashpickup.mp3")

@export var money_reward: int = 1
@export var appeal_reward: int = 1
@export var interact_hold_duration: float = 1.0

var player_in_range: bool = false
var interact_hold_time: float = 0.0
var interact_completed_while_held: bool = false

@onready var interact_prompt: Sprite2D = $InteractPrompt

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hide_interact_prompt()

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_pressed("interact") and not interact_completed_while_held:
		interact_hold_time = min(interact_hold_time + delta, interact_hold_duration)
		show_interact_progress(interact_hold_time / max(interact_hold_duration, 0.001))

		if interact_hold_time >= interact_hold_duration:
			interact_completed_while_held = true
			hide_interact_prompt()
			collect_trash()
		return

	if not Input.is_action_pressed("interact"):
		interact_completed_while_held = false

	if interact_hold_time > 0.0:
		interact_hold_time = 0.0

	if player_in_range and not interact_completed_while_held:
		show_interact_idle()
	else:
		hide_interact_prompt()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		show_interact_idle()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		interact_hold_time = 0.0
		interact_completed_while_held = false
		hide_interact_prompt()

func collect_trash() -> void:
	play_trash_pickup_sfx()
	collected.emit(money_reward, appeal_reward)
	queue_free()

func play_trash_pickup_sfx() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	var pickup_sfx_player := AudioStreamPlayer.new()
	pickup_sfx_player.name = "TrashPickupSfx"
	pickup_sfx_player.stream = TRASH_PICKUP_SFX
	scene_root.add_child(pickup_sfx_player)
	pickup_sfx_player.finished.connect(pickup_sfx_player.queue_free)
	pickup_sfx_player.play()

func show_interact_idle() -> void:
	if interact_prompt == null:
		return
	interact_prompt.visible = true
	interact_prompt.frame = 0

func show_interact_progress(progress: float) -> void:
	if interact_prompt == null:
		return
	var frame_count: int = max(interact_prompt.hframes, 1)
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	interact_prompt.visible = true
	interact_prompt.frame = mini(int(clamped_progress * float(frame_count - 1)), frame_count - 1)

func hide_interact_prompt() -> void:
	if interact_prompt == null:
		return
	interact_prompt.visible = false
	interact_prompt.frame = 0
