extends Node
class_name Stats

# =========================
# 戦闘・派生ステータス
# =========================
@export var max_hp: int = 2000
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
@export var element_resistances: Dictionary = {
	"neutral": 1.0
}

# バフ・デバフ倍率
@export var attack_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0
@export var accuracy_multiplier: float = 1.0
@export var evasion_multiplier: float = 1.0
@export var crit_rate_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0

# =========================
# 基礎能力ステータス
# =========================
@export var strength: int = 10
@export var vitality: int = 10
@export var agility: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10
@export var spirit: int = 10
@export var sense: int = 10
@export var charm: int = 10

# =========================
# 基礎能力成長
# =========================
@export var base_stat_growth_threshold: int = 200

var base_stat_growth_points: Dictionary = {
	"strength": 0,
	"vitality": 0,
	"agility": 0,
	"dexterity": 0,
	"intelligence": 0,
	"spirit": 0,
	"sense": 0,
	"charm": 0
}

# 現在状態
var hp: int = 0
var action_progress_seconds: float = 0.0
var pending_actions: int = 0

# スタミナ / 空腹
@export var max_stamina: int = 100
var stamina: int = 100

@export var max_hunger: int = 100
var hunger: float = 100.0

# 空腹の減少速度と餓死ダメージ
# 3日で100% -> 10% まで下がる既定値
@export var hunger_days_to_ten_percent: float = 3.0
@export var starvation_damage_per_day: float = 10.0

func _ready() -> void:
	reset_stats()

func reset_stats() -> void:
	hp = max_hp
	stamina = max_stamina
	hunger = float(max_hunger)
	action_progress_seconds = 0.0
	pending_actions = 0

func take_damage(amount: int) -> void:
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

func get_effective_speed() -> float:
	return max(0.0, speed * speed_multiplier)

func get_element_rate(attacking_element: String) -> float:
	if attacking_element == "" or attacking_element == "neutral":
		return 1.0

	if element_resistances.has(attacking_element):
		var value = element_resistances[attacking_element]
		if value is int or value is float:
			return float(value)

	return 1.0

func gain_base_stat_growth(stat_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	if not base_stat_growth_points.has(stat_name):
		push_warning("未知の基礎ステータスです: %s" % stat_name)
		return

	base_stat_growth_points[stat_name] += amount
	apply_base_stat_growth(stat_name)

func apply_base_stat_growth(stat_name: String) -> void:
	if not base_stat_growth_points.has(stat_name):
		push_warning("未知の基礎ステータスです: %s" % stat_name)
		return

	while base_stat_growth_points[stat_name] >= base_stat_growth_threshold:
		base_stat_growth_points[stat_name] -= base_stat_growth_threshold
		increase_base_stat(stat_name, 1)

func increase_base_stat(stat_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	match stat_name:
		"strength":
			strength += amount
		"vitality":
			vitality += amount
		"agility":
			agility += amount
		"dexterity":
			dexterity += amount
		"intelligence":
			intelligence += amount
		"spirit":
			spirit += amount
		"sense":
			sense += amount
		"charm":
			charm += amount
		_:
			push_warning("increase_base_stat: 未知の基礎ステータスです: %s" % stat_name)
			return

	on_base_stat_increased(stat_name, amount)

func on_base_stat_increased(stat_name: String, amount: int) -> void:
	print(stat_name, " が ", amount, " 上がりました")

func get_base_stat_value(stat_name: String) -> int:
	match stat_name:
		"strength":
			return strength
		"vitality":
			return vitality
		"agility":
			return agility
		"dexterity":
			return dexterity
		"intelligence":
			return intelligence
		"spirit":
			return spirit
		"sense":
			return sense
		"charm":
			return charm
		_:
			push_warning("未知の基礎ステータスです: %s" % stat_name)
			return 0

func set_base_stat_value(stat_name: String, value: int) -> void:
	value = max(value, 0)

	match stat_name:
		"strength":
			strength = value
		"vitality":
			vitality = value
		"agility":
			agility = value
		"dexterity":
			dexterity = value
		"intelligence":
			intelligence = value
		"spirit":
			spirit = value
		"sense":
			sense = value
		"charm":
			charm = value
		_:
			push_warning("未知の基礎ステータスです: %s" % stat_name)

func get_base_stat_growth_point(stat_name: String) -> int:
	if base_stat_growth_points.has(stat_name):
		return int(base_stat_growth_points[stat_name])

	push_warning("未知の基礎ステータスです: %s" % stat_name)
	return 0


func get_hunger_ratio() -> float:
	if max_hunger <= 0:
		return 0.0
	return clamp(float(hunger) / float(max_hunger), 0.0, 1.0)


func get_stamina_ratio() -> float:
	if max_stamina <= 0:
		return 0.0
	return clamp(float(stamina) / float(max_stamina), 0.0, 1.0)


func get_hunger_condition_key() -> String:
	var ratio: float = get_hunger_ratio()

	if ratio <= 0.0:
		return "starving_dead"
	if ratio <= 0.10:
		return "starving"
	if ratio <= 0.40:
		return "hungry"
	if ratio >= 0.80:
		return "full"

	return ""


func get_stamina_condition_key() -> String:
	var ratio: float = get_stamina_ratio()

	if ratio <= 0.05:
		return "overwork"
	if ratio <= 0.40:
		return "fatigue"

	return ""

func get_stats_data() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"hunger": hunger,
		"max_hunger": max_hunger,
		"hunger_days_to_ten_percent": hunger_days_to_ten_percent,
		"starvation_damage_per_day": starvation_damage_per_day,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"accuracy": accuracy,
		"evasion": evasion,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,
		"luck": luck,
		"element": element,
		"element_resistances": element_resistances.duplicate(true),
		"attack_multiplier": attack_multiplier,
		"defense_multiplier": defense_multiplier,
		"accuracy_multiplier": accuracy_multiplier,
		"evasion_multiplier": evasion_multiplier,
		"crit_rate_multiplier": crit_rate_multiplier,
		"speed_multiplier": speed_multiplier,
		"strength": strength,
		"vitality": vitality,
		"agility": agility,
		"dexterity": dexterity,
		"intelligence": intelligence,
		"spirit": spirit,
		"sense": sense,
		"charm": charm,
		"base_stat_growth_threshold": base_stat_growth_threshold,
		"base_stat_growth_points": base_stat_growth_points.duplicate(true),
		"action_progress_seconds": action_progress_seconds,
		"pending_actions": pending_actions
	}

func apply_stats_data(data: Dictionary) -> void:
	if data.has("max_hp"):
		max_hp = int(data["max_hp"])
	if data.has("hp"):
		hp = int(data["hp"])
	if data.has("max_stamina"):
		max_stamina = int(data["max_stamina"])
	if data.has("stamina"):
		stamina = int(data["stamina"])
	if data.has("max_hunger"):
		max_hunger = int(data["max_hunger"])
	if data.has("hunger"):
		hunger = float(data["hunger"])
	if data.has("hunger_days_to_ten_percent"):
		hunger_days_to_ten_percent = float(data["hunger_days_to_ten_percent"])
	if data.has("starvation_damage_per_day"):
		starvation_damage_per_day = float(data["starvation_damage_per_day"])
	if data.has("attack"):
		attack = int(data["attack"])
	if data.has("defense"):
		defense = int(data["defense"])
	if data.has("speed"):
		speed = float(data["speed"])
	if data.has("accuracy"):
		accuracy = float(data["accuracy"])
	if data.has("evasion"):
		evasion = float(data["evasion"])
	if data.has("crit_rate"):
		crit_rate = float(data["crit_rate"])
	if data.has("crit_damage"):
		crit_damage = float(data["crit_damage"])
	if data.has("luck"):
		luck = int(data["luck"])
	if data.has("element"):
		element = String(data["element"])
	if data.has("element_resistances"):
		element_resistances = data["element_resistances"].duplicate(true)
	if data.has("attack_multiplier"):
		attack_multiplier = float(data["attack_multiplier"])
	if data.has("defense_multiplier"):
		defense_multiplier = float(data["defense_multiplier"])
	if data.has("accuracy_multiplier"):
		accuracy_multiplier = float(data["accuracy_multiplier"])
	if data.has("evasion_multiplier"):
		evasion_multiplier = float(data["evasion_multiplier"])
	if data.has("crit_rate_multiplier"):
		crit_rate_multiplier = float(data["crit_rate_multiplier"])
	if data.has("speed_multiplier"):
		speed_multiplier = float(data["speed_multiplier"])
	if data.has("strength"):
		strength = int(data["strength"])
	if data.has("vitality"):
		vitality = int(data["vitality"])
	if data.has("agility"):
		agility = int(data["agility"])
	if data.has("dexterity"):
		dexterity = int(data["dexterity"])
	if data.has("intelligence"):
		intelligence = int(data["intelligence"])
	if data.has("spirit"):
		spirit = int(data["spirit"])
	if data.has("sense"):
		sense = int(data["sense"])
	if data.has("charm"):
		charm = int(data["charm"])
	if data.has("base_stat_growth_threshold"):
		base_stat_growth_threshold = int(data["base_stat_growth_threshold"])
	if data.has("base_stat_growth_points"):
		base_stat_growth_points = data["base_stat_growth_points"].duplicate(true)
	if data.has("action_progress_seconds"):
		action_progress_seconds = float(data["action_progress_seconds"])
	if data.has("pending_actions"):
		pending_actions = int(data["pending_actions"])

	hp = clamp(hp, 0, max_hp)
	stamina = clamp(stamina, 0, max_stamina)
	hunger = clamp(hunger, 0.0, float(max_hunger))
