extends RefCounted
class_name BaseDungeonGenerator

const TILE_WALL = 0
const TILE_FLOOR = 1
const TILE_RETURN = 2
const TILE_NEXT = 3

var map_width = 0
var map_height = 0
var tile_result: Array = []

func _init(p_map_width: int, p_map_height: int) -> void:
	map_width = p_map_width
	map_height = p_map_height

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
			var tile = tile_result[y][x]
			if tile == TILE_FLOOR or tile == TILE_RETURN or tile == TILE_NEXT:
				result.append(Vector2i(x, y))

	return result

func get_tile_at(cell: Vector2i) -> int:
	if tile_result.is_empty():
		return -1

	if cell.x < 0 or cell.x >= map_width or cell.y < 0 or cell.y >= map_height:
		return -1

	return tile_result[cell.y][cell.x]
