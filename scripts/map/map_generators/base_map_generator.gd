extends RefCounted
class_name BaseMapGenerator

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
