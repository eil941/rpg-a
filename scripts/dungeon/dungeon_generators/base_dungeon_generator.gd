extends RefCounted
class_name BaseDungeonGenerator

const TILE_WALL = 0
const TILE_FLOOR = 1
const TILE_RETURN = 2
const TILE_NEXT = 3

const DUNGEON_VISUAL_KIND_DOWN: String = "DOWN"
const DUNGEON_VISUAL_KIND_UP: String = "UP"
const DUNGEON_VISUAL_KIND_FLOOR: String = "FLOOR"
const DUNGEON_VISUAL_KIND_WALL: String = "WALL"

var map_width: int = 0
var map_height: int = 0
var tile_result: Array = []

var dungeon_tile_visual_config: DungeonTileVisualConfig = null
var generator_theme_for_visual: String = "NATURAL"

func _init(p_map_width: int, p_map_height: int) -> void:
	map_width = p_map_width
	map_height = p_map_height

func setup_visual_config(p_config: DungeonTileVisualConfig, p_generator_theme: String) -> void:
	dungeon_tile_visual_config = p_config
	generator_theme_for_visual = String(p_generator_theme).strip_edges().replace("\"", "").to_upper()
	if generator_theme_for_visual == "":
		generator_theme_for_visual = "NATURAL"

func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer,
	is_bottom_floor: bool
) -> void:
	pass

func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if tile_result.is_empty():
		return result

	for y in range(map_height):
		for x in range(map_width):
			var tile: int = int(tile_result[y][x])
			if tile == TILE_FLOOR or tile == TILE_RETURN or tile == TILE_NEXT:
				result.append(Vector2i(x, y))

	return result

func get_tile_at(cell: Vector2i) -> int:
	if tile_result.is_empty():
		return -1

	if cell.x < 0 or cell.x >= map_width or cell.y < 0 or cell.y >= map_height:
		return -1

	return int(tile_result[cell.y][cell.x])

func draw_tile_result(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile: int = int(tile_result[y][x])

			match tile:
				TILE_WALL:
					_set_tile_from_visual(wall_layer, cell, DUNGEON_VISUAL_KIND_WALL)

				TILE_FLOOR:
					_set_tile_from_visual(ground_layer, cell, DUNGEON_VISUAL_KIND_FLOOR)

				TILE_RETURN:
					_set_tile_from_visual(ground_layer, cell, DUNGEON_VISUAL_KIND_FLOOR)
					_set_tile_from_visual(event_layer, cell, DUNGEON_VISUAL_KIND_UP)

				TILE_NEXT:
					_set_tile_from_visual(ground_layer, cell, DUNGEON_VISUAL_KIND_FLOOR)
					_set_tile_from_visual(event_layer, cell, DUNGEON_VISUAL_KIND_DOWN)

func _set_tile_from_visual(layer: TileMapLayer, cell: Vector2i, kind: String) -> void:
	var visual: Dictionary = _get_visual(kind)
	layer.set_cell(
		cell,
		int(visual.get("source_id", -1)),
		visual.get("atlas_coords", Vector2i.ZERO),
		int(visual.get("alternative_tile", 0))
	)

func _get_visual(kind: String) -> Dictionary:
	if dungeon_tile_visual_config != null:
		return dungeon_tile_visual_config.get_tile(generator_theme_for_visual, kind)

	# Fallback: old hard-coded dungeon visuals.
	match kind:
		DUNGEON_VISUAL_KIND_WALL:
			return _make_tile(5, Vector2i(0, 0), 0)
		DUNGEON_VISUAL_KIND_FLOOR:
			return _make_tile(29, Vector2i(1, 4), 0)
		DUNGEON_VISUAL_KIND_UP:
			return _make_tile(3, Vector2i(0, 0), 0)
		DUNGEON_VISUAL_KIND_DOWN:
			return _make_tile(6, Vector2i(0, 0), 0)

	return _make_tile(29, Vector2i(1, 4), 0)

func _make_tile(source_id: int, atlas_coords: Vector2i, alternative_tile: int) -> Dictionary:
	return {
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile": alternative_tile
	}
