extends Node

func calculate_damage(attacker, target) -> int:
	if attacker == null or target == null:
		return 0

	if not attacker.has_node("Stats"):
		return 0

	if not target.has_node("Stats"):
		return 0

	return max(1, attacker.stats.attack - target.stats.defense)
