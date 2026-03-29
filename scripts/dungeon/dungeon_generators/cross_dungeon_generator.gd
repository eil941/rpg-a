extends BaseDungeonGenerator
class_name CrossDungeonGenerator

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

	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(TILE_WALL)
		tile_result.append(row)

	var center_x = map_width / 2
	var center_y = map_height / 2
	var corridor_half = 1

	# 十字通路
	for y in range(1, map_height - 1):
		for dx in range(-corridor_half, corridor_half + 1):
			var xx = center_x + dx
			if xx > 0 and xx < map_width - 1:
				tile_result[y][xx] = TILE_FLOOR

	for x in range(1, map_width - 1):
		for dy in range(-corridor_half, corridor_half + 1):
			var yy = center_y + dy
			if yy > 0 and yy < map_height - 1:
				tile_result[yy][x] = TILE_FLOOR

	# 四隅の部屋
	_carve_room(Rect2i(2, 2, 6, 6))
	_carve_room(Rect2i(map_width - 8, 2, 6, 6))
	_carve_room(Rect2i(2, map_height - 8, 6, 6))
	_carve_room(Rect2i(map_width - 8, map_height - 8, 6, 6))

	# 十字と部屋をつなぐ
	_carve_corridor(Vector2i(5, 5), Vector2i(center_x, center_y))
	_carve_corridor(Vector2i(map_width - 5, 5), Vector2i(center_x, center_y))
	_carve_corridor(Vector2i(5, map_height - 5), Vector2i(center_x, center_y))
	_carve_corridor(Vector2i(map_width - 5, map_height - 5), Vector2i(center_x, center_y))

	# 少し枝道を追加
	_add_side_branches()

	var return_cell = Vector2i(5, 5)
	tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	if not is_bottom_floor:
		var next_cell = Vector2i(map_width - 5, map_height - 5)
		if next_cell != return_cell:
			tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			tile_result[y][x] = TILE_FLOOR


func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var x = a.x
	var y = a.y

	while x != b.x:
		tile_result[y][x] = TILE_FLOOR
		if b.x > x:
			x += 1
		else:
			x -= 1

	while y != b.y:
		tile_result[y][x] = TILE_FLOOR
		if b.y > y:
			y += 1
		else:
			y -= 1

	tile_result[b.y][b.x] = TILE_FLOOR


func _add_side_branches() -> void:
	for i in range(6):
		var start_x = randi_range(3, map_width - 4)
		var start_y = randi_range(3, map_height - 4)

		if tile_result[start_y][start_x] != TILE_FLOOR:
			continue

		var length = randi_range(2, 5)
		var dir = [
			Vector2i(1, 0),
			Vector2i(-1, 0),
			Vector2i(0, 1),
			Vector2i(0, -1)
		][randi_range(0, 3)]

		var x = start_x
		var y = start_y

		for j in range(length):
			x += dir.x
			y += dir.y

			if x <= 1 or y <= 1 or x >= map_width - 2 or y >= map_height - 2:
				break

			tile_result[y][x] = TILE_FLOOR


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
