extends Node

@export var max_hp: int = 20
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 120.0

var hp: int = 0
var action_progress_seconds: float = 0.0
var pending_actions: int = 0

func _ready() -> void:
	reset_stats()

func reset_stats() -> void:
	hp = max_hp
	action_progress_seconds = 0.0
	pending_actions = 0

func take_damage(amount: int) -> void:
	var final_damage = max(1, amount - defense)
	hp -= final_damage

	print("ダメージ: ", final_damage, " / HP: ", hp, "/", max_hp)

	if hp <= 0:
		hp = 0
		die()

func heal(amount: int) -> void:
	hp += amount
	if hp > max_hp:
		hp = max_hp

	print("回復: ", amount, " / HP: ", hp, "/", max_hp)

func die() -> void:
	print("死亡しました")

	var unit = get_parent()
	if unit != null and unit.has_method("handle_death"):
		unit.handle_death()
