extends Area2D

signal collected(money_gain: int, appeal_gain: int)

@export var money_reward: int = 1
@export var appeal_reward: int = 1

var player_in_range: bool = false

@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		collect_trash()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false

func collect_trash() -> void:
	collected.emit(money_reward, appeal_reward)
	queue_free()
