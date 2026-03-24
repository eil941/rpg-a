extends BaseDungeonGenerator
class_name CaveDungeonGenerator

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

	# 1. 初期生成
	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				row.append(TILE_WALL)
			else:
				if randf() < 0.43:
					row.append(TILE_WALL)
				else:
					row.append(TILE_FLOOR)
		tile_result.append(row)

	# 2. 平滑化
	for i in range(5):
		_smooth_map()

	# 3. 戻る階段を置く
	var return_cell = _find_random_floor_cell()
	if return_cell.x != -1:
		tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	# 4. 次へ進む階段を置く
	if not is_bottom_floor:
		var next_cell = _find_random_floor_cell_far_from(return_cell, 10)
		if next_cell.x == -1:
			next_cell = _find_random_floor_cell()

		if next_cell.x != -1 and next_cell != return_cell:
			tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	# 5. 描画
	_draw_map(ground_layer, wall_layer, event_layer)


func _smooth_map() -> void:
	var new_map: Array = []

	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			var wall_count = _count_wall_neighbors(x, y)

			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				row.append(TILE_WALL)
			elif wall_count >= 5:
				row.append(TILE_WALL)
			else:
				row.append(TILE_FLOOR)
		new_map.append(row)

	tile_result = new_map


func _count_wall_neighbors(x: int, y: int) -> int:
	var count = 0

	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx = x + dx
			var ny = y + dy

			if nx < 0 or ny < 0 or nx >= map_width or ny >= map_height:
				count += 1
			elif tile_result[ny][nx] == TILE_WALL:
				count += 1

	return count


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
