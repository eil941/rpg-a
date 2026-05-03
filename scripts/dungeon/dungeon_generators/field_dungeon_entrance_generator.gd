extends RefCounted
class_name FieldDungeonEntranceGenerator

var map_width: int = 0
var map_height: int = 0
var dungeon_tile_visual_config: DungeonTileVisualConfig = null
var theme_weights: Dictionary = {}
var min_floor_count: int = 3
var max_floor_count: int = 6
var min_difficulty: int = 1
var max_difficulty: int = 100


func _init(
	p_map_width: int,
	p_map_height: int,
	p_dungeon_tile_visual_config: DungeonTileVisualConfig = null,
	p_theme_weights: Dictionary = {},
	p_min_floor_count: int = 3,
	p_max_floor_count: int = 6,
	p_min_difficulty: int = 1,
	p_max_difficulty: int = 100
) -> void:
	map_width = p_map_width
	map_height = p_map_height
	dungeon_tile_visual_config = p_dungeon_tile_visual_config
	theme_weights = p_theme_weights.duplicate(true)
	min_floor_count = p_min_floor_count
	max_floor_count = p_max_floor_count
	min_difficulty = p_min_difficulty
	max_difficulty = p_max_difficulty


func generate_map(
	map_id: String,
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer,
	entrance_count: int
) -> Array:
	var result: Array = []
	var used_positions: Dictionary = {}

	var candidates: Array = _get_candidates(ground_layer, wall_layer)
	candidates.shuffle()

	var placed: int = 0

	for cell in candidates:
		if placed >= entrance_count:
			break

		var key: String = str(cell.x) + "," + str(cell.y)
		if used_positions.has(key):
			continue

		var dungeon_id: String = map_id + "_dungeon_" + str(cell.x) + "_" + str(cell.y)
		var generator_theme: String = choose_dungeon_theme()
		var layout_generator_type: String = choose_layout_generator_type(generator_theme)
		var max_floor: int = choose_max_floor()
		var difficulty: int = choose_dungeon_difficulty()

		if WorldState.dungeon_data.has(dungeon_id):
			var existing_data: Dictionary = WorldState.dungeon_data[dungeon_id]
			generator_theme = String(existing_data.get("generator_theme", generator_theme)).strip_edges().replace("\"", "").to_upper()
			layout_generator_type = String(existing_data.get("layout_generator_type", layout_generator_type)).strip_edges().replace("\"", "").to_upper()
			max_floor = int(existing_data.get("max_floor", max_floor))
			difficulty = int(existing_data.get("difficulty", difficulty))

		var visual: Dictionary = get_field_visual(generator_theme)
		var source_id: int = int(visual.get("source_id", 4))
		var atlas_coords: Vector2i = visual.get("atlas_coords", Vector2i(0, 0))
		var alternative_tile: int = int(visual.get("alternative_tile", 0))

		event_layer.set_cell(cell, source_id, atlas_coords, alternative_tile)

		var entrance_data: Dictionary = {
			"x": cell.x,
			"y": cell.y,
			"dungeon_id": dungeon_id,
			"generator_theme": generator_theme,
			"layout_generator_type": layout_generator_type,
			"difficulty": difficulty
		}
		result.append(entrance_data)

		if not WorldState.dungeon_data.has(dungeon_id):
			WorldState.dungeon_data[dungeon_id] = {
				"origin_field_map_id": map_id,
				"origin_x": cell.x,
				"origin_y": cell.y,
				"max_floor": max_floor,
				"difficulty": difficulty,
				"generator_theme": generator_theme,
				"layout_generator_type": layout_generator_type,
				"generator_type": layout_generator_type,
				"seed": randi()
			}
		else:
			var updated_data: Dictionary = WorldState.dungeon_data[dungeon_id]
			updated_data["origin_field_map_id"] = String(updated_data.get("origin_field_map_id", map_id))
			updated_data["origin_x"] = int(updated_data.get("origin_x", cell.x))
			updated_data["origin_y"] = int(updated_data.get("origin_y", cell.y))
			updated_data["max_floor"] = int(updated_data.get("max_floor", max_floor))
			updated_data["difficulty"] = int(updated_data.get("difficulty", difficulty))
			updated_data["generator_theme"] = String(updated_data.get("generator_theme", generator_theme)).strip_edges().replace("\"", "").to_upper()
			updated_data["layout_generator_type"] = String(updated_data.get("layout_generator_type", layout_generator_type)).strip_edges().replace("\"", "").to_upper()
			updated_data["generator_type"] = String(updated_data.get("generator_type", updated_data["layout_generator_type"])).strip_edges().replace("\"", "").to_upper()
			if not updated_data.has("seed"):
				updated_data["seed"] = randi()
			WorldState.dungeon_data[dungeon_id] = updated_data

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
			var cell: Vector2i = Vector2i(x, y)

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


func get_field_visual(generator_theme: String) -> Dictionary:
	var fallback: Dictionary = {
		"source_id": 4,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0
	}

	if dungeon_tile_visual_config == null:
		return fallback

	if not dungeon_tile_visual_config.has_method("get_tile"):
		return fallback

	var theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()
	return dungeon_tile_visual_config.get_tile(theme, "FIELD")


func choose_dungeon_theme() -> String:
	var weights: Dictionary = get_effective_theme_weights()
	var total_weight: int = 0

	for theme in weights.keys():
		total_weight += int(weights[theme])

	if total_weight <= 0:
		return "NATURAL"

	var roll: int = randi_range(1, total_weight)
	var current: int = 0

	for theme in weights.keys():
		current += int(weights[theme])
		if roll <= current:
			return String(theme)

	return "NATURAL"


func get_effective_theme_weights() -> Dictionary:
	var result: Dictionary = {
		"NATURAL": 40,
		"FORTIFIED": 15,
		"RUINED": 25,
		"ARTIFICIAL": 10,
		"CHAOTIC": 10
	}

	for theme in theme_weights.keys():
		var normalized_theme: String = String(theme).strip_edges().replace("\"", "").to_upper()
		if result.has(normalized_theme):
			var value: int = int(theme_weights[theme])
			if value < 0:
				value = 0
			result[normalized_theme] = value

	return result


func choose_layout_generator_type(generator_theme: String) -> String:
	var candidates: Array[String] = get_layout_candidates_for_theme(generator_theme)
	if candidates.is_empty():
		return "ROOM"
	return candidates[randi_range(0, candidates.size() - 1)]


func get_layout_candidates_for_theme(generator_theme: String) -> Array[String]:
	var theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()

	match theme:
		"NATURAL":
			return ["CAVE", "ROOM", "RUINS"]
		"FORTIFIED":
			return ["ROOM", "LINEAR", "CROSS", "ARENA"]
		"RUINED":
			return ["RUINS", "ROOM", "MAZE", "CROSS"]
		"ARTIFICIAL":
			return ["MAZE", "LINEAR", "CROSS", "ROOM"]
		"CHAOTIC":
			return ["RINGS", "CAVE", "MAZE", "ARENA"]

	return ["ROOM"]


func choose_max_floor() -> int:
	if max_floor_count < min_floor_count:
		return min_floor_count
	return randi_range(min_floor_count, max_floor_count)


func choose_dungeon_difficulty() -> int:
	if max_difficulty < min_difficulty:
		return min_difficulty
	return randi_range(min_difficulty, max_difficulty)
