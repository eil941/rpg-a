extends RefCounted
class_name BaseMapGenerator

var map_width: int
var map_height: int

var floor_source_id: int
var wall_source_id: int

var floor_atlas_coords: Vector2i
var wall_atlas_coords: Vector2i

var tile_visual_config: MapTileVisualConfig = null


func _init(
	p_map_width: int,
	p_map_height: int,
	p_floor_source_id: int,
	p_wall_source_id: int,
	p_floor_atlas_coords: Vector2i,
	p_wall_atlas_coords: Vector2i,
	p_tile_visual_config: MapTileVisualConfig = null
) -> void:
	map_width = p_map_width
	map_height = p_map_height
	floor_source_id = p_floor_source_id
	wall_source_id = p_wall_source_id
	floor_atlas_coords = p_floor_atlas_coords
	wall_atlas_coords = p_wall_atlas_coords
	tile_visual_config = p_tile_visual_config


func set_tile_visual_config(config: MapTileVisualConfig) -> void:
	tile_visual_config = config


func _set_config_cell(
	layer: TileMapLayer,
	cell: Vector2i,
	tile_key: String,
	fallback_source_id: int,
	fallback_atlas_coords: Vector2i,
	fallback_alternative_tile: int = 0
) -> void:
	if layer == null:
		return

	if tile_visual_config != null:
		tile_visual_config.set_cell(layer, cell, tile_key, fallback_source_id, fallback_atlas_coords, fallback_alternative_tile)
		return

	layer.set_cell(cell, fallback_source_id, fallback_atlas_coords, fallback_alternative_tile)
