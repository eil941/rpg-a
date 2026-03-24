extends BaseDungeonGenerator
class_name MazeDungeonGenerator

func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer,
	is_bottom_floor: bool
) -> void:
	ground_layer.clear()
	wall_layer.clear()
	event_layer.clear()

	tile_result.clear()
	randomize()

	# 全部壁
	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(TILE_WALL)
		tile_result.append(row)

	# 開始地点
	var start = Vector2i(1, 1)
	tile_result[start.y][start.x] = TILE_FLOOR

	_carve_maze_from(start)

	# 戻る階段
	var return_cell = _find_random_floor_cell()
	if return_cell.x != -1:
		tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	# 次へ進む階段
	if not is_bottom_floor:
		var next_cell = _find_random_floor_cell_far_from(return_cell, 10)
		if next_cell.x == -1:
			next_cell = _find_random_floor_cell()

		if next_cell.x != -1 and next_cell != return_cell:
			tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


func _carve_maze_from(start: Vector2i) -> void:
	var stack: Array = [start]
	var directions = [
		Vector2i(2, 0),
		Vector2i(-2, 0),
		Vector2i(0, 2),
		Vector2i(0, -2)
	]

	while not stack.is_empty():
		var current: Vector2i = stack[stack.size() - 1]
		var neighbors: Array = []

		for dir in directions:
			var next = current + dir

			if next.x <= 0 or next.y <= 0 or next.x >= map_width - 1 or next.y >= map_height - 1:
				continue

			if tile_result[next.y][next.x] == TILE_WALL:
				neighbors.append(next)

		if neighbors.is_empty():
			stack.pop_back()
			continue

		var chosen: Vector2i = neighbors[randi_range(0, neighbors.size() - 1)]
		var between = Vector2i(
			(current.x + chosen.x) / 2,
			(current.y + chosen.y) / 2
		)

		tile_result[between.y][between.x] = TILE_FLOOR
		tile_result[chosen.y][chosen.x] = TILE_FLOOR
		stack.append(chosen)


func _find_random_floor_cell() -> Vector2i:
	var candidates: Array = []

	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if tile_result[y][x] == TILE_FLOOR:
				candidates.append(Vector2i(x, y))

	if candidates.is_empty():
		return Vector2i(-1, -1)

	return candidates[randi_range(0, candidates.size() - 1)]


func _find_random_floor_cell_far_from(base_cell: Vector2i, min_dist: int) -> Vector2i:
	var candidates: Array = []

	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if tile_result[y][x] != TILE_FLOOR:
				continue

			var cell = Vector2i(x, y)
			if cell.distance_to(base_cell) >= min_dist:
				candidates.append(cell)

	if candidates.is_empty():
		return Vector2i(-1, -1)

	return candidates[randi_range(0, candidates.size() - 1)]


func _draw_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	for y in range(map_height):
		for x in range(map_width):
			var cell = Vector2i(x, y)
			var tile = tile_result[y][x]

			match tile:
				TILE_WALL:
					ground_layer.set_cell(cell, 6, Vector2i(1, 4), 0)
					wall_layer.set_cell(cell, 5, Vector2i(0, 0), 0)

				TILE_FLOOR:
					ground_layer.set_cell(cell, 29, Vector2i(1, 4), 0)

				TILE_RETURN:
					ground_layer.set_cell(cell, 3, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 3, Vector2i(0, 0), 0)

				TILE_NEXT:
					ground_layer.set_cell(cell, 6, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 6, Vector2i(0, 0), 0)
