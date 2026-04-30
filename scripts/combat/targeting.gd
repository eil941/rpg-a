extends Node


func get_unit_on_tile(units_node: Node, tile: Vector2i, self_unit):
	if units_node == null:
		return null

	for other in units_node.get_children():
		if other == null:
			continue
		if other == self_unit:
			continue
		if not other.has_method("get_occupied_tile_coords"):
			continue

		if other.get_occupied_tile_coords() == tile:
			return other

	return null


func is_hostile(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	if unit_a == unit_b:
		return false

	return FactionManager.are_units_hostile(unit_a, unit_b)


func is_friendly(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	if unit_a == unit_b:
		return false

	return FactionManager.are_units_friendly(unit_a, unit_b)


func is_neutral(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	if unit_a == unit_b:
		return false

	return FactionManager.are_units_neutral(unit_a, unit_b)


func get_distance_between_tiles(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func get_distance_between_units(unit_a, unit_b) -> int:
	if unit_a == null or unit_b == null:
		return 999999

	return get_distance_between_tiles(
		unit_a.get_occupied_tile_coords(),
		unit_b.get_occupied_tile_coords()
	)


func is_unit_alive(unit) -> bool:
	if unit == null:
		return false
	if not unit.has_node("Stats"):
		return false
	return unit.stats != null and int(unit.stats.hp) > 0


func get_units_in_radius(
	units_node: Node,
	center_unit,
	min_range: int,
	max_range: int,
	include_hostile: bool = true,
	include_neutral: bool = false,
	include_friendly: bool = false
) -> Array:
	var result: Array = []

	if units_node == null or center_unit == null:
		return result

	min_range = max(0, min_range)
	max_range = max(min_range, max_range)

	for other in units_node.get_children():
		if other == null:
			continue
		if other == center_unit:
			continue
		if not is_unit_alive(other):
			continue
		if not other.has_method("get_occupied_tile_coords"):
			continue

		var dist: int = get_distance_between_units(center_unit, other)
		if dist < min_range or dist > max_range:
			continue

		if is_hostile(center_unit, other):
			if include_hostile:
				result.append(other)
			continue

		if is_neutral(center_unit, other):
			if include_neutral:
				result.append(other)
			continue

		if is_friendly(center_unit, other):
			if include_friendly:
				result.append(other)
			continue

	return result


func get_hostile_units_in_radius(units_node: Node, attacker, min_range: int, max_range: int) -> Array:
	return get_units_in_radius(units_node, attacker, min_range, max_range, true, false, false)


func get_nearest_hostile_unit(units_node: Node, self_unit, max_range: int):
	if units_node == null or self_unit == null:
		return null

	var candidates: Array = get_hostile_units_in_radius(units_node, self_unit, 1, max_range)
	return get_nearest_to_unit(candidates, self_unit)


func get_hostile_units_in_attack_range(units_node: Node, attacker) -> Array:
	if attacker == null:
		return []

	return get_hostile_units_in_radius(
		units_node,
		attacker,
		attacker.get_attack_min_range(),
		attacker.get_attack_max_range()
	)


func get_player_unit(units_node: Node):
	if units_node == null:
		return null

	for other in units_node.get_children():
		if other == null:
			continue
		if "is_player_unit" in other and bool(other.is_player_unit):
			return other

	return null


func get_nearest_to_unit(targets: Array, center_unit):
	if targets.is_empty():
		return null
	if center_unit == null:
		return targets[0]

	var best_target = null
	var best_distance: int = 999999
	var center_tile: Vector2i = center_unit.get_occupied_tile_coords()

	for target in targets:
		if target == null:
			continue
		if not target.has_method("get_occupied_tile_coords"):
			continue

		var dist: int = get_distance_between_tiles(center_tile, target.get_occupied_tile_coords())
		if dist < best_distance:
			best_distance = dist
			best_target = target

	return best_target


func get_nearest_to_player(targets: Array, units_node: Node):
	if targets.is_empty():
		return null

	var player = get_player_unit(units_node)
	if player == null:
		return targets[0]

	return get_nearest_to_unit(targets, player)


func get_forward_dir(unit) -> Vector2i:
	if unit == null:
		return Vector2i.ZERO

	match unit.facing:
		unit.Facing.RIGHT:
			return Vector2i.RIGHT
		unit.Facing.LEFT:
			return Vector2i.LEFT
		unit.Facing.DOWN:
			return Vector2i.DOWN
		unit.Facing.UP:
			return Vector2i.UP

	return Vector2i.ZERO


# 旧互換: 以前の「前方直線」攻撃用API。
# 現在の通常攻撃は周囲NマスのRADIUS判定を使うが、
# 既存コードが呼んでも壊れないように残しておく。
func get_hostile_units_in_forward_line(units_node: Node, attacker) -> Array:
	var result: Array = []

	if units_node == null or attacker == null:
		return result

	var origin: Vector2i = attacker.get_current_tile_coords()
	var forward: Vector2i = get_forward_dir(attacker)

	if forward == Vector2i.ZERO:
		return result

	var min_range: int = attacker.get_attack_min_range()
	var max_range: int = attacker.get_attack_max_range()

	for other in units_node.get_children():
		if other == null:
			continue
		if other == attacker:
			continue
		if not is_unit_alive(other):
			continue
		if not is_hostile(attacker, other):
			continue

		var other_tile: Vector2i = other.get_occupied_tile_coords()
		var diff: Vector2i = other_tile - origin

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
			continue
		if dist < min_range or dist > max_range:
			continue

		result.append(other)

	return result


func get_best_forward_line_hostile_target(units_node: Node, attacker):
	var targets: Array = get_hostile_units_in_forward_line(units_node, attacker)
	return get_nearest_to_player(targets, units_node)
