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


func can_perform_selected_target_action(user, target) -> bool:
	if _get_selected_target_item_data(user) != null:
		return can_use_selected_target_item(user, target)

	if _is_selected_hotbar_non_target_item_blocking_attack(user):
		return false

	return can_attack(user, target, true)


func perform_selected_target_action(user, target) -> bool:
	if _get_selected_target_item_data(user) != null:
		return perform_selected_target_item_use(user, target)

	if _is_selected_hotbar_non_target_item_blocking_attack(user):
		if user != null and user.has_method("notify_hud_log"):
			user.notify_hud_log("選択中のアイテムは対象に使えません")
		return false

	return perform_attack(user, target, true)


func _get_selected_target_item_data(user) -> ItemData:
	if user == null:
		return null

	if user.has_method("get_selected_target_item_data"):
		return user.get_selected_target_item_data()

	return null

func _is_selected_hotbar_non_target_item_blocking_attack(user) -> bool:
	if user == null:
		return false

	if user.has_method("is_selected_hotbar_non_target_item_blocking_attack"):
		return bool(user.is_selected_hotbar_non_target_item_blocking_attack())

	return false



func can_use_selected_target_item(user, target) -> bool:
	if user == null or target == null:
		return false
	if not user.has_node("Stats"):
		return false
	if not target.has_node("Stats"):
		return false
	if user.stats.hp <= 0 or target.stats.hp <= 0:
		return false
	if user.has_method("is_action_blocked_by_status"):
		if user.is_action_blocked_by_status():
			return false

	var item_data: ItemData = _get_selected_target_item_data(user)
	if item_data == null:
		return false

	if item_data.effects.is_empty():
		return false

	if not _is_target_allowed_for_item(user, target, item_data):
		return false

	if not _is_target_in_selected_item_range(user, target):
		return false

	return true


func perform_selected_target_item_use(user, target) -> bool:
	if not can_use_selected_target_item(user, target):
		return false

	var item_data: ItemData = _get_selected_target_item_data(user)
	if item_data == null:
		return false

	var item_name: String = String(item_data.display_name)
	if item_name == "":
		item_name = String(item_data.item_id)

	var hit: bool = true
	if user != target:
		hit = _roll_target_item_hit(user, target)
	var consumed: bool = _consume_selected_target_item(user)

	if not hit:
		_log_attack_message(user, target, "%s は %s を使ったが、%s は回避した" % [user.name, item_name, target.name])
		_refresh_hud_status(user, target)
		return consumed

	var applied: bool = ItemEffectManager.apply_item_effect(user, target, item_data)

	if applied:
		_wake_up_target_if_needed(target)
		_log_attack_message(user, target, "%s は %s に %s を使った" % [user.name, target.name, item_name])
	else:
		_log_attack_message(user, target, "%s は %s に %s を使ったが、効果がなかった" % [user.name, target.name, item_name])

	_refresh_hud_status(user, target)
	return consumed or applied


func _consume_selected_target_item(user) -> bool:
	if user == null:
		return false

	if user.has_method("consume_selected_hotbar_target_item"):
		return bool(user.consume_selected_hotbar_target_item(1))

	var inv = null
	if "inventory" in user:
		inv = user.inventory

	if inv != null and inv.has_method("consume_selected_hotbar_item_for_target_action"):
		return bool(inv.consume_selected_hotbar_item_for_target_action(1))

	return false


func _is_target_in_selected_item_range(user, target) -> bool:
	# 自分自身への対象指定使用は、距離0として常に射程内扱いにする。
	# TARGET_SELF の可否は _is_target_allowed_for_item() 側で判定する。
	if user == target:
		return true

	var dist: int = Targeting.get_distance_between_units(user, target)
	var min_range: int = 1
	var max_range: int = 5

	if user.has_method("get_target_item_use_min_range"):
		min_range = int(user.get_target_item_use_min_range())
	if user.has_method("get_target_item_use_max_range"):
		max_range = int(user.get_target_item_use_max_range())

	min_range = max(0, min_range)
	max_range = max(min_range, max_range)

	return dist >= min_range and dist <= max_range


func _is_target_allowed_for_item(user, target, item_data: ItemData) -> bool:
	if item_data == null:
		return false

	if target == user:
		return item_data.has_target_flag(ItemData.ItemTargetFlag.TARGET_SELF)

	if Targeting.is_hostile(user, target):
		return item_data.has_target_flag(ItemData.ItemTargetFlag.TARGET_ENEMY)

	if _are_units_friendly(user, target):
		return item_data.has_target_flag(ItemData.ItemTargetFlag.TARGET_ALLY)

	return item_data.has_target_flag(ItemData.ItemTargetFlag.TARGET_NEUTRAL)


func _are_units_friendly(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	if unit_a == unit_b:
		return true

	if FactionManager != null and FactionManager.has_method("are_units_friendly"):
		return bool(FactionManager.are_units_friendly(unit_a, unit_b))

	if "faction" in unit_a and "faction" in unit_b:
		return String(unit_a.faction).to_upper() == String(unit_b.faction).to_upper()

	return false


func _roll_target_item_hit(user, target) -> bool:
	var hit_chance: float = 0.9

	if user != null and user.has_method("get_total_accuracy"):
		hit_chance = float(user.get_total_accuracy())

	if target != null and target.has_method("get_total_evasion"):
		hit_chance -= float(target.get_total_evasion())

	var user_luck: int = 0
	var target_luck: int = 0
	if user != null and user.has_method("get_total_luck"):
		user_luck = int(user.get_total_luck())
	if target != null and target.has_method("get_total_luck"):
		target_luck = int(target.get_total_luck())

	hit_chance += float(user_luck - target_luck) * 0.001
	hit_chance = clamp(hit_chance, 0.05, 0.95)

	return randf() <= hit_chance



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
