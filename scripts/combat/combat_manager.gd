extends Node



func uses_forward_line_targeting(attacker) -> bool:
	if attacker == null:
		return false

	return attacker.get_attack_max_range() > 1


func is_target_in_attack_range(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	var dist = Targeting.get_distance_between_units(attacker, target)
	return dist >= attacker.get_attack_min_range() and dist <= attacker.get_attack_max_range()


func is_target_in_forward_line(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	var candidates = Targeting.get_hostile_units_in_forward_line(attacker.units_node, attacker)
	return candidates.has(target)


func get_attackable_targets(attacker) -> Array:
	var result: Array = []

	if attacker == null:
		return result
	if attacker.units_node == null:
		return result

	if uses_forward_line_targeting(attacker):
		return Targeting.get_hostile_units_in_forward_line(attacker.units_node, attacker)

	return Targeting.get_hostile_units_in_attack_range(attacker.units_node, attacker)


func get_best_attack_target(attacker):
	if attacker == null:
		return null
	if attacker.units_node == null:
		return null

	if uses_forward_line_targeting(attacker):
		return Targeting.get_best_forward_line_hostile_target(attacker.units_node, attacker)

	var candidates = Targeting.get_hostile_units_in_attack_range(attacker.units_node, attacker)
	return Targeting.get_nearest_to_player(candidates, attacker.units_node)


func try_bump_attack(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	if not attacker.can_bump_attack:
		return false

	if not can_attack(attacker, target):
		return false

	var result = DamageCalculator.calculate_damage(attacker, target)

	if not result["hit"]:
		_log_attack_message(attacker, target, "%s の攻撃は %s に回避された" % [attacker.name, target.name])
		_refresh_hud_status(attacker, target)
		return false

	var damage = int(result["final_damage"])
	if damage < 1:
		damage = 1

	target.stats.take_damage(damage)

	if result["is_critical"]:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ（クリティカル）" % [attacker.name, target.name, damage])
	else:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ" % [attacker.name, target.name, damage])

	print("攻撃ダメージ: ", damage)

	_refresh_hud_status(attacker, target)
	return true


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

	if uses_forward_line_targeting(attacker):
		if not is_target_in_forward_line(attacker, target):
			return false

	return true


func perform_attack(attacker, target) -> bool:
	if not can_attack(attacker, target):
		return false

	# 近接だけ向きを合わせる
	if not uses_forward_line_targeting(attacker):
		if attacker.has_method("update_facing_only"):
			var my_tile = attacker.get_current_tile_coords()
			var target_tile = target.get_current_tile_coords()
			var diff = target_tile - my_tile

			if abs(diff.x) > abs(diff.y):
				if diff.x > 0:
					attacker.update_facing_only(Vector2.RIGHT)
				elif diff.x < 0:
					attacker.update_facing_only(Vector2.LEFT)
			else:
				if diff.y > 0:
					attacker.update_facing_only(Vector2.DOWN)
				elif diff.y < 0:
					attacker.update_facing_only(Vector2.UP)

	var result = DamageCalculator.calculate_damage(attacker, target)

	if not result["hit"]:
		_log_attack_message(attacker, target, "%s の攻撃は %s に回避された" % [attacker.name, target.name])
		_refresh_hud_status(attacker, target)
		return false

	var damage = int(result["final_damage"])
	if damage < 1:
		damage = 1

	target.stats.take_damage(damage)

	if result["is_critical"]:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ（クリティカル）" % [attacker.name, target.name, damage])
	else:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ" % [attacker.name, target.name, damage])

	_refresh_hud_status(attacker, target)
	return true


func _log_attack_message(attacker, target, message: String) -> void:
	if attacker != null and attacker.has_method("notify_hud_log"):
		attacker.notify_hud_log(message)
		return

	if target != null and target.has_method("notify_hud_log"):
		target.notify_hud_log(message)


func _refresh_hud_status(attacker, target) -> void:
	if attacker != null and attacker.is_player_unit:
		attacker.notify_hud_player_status_refresh()

	if target != null and target.is_player_unit:
		target.notify_hud_player_status_refresh()
