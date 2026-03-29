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
	return unit_a.faction != unit_b.faction

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
