extends Node
class_name Stats

@export var max_hp: int = 20
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 120.0

# 0.0 ~ 1.0 を想定
@export_range(0.0, 1.0, 0.01) var accuracy: float = 0.95
@export_range(0.0, 1.0, 0.01) var evasion: float = 0.05
@export_range(0.0, 1.0, 0.01) var crit_rate: float = 0.05

# クリティカル時のダメージ倍率
@export var crit_damage: float = 1.5

# 幸運
@export var luck: int = 0

# 自身の属性
@export var element: String = "neutral"

# 受ける属性ダメージ倍率
# 例:
# {
#   "neutral": 1.0,
#   "fire": 1.5,   # 火が弱点
#   "ice": 0.5     # 氷に耐性
# }
@export var element_resistances: Dictionary = {
	"neutral": 1.0
}

# バフ・デバフ倍率
@export var attack_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0
@export var accuracy_multiplier: float = 1.0
@export var evasion_multiplier: float = 1.0
@export var crit_rate_multiplier: float = 1.0

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
	# 防御計算は DamageCalculator 側で済ませる
	# ここでは受け取ったダメージをそのまま適用する
	var final_damage = max(0, amount)
	hp -= final_damage

	print("ダメージ: ", final_damage, " / HP: ", hp, "/", max_hp)

	if hp <= 0:
		hp = 0
		die()

func heal(amount: int) -> void:
	var final_heal = max(0, amount)
	hp += final_heal
	if hp > max_hp:
		hp = max_hp

	print("回復: ", final_heal, " / HP: ", hp, "/", max_hp)

func die() -> void:
	print("死亡しました")

	var unit = get_parent()
	if unit != null and unit.has_method("handle_death"):
		unit.handle_death()

func get_effective_attack() -> float:
	return max(0.0, attack * attack_multiplier)

func get_effective_defense() -> float:
	return max(0.0, defense * defense_multiplier)

func get_effective_accuracy() -> float:
	return clamp(accuracy * accuracy_multiplier, 0.0, 1.0)

func get_effective_evasion() -> float:
	return clamp(evasion * evasion_multiplier, 0.0, 1.0)

func get_effective_crit_rate() -> float:
	return clamp(crit_rate * crit_rate_multiplier, 0.0, 1.0)

func get_element_rate(attacking_element: String) -> float:
	if attacking_element == "" or attacking_element == "neutral":
		return 1.0

	if element_resistances.has(attacking_element):
		return float(element_resistances[attacking_element])

	return 1.0
