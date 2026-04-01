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


func get_distance_between_tiles(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func get_distance_between_units(unit_a, unit_b) -> int:
	if unit_a == null or unit_b == null:
		return 999999

	return get_distance_between_tiles(
		unit_a.get_occupied_tile_coords(),
		unit_b.get_occupied_tile_coords()
	)


func get_nearest_hostile_unit(units_node: Node, self_unit, max_range: int):
	if units_node == null or self_unit == null:
		return null

	var best_target = null
	var best_distance = 999999

	for other in units_node.get_children():
		if other == null:
			continue
		if other == self_unit:
			continue
		if not other.has_node("Stats"):
			continue
		if other.stats.hp <= 0:
			continue
		if not is_hostile(self_unit, other):
			continue

		var dist = get_distance_between_units(self_unit, other)
		if dist > max_range:
			continue

		if dist < best_distance:
			best_distance = dist
			best_target = other

	return best_target


func get_hostile_units_in_attack_range(units_node: Node, attacker) -> Array:
	var result: Array = []

	if units_node == null or attacker == null:
		return result

	for other in units_node.get_children():
		if other == null:
			continue
		if other == attacker:
			continue
		if not other.has_node("Stats"):
			continue
		if other.stats.hp <= 0:
			continue
		if not is_hostile(attacker, other):
			continue

		var dist = get_distance_between_units(attacker, other)
		if dist < attacker.get_attack_min_range():
			continue
		if dist > attacker.get_attack_max_range():
			continue

		result.append(other)

	return result


func get_player_unit(units_node: Node):
	if units_node == null:
		return null

	for other in units_node.get_children():
		if other == null:
			continue
		if other.is_player_unit:
			return other

	return null


func get_nearest_to_player(targets: Array, units_node: Node):
	if targets.is_empty():
		return null

	var player = get_player_unit(units_node)
	if player == null:
		return targets[0]

	var best_target = null
	var best_distance = 999999
	var player_tile = player.get_occupied_tile_coords()

	for target in targets:
		if target == null:
			continue

		var dist = get_distance_between_tiles(
			player_tile,
			target.get_occupied_tile_coords()
		)

		if dist < best_distance:
			best_distance = dist
			best_target = target

	return best_target


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


func get_hostile_units_in_forward_line(units_node: Node, attacker) -> Array:
	var result: Array = []

	if units_node == null or attacker == null:
		return result

	var origin = attacker.get_current_tile_coords()
	var forward = get_forward_dir(attacker)

	if forward == Vector2i.ZERO:
		return result

	var min_range = attacker.get_attack_min_range()
	var max_range = attacker.get_attack_max_range()

	for other in units_node.get_children():
		if other == null:
			continue
		if other == attacker:
			continue
		if not other.has_node("Stats"):
			continue
		if other.stats.hp <= 0:
			continue
		if not is_hostile(attacker, other):
			continue

		var other_tile = other.get_occupied_tile_coords()
		var diff = other_tile - origin

		var in_line := false
		var dist := 999999

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
	var targets = get_hostile_units_in_forward_line(units_node, attacker)
	return get_nearest_to_player(targets, units_node)
