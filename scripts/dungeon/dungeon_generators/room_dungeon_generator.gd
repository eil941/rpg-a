extends BaseDungeonGenerator
class_name RoomDungeonGenerator

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

	var max_rooms = 12
	var min_room_size = 4
	var max_room_size = 8

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

		if not rooms.is_empty():
			var prev_room = rooms[rooms.size() - 1]
			var prev_center = _room_center(prev_room)
			var new_center = _room_center(new_room)
			_carve_corridor(prev_center, new_center)

		rooms.append(new_room)

	if rooms.size() >= 1:
		var first_room = rooms[0]
		var return_pos = _room_center(first_room)
		tile_result[return_pos.y][return_pos.x] = TILE_RETURN

	if not is_bottom_floor:
		if rooms.size() >= 2:
			var next_pos = _room_center(rooms[rooms.size() - 1])
			if tile_result[next_pos.y][next_pos.x] == TILE_RETURN:
				next_pos = _find_other_tile_in_room(rooms[rooms.size() - 1], next_pos)
			tile_result[next_pos.y][next_pos.x] = TILE_NEXT
		elif rooms.size() == 1:
			var only_room = rooms[0]
			var next_pos_single = Vector2i(
				only_room.position.x + only_room.size.x - 2,
				only_room.position.y + only_room.size.y - 2
			)

			if tile_result[next_pos_single.y][next_pos_single.x] == TILE_RETURN:
				next_pos_single = _find_other_tile_in_room(only_room, next_pos_single)

			tile_result[next_pos_single.y][next_pos_single.x] = TILE_NEXT

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

func _room_center(room: Rect2i) -> Vector2i:
	return Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)

func _find_other_tile_in_room(room: Rect2i, avoid_cell: Vector2i) -> Vector2i:
	for y in range(room.position.y + 1, room.position.y + room.size.y - 1):
		for x in range(room.position.x + 1, room.position.x + room.size.x - 1):
			var cell = Vector2i(x, y)
			if cell != avoid_cell:
				return cell

	return avoid_cell

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
