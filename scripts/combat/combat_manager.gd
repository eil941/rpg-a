extends Node



func uses_forward_line_targeting(attacker) -> bool:
	# 現在の通常攻撃範囲は「周囲Nマス」。
	# 前方直線専用の判定は使わない。
	return false


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


func is_target_in_forward_line_any(attacker, target) -> bool:
	if attacker == null or target == null:
		return false

	if not attacker.has_method("get_current_tile_coords"):
		return false
	if not target.has_method("get_occupied_tile_coords"):
		return false

	var origin: Vector2i = attacker.get_current_tile_coords()
	var target_tile: Vector2i = target.get_occupied_tile_coords()
	var forward: Vector2i = Targeting.get_forward_dir(attacker)

	if forward == Vector2i.ZERO:
		return false

	var diff: Vector2i = target_tile - origin
	var in_line: bool = false
	var dist: int = 999999

	if forward == Vector2i.RIGHT:
		in_line = diff.y == 0 and diff.x > 0
		dist = diff.x
	elif forward == Vector2i.LEFT:
		in_line = diff.y == 0 and diff.x < 0
		dist = -diff.x
	elif forward == Vector2i.DOWN:
		in_line = diff.x == 0 and diff.y > 0
		dist = diff.y
	elif forward == Vector2i.UP:
		in_line = diff.x == 0 and diff.y < 0
		dist = -diff.y

	if not in_line:
		return false

	return dist >= attacker.get_attack_min_range() and dist <= attacker.get_attack_max_range()


func get_attackable_targets(attacker) -> Array:
	var result: Array = []

	if attacker == null:
		return result
	if attacker.units_node == null:
		return result

	return Targeting.get_hostile_units_in_attack_range(attacker.units_node, attacker)


func get_best_attack_target(attacker):
	if attacker == null:
		return null
	if attacker.units_node == null:
		return null

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
	_wake_up_target_if_needed(target)

	if result["is_critical"]:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ（クリティカル）" % [attacker.name, target.name, damage])
	else:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ" % [attacker.name, target.name, damage])

	print("攻撃ダメージ: ", damage)

	_refresh_hud_status(attacker, target)
	return true


func can_attack(attacker, target, require_hostile: bool = true) -> bool:
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
	if attacker.has_method("is_action_blocked_by_status"):
		if attacker.is_action_blocked_by_status():
			return false

	if require_hostile and not Targeting.is_hostile(attacker, target):
		return false

	if not is_target_in_attack_range(attacker, target):
		return false

	return true


func perform_attack(attacker, target, require_hostile: bool = true) -> bool:
	if not can_attack(attacker, target, require_hostile):
		return false

	var force_hostile_after_attack: bool = _should_force_target_hostile(attacker, target, require_hostile)
	if force_hostile_after_attack:
		_make_target_hostile_to_attacker(attacker, target)

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
		if force_hostile_after_attack:
			_save_forced_hostility_state(target)
		_refresh_hud_status(attacker, target)
		return false

	var damage = int(result["final_damage"])
	if damage < 1:
		damage = 1

	target.stats.take_damage(damage)
	_wake_up_target_if_needed(target)

	if force_hostile_after_attack and is_instance_valid(target):
		_save_forced_hostility_state(target)

	if result["is_critical"]:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ（クリティカル）" % [attacker.name, target.name, damage])
	else:
		_log_attack_message(attacker, target, "%s の攻撃！ %s に %d ダメージ" % [attacker.name, target.name, damage])

	_refresh_hud_status(attacker, target)
	return true


func _should_force_target_hostile(attacker, target, require_hostile: bool) -> bool:
	if require_hostile:
		return false

	if attacker == null or target == null:
		return false

	if Targeting.is_hostile(attacker, target):
		return false

	if not ("is_player_unit" in attacker):
		return false

	return bool(attacker.is_player_unit)


func _make_target_hostile_to_attacker(attacker, target) -> void:
	if attacker == null or target == null:
		return

	if target.has_method("on_attacked_by_player"):
		target.on_attacked_by_player(attacker)
	else:
		if "faction" in target:
			target.faction = "ENEMY"

	if attacker.has_method("notify_hud_log"):
		attacker.notify_hud_log("%s は敵対した" % target.name)


func _save_forced_hostility_state(target) -> void:
	if target == null:
		return

	if target.has_method("save_persistent_stats"):
		target.save_persistent_stats()
		return

	if "unit_id" in target and String(target.unit_id) != "":
		if target.has_method("get_stats_data"):
			var data: Dictionary = target.get_stats_data()
			data["faction"] = String(target.faction)
			WorldState.unit_states[String(target.unit_id)] = data


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


func _wake_up_target_if_needed(target) -> void:
	if target == null:
		return
	if target.has_method("remove_status_effect"):
		target.remove_status_effect(&"sleep")
