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

	target.notify_hud_log("%s に %d ダメージ" % [target.name, damage])

	if attacker != null and attacker.is_player_unit:
		attacker.notify_hud_player_status_refresh()

	if target != null and target.is_player_unit:
		target.notify_hud_player_status_refresh()

	return true


func is_target_in_attack_range(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	var dist = Targeting.get_distance_between_units(attacker, target)
	return dist >= attacker.get_attack_min_range() and dist <= attacker.get_attack_max_range()


func can_attack(attacker, target) -> bool:
	if attacker == null or target == null:
		return false
	if attacker == target:
		return false
	if not attacker.has_node("Stats"):
		return false
	if not target.has_node("Stats"):
		return false
	if attacker.stats.hp <= 0 or target.stats.hp <= 0:
		return false
	if not Targeting.is_hostile(attacker, target):
		return false
	if not is_target_in_attack_range(attacker, target):
		return false

	return true

func perform_attack(attacker, target) -> bool:
	if not can_attack(attacker, target):
		return false

	var damage = DamageCalculator.calculate_damage(attacker, target)
	if damage < 1:
		damage = 1

	target.stats.take_damage(damage)

	if attacker.has_method("notify_hud_log"):
		attacker.notify_hud_log("%s に %d ダメージ" % [target.name, damage])

	if attacker.is_player_unit:
		attacker.notify_hud_player_status_refresh()

	if target.is_player_unit:
		target.notify_hud_player_status_refresh()

	return true
