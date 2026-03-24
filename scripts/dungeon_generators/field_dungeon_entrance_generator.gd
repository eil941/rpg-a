extends RefCounted
class_name FieldDungeonEntranceGenerator

var map_width = 0
var map_height = 0

func _init(p_map_width: int, p_map_height: int) -> void:
	map_width = p_map_width
	map_height = p_map_height

func generate_map(
	map_id: String,
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer,
	entrance_count: int
) -> Array:
	var result: Array = []
	var used_positions: Dictionary = {}

	var candidates = _get_candidates(ground_layer, wall_layer)
	candidates.shuffle()

	var placed = 0

	for cell in candidates:
		if placed >= entrance_count:
			break

		var key = str(cell.x) + "," + str(cell.y)
		if used_positions.has(key):
			continue

		var dungeon_id = map_id + "_dungeon_" + str(cell.x) + "_" + str(cell.y)

		# フィールド上のダンジョン入口
		print("Duongeon : ",cell)
		event_layer.set_cell(cell, 4, Vector2i(0, 0), 0)

		result.append({
			"x": cell.x,
			"y": cell.y,
			"dungeon_id": dungeon_id
		})

		if not WorldState.dungeon_data.has(dungeon_id):
			WorldState.dungeon_data[dungeon_id] = {
				"origin_field_map_id": map_id,
				"origin_x": cell.x,
				"origin_y": cell.y,
				"max_floor": randi_range(3, 6)
			}

		used_positions[key] = true
		placed += 1

	print("generated and placed dungeon entrances = ", result)
	return result

func _get_candidates(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer
) -> Array:
	var result: Array = []

	for y in range(2, map_height - 2):
		for x in range(2, map_width - 2):
			var cell = Vector2i(x, y)

			if not _is_walkable_cell(cell, ground_layer, wall_layer):
				continue

			result.append(cell)

	return result

func _is_walkable_cell(
	cell: Vector2i,
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer
) -> bool:
	if ground_layer.get_cell_source_id(cell) == -1:
		return false

	if wall_layer.get_cell_source_id(cell) != -1:
		return false

	return true
