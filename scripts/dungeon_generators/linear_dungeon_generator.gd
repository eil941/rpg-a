extends BaseDungeonGenerator
class_name LinearDungeonGenerator

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

	var room_count = 6
	var room_w = 5
	var room_h = 5
	var spacing = max(3, int((map_width - 4 - room_count * room_w) / max(1, room_count - 1)))

	var start_x = 2
	var center_y = map_height / 2 - room_h / 2

	for i in range(room_count):
		var rx = start_x + i * (room_w + spacing)
		if rx + room_w >= map_width - 1:
			break

		var ry = center_y + randi_range(-2, 2)
		ry = clampi(ry, 2, map_height - room_h - 2)

		var room = Rect2i(rx, ry, room_w, room_h)
		rooms.append(room)
		_carve_room(room)

	for i in range(rooms.size() - 1):
		var a = _room_center(rooms[i])
		var b = _room_center(rooms[i + 1])
		_carve_corridor(a, b)

	if rooms.size() > 0:
		var return_cell = _room_center(rooms[0])
		tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	if not is_bottom_floor and rooms.size() > 1:
		var next_cell = _room_center(rooms[rooms.size() - 1])
		tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			tile_result[y][x] = TILE_FLOOR


func _room_center(room: Rect2i) -> Vector2i:
	return Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)


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
