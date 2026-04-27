extends Node
class_name Stats


# =========================
# 戦闘・派生ステータス
# =========================
# 注意:
# attack / defense / accuracy / evasion / crit_rate / crit_damage は旧データ互換・デバッグ用として残しています。
# 現在の通常攻撃計算では、これらの値を直接使わず、
# 基礎ステータスから get_effective_*() で派生した値を使います。
#
# 実際の戦闘・UI表示では、基本的に Unit 側の get_total_*() / get_total_combat_stats() を参照します。
#
# つまり、通常の参照優先順位は以下です。
# 1. Unit.get_total_*()
# 2. Stats.get_effective_*()
# 3. 旧 attack / defense などは最後の保険・互換用
#
# 将来的に完全移行できたら、attack / defense などは削除、または legacy_* に改名してもよいです。

# max_hp は少し特殊です。
# 現在HP hp との関係があるため、完全な旧デバッグ値というより、
# get_effective_max_hp() の結果を反映する現在最大HPのキャッシュとして使う想定です。
@export var max_hp: int = 100

# 旧データ互換・デバッグ用。
# 現在の通常攻撃の攻撃力は get_effective_attack() / Unit.get_total_attack() を使います。
@export var attack: int = 10

# 旧データ互換・デバッグ用。
# 現在の通常攻撃の防御力は get_effective_defense() / Unit.get_total_defense() を使います。
@export var defense: int = 5

# 速度は特殊ステータスです。
# 筋力・敏捷などの基礎ステータスから自動派生させず、独立値として扱います。
@export var speed: float = 120.0

# 旧データ互換・デバッグ用。
# 現在の命中率は get_effective_accuracy() / Unit.get_total_accuracy() を使います。
@export_range(0.0, 1.0, 0.01) var accuracy: float = 0.80

# 旧データ互換・デバッグ用。
# 現在の回避率は get_effective_evasion() / Unit.get_total_evasion() を使います。
@export_range(0.0, 1.0, 0.01) var evasion: float = 0.05

# 旧データ互換・デバッグ用。
# 現在のクリティカル率は get_effective_crit_rate() / Unit.get_total_crit_rate() を使います。
@export_range(0.0, 1.0, 0.01) var crit_rate: float = 0.05

# 旧データ互換・デバッグ用。
# 現在のクリティカル倍率は get_effective_crit_damage() / Unit.get_total_crit_damage() を使います。
@export var crit_damage: float = 1.5

# 運は特殊ステータスです。
# 攻撃力・防御力などの派生値には直接混ぜず、
# DamageCalculator 側でクリティカル、ダメージ上振れ、事故軽減などに広く浅く使います。
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
# 通常基礎ステータス:
# 筋力 / 体力 / 敏捷 / 器用 / 知力 / 精神力 / 感覚 / 魅力
#
# 特殊ステータス:
# 速度 / 運

@export var strength: int = 10      # 筋力
@export var vitality: int = 10      # 体力
@export var agility: int = 10       # 敏捷
@export var dexterity: int = 10     # 器用
@export var intelligence: int = 10  # 知力
@export var spirit: int = 10        # 精神力
@export var sense: int = 10         # 感覚
@export var charm: int = 10         # 魅力


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
	"charm": 0,
	"luck": 0
}

# 成長プロフィールで normal 1回分として使う基本ポイント。
# base_stat_growth_threshold が 200 の場合、normal 4pt なら約50回で +1。
const BASE_GROWTH_POINT_UNIT: int = 4

const BASE_STAT_GROWTH_RATE_MULTIPLIERS: Dictionary = {
	&"none": 0.0,
	&"very_low": 0.25,
	&"low": 0.5,
	&"normal": 1.0,
	&"high": 1.5,
	&"very_high": 2.0
}

# 成長内容の定義はここに集約する。
# 他スクリプト側では、基本的に Unit.apply_base_growth_profile() 経由で呼ぶ。
# まだ各行動には散らばせず、入口だけ用意しておく。
const BASE_STAT_GROWTH_PROFILES: Dictionary = {
	&"move": {
		"agility": &"normal",
		"vitality": &"low"
	},
	&"normal_attack": {
		"strength": &"normal",
		"dexterity": &"normal",
		"sense": &"low"
	},
	&"take_damage": {
		"vitality": &"normal",
		"spirit": &"low"
	},
	&"dodge": {
		"agility": &"normal",
		"sense": &"low"
	},
	&"interact": {
		"charm": &"normal",
		"sense": &"very_low"
	},
	&"gather": {
		"sense": &"normal",
		"dexterity": &"low",
		"vitality": &"very_low"
	},
	&"craft": {
		"dexterity": &"normal",
		"intelligence": &"low",
		"sense": &"low"
	},
	&"trade": {
		"charm": &"normal",
		"intelligence": &"low"
	},
	&"study": {
		"intelligence": &"normal",
		"spirit": &"low"
	},
	# 運は頻繁に伸ばさず、特殊イベントやレア成功などで使う想定。
	&"lucky_event": {
		"luck": &"low"
	}
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
	ensure_base_stat_growth_keys()
	reset_stats()


func reset_stats() -> void:
	refresh_derived_max_hp(false)

	hp = max_hp
	stamina = max_stamina
	hunger = float(max_hunger)
	action_progress_seconds = 0.0
	pending_actions = 0


func take_damage(amount: int) -> void:
	var final_damage: int = max(0, amount)

	refresh_derived_max_hp(false)

	hp -= final_damage
	print("ダメージ: ", final_damage, " / HP: ", hp, "/", max_hp)

	if hp <= 0:
		hp = 0
		die()


func heal(amount: int) -> void:
	var final_heal: int = max(0, amount)

	refresh_derived_max_hp(false)

	hp += final_heal
	if hp > max_hp:
		hp = max_hp

	print("回復: ", final_heal, " / HP: ", hp, "/", max_hp)


func die() -> void:
	print("死亡しました")

	var unit = get_parent()
	if unit != null and unit.has_method("handle_death"):
		unit.handle_death()


# =========================
# 基礎ステータス → 派生戦闘ステータス
# =========================

func get_ability_rating(value: int) -> float:
	var safe_value: float = float(max(value, 1))

	if safe_value <= 10.0:
		return safe_value

	var over_value: float = safe_value - 10.0
	return 10.0 + sqrt(over_value) * 2.5 + over_value * 0.15


func get_base_max_hp_from_abilities() -> int:
	var vitality_rating: float = get_ability_rating(vitality)
	var spirit_rating: float = get_ability_rating(spirit)

	var value: float = 50.0
	value += vitality_rating * 4.0
	value += spirit_rating * 1.0

	return max(1, int(round(value)))


func get_base_attack_from_abilities() -> int:
	var strength_rating: float = get_ability_rating(strength)
	var dexterity_rating: float = get_ability_rating(dexterity)
	var sense_rating: float = get_ability_rating(sense)

	var value: float = 0.0
	value += strength_rating * 0.65
	value += dexterity_rating * 0.25
	value += sense_rating * 0.10

	return max(1, int(round(value)))


func get_base_defense_from_abilities() -> int:
	var vitality_rating: float = get_ability_rating(vitality)
	var strength_rating: float = get_ability_rating(strength)
	var spirit_rating: float = get_ability_rating(spirit)

	var value: float = 0.0
	value += vitality_rating * 0.55
	value += strength_rating * 0.20
	value += spirit_rating * 0.25

	return max(0, int(round(value * 0.6)))


func get_base_accuracy_from_abilities() -> float:
	var dexterity_rating: float = get_ability_rating(dexterity)
	var sense_rating: float = get_ability_rating(sense)

	var value: float = 0.65
	value += dexterity_rating * 0.010
	value += sense_rating * 0.005

	return clamp(value, 0.05, 0.95)


func get_base_evasion_from_abilities() -> float:
	var agility_rating: float = get_ability_rating(agility)
	var sense_rating: float = get_ability_rating(sense)

	var value: float = 0.02
	value += agility_rating * 0.004
	value += sense_rating * 0.002

	return clamp(value, 0.0, 0.50)


func get_base_crit_rate_from_abilities() -> float:
	var sense_rating: float = get_ability_rating(sense)
	var dexterity_rating: float = get_ability_rating(dexterity)

	var value: float = 0.02
	value += sense_rating * 0.002
	value += dexterity_rating * 0.001

	return clamp(value, 0.0, 0.40)


func get_base_crit_damage_from_abilities() -> float:
	var strength_rating: float = get_ability_rating(strength)
	var sense_rating: float = get_ability_rating(sense)

	var value: float = 1.30
	value += strength_rating * 0.010
	value += sense_rating * 0.004

	return clamp(value, 1.0, 2.5)


func get_effective_max_hp() -> int:
	return max(1, get_base_max_hp_from_abilities())


func get_effective_attack() -> float:
	return max(0.0, float(get_base_attack_from_abilities()) * attack_multiplier)


func get_effective_defense() -> float:
	return max(0.0, float(get_base_defense_from_abilities()) * defense_multiplier)


func get_effective_accuracy() -> float:
	return clamp(get_base_accuracy_from_abilities() * accuracy_multiplier, 0.0, 1.0)


func get_effective_evasion() -> float:
	return clamp(get_base_evasion_from_abilities() * evasion_multiplier, 0.0, 1.0)


func get_effective_crit_rate() -> float:
	return clamp(get_base_crit_rate_from_abilities() * crit_rate_multiplier, 0.0, 1.0)


func get_effective_crit_damage() -> float:
	return get_base_crit_damage_from_abilities()


func get_effective_speed() -> float:
	return max(1.0, speed * speed_multiplier)


func get_effective_luck() -> int:
	return max(0, luck)


func refresh_derived_max_hp(keep_ratio: bool = false) -> void:
	var old_max_hp: int = max(max_hp, 1)
	var old_hp: int = hp
	var new_max_hp: int = get_effective_max_hp()

	max_hp = new_max_hp

	if keep_ratio:
		var ratio: float = clamp(float(old_hp) / float(old_max_hp), 0.0, 1.0)
		hp = clamp(int(round(float(new_max_hp) * ratio)), 0, new_max_hp)
	else:
		hp = clamp(old_hp, 0, new_max_hp)


func get_debug_derived_combat_stats() -> Dictionary:
	return {
		"max_hp": get_effective_max_hp(),
		"attack": get_effective_attack(),
		"defense": get_effective_defense(),
		"accuracy": get_effective_accuracy(),
		"evasion": get_effective_evasion(),
		"crit_rate": get_effective_crit_rate(),
		"crit_damage": get_effective_crit_damage(),
		"speed": get_effective_speed(),
		"luck": get_effective_luck()
	}


func get_element_rate(attacking_element: String) -> float:
	if attacking_element == "" or attacking_element == "neutral":
		return 1.0

	if element_resistances.has(attacking_element):
		var value = element_resistances[attacking_element]
		if value is int or value is float:
			return float(value)

	return 1.0


# =========================
# 基礎能力成長
# =========================

func ensure_base_stat_growth_keys() -> void:
	var keys: Array[String] = [
		"strength",
		"vitality",
		"agility",
		"dexterity",
		"intelligence",
		"spirit",
		"sense",
		"charm",
		"luck"
	]

	for key in keys:
		if not base_stat_growth_points.has(key):
			base_stat_growth_points[key] = 0


func get_base_growth_rate_multiplier(rate_id: StringName) -> float:
	if BASE_STAT_GROWTH_RATE_MULTIPLIERS.has(rate_id):
		return float(BASE_STAT_GROWTH_RATE_MULTIPLIERS[rate_id])

	push_warning("未知の基礎ステータス成長率です: %s" % String(rate_id))
	return 0.0


func get_base_growth_amount_by_rate(rate_id: StringName, multiplier: int = 1) -> int:
	if multiplier <= 0:
		return 0

	var rate_multiplier: float = get_base_growth_rate_multiplier(rate_id)
	if rate_multiplier <= 0.0:
		return 0

	var raw_amount: float = float(BASE_GROWTH_POINT_UNIT) * rate_multiplier * float(multiplier)
	var amount: int = int(round(raw_amount))

	# very_low などが 0 に丸められないようにする。
	if amount <= 0:
		amount = 1

	return amount


func has_base_growth_profile(profile_id: StringName) -> bool:
	return BASE_STAT_GROWTH_PROFILES.has(profile_id)


func get_base_growth_profile(profile_id: StringName) -> Dictionary:
	if not BASE_STAT_GROWTH_PROFILES.has(profile_id):
		return {}

	var growth_map: Dictionary = BASE_STAT_GROWTH_PROFILES[profile_id]
	return growth_map.duplicate(true)


func gain_base_stat_growth(stat_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	ensure_base_stat_growth_keys()

	if not base_stat_growth_points.has(stat_name):
		push_warning("未知の基礎ステータスです: %s" % stat_name)
		return

	base_stat_growth_points[stat_name] += amount
	apply_base_stat_growth(stat_name)


func gain_base_stat_growth_map(growth_map: Dictionary, multiplier: int = 1) -> void:
	if multiplier <= 0:
		return

	if growth_map.is_empty():
		return

	for stat_name_key in growth_map.keys():
		var stat_name: String = String(stat_name_key)
		var raw_value = growth_map[stat_name_key]
		var amount: int = 0

		# 値が数値なら、そのまま成長ポイントとして扱う。
		# 値が StringName / String なら、成長率段階として扱う。
		if raw_value is int:
			amount = int(raw_value) * multiplier
		elif raw_value is float:
			amount = int(round(float(raw_value) * float(multiplier)))
		else:
			var rate_id: StringName = StringName(String(raw_value))
			amount = get_base_growth_amount_by_rate(rate_id, multiplier)

		if amount > 0:
			gain_base_stat_growth(stat_name, amount)


func apply_base_growth_profile(profile_id: StringName, multiplier: int = 1) -> void:
	if multiplier <= 0:
		return

	if not BASE_STAT_GROWTH_PROFILES.has(profile_id):
		push_warning("未知の基礎ステータス成長プロフィールです: %s" % String(profile_id))
		return

	var growth_map: Dictionary = BASE_STAT_GROWTH_PROFILES[profile_id]
	gain_base_stat_growth_map(growth_map, multiplier)


func apply_base_stat_growth(stat_name: String) -> void:
	ensure_base_stat_growth_keys()

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
		"luck":
			luck += amount
		_:
			push_warning("increase_base_stat: 未知の基礎ステータスです: %s" % stat_name)
			return

	refresh_derived_max_hp(false)
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
		"luck":
			return luck
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
		"luck":
			luck = value
		_:
			push_warning("未知の基礎ステータスです: %s" % stat_name)
			return

	refresh_derived_max_hp(false)


func get_base_stat_growth_point(stat_name: String) -> int:
	ensure_base_stat_growth_keys()

	if base_stat_growth_points.has(stat_name):
		return int(base_stat_growth_points[stat_name])

	push_warning("未知の基礎ステータスです: %s" % stat_name)
	return 0


# =========================
# 空腹 / スタミナ
# =========================

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


# =========================
# 保存 / 復元
# =========================

func get_stats_data() -> Dictionary:
	refresh_derived_max_hp(false)

	return {
		"hp": hp,
		"max_hp": max_hp,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"hunger": hunger,
		"max_hunger": max_hunger,
		"hunger_days_to_ten_percent": hunger_days_to_ten_percent,
		"starvation_damage_per_day": starvation_damage_per_day,

		# 旧データ互換・デバッグ用。通常攻撃計算の中心ではない。
		"attack": attack,
		"defense": defense,
		"accuracy": accuracy,
		"evasion": evasion,
		"crit_rate": crit_rate,
		"crit_damage": crit_damage,

		"speed": speed,
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

	# 旧データ互換・デバッグ用。通常攻撃計算の中心ではない。
	if data.has("attack"):
		attack = int(data["attack"])

	if data.has("defense"):
		defense = int(data["defense"])

	if data.has("accuracy"):
		accuracy = float(data["accuracy"])

	if data.has("evasion"):
		evasion = float(data["evasion"])

	if data.has("crit_rate"):
		crit_rate = float(data["crit_rate"])

	if data.has("crit_damage"):
		crit_damage = float(data["crit_damage"])

	if data.has("speed"):
		speed = float(data["speed"])

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

	ensure_base_stat_growth_keys()
	refresh_derived_max_hp(false)

	stamina = clamp(stamina, 0, max_stamina)
	hunger = clamp(hunger, 0.0, float(max_hunger))
