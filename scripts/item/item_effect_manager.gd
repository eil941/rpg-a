extends Node
class_name ItemEffectManager


static func apply_item_effect(owner_unit, item_id: String, target_unit = null, use_flag_override: int = -1) -> bool:
	var data = ItemDatabase.get_item_data(item_id)

	if data == null:
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sを使用した" % item_id)
		return true

	if not bool(data.usable):
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sは使用できない" % ItemDatabase.get_display_name(item_id))
		return false

	var item_name: String = String(data.display_name)
	var actual_target = target_unit
	if actual_target == null:
		actual_target = owner_unit

	# 新方式を優先
	if "effects" in data and data.effects is Array and not data.effects.is_empty():
		var success: bool = _apply_effect_list(owner_unit, actual_target, data, use_flag_override)

		if success:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)

			if owner_unit != null and owner_unit.has_method("notify_hud_player_status_refresh"):
				owner_unit.notify_hud_player_status_refresh()

			if actual_target != null and actual_target != owner_unit and actual_target.has_method("notify_hud_player_status_refresh"):
				actual_target.notify_hud_player_status_refresh()

		return success

	# 旧方式フォールバック
	var effect_type: int = int(data.effect_type)
	var effect_value: int = int(data.effect_value)

	match effect_type:
		ItemData.ItemEffectType.HEAL_HP:
			if actual_target != null:
				var target_stats = actual_target.get("stats")
				if target_stats != null:
					var max_hp: int = int(target_stats.max_hp)
					if actual_target.has_method("get_total_max_hp"):
						max_hp = int(actual_target.get_total_max_hp())

					target_stats.hp = min(max_hp, int(target_stats.hp) + effect_value)

					if owner_unit != null and owner_unit.has_method("notify_hud_log"):
						owner_unit.notify_hud_log("%sを使用した" % item_name)

					if owner_unit != null and owner_unit.has_method("notify_hud_player_status_refresh"):
						owner_unit.notify_hud_player_status_refresh()

					if actual_target != null and actual_target != owner_unit and actual_target.has_method("notify_hud_player_status_refresh"):
						actual_target.notify_hud_player_status_refresh()

					return true

			return false

		ItemData.ItemEffectType.LOG_ONLY:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true

		ItemData.ItemEffectType.NONE:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true

		_:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true


static func _apply_effect_list(owner_unit, target_unit, item_data, use_flag_override: int) -> bool:
	var applied_any: bool = false

	for effect in item_data.effects:
		if effect == null:
			continue

		var single_result: bool = _apply_single_effect(owner_unit, target_unit, item_data, effect, use_flag_override)
		applied_any = applied_any or single_result

	return applied_any


static func _apply_single_effect(owner_unit, target_unit, item_data, effect: ItemEffectData, use_flag_override: int) -> bool:
	match effect.effect_type:
		ItemEffectData.EffectType.RESTORE_HP:
			return _apply_restore_hp(target_unit, effect)

		ItemEffectData.EffectType.CURE_STATUS:
			return _apply_cure_status(target_unit, effect)

		ItemEffectData.EffectType.APPLY_STATUS:
			return _apply_status(target_unit, effect)

		ItemEffectData.EffectType.APPLY_BUFF:
			return _apply_buff(target_unit, effect)

		ItemEffectData.EffectType.TELEPORT_RANDOM:
			return _apply_teleport_random(target_unit, effect)

		ItemEffectData.EffectType.NONE:
			return true

		_:
			return false


static func _apply_restore_hp(target_unit, effect: ItemEffectData) -> bool:
	if target_unit == null:
		return false

	var stats = target_unit.get("stats")
	if stats == null:
		return false

	var max_hp: int = int(stats.max_hp)
	if target_unit.has_method("get_total_max_hp"):
		max_hp = int(target_unit.get_total_max_hp())

	match effect.value_mode:
		ItemEffectData.ValueMode.FLAT:
			var heal_amount: int = effect.power_min
			if effect.power_max > effect.power_min:
				heal_amount = randi_range(effect.power_min, effect.power_max)

			stats.hp = min(max_hp, int(stats.hp) + heal_amount)
			return true

		ItemEffectData.ValueMode.PERCENT:
			var percent_amount: int = int(round(float(max_hp) * effect.percent_value))
			stats.hp = min(max_hp, int(stats.hp) + max(1, percent_amount))
			return true

		ItemEffectData.ValueMode.FULL:
			stats.hp = max_hp
			return true

		_:
			return false


static func _apply_cure_status(target_unit, effect: ItemEffectData) -> bool:
	if target_unit == null:
		return false

	return UnitEffectRuntime.cure_status(target_unit, effect.status_id)


static func _apply_status(target_unit, effect: ItemEffectData) -> bool:
	if target_unit == null:
		return false

	return UnitEffectRuntime.apply_status(
		target_unit,
		effect.status_id,
		effect.duration_seconds,
		effect.status_power
	)


static func _apply_buff(target_unit, effect: ItemEffectData) -> bool:
	if target_unit == null:
		return false

	return UnitEffectRuntime.apply_buff(
		target_unit,
		effect.stat_name,
		effect.duration_seconds,
		effect.stat_flat,
		effect.stat_percent
	)


static func _apply_teleport_random(target_unit, effect: ItemEffectData) -> bool:
	if target_unit == null:
		return false

	var ground_layer = target_unit.get("ground_layer")
	if ground_layer == null:
		return false

	var wall_layer = target_unit.get("wall_layer")
	var units_node = target_unit.get("units_node")

	var used_cells: Array[Vector2i] = ground_layer.get_used_cells()
	if used_cells.is_empty():
		return false

	var current_cell: Vector2i = ground_layer.local_to_map(ground_layer.to_local(target_unit.global_position))
	var candidate_cells: Array[Vector2i] = []

	for cell in used_cells:
		if wall_layer != null and wall_layer.get_cell_source_id(cell) != -1:
			continue

		var distance: int = abs(cell.x - current_cell.x) + abs(cell.y - current_cell.y)
		if distance < effect.teleport_min_range:
			continue
		if effect.teleport_max_range > 0 and distance > effect.teleport_max_range:
			continue

		if _is_cell_occupied_by_other_unit(target_unit, units_node, ground_layer, cell):
			continue

		candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return false

	var dest_cell: Vector2i = candidate_cells[randi_range(0, candidate_cells.size() - 1)]
	var dest_global: Vector2 = ground_layer.to_global(ground_layer.map_to_local(dest_cell))

	target_unit.global_position = dest_global

	if target_unit.get("target_position") != null:
		target_unit.target_position = dest_global

	if target_unit.get("is_moving") != null:
		target_unit.is_moving = false

	if target_unit.get("repeat_timer") != null:
		target_unit.repeat_timer = 0.0

	return true


static func _is_cell_occupied_by_other_unit(target_unit, units_node, ground_layer, cell: Vector2i) -> bool:
	if target_unit == null:
		return false
	if units_node == null:
		return false
	if ground_layer == null:
		return false

	for other in units_node.get_children():
		if other == null:
			continue
		if other == target_unit:
			continue

		var other_cell: Vector2i = ground_layer.local_to_map(
			ground_layer.to_local(other.global_position)
		)
		if other_cell == cell:
			return true

	return false
