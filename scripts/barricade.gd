extends StaticBody2D

signal destroyed

@export var max_hp: int = 8

var current_hp: int = 0

@onready var hp_label: Label = $HpLabel

func _ready() -> void:
	current_hp = max_hp
	add_to_group("barricade")
	print("Barricade ready | in group:", is_in_group("barricade"))
	update_hp_label()

func take_damage(amount: int) -> void:
	print("Barricade took damage:", amount)

	if current_hp <= 0:
		return

	current_hp = max(current_hp - amount, 0)
	update_hp_label()

	if current_hp <= 0:
		destroyed.emit()
		queue_free()

func update_hp_label() -> void:
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
