extends BaseMapGenerator
class_name PlainMapGenerator

const TERRAIN_SEA: int = 0
const TERRAIN_SAND: int = 1
const TERRAIN_GRASS: int = 2
const TERRAIN_FOREST: int = 3
const TERRAIN_ROCK: int = 4
const TERRAIN_LAKE: int = 5

const BIOME_OCEAN: int = 0
const BIOME_COAST: int = 1
const BIOME_PLAINS: int = 2
const BIOME_FOREST: int = 3
const BIOME_DESERT: int = 4
const BIOME_HIGHLAND: int = 5
const BIOME_MOUNTAIN: int = 6
const BIOME_LAKE: int = 7
const BIOME_DRY_PLAINS: int = 8

# =========================
# Pipoya RPG World Tileset 32x32 / [A]_type3
# TileSet atlas source_id order:
# 0: pipo-map001_at-umi.png
# 1: pipo-map001_at-kusa.png
# 2: pipo-map001_at-mori.png
# 3: pipo-map001_at-sabaku.png
# 4: pipo-map001_at-miti.png
# 5: pipo-map001_at-tuti.png
# 6: pipo-map001_at-yama1.png
# 7: pipo-map001_at-yama2.png
# 8: pipo-map001_at-yama3.png
# =========================

const SRC_UMI: int = 0
const SRC_KUSA: int = 1
const SRC_MORI: int = 2
const SRC_SABAKU: int = 3
const SRC_MITI: int = 4
const SRC_TUTI: int = 5
const SRC_YAMA1: int = 6
const SRC_YAMA2: int = 7
const SRC_YAMA3: int = 8

# 8x6 のオートタイル画像内で、単体表示に使いやすい塗りつぶしタイル。
# 草・砂・水・土など、地面として敷くタイルに使います。
const FILL_ATLAS_COORDS: Vector2i = Vector2i(3, 5)

# 森は下地を草/土にして、上に森タイルを重ねます。
const FOREST_OVERLAY_ATLAS_COORDS: Vector2i = Vector2i(6, 1)

# 乾いた平原は下地を土にして、上に道/乾いた地面タイルを重ねます。
const DRY_OVERLAY_ATLAS_COORDS: Vector2i = Vector2i(6, 1)

# 山は下地を土にして、上に山アイコンを重ねます。
const MOUNTAIN_OVERLAY_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

const OCEAN_GROUND_SOURCE_ID: int = SRC_UMI
const OCEAN_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const OCEAN_EVENT_SOURCE_ID: int = SRC_UMI
const OCEAN_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const COAST_GROUND_SOURCE_ID: int = SRC_SABAKU
const COAST_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const COAST_EVENT_SOURCE_ID: int = SRC_SABAKU
const COAST_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const PLAINS_GROUND_SOURCE_ID: int = SRC_KUSA
const PLAINS_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const PLAINS_EVENT_SOURCE_ID: int = SRC_KUSA
const PLAINS_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const DRY_PLAINS_GROUND_SOURCE_ID: int = SRC_TUTI
const DRY_PLAINS_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const DRY_PLAINS_EVENT_SOURCE_ID: int = SRC_MITI
const DRY_PLAINS_EVENT_ATLAS_COORDS: Vector2i = DRY_OVERLAY_ATLAS_COORDS

const FOREST_GROUND_SOURCE_ID: int = SRC_KUSA
const FOREST_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const FOREST_EVENT_SOURCE_ID: int = SRC_MORI
const FOREST_EVENT_ATLAS_COORDS: Vector2i = FOREST_OVERLAY_ATLAS_COORDS

const DESERT_GROUND_SOURCE_ID: int = SRC_SABAKU
const DESERT_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const DESERT_EVENT_SOURCE_ID: int = SRC_SABAKU
const DESERT_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const HIGHLAND_GRASS_GROUND_SOURCE_ID: int = SRC_TUTI
const HIGHLAND_GRASS_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const HIGHLAND_GRASS_EVENT_SOURCE_ID: int = SRC_TUTI
const HIGHLAND_GRASS_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const HIGHLAND_FOREST_GROUND_SOURCE_ID: int = SRC_TUTI
const HIGHLAND_FOREST_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const HIGHLAND_FOREST_EVENT_SOURCE_ID: int = SRC_MORI
const HIGHLAND_FOREST_EVENT_ATLAS_COORDS: Vector2i = FOREST_OVERLAY_ATLAS_COORDS

const HIGHLAND_ROCK_GROUND_SOURCE_ID: int = SRC_TUTI
const HIGHLAND_ROCK_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const HIGHLAND_ROCK_WALL_SOURCE_ID: int = SRC_YAMA2
const HIGHLAND_ROCK_WALL_ATLAS_COORDS: Vector2i = MOUNTAIN_OVERLAY_ATLAS_COORDS

const MOUNTAIN_GRASS_GROUND_SOURCE_ID: int = SRC_TUTI
const MOUNTAIN_GRASS_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const MOUNTAIN_GRASS_EVENT_SOURCE_ID: int = SRC_YAMA1
const MOUNTAIN_GRASS_EVENT_ATLAS_COORDS: Vector2i = MOUNTAIN_OVERLAY_ATLAS_COORDS

const MOUNTAIN_FOREST_GROUND_SOURCE_ID: int = SRC_TUTI
const MOUNTAIN_FOREST_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const MOUNTAIN_FOREST_EVENT_SOURCE_ID: int = SRC_MORI
const MOUNTAIN_FOREST_EVENT_ATLAS_COORDS: Vector2i = FOREST_OVERLAY_ATLAS_COORDS

const MOUNTAIN_ROCK_GROUND_SOURCE_ID: int = SRC_TUTI
const MOUNTAIN_ROCK_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const MOUNTAIN_ROCK_WALL_SOURCE_ID: int = SRC_YAMA3
const MOUNTAIN_ROCK_WALL_ATLAS_COORDS: Vector2i = MOUNTAIN_OVERLAY_ATLAS_COORDS

const LAKE_GROUND_SOURCE_ID: int = SRC_UMI
const LAKE_GROUND_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS
const LAKE_EVENT_SOURCE_ID: int = SRC_UMI
const LAKE_EVENT_ATLAS_COORDS: Vector2i = FILL_ATLAS_COORDS

const BORDER_WALL_SOURCE_ID: int = SRC_YAMA3
const BORDER_WALL_ATLAS_COORDS: Vector2i = MOUNTAIN_OVERLAY_ATLAS_COORDS

var terrain_result: Array = []
var biome_result: Array = []
var world_seed: int = 0


func _init(
	p_map_width: int,
	p_map_height: int,
	p_floor_source_id: int,
	p_wall_source_id: int,
	p_floor_atlas_coords: Vector2i,
	p_wall_atlas_coords: Vector2i,
	p_world_seed: int = 0,
	p_tile_visual_config: MapTileVisualConfig = null
) -> void:
	super(
		p_map_width,
		p_map_height,
		p_floor_source_id,
		p_wall_source_id,
		p_floor_atlas_coords,
		p_wall_atlas_coords,
		p_tile_visual_config
	)
	world_seed = p_world_seed


func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	var terrain_data: Array = []
	var biome_data: Array = []

	var continental_noise_a: FastNoiseLite = FastNoiseLite.new()
	continental_noise_a.seed = world_seed + 11
	continental_noise_a.frequency = 0.0075
	continental_noise_a.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var continental_noise_b: FastNoiseLite = FastNoiseLite.new()
	continental_noise_b.seed = world_seed + 19
	continental_noise_b.frequency = 0.014
	continental_noise_b.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var continental_noise_c: FastNoiseLite = FastNoiseLite.new()
	continental_noise_c.seed = world_seed + 29
	continental_noise_c.frequency = 0.028
	continental_noise_c.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var split_noise: FastNoiseLite = FastNoiseLite.new()
	split_noise.seed = world_seed + 37
	split_noise.frequency = 0.010
	split_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var temperature_noise: FastNoiseLite = FastNoiseLite.new()
	temperature_noise.seed = world_seed + 43
	temperature_noise.frequency = 0.004
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var humidity_noise: FastNoiseLite = FastNoiseLite.new()
	humidity_noise.seed = world_seed + 57
	humidity_noise.frequency = 0.004
	humidity_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var mountain_noise_a: FastNoiseLite = FastNoiseLite.new()
	mountain_noise_a.seed = world_seed + 71
	mountain_noise_a.frequency = 0.008
	mountain_noise_a.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var mountain_noise_b: FastNoiseLite = FastNoiseLite.new()
	mountain_noise_b.seed = world_seed + 79
	mountain_noise_b.frequency = 0.018
	mountain_noise_b.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var lake_noise: FastNoiseLite = FastNoiseLite.new()
	lake_noise.seed = world_seed + 83
	lake_noise.frequency = 0.020
	lake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var detail_noise: FastNoiseLite = FastNoiseLite.new()
	detail_noise.seed = world_seed + 89
	detail_noise.frequency = 0.040
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for y in range(map_height):
		var terrain_row: Array = []
		var biome_row: Array = []

		for x in range(map_width):
			var cont_a: float = (continental_noise_a.get_noise_2d(x, y) + 1.0) * 0.5
			var cont_b: float = (continental_noise_b.get_noise_2d(x, y) + 1.0) * 0.5
			var cont_c: float = (continental_noise_c.get_noise_2d(x, y) + 1.0) * 0.5
			var split_value_raw: float = (split_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var raw_temperature: float = (temperature_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var raw_humidity: float = (humidity_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var mountain_a: float = (mountain_noise_a.get_noise_2d(x, y) + 1.0) * 0.5
			var mountain_b: float = (mountain_noise_b.get_noise_2d(x, y) + 1.0) * 0.5
			var raw_lake: float = (lake_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var detail: float = (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var continent_value: float = cont_a * 0.50 + cont_b * 0.30 + cont_c * 0.20

			var split_strength: float = 0.0
			if split_value_raw > 0.60 and split_value_raw < 0.76:
				split_strength = 0.12
			elif split_value_raw > 0.54 and split_value_raw < 0.82:
				split_strength = 0.06

			var dist_left: int = x
			var dist_right: int = map_width - 1 - x
			var dist_top: int = y
			var dist_bottom: int = map_height - 1 - y
			var edge_dist: int = min(dist_left, dist_right, dist_top, dist_bottom)
			var max_edge_dist: float = float(min(map_width, map_height)) / 2.0
			var edge_factor: float = clamp(float(edge_dist) / max_edge_dist, 0.0, 1.0)

			var land_value: float = continent_value * 0.94 + edge_factor * 0.06 - split_strength

			var mountain_value: float = mountain_a * 0.72 + mountain_b * 0.28
			var temperature: float = clamp(raw_temperature - mountain_value * 0.10, 0.0, 1.0)
			var humidity: float = clamp(raw_humidity - mountain_value * 0.12, 0.0, 1.0)

			var biome: int = BIOME_PLAINS
			var terrain: int = TERRAIN_GRASS

			if land_value < 0.41:
				biome = BIOME_OCEAN
			elif land_value < 0.47:
				biome = BIOME_COAST
			else:
				var lake_edge_ok: bool = edge_dist >= 8
				var lake_land_ok: bool = land_value > 0.53
				var lake_height_ok: bool = mountain_value < 0.58

				if lake_edge_ok and lake_land_ok and lake_height_ok and raw_lake > 0.79 and raw_lake < 0.90:
					biome = BIOME_LAKE
				elif mountain_value > 0.74 and land_value > 0.52:
					biome = BIOME_MOUNTAIN
				elif mountain_value > 0.64 and land_value > 0.50:
					biome = BIOME_HIGHLAND
				else:
					if temperature > 0.66 and humidity < 0.28:
						biome = BIOME_DESERT
					elif temperature > 0.60 and humidity < 0.38:
						biome = BIOME_DRY_PLAINS
					elif humidity > 0.66:
						biome = BIOME_FOREST
					else:
						biome = BIOME_PLAINS

			match biome:
				BIOME_OCEAN:
					terrain = TERRAIN_SEA

				BIOME_COAST:
					terrain = TERRAIN_SAND

				BIOME_PLAINS:
					if mountain_value > 0.82 and detail > 0.76:
						terrain = TERRAIN_ROCK
					else:
						terrain = TERRAIN_GRASS

				BIOME_DRY_PLAINS:
					if detail > 0.82:
						terrain = TERRAIN_SAND
					else:
						terrain = TERRAIN_GRASS

				BIOME_FOREST:
					if mountain_value > 0.68 and detail > 0.66:
						terrain = TERRAIN_GRASS
					else:
						terrain = TERRAIN_FOREST

				BIOME_DESERT:
					if mountain_value > 0.78 and detail > 0.58:
						terrain = TERRAIN_ROCK
					else:
						terrain = TERRAIN_SAND

				BIOME_HIGHLAND:
					if detail < 0.20:
						terrain = TERRAIN_GRASS
					elif detail < 0.58:
						terrain = TERRAIN_FOREST
					else:
						terrain = TERRAIN_ROCK

				BIOME_MOUNTAIN:
					if detail < 0.12:
						terrain = TERRAIN_GRASS
					elif detail < 0.28:
						terrain = TERRAIN_FOREST
					else:
						terrain = TERRAIN_ROCK

				BIOME_LAKE:
					terrain = TERRAIN_LAKE

			terrain_row.append(terrain)
			biome_row.append(biome)

		terrain_data.append(terrain_row)
		biome_data.append(biome_row)

	terrain_result.clear()
	biome_result.clear()

	for y in range(map_height):
		var terrain_row_fixed: Array = []
		var biome_row_fixed: Array = []

		for x in range(map_width):
			var current_terrain: int = terrain_data[y][x]
			var current_biome: int = biome_data[y][x]

			var near_sea: bool = false
			var near_lake: bool = false
			var near_sand: bool = false
			var near_forest: bool = false
			var near_rock: bool = false
			var near_mountain: bool = false

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue

					var nx: int = x + dx
					var ny: int = y + dy

					if nx < 0 or nx >= map_width or ny < 0 or ny >= map_height:
						continue

					var neighbor_terrain: int = terrain_data[ny][nx]
					var neighbor_biome: int = biome_data[ny][nx]

					if neighbor_terrain == TERRAIN_SEA:
						near_sea = true
					if neighbor_terrain == TERRAIN_LAKE:
						near_lake = true
					if neighbor_terrain == TERRAIN_SAND:
						near_sand = true
					if neighbor_terrain == TERRAIN_FOREST:
						near_forest = true
					if neighbor_terrain == TERRAIN_ROCK:
						near_rock = true
					if neighbor_biome == BIOME_MOUNTAIN or neighbor_biome == BIOME_HIGHLAND:
						near_mountain = true

			if current_terrain == TERRAIN_GRASS and near_sea:
				current_terrain = TERRAIN_SAND
				if current_biome == BIOME_PLAINS:
					current_biome = BIOME_COAST

			if current_terrain == TERRAIN_SAND and near_lake and current_biome != BIOME_DESERT:
				current_terrain = TERRAIN_GRASS
				if current_biome == BIOME_COAST:
					current_biome = BIOME_PLAINS

			if current_terrain == TERRAIN_FOREST and near_sand and current_biome != BIOME_FOREST:
				current_terrain = TERRAIN_GRASS

			if current_terrain == TERRAIN_SAND and near_forest and current_biome != BIOME_DESERT and current_biome != BIOME_COAST:
				current_terrain = TERRAIN_GRASS

			if current_terrain == TERRAIN_FOREST and near_rock and near_mountain:
				current_terrain = TERRAIN_GRASS

			terrain_row_fixed.append(current_terrain)
			biome_row_fixed.append(current_biome)

		terrain_result.append(terrain_row_fixed)
		biome_result.append(biome_row_fixed)

	for x in range(map_width):
		terrain_result[0][x] = TERRAIN_SEA
		biome_result[0][x] = BIOME_OCEAN

		terrain_result[map_height - 1][x] = TERRAIN_SEA
		biome_result[map_height - 1][x] = BIOME_OCEAN

	for y in range(map_height):
		terrain_result[y][0] = TERRAIN_SEA
		biome_result[y][0] = BIOME_OCEAN

		terrain_result[y][map_width - 1] = TERRAIN_SEA
		biome_result[y][map_width - 1] = BIOME_OCEAN

	ground_layer.clear()
	wall_layer.clear()
	event_layer.clear()

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var biome: int = biome_result[y][x]

			match biome:
				BIOME_OCEAN:
					_set_config_cell(ground_layer, cell, "field_ocean_ground", OCEAN_GROUND_SOURCE_ID, OCEAN_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_ocean_event", OCEAN_EVENT_SOURCE_ID, OCEAN_EVENT_ATLAS_COORDS, 0)

				BIOME_COAST:
					_set_config_cell(ground_layer, cell, "field_coast_ground", COAST_GROUND_SOURCE_ID, COAST_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_coast_event", COAST_EVENT_SOURCE_ID, COAST_EVENT_ATLAS_COORDS, 0)

				BIOME_PLAINS:
					_set_config_cell(ground_layer, cell, "field_plains_ground", PLAINS_GROUND_SOURCE_ID, PLAINS_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_plains_event", PLAINS_EVENT_SOURCE_ID, PLAINS_EVENT_ATLAS_COORDS, 0)

				BIOME_DRY_PLAINS:
					_set_config_cell(ground_layer, cell, "field_dry_plains_ground", DRY_PLAINS_GROUND_SOURCE_ID, DRY_PLAINS_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_dry_plains_event", DRY_PLAINS_EVENT_SOURCE_ID, DRY_PLAINS_EVENT_ATLAS_COORDS, 0)

				BIOME_FOREST:
					_set_config_cell(ground_layer, cell, "field_forest_ground", FOREST_GROUND_SOURCE_ID, FOREST_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_forest_event", FOREST_EVENT_SOURCE_ID, FOREST_EVENT_ATLAS_COORDS, 0)

				BIOME_DESERT:
					_set_config_cell(ground_layer, cell, "field_desert_ground", DESERT_GROUND_SOURCE_ID, DESERT_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_desert_event", DESERT_EVENT_SOURCE_ID, DESERT_EVENT_ATLAS_COORDS, 0)

				BIOME_HIGHLAND:
					var terrain_highland: int = terrain_result[y][x]
					if terrain_highland == TERRAIN_ROCK:
						_set_config_cell(ground_layer, cell, "field_highland_rock_ground", HIGHLAND_ROCK_GROUND_SOURCE_ID, HIGHLAND_ROCK_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(wall_layer, cell, "field_highland_rock_wall", HIGHLAND_ROCK_WALL_SOURCE_ID, HIGHLAND_ROCK_WALL_ATLAS_COORDS, 0)
					elif terrain_highland == TERRAIN_FOREST:
						_set_config_cell(ground_layer, cell, "field_highland_forest_ground", HIGHLAND_FOREST_GROUND_SOURCE_ID, HIGHLAND_FOREST_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(event_layer, cell, "field_highland_forest_event", HIGHLAND_FOREST_EVENT_SOURCE_ID, HIGHLAND_FOREST_EVENT_ATLAS_COORDS, 0)
					else:
						_set_config_cell(ground_layer, cell, "field_highland_grass_ground", HIGHLAND_GRASS_GROUND_SOURCE_ID, HIGHLAND_GRASS_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(event_layer, cell, "field_highland_grass_event", HIGHLAND_GRASS_EVENT_SOURCE_ID, HIGHLAND_GRASS_EVENT_ATLAS_COORDS, 0)

				BIOME_MOUNTAIN:
					var terrain_mountain: int = terrain_result[y][x]
					if terrain_mountain == TERRAIN_ROCK:
						_set_config_cell(ground_layer, cell, "field_mountain_rock_ground", MOUNTAIN_ROCK_GROUND_SOURCE_ID, MOUNTAIN_ROCK_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(wall_layer, cell, "field_mountain_rock_wall", MOUNTAIN_ROCK_WALL_SOURCE_ID, MOUNTAIN_ROCK_WALL_ATLAS_COORDS, 0)
					elif terrain_mountain == TERRAIN_FOREST:
						_set_config_cell(ground_layer, cell, "field_mountain_forest_ground", MOUNTAIN_FOREST_GROUND_SOURCE_ID, MOUNTAIN_FOREST_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(event_layer, cell, "field_mountain_forest_event", MOUNTAIN_FOREST_EVENT_SOURCE_ID, MOUNTAIN_FOREST_EVENT_ATLAS_COORDS, 0)
					else:
						_set_config_cell(ground_layer, cell, "field_mountain_grass_ground", MOUNTAIN_GRASS_GROUND_SOURCE_ID, MOUNTAIN_GRASS_GROUND_ATLAS_COORDS, 0)
						_set_config_cell(event_layer, cell, "field_mountain_grass_event", MOUNTAIN_GRASS_EVENT_SOURCE_ID, MOUNTAIN_GRASS_EVENT_ATLAS_COORDS, 0)

				BIOME_LAKE:
					_set_config_cell(ground_layer, cell, "field_lake_ground", LAKE_GROUND_SOURCE_ID, LAKE_GROUND_ATLAS_COORDS, 0)
					_set_config_cell(event_layer, cell, "field_lake_event", LAKE_EVENT_SOURCE_ID, LAKE_EVENT_ATLAS_COORDS, 0)

	for x in range(map_width):
		_set_config_cell(wall_layer, Vector2i(x, 0), "field_border_wall", BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		_set_config_cell(wall_layer, Vector2i(x, map_height - 1), "field_border_wall", BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		_set_config_cell(wall_layer, Vector2i(0, y), "field_border_wall", BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		_set_config_cell(wall_layer, Vector2i(map_width - 1, y), "field_border_wall", BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)


func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if terrain_result.is_empty():
		return result

	for y in range(map_height):
		for x in range(map_width):
			var terrain: int = terrain_result[y][x]
			if terrain == TERRAIN_SAND or terrain == TERRAIN_GRASS:
				result.append(Vector2i(x, y))

	return result


func _is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < map_width and y >= 0 and y < map_height
