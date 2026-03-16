extends Node

func try_bump_attack(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	if not attacker.can_bump_attack:
		return false

	if not target.is_enemy:
		return false

	var damage = DamageCalculator.calculate_damage(attacker, target)
	if damage <= 0:
		return false

	target.stats.take_damage(damage)
	print("攻撃ダメージ: ", damage)

	return true
