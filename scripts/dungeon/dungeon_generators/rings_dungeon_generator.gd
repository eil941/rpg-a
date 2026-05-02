extends BaseDungeonGenerator
class_name RingsDungeonGenerator

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

	# 外周リング
	_carve_ring(2, 2, map_width - 3, map_height - 3)

	# 中央リング
	if map_width >= 18 and map_height >= 18:
		_carve_ring(6, 6, map_width - 7, map_height - 7)

	# 接続通路
	var center_x = map_width / 2
	var center_y = map_height / 2

	for y in range(2, map_height - 2):
		tile_result[y][center_x] = TILE_FLOOR

	for x in range(2, map_width - 2):
		tile_result[center_y][x] = TILE_FLOOR

	var return_cell = Vector2i(2, 2)
	tile_result[return_cell.y][return_cell.x] = TILE_RETURN

	if not is_bottom_floor:
		var next_cell = Vector2i(map_width - 3, map_height - 3)
		tile_result[next_cell.y][next_cell.x] = TILE_NEXT

	_draw_map(ground_layer, wall_layer, event_layer)


func _carve_ring(left: int, top: int, right: int, bottom: int) -> void:
	for x in range(left, right + 1):
		tile_result[top][x] = TILE_FLOOR
		tile_result[bottom][x] = TILE_FLOOR

	for y in range(top, bottom + 1):
		tile_result[y][left] = TILE_FLOOR
		tile_result[y][right] = TILE_FLOOR


func _draw_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	draw_tile_result(ground_layer, wall_layer, event_layer)
