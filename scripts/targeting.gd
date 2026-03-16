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
