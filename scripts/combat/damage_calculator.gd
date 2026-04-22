extends Node

const MIN_HIT_RATE = 0.05
const MAX_HIT_RATE = 0.95

# ダメージレンジの基本値
const BASE_MIN_RATIO = 0.90
const BASE_MAX_RATIO = 1.15

# 攻撃側の運が上振れ上限に与える影響
# attacker_luck_rate * ATTACK_LUCK_MAX_BONUS が max_ratio に加算される
const ATTACK_LUCK_MAX_BONUS = 0.15

# 防御側の運が受けるダメージ全体に与える軽減率
# target_luck_rate * DEFENSE_LUCK_DAMAGE_REDUCTION が最終ダメージに掛かる
const DEFENSE_LUCK_DAMAGE_REDUCTION = 0.12

# ダメージ下限が 1 を下回った時、その不足分を命中不利へ変換する係数
const UNDERFLOW_TO_HIT_PENALTY = 0.03


func calculate_damage(attacker, target, attack_data: Dictionary = {}) -> Dictionary:
	if attacker == null or target == null:
		return _make_result(false, false, false, 0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, "invalid_target")

	if not attacker.has_node("Stats"):
		return _make_result(false, false, false, 0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, "attacker_has_no_stats")

	if not target.has_node("Stats"):
		return _make_result(false, false, false, 0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0, "target_has_no_stats")

	var attacker_stats = attacker.get_node("Stats")
	var target_stats = target.get_node("Stats")

	var power = float(attack_data.get("power", 1.0))
	var element = str(attack_data.get("element", "neutral"))
	var bonus_accuracy = float(attack_data.get("bonus_accuracy", 0.0))
	var bonus_crit_rate = float(attack_data.get("bonus_crit_rate", 0.0))
	var ignore_defense_rate = clamp(float(attack_data.get("ignore_defense_rate", 0.0)), 0.0, 1.0)
	var fixed_damage_bonus = float(attack_data.get("fixed_damage_bonus", 0.0))

	var attacker_luck = _get_attacker_luck(attacker, attacker_stats)
	var target_luck = _get_target_luck(target, target_stats)

	var attacker_luck_rate = _compress_luck(attacker_luck)
	var target_luck_rate = _compress_luck(target_luck)

	# 1. 攻撃値・防御値
	var total_attack = 0.0
	if attacker.has_method("get_total_attack"):
		total_attack = float(attacker.get_total_attack())
	else:
		total_attack = _get_effective_attack(attacker_stats)

	var total_defense = 0.0
	if target.has_method("get_total_defense"):
		total_defense = float(target.get_total_defense())
	else:
		total_defense = _get_effective_defense(target_stats)

	var effective_attack = max(0.0, total_attack)
	var effective_defense = max(0.0, total_defense * (1.0 - ignore_defense_rate))

	# 2. 基準ダメージ
	var base_damage = (effective_attack * power) + fixed_damage_bonus
	base_damage = max(0.0, base_damage)

	var reduced_damage = base_damage * (100.0 / (100.0 + effective_defense))

	# 3. 属性補正
	var element_rate = _get_element_rate(target_stats, element)

	# 4. クリティカル判定
	# 運は少しだけクリ率に影響
	var crit_rate = _get_attacker_crit_rate(attacker, attacker_stats) + bonus_crit_rate
	crit_rate += attacker_luck_rate * 0.05
	crit_rate -= target_luck_rate * 0.03
	crit_rate = clamp(crit_rate, 0.0, 1.0)

	var is_critical = randf() < crit_rate

	var crit_damage_rate = _get_attacker_crit_damage(attacker, attacker_stats)
	if not is_critical:
		crit_damage_rate = 1.0

	# 5. 防御側の運による被ダメ軽減
	var defense_luck_damage_rate = 1.0 - target_luck_rate * DEFENSE_LUCK_DAMAGE_REDUCTION
	defense_luck_damage_rate = clamp(defense_luck_damage_rate, 1.0 - DEFENSE_LUCK_DAMAGE_REDUCTION, 1.0)

	# 6. レンジ決定前の基準値
	var pre_random_damage = reduced_damage
	pre_random_damage *= element_rate
	pre_random_damage *= crit_damage_rate
	pre_random_damage *= defense_luck_damage_rate

	# 7. レンジ計算
	# 下限は固定
	# 上限だけ攻撃側の運で伸ばす
	var min_ratio = BASE_MIN_RATIO
	var max_ratio = BASE_MAX_RATIO + attacker_luck_rate * ATTACK_LUCK_MAX_BONUS

	min_ratio = clamp(min_ratio, 0.70, 0.98)
	max_ratio = clamp(max_ratio, 1.02, BASE_MAX_RATIO + ATTACK_LUCK_MAX_BONUS)

	var min_damage_raw = pre_random_damage * min_ratio
	var max_damage_raw = pre_random_damage * max_ratio

	# 8. 下限が 1 未満になったら、その不足分を命中不利へ変換
	var underflow = 0.0
	if min_damage_raw < 1.0:
		underflow = 1.0 - min_damage_raw

	var underflow_accuracy_penalty = underflow * UNDERFLOW_TO_HIT_PENALTY
	var underflow_evasion_bonus = underflow * UNDERFLOW_TO_HIT_PENALTY

	# 9. 命中判定
	var accuracy_value = _get_attacker_accuracy(attacker, attacker_stats) + bonus_accuracy
	var evasion_value = _get_target_evasion(target, target_stats)

	accuracy_value -= underflow_accuracy_penalty
	evasion_value += underflow_evasion_bonus

	var final_hit_rate = clamp(
		accuracy_value - evasion_value,
		MIN_HIT_RATE,
		MAX_HIT_RATE
	)

	if randf() > final_hit_rate:
		if DebugSettings.debug_damage_calculate:
			print("----- Damage Calculate -----")
			print("phase: ", "dodged")
			print("attacker: ", attacker.name)
			print("target: ", target.name)
			print("total_attack: ", total_attack)
			print("total_defense: ", total_defense)
			print("effective_attack: ", effective_attack)
			print("effective_defense: ", effective_defense)
			print("power: ", power)
			print("element: ", element)
			print("element_rate: ", element_rate)
			print("crit_rate: ", crit_rate)
			print("is_critical: ", is_critical)
			print("crit_damage_rate: ", crit_damage_rate)
			print("attacker_luck: ", attacker_luck)
			print("target_luck: ", target_luck)
			print("attacker_luck_rate: ", attacker_luck_rate)
			print("target_luck_rate: ", target_luck_rate)
			print("defense_luck_damage_rate: ", defense_luck_damage_rate)
			print("base_damage: ", base_damage)
			print("reduced_damage: ", reduced_damage)
			print("pre_random_damage: ", pre_random_damage)
			print("min_ratio: ", min_ratio)
			print("max_ratio: ", max_ratio)
			print("min_damage_raw: ", min_damage_raw)
			print("max_damage_raw: ", max_damage_raw)
			print("min_damage: ", max(1, int(floor(max(1.0, min_damage_raw)))))
			print("max_damage: ", max(1, int(ceil(max(1.0, max_damage_raw)))))
			print("final_damage: ", 0)
			print("accuracy_value: ", accuracy_value)
			print("evasion_value: ", evasion_value)
			print("final_hit_rate: ", final_hit_rate)
			print("underflow: ", underflow)
			print("underflow_accuracy_penalty: ", underflow_accuracy_penalty)
			print("underflow_evasion_bonus: ", underflow_evasion_bonus)
			print("----------------------------")

		return {
			"hit": false,
			"dodged": true,
			"is_critical": false,
			"final_damage": 0,
			"base_damage": max(1, int(round(pre_random_damage))),
			"min_damage": max(1, int(floor(max(1.0, min_damage_raw)))),
			"max_damage": max(1, int(ceil(max(1.0, max_damage_raw)))),
			"hit_rate": final_hit_rate,
			"crit_rate": crit_rate,
			"element_rate": element_rate,
			"attacker_luck_rate": attacker_luck_rate,
			"target_luck_rate": target_luck_rate,
			"defense_luck_damage_rate": defense_luck_damage_rate,
			"underflow": underflow,
			"underflow_accuracy_penalty": underflow_accuracy_penalty,
			"underflow_evasion_bonus": underflow_evasion_bonus,
			"reason": "dodged"
		}

	# 10. 最終ダメージをレンジから抽選
	var min_damage = max(1, int(floor(min_damage_raw)))
	var max_damage = max(min_damage, int(ceil(max_damage_raw)))

	var final_damage = randi_range(min_damage, max_damage)

	if DebugSettings.debug_damage_calculate:
		print("----- Damage Calculate -----")
		print("phase: ", "hit")
		print("attacker: ", attacker.name)
		print("target: ", target.name)
		print("total_attack: ", total_attack)
		print("total_defense: ", total_defense)
		print("effective_attack: ", effective_attack)
		print("effective_defense: ", effective_defense)
		print("power: ", power)
		print("element: ", element)
		print("element_rate: ", element_rate)
		print("crit_rate: ", crit_rate)
		print("is_critical: ", is_critical)
		print("crit_damage_rate: ", crit_damage_rate)
		print("attacker_luck: ", attacker_luck)
		print("target_luck: ", target_luck)
		print("attacker_luck_rate: ", attacker_luck_rate)
		print("target_luck_rate: ", target_luck_rate)
		print("defense_luck_damage_rate: ", defense_luck_damage_rate)
		print("base_damage: ", base_damage)
		print("reduced_damage: ", reduced_damage)
		print("pre_random_damage: ", pre_random_damage)
		print("min_ratio: ", min_ratio)
		print("max_ratio: ", max_ratio)
		print("min_damage_raw: ", min_damage_raw)
		print("max_damage_raw: ", max_damage_raw)
		print("min_damage: ", min_damage)
		print("max_damage: ", max_damage)
		print("final_damage: ", final_damage)
		print("accuracy_value: ", accuracy_value)
		print("evasion_value: ", evasion_value)
		print("final_hit_rate: ", final_hit_rate)
		print("underflow: ", underflow)
		print("underflow_accuracy_penalty: ", underflow_accuracy_penalty)
		print("underflow_evasion_bonus: ", underflow_evasion_bonus)
		print("----------------------------")

	return {
		"hit": true,
		"dodged": false,
		"is_critical": is_critical,
		"final_damage": final_damage,
		"base_damage": max(1, int(round(pre_random_damage))),
		"min_damage": min_damage,
		"max_damage": max_damage,
		"hit_rate": final_hit_rate,
		"crit_rate": crit_rate,
		"element_rate": element_rate,
		"attacker_luck_rate": attacker_luck_rate,
		"target_luck_rate": target_luck_rate,
		"defense_luck_damage_rate": defense_luck_damage_rate,
		"underflow": underflow,
		"underflow_accuracy_penalty": underflow_accuracy_penalty,
		"underflow_evasion_bonus": underflow_evasion_bonus,
		"reason": "ok"
	}


func _compress_luck(luck: int) -> float:
	var value = max(0, luck)
	return float(value) / float(value + 100.0)


func _get_effective_attack(stats) -> float:
	if stats == null:
		return 0.0

	if stats.has_method("get_effective_attack"):
		return float(stats.get_effective_attack())

	if "attack" in stats:
		return float(stats.attack)

	return 0.0


func _get_effective_defense(stats) -> float:
	if stats == null:
		return 0.0

	if stats.has_method("get_effective_defense"):
		return float(stats.get_effective_defense())

	if "defense" in stats:
		return float(stats.defense)

	return 0.0


func _get_attacker_accuracy(attacker, attacker_stats) -> float:
	if attacker != null and attacker.has_method("get_total_accuracy"):
		return float(attacker.get_total_accuracy())
	return _get_effective_accuracy(attacker_stats)


func _get_target_evasion(target, target_stats) -> float:
	if target != null and target.has_method("get_total_evasion"):
		return float(target.get_total_evasion())
	return _get_effective_evasion(target_stats)


func _get_attacker_crit_rate(attacker, attacker_stats) -> float:
	if attacker != null and attacker.has_method("get_total_crit_rate"):
		return float(attacker.get_total_crit_rate())
	return _get_effective_crit_rate(attacker_stats)


func _get_attacker_crit_damage(attacker, attacker_stats) -> float:
	if attacker != null and attacker.has_method("get_total_crit_damage"):
		return float(attacker.get_total_crit_damage())
	return _get_crit_damage(attacker_stats)


func _get_attacker_luck(attacker, attacker_stats) -> int:
	if attacker != null and attacker.has_method("get_total_luck"):
		return int(attacker.get_total_luck())
	return _get_luck(attacker_stats)


func _get_target_luck(target, target_stats) -> int:
	if target != null and target.has_method("get_total_luck"):
		return int(target.get_total_luck())
	return _get_luck(target_stats)


func _get_effective_accuracy(stats) -> float:
	if stats == null:
		return 1.0

	if stats.has_method("get_effective_accuracy"):
		return float(stats.get_effective_accuracy())

	if "accuracy" in stats:
		return clamp(float(stats.accuracy), 0.0, 1.0)

	return 1.0


func _get_effective_evasion(stats) -> float:
	if stats == null:
		return 0.0

	if stats.has_method("get_effective_evasion"):
		return float(stats.get_effective_evasion())

	if "evasion" in stats:
		return clamp(float(stats.evasion), 0.0, 1.0)

	return 0.0


func _get_effective_crit_rate(stats) -> float:
	if stats == null:
		return 0.0

	if stats.has_method("get_effective_crit_rate"):
		return float(stats.get_effective_crit_rate())

	if "crit_rate" in stats:
		return clamp(float(stats.crit_rate), 0.0, 1.0)

	return 0.0


func _get_crit_damage(stats) -> float:
	if stats == null:
		return 1.5

	if "crit_damage" in stats:
		return max(1.0, float(stats.crit_damage))

	return 1.5


func _get_luck(stats) -> int:
	if stats == null:
		return 0

	if "luck" in stats:
		return int(stats.luck)

	return 0


func _get_element_rate(stats, attacking_element: String) -> float:
	if stats == null:
		return 1.0

	if attacking_element == "" or attacking_element == "neutral":
		return 1.0

	if stats.has_method("get_element_rate"):
		return float(stats.get_element_rate(attacking_element))

	if "element_resistances" in stats:
		var resistances = stats.element_resistances
		if resistances is Dictionary and resistances.has(attacking_element):
			return float(resistances[attacking_element])

	return 1.0


func _make_result(
	hit: bool,
	dodged: bool,
	is_critical: bool,
	final_damage: int,
	hit_rate: float,
	crit_rate: float,
	element_rate: float,
	attacker_luck_rate: float,
	target_luck_rate: float,
	defense_luck_damage_rate: float,
	reason: String
) -> Dictionary:
	return {
		"hit": hit,
		"dodged": dodged,
		"is_critical": is_critical,
		"final_damage": final_damage,
		"hit_rate": hit_rate,
		"crit_rate": crit_rate,
		"element_rate": element_rate,
		"attacker_luck_rate": attacker_luck_rate,
		"target_luck_rate": target_luck_rate,
		"defense_luck_damage_rate": defense_luck_damage_rate,
		"reason": reason
	}
