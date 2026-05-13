extends StaticBody2D

signal interacted
signal hp_changed(current_hp: int, max_hp: int)
signal destroyed

@export var max_hp: int = 20

var player_in_range: bool = false
var current_hp: int = 0

@onready var interact_area: Area2D = get_node_or_null("InteractArea") as Area2D
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label

func _ready() -> void:
	print("FoodCart _ready calisti")
	print("Node path:", get_path())

	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

	print("InteractArea bulundu mu?:", interact_area)
	print("PromptLabel bulundu mu?:", prompt_label)

	if interact_area == null:
		push_error("FoodCart altinda InteractArea yok.")
		return

	if prompt_label == null:
		push_error("FoodCart altinda PromptLabel yok.")
		return

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	prompt_label.visible = false
	print("FoodCart signal connect tamam")

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		print("E basildi, cart interact")
		interacted.emit()

func _on_body_entered(body: Node) -> void:
	print("InteractArea body_entered:", body.name)
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true
		print("player range icinde")

func _on_body_exited(body: Node) -> void:
	print("InteractArea body_exited:", body.name)
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
		print("player range disinda")

func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		destroyed.emit()

func reset_hp() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
