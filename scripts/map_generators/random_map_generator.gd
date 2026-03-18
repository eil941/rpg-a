extends RefCounted
class_name MapGenerator

var map_width: int
var map_height: int

var floor_source_id: int
var wall_source_id: int

var floor_atlas_coords: Vector2i
var wall_atlas_coords: Vector2i

func _init(
	p_map_width: int,
	p_map_height: int,
	p_floor_source_id: int,
	p_wall_source_id: int,
	p_floor_atlas_coords: Vector2i,
	p_wall_atlas_coords: Vector2i
) -> void:
	map_width = p_map_width
	map_height = p_map_height
	floor_source_id = p_floor_source_id
	wall_source_id = p_wall_source_id
	floor_atlas_coords = p_floor_atlas_coords
	wall_atlas_coords = p_wall_atlas_coords

func generate_map(ground_layer: TileMapLayer, wall_layer: TileMapLayer,event_layer:TileMapLayer) -> void:
	for y in range(0, map_height, 1):
		for x in range(0, map_width, 1):
			var cell = Vector2i(x, y)

			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				#wall_layer.set_cell(cell, wall_source_id, wall_atlas_coords, 0)
				event_layer.set_cell(cell, wall_source_id, wall_atlas_coords, 0)
			else:
				ground_layer.set_cell(cell, floor_source_id, floor_atlas_coords, 0)

	for x in range(10, 20):
		#wall_layer.set_cell(Vector2i(x, 10), wall_source_id, wall_atlas_coords, 0)
		wall_layer.set_cell(Vector2i(x, 10), 3, wall_atlas_coords, 0)

	for y in range(20, 30):
		#wall_layer.set_cell(Vector2i(25, y), wall_source_id, wall_atlas_coords, 0)
		wall_layer.set_cell(Vector2i(25, y), 5, wall_atlas_coords, 0)



func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for y in range(map_height):
		for x in range(map_width):
			var tile = Vector2i(x, y)

			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				continue

			if (x >= 10 and x < 20 and y == 10):
				continue

			if (x == 25 and y >= 20 and y < 30):
				continue

			result.append(tile)

	return result
