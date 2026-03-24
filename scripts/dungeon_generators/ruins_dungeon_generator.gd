extends BaseDungeonGenerator
class_name RuinsDungeonGenerator

var rooms: Array = []

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
	rooms.clear()

	randomize()

	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(TILE_WALL)
		tile_result.append(row)

	var max_rooms = 10
	var min_room_size = 5
	var max_room_size = 9

	for i in range(max_rooms):
		var w = randi_range(min_room_size, max_room_size)
		var h = randi_range(min_room_size, max_room_size)
		var x = randi_range(1, map_width - w - 2)
		var y = randi_range(1, map_height - h - 2)

		var new_room = Rect2i(x, y, w, h)

		var overlaps = false
		for room in rooms:
			if _rooms_overlap(room, new_room):
				overlaps = true
				break

		if overlaps:
			continue

		_carve_room(new_room)
		_break_room_edges(new_room)

		if not rooms.is_empty():
			var prev_room = rooms[rooms.size() - 1]
			var prev_center = _room_center(prev_room)
			var new_center = _room_center(new_room)
			_carve_corridor(prev_center, new_center)

		rooms.append(new_room)

	_add_broken_pillars()
	_add_open_courtyard()

	if rooms.size() >= 1:
		var first_room = rooms[0]
		var return_pos = _room_center(first_room)
		tile_result[return_pos.y][return_pos.x] = TILE_RETURN

	if not is_bottom_floor:
		var next_pos = _find_floor_far_from(_room_center(rooms[0]), 10)
		if next_pos.x == -1:
			next_pos = _find_random_floor()

		if next_pos.x != -1 and tile_result[next_pos.y][next_pos.x] != TILE_RETURN:
			tile_result[next_pos.y][next_pos.x] = TILE_NEXT
		elif next_pos.x != -1:
			var other = _find_other_floor(next_pos)
			if other.x != -1:
				tile_result[other.y][other.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


func _rooms_overlap(a: Rect2i, b: Rect2i) -> bool:
	var expanded_a = Rect2i(
		a.position.x - 1,
		a.position.y - 1,
		a.size.x + 2,
		a.size.y + 2
	)
	return expanded_a.intersects(b)


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			tile_result[y][x] = TILE_FLOOR


func _break_room_edges(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			var on_edge = x == room.position.x or y == room.position.y or x == room.position.x + room.size.x - 1 or y == room.position.y + room.size.y - 1
			if not on_edge:
				continue

			if randf() < 0.18:
				tile_result[y][x] = TILE_WALL


func _add_broken_pillars() -> void:
	for y in range(2, map_height - 2):
		for x in range(2, map_width - 2):
			if tile_result[y][x] != TILE_FLOOR:
				continue

			var floor_neighbors = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if tile_result[y + dy][x + dx] == TILE_FLOOR:
						floor_neighbors += 1

			if floor_neighbors >= 7 and randf() < 0.035:
				tile_result[y][x] = TILE_WALL


func _add_open_courtyard() -> void:
	if randf() < 0.5:
		return

	var w = randi_range(5, 8)
	var h = randi_range(5, 8)
	var x = randi_range(2, map_width - w - 3)
	var y = randi_range(2, map_height - h - 3)

	for yy in range(y, y + h):
		for xx in range(x, x + w):
			tile_result[yy][xx] = TILE_FLOOR


func _room_center(room: Rect2i) -> Vector2i:
	return Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)


func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var x = a.x
	var y = a.y

	if randf() < 0.5:
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
	else:
		while y != b.y:
			tile_result[y][x] = TILE_FLOOR
			if b.y > y:
				y += 1
			else:
				y -= 1

		while x != b.x:
			tile_result[y][x] = TILE_FLOOR
			if b.x > x:
				x += 1
			else:
				x -= 1

	tile_result[b.y][b.x] = TILE_FLOOR


func _find_random_floor() -> Vector2i:
	var cells: Array = []

	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if tile_result[y][x] == TILE_FLOOR:
				cells.append(Vector2i(x, y))

	if cells.is_empty():
		return Vector2i(-1, -1)

	return cells[randi_range(0, cells.size() - 1)]


func _find_floor_far_from(base_cell: Vector2i, min_dist: int) -> Vector2i:
	var cells: Array = []

	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if tile_result[y][x] != TILE_FLOOR:
				continue

			var cell = Vector2i(x, y)
			if cell.distance_to(base_cell) >= min_dist:
				cells.append(cell)

	if cells.is_empty():
		return Vector2i(-1, -1)

	return cells[randi_range(0, cells.size() - 1)]


func _find_other_floor(avoid_cell: Vector2i) -> Vector2i:
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			var cell = Vector2i(x, y)
			if cell == avoid_cell:
				continue
			if tile_result[y][x] == TILE_FLOOR:
				return cell

	return Vector2i(-1, -1)


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
