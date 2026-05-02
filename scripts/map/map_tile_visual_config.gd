extends Resource
class_name MapTileVisualConfig

# 生成マップの見た目用タイル設定。
# source_id / atlas_coords / alternative_tile は TileMapLayer.set_cell() に渡す値です。
# main.gd と FiledMap.gd のインスペクターからこのResourceを指定して使います。

@export_group("Detail Common")
@export var detail_water_source_id: int = 58
@export var detail_water_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_water_alternative_tile: int = 0

@export var detail_sand_source_id: int = 45
@export var detail_sand_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_sand_alternative_tile: int = 0

@export var detail_grass_source_id: int = 48
@export var detail_grass_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_grass_alternative_tile: int = 0

@export var detail_forest_source_id: int = 42
@export var detail_forest_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_forest_alternative_tile: int = 0

@export var detail_rock_ground_source_id: int = 26
@export var detail_rock_ground_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_rock_ground_alternative_tile: int = 0

@export var detail_rock_wall_source_id: int = 5
@export var detail_rock_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var detail_rock_wall_alternative_tile: int = 0

@export var detail_border_event_source_id: int = 0
@export var detail_border_event_atlas_coords: Vector2i = Vector2i(0, 0)
@export var detail_border_event_alternative_tile: int = 0

@export_group("Detail Sea")
@export var detail_sea_shallow_source_id: int = 58
@export var detail_sea_shallow_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_sea_shallow_alternative_tile: int = 0

@export var detail_sea_source_id: int = 57
@export var detail_sea_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_sea_alternative_tile: int = 0

@export var detail_sea_deep_source_id: int = 60
@export var detail_sea_deep_atlas_coords: Vector2i = Vector2i(1, 4)
@export var detail_sea_deep_alternative_tile: int = 0

@export_group("Field Ocean / Coast / Plains")
@export var field_ocean_ground_source_id: int = 87
@export var field_ocean_ground_atlas_coords: Vector2i = Vector2i(0, 4)
@export var field_ocean_ground_alternative_tile: int = 0
@export var field_ocean_event_source_id: int = 87
@export var field_ocean_event_atlas_coords: Vector2i = Vector2i(0, 4)
@export var field_ocean_event_alternative_tile: int = 0

@export var field_coast_ground_source_id: int = 14
@export var field_coast_ground_atlas_coords: Vector2i = Vector2i(1, 0)
@export var field_coast_ground_alternative_tile: int = 0
@export var field_coast_event_source_id: int = 14
@export var field_coast_event_atlas_coords: Vector2i = Vector2i(1, 0)
@export var field_coast_event_alternative_tile: int = 0

@export var field_plains_ground_source_id: int = 14
@export var field_plains_ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_plains_ground_alternative_tile: int = 0
@export var field_plains_event_source_id: int = 14
@export var field_plains_event_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_plains_event_alternative_tile: int = 0

@export var field_dry_plains_ground_source_id: int = 25
@export var field_dry_plains_ground_atlas_coords: Vector2i = Vector2i(2, 0)
@export var field_dry_plains_ground_alternative_tile: int = 0
@export var field_dry_plains_event_source_id: int = 25
@export var field_dry_plains_event_atlas_coords: Vector2i = Vector2i(2, 0)
@export var field_dry_plains_event_alternative_tile: int = 0

@export_group("Field Forest / Desert / Lake")
@export var field_forest_ground_source_id: int = 14
@export var field_forest_ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_forest_ground_alternative_tile: int = 0
@export var field_forest_event_source_id: int = 14
@export var field_forest_event_atlas_coords: Vector2i = Vector2i(5, 11)
@export var field_forest_event_alternative_tile: int = 0

@export var field_desert_ground_source_id: int = 25
@export var field_desert_ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_desert_ground_alternative_tile: int = 0
@export var field_desert_event_source_id: int = 25
@export var field_desert_event_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_desert_event_alternative_tile: int = 0

@export var field_lake_ground_source_id: int = 15
@export var field_lake_ground_atlas_coords: Vector2i = Vector2i(2, 4)
@export var field_lake_ground_alternative_tile: int = 0
@export var field_lake_event_source_id: int = 15
@export var field_lake_event_atlas_coords: Vector2i = Vector2i(2, 4)
@export var field_lake_event_alternative_tile: int = 0

@export_group("Field Highland")
@export var field_highland_grass_ground_source_id: int = 73
@export var field_highland_grass_ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_highland_grass_ground_alternative_tile: int = 0
@export var field_highland_grass_event_source_id: int = 73
@export var field_highland_grass_event_atlas_coords: Vector2i = Vector2i(0, 0)
@export var field_highland_grass_event_alternative_tile: int = 0

@export var field_highland_forest_ground_source_id: int = 59
@export var field_highland_forest_ground_atlas_coords: Vector2i = Vector2i(1, 0)
@export var field_highland_forest_ground_alternative_tile: int = 0
@export var field_highland_forest_event_source_id: int = 59
@export var field_highland_forest_event_atlas_coords: Vector2i = Vector2i(7, 9)
@export var field_highland_forest_event_alternative_tile: int = 0

@export var field_highland_rock_ground_source_id: int = 59
@export var field_highland_rock_ground_atlas_coords: Vector2i = Vector2i(1, 6)
@export var field_highland_rock_ground_alternative_tile: int = 0
@export var field_highland_rock_wall_source_id: int = 59
@export var field_highland_rock_wall_atlas_coords: Vector2i = Vector2i(1, 6)
@export var field_highland_rock_wall_alternative_tile: int = 0

@export_group("Field Mountain")
@export var field_mountain_grass_ground_source_id: int = 58
@export var field_mountain_grass_ground_atlas_coords: Vector2i = Vector2i(2, 0)
@export var field_mountain_grass_ground_alternative_tile: int = 0
@export var field_mountain_grass_event_source_id: int = 58
@export var field_mountain_grass_event_atlas_coords: Vector2i = Vector2i(2, 0)
@export var field_mountain_grass_event_alternative_tile: int = 0

@export var field_mountain_forest_ground_source_id: int = 58
@export var field_mountain_forest_ground_atlas_coords: Vector2i = Vector2i(2, 0)
@export var field_mountain_forest_ground_alternative_tile: int = 0
@export var field_mountain_forest_event_source_id: int = 14
@export var field_mountain_forest_event_atlas_coords: Vector2i = Vector2i(1, 1)
@export var field_mountain_forest_event_alternative_tile: int = 0

@export var field_mountain_rock_ground_source_id: int = 58
@export var field_mountain_rock_ground_atlas_coords: Vector2i = Vector2i(1, 5)
@export var field_mountain_rock_ground_alternative_tile: int = 0
@export var field_mountain_rock_wall_source_id: int = 58
@export var field_mountain_rock_wall_atlas_coords: Vector2i = Vector2i(1, 5)
@export var field_mountain_rock_wall_alternative_tile: int = 0

@export_group("Field Border")
@export var field_border_wall_source_id: int = 86
@export var field_border_wall_atlas_coords: Vector2i = Vector2i(0, 4)
@export var field_border_wall_alternative_tile: int = 0


func set_cell(layer: TileMapLayer, cell: Vector2i, tile_key: String, fallback_source_id: int, fallback_atlas_coords: Vector2i, fallback_alternative_tile: int = 0) -> void:
	if layer == null:
		return

	var source_id: int = fallback_source_id
	var atlas_coords: Vector2i = fallback_atlas_coords
	var alternative_tile: int = fallback_alternative_tile

	match tile_key:
		"detail_water":
			source_id = detail_water_source_id
			atlas_coords = detail_water_atlas_coords
			alternative_tile = detail_water_alternative_tile
		"detail_sand":
			source_id = detail_sand_source_id
			atlas_coords = detail_sand_atlas_coords
			alternative_tile = detail_sand_alternative_tile
		"detail_grass":
			source_id = detail_grass_source_id
			atlas_coords = detail_grass_atlas_coords
			alternative_tile = detail_grass_alternative_tile
		"detail_forest":
			source_id = detail_forest_source_id
			atlas_coords = detail_forest_atlas_coords
			alternative_tile = detail_forest_alternative_tile
		"detail_rock_ground":
			source_id = detail_rock_ground_source_id
			atlas_coords = detail_rock_ground_atlas_coords
			alternative_tile = detail_rock_ground_alternative_tile
		"detail_rock_wall":
			source_id = detail_rock_wall_source_id
			atlas_coords = detail_rock_wall_atlas_coords
			alternative_tile = detail_rock_wall_alternative_tile
		"detail_border_event":
			source_id = detail_border_event_source_id
			atlas_coords = detail_border_event_atlas_coords
			alternative_tile = detail_border_event_alternative_tile
		"detail_sea_shallow":
			source_id = detail_sea_shallow_source_id
			atlas_coords = detail_sea_shallow_atlas_coords
			alternative_tile = detail_sea_shallow_alternative_tile
		"detail_sea":
			source_id = detail_sea_source_id
			atlas_coords = detail_sea_atlas_coords
			alternative_tile = detail_sea_alternative_tile
		"detail_sea_deep":
			source_id = detail_sea_deep_source_id
			atlas_coords = detail_sea_deep_atlas_coords
			alternative_tile = detail_sea_deep_alternative_tile
		"field_ocean_ground":
			source_id = field_ocean_ground_source_id
			atlas_coords = field_ocean_ground_atlas_coords
			alternative_tile = field_ocean_ground_alternative_tile
		"field_ocean_event":
			source_id = field_ocean_event_source_id
			atlas_coords = field_ocean_event_atlas_coords
			alternative_tile = field_ocean_event_alternative_tile
		"field_coast_ground":
			source_id = field_coast_ground_source_id
			atlas_coords = field_coast_ground_atlas_coords
			alternative_tile = field_coast_ground_alternative_tile
		"field_coast_event":
			source_id = field_coast_event_source_id
			atlas_coords = field_coast_event_atlas_coords
			alternative_tile = field_coast_event_alternative_tile
		"field_plains_ground":
			source_id = field_plains_ground_source_id
			atlas_coords = field_plains_ground_atlas_coords
			alternative_tile = field_plains_ground_alternative_tile
		"field_plains_event":
			source_id = field_plains_event_source_id
			atlas_coords = field_plains_event_atlas_coords
			alternative_tile = field_plains_event_alternative_tile
		"field_dry_plains_ground":
			source_id = field_dry_plains_ground_source_id
			atlas_coords = field_dry_plains_ground_atlas_coords
			alternative_tile = field_dry_plains_ground_alternative_tile
		"field_dry_plains_event":
			source_id = field_dry_plains_event_source_id
			atlas_coords = field_dry_plains_event_atlas_coords
			alternative_tile = field_dry_plains_event_alternative_tile
		"field_forest_ground":
			source_id = field_forest_ground_source_id
			atlas_coords = field_forest_ground_atlas_coords
			alternative_tile = field_forest_ground_alternative_tile
		"field_forest_event":
			source_id = field_forest_event_source_id
			atlas_coords = field_forest_event_atlas_coords
			alternative_tile = field_forest_event_alternative_tile
		"field_desert_ground":
			source_id = field_desert_ground_source_id
			atlas_coords = field_desert_ground_atlas_coords
			alternative_tile = field_desert_ground_alternative_tile
		"field_desert_event":
			source_id = field_desert_event_source_id
			atlas_coords = field_desert_event_atlas_coords
			alternative_tile = field_desert_event_alternative_tile
		"field_lake_ground":
			source_id = field_lake_ground_source_id
			atlas_coords = field_lake_ground_atlas_coords
			alternative_tile = field_lake_ground_alternative_tile
		"field_lake_event":
			source_id = field_lake_event_source_id
			atlas_coords = field_lake_event_atlas_coords
			alternative_tile = field_lake_event_alternative_tile
		"field_highland_grass_ground":
			source_id = field_highland_grass_ground_source_id
			atlas_coords = field_highland_grass_ground_atlas_coords
			alternative_tile = field_highland_grass_ground_alternative_tile
		"field_highland_grass_event":
			source_id = field_highland_grass_event_source_id
			atlas_coords = field_highland_grass_event_atlas_coords
			alternative_tile = field_highland_grass_event_alternative_tile
		"field_highland_forest_ground":
			source_id = field_highland_forest_ground_source_id
			atlas_coords = field_highland_forest_ground_atlas_coords
			alternative_tile = field_highland_forest_ground_alternative_tile
		"field_highland_forest_event":
			source_id = field_highland_forest_event_source_id
			atlas_coords = field_highland_forest_event_atlas_coords
			alternative_tile = field_highland_forest_event_alternative_tile
		"field_highland_rock_ground":
			source_id = field_highland_rock_ground_source_id
			atlas_coords = field_highland_rock_ground_atlas_coords
			alternative_tile = field_highland_rock_ground_alternative_tile
		"field_highland_rock_wall":
			source_id = field_highland_rock_wall_source_id
			atlas_coords = field_highland_rock_wall_atlas_coords
			alternative_tile = field_highland_rock_wall_alternative_tile
		"field_mountain_grass_ground":
			source_id = field_mountain_grass_ground_source_id
			atlas_coords = field_mountain_grass_ground_atlas_coords
			alternative_tile = field_mountain_grass_ground_alternative_tile
		"field_mountain_grass_event":
			source_id = field_mountain_grass_event_source_id
			atlas_coords = field_mountain_grass_event_atlas_coords
			alternative_tile = field_mountain_grass_event_alternative_tile
		"field_mountain_forest_ground":
			source_id = field_mountain_forest_ground_source_id
			atlas_coords = field_mountain_forest_ground_atlas_coords
			alternative_tile = field_mountain_forest_ground_alternative_tile
		"field_mountain_forest_event":
			source_id = field_mountain_forest_event_source_id
			atlas_coords = field_mountain_forest_event_atlas_coords
			alternative_tile = field_mountain_forest_event_alternative_tile
		"field_mountain_rock_ground":
			source_id = field_mountain_rock_ground_source_id
			atlas_coords = field_mountain_rock_ground_atlas_coords
			alternative_tile = field_mountain_rock_ground_alternative_tile
		"field_mountain_rock_wall":
			source_id = field_mountain_rock_wall_source_id
			atlas_coords = field_mountain_rock_wall_atlas_coords
			alternative_tile = field_mountain_rock_wall_alternative_tile
		"field_border_wall":
			source_id = field_border_wall_source_id
			atlas_coords = field_border_wall_atlas_coords
			alternative_tile = field_border_wall_alternative_tile
		_:
			pass

	layer.set_cell(cell, source_id, atlas_coords, alternative_tile)
