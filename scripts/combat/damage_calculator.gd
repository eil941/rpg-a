extends Node

func calculate_damage(attacker, target) -> int:
	if attacker == null or target == null:
		return 0

	if not attacker.has_node("Stats"):
		return 0

	if not target.has_node("Stats"):
		return 0

	var attack_value = attacker.get_total_attack()
	var defense_value = target.get_total_defense()

	return max(1, attack_value - defense_value)
