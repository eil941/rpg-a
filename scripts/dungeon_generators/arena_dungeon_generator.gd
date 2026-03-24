extends BaseDungeonGenerator
class_name ArenaDungeonGenerator

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

	var room_margin_x = 3
	var room_margin_y = 3

	for y in range(room_margin_y, map_height - room_margin_y):
		for x in range(room_margin_x, map_width - room_margin_x):
			tile_result[y][x] = TILE_FLOOR

	# 柱や障害物を少し置く
	for i in range(8):
		var px = randi_range(room_margin_x + 1, map_width - room_margin_x - 2)
		var py = randi_range(room_margin_y + 1, map_height - room_margin_y - 2)

		if randf() < 0.7:
			tile_result[py][px] = TILE_WALL

	var return_cell = Vector2i(room_margin_x + 1, room_margin_y + 1)
	tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	if not is_bottom_floor:
		var next_cell = Vector2i(map_width - room_margin_x - 2, map_height - room_margin_y - 2)
		tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


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
