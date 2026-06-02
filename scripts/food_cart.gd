extends StaticBody2D

signal interacted
signal hp_changed(current_hp: int, max_hp: int)
signal destroyed

@export var max_hp: int = 20
@export var interact_hold_duration: float = 1.0

var player_in_range: bool = false
var current_hp: int = 0
var interact_hold_time: float = 0.0
var interact_completed_while_held: bool = false
var interaction_enabled: bool = true

@onready var interact_area: Area2D = get_node_or_null("InteractArea") as Area2D
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label
@onready var interact_prompt: Sprite2D = get_node_or_null("InteractPrompt") as Sprite2D

func _ready() -> void:
	print("FoodCart _ready calisti")
	print("Node path:", get_path())
	
	# KRİTİK EKLEME: Düşmanların bizi hedef alabilmesi için kendimizi Stand grubuna ekliyoruz
	add_to_group("Stand")

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

	if interact_prompt == null:
		push_error("FoodCart altinda InteractPrompt yok.")
		return

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	prompt_label.visible = false
	hide_interact_prompt()
	print("FoodCart signal connect tamam")

func _process(delta: float) -> void:
	update_interact_hold(delta)

func set_recipe_hint(text_value: String) -> void:
	if prompt_label:
		prompt_label.text = text_value
		prompt_label.visible = text_value != ""
	refresh_interact_prompt()

func set_interaction_enabled(enabled: bool) -> void:
	if interaction_enabled == enabled:
		return

	interaction_enabled = enabled
	if not interaction_enabled:
		interact_hold_time = 0.0
		interact_completed_while_held = false
	refresh_interact_prompt()

func _on_body_entered(body: Node) -> void:
	print("InteractArea body_entered:", body.name)
	if body.is_in_group("player"):
		player_in_range = true
		if has_recipe_hint():
			prompt_label.visible = true
			hide_interact_prompt()
		else:
			refresh_interact_prompt()
		print("player range icinde")

func _on_body_exited(body: Node) -> void:
	print("InteractArea body_exited:", body.name)
	if body.is_in_group("player"):
		player_in_range = false
		interact_hold_time = 0.0
		interact_completed_while_held = false
		hide_interact_prompt()
		prompt_label.visible = false
		print("player range disinda")

func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	current_hp = max(current_hp - amount, 0)
	hp_changed.emit(current_hp, max_hp)

	if current_hp == 0:
		destroyed.emit()
		print("TEZGAH YIKILDI! GAME OVER!")

func reset_hp() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

func update_interact_hold(delta: float) -> void:
	var can_interact: bool = can_show_interact_prompt()

	if can_interact and Input.is_action_pressed("interact") and not interact_completed_while_held:
		interact_hold_time = min(interact_hold_time + delta, interact_hold_duration)
		show_interact_progress(interact_hold_time / max(interact_hold_duration, 0.001))

		if interact_hold_time >= interact_hold_duration:
			interact_completed_while_held = true
			hide_interact_prompt()
			print("E basili tutuldu, cart interact")
			interacted.emit()
		return

	if not Input.is_action_pressed("interact"):
		interact_completed_while_held = false

	if interact_hold_time > 0.0:
		interact_hold_time = 0.0

	if can_interact and not interact_completed_while_held:
		show_interact_idle()
	else:
		hide_interact_prompt()

func can_show_interact_prompt() -> bool:
	return player_in_range and interaction_enabled and not has_recipe_hint()

func has_recipe_hint() -> bool:
	return prompt_label != null and prompt_label.text != ""

func refresh_interact_prompt() -> void:
	if can_show_interact_prompt() and not Input.is_action_pressed("interact"):
		show_interact_idle()
	else:
		hide_interact_prompt()

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
