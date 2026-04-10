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
# biome visual settings
# 値が同じでも意味ごとに分ける
# =========================

const OCEAN_GROUND_SOURCE_ID: int = 87
const OCEAN_GROUND_ATLAS_COORDS: Vector2i = Vector2i(0, 4)
const OCEAN_EVENT_SOURCE_ID: int = 87
const OCEAN_EVENT_ATLAS_COORDS: Vector2i = Vector2i(0, 4)

const COAST_GROUND_SOURCE_ID: int = 14
const COAST_GROUND_ATLAS_COORDS: Vector2i = Vector2i(1, 0)
const COAST_EVENT_SOURCE_ID: int = 14
const COAST_EVENT_ATLAS_COORDS: Vector2i = Vector2i(1, 0)

const PLAINS_GROUND_SOURCE_ID: int = 14
const PLAINS_GROUND_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const PLAINS_EVENT_SOURCE_ID: int = 14
const PLAINS_EVENT_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

const DRY_PLAINS_GROUND_SOURCE_ID: int = 25
const DRY_PLAINS_GROUND_ATLAS_COORDS: Vector2i = Vector2i(2, 0)
const DRY_PLAINS_EVENT_SOURCE_ID: int = 25
const DRY_PLAINS_EVENT_ATLAS_COORDS: Vector2i = Vector2i(2, 0)

const FOREST_GROUND_SOURCE_ID: int = 14
const FOREST_GROUND_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const FOREST_EVENT_SOURCE_ID: int = 14
const FOREST_EVENT_ATLAS_COORDS: Vector2i = Vector2i(5, 11)

const DESERT_GROUND_SOURCE_ID: int = 25
const DESERT_GROUND_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const DESERT_EVENT_SOURCE_ID: int = 25
const DESERT_EVENT_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

const HIGHLAND_GRASS_GROUND_SOURCE_ID: int = 73
const HIGHLAND_GRASS_GROUND_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const HIGHLAND_GRASS_EVENT_SOURCE_ID: int = 73
const HIGHLAND_GRASS_EVENT_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

const HIGHLAND_FOREST_GROUND_SOURCE_ID: int = 59
const HIGHLAND_FOREST_GROUND_ATLAS_COORDS: Vector2i = Vector2i(1, 0)
const HIGHLAND_FOREST_EVENT_SOURCE_ID: int = 59
const HIGHLAND_FOREST_EVENT_ATLAS_COORDS: Vector2i = Vector2i(7, 9)

const HIGHLAND_ROCK_GROUND_SOURCE_ID: int = 59
const HIGHLAND_ROCK_GROUND_ATLAS_COORDS: Vector2i = Vector2i(1, 6)
const HIGHLAND_ROCK_WALL_SOURCE_ID: int = 59
const HIGHLAND_ROCK_WALL_ATLAS_COORDS: Vector2i = Vector2i(1, 6)

const MOUNTAIN_GRASS_GROUND_SOURCE_ID: int = 58
const MOUNTAIN_GRASS_GROUND_ATLAS_COORDS: Vector2i = Vector2i(2, 0)
const MOUNTAIN_GRASS_EVENT_SOURCE_ID: int = 58
const MOUNTAIN_GRASS_EVENT_ATLAS_COORDS: Vector2i = Vector2i(2, 0)

const MOUNTAIN_FOREST_GROUND_SOURCE_ID: int = 58
const MOUNTAIN_FOREST_GROUND_ATLAS_COORDS: Vector2i = Vector2i(2, 0)
const MOUNTAIN_FOREST_EVENT_SOURCE_ID: int = 14
const MOUNTAIN_FOREST_EVENT_ATLAS_COORDS: Vector2i = Vector2i(1, 1)

const MOUNTAIN_ROCK_GROUND_SOURCE_ID: int = 58
const MOUNTAIN_ROCK_GROUND_ATLAS_COORDS: Vector2i = Vector2i(1, 5)
const MOUNTAIN_ROCK_WALL_SOURCE_ID: int = 58
const MOUNTAIN_ROCK_WALL_ATLAS_COORDS: Vector2i = Vector2i(1, 5)

const LAKE_GROUND_SOURCE_ID: int = 15
const LAKE_GROUND_ATLAS_COORDS: Vector2i = Vector2i(2, 4)
const LAKE_EVENT_SOURCE_ID: int = 15
const LAKE_EVENT_ATLAS_COORDS: Vector2i = Vector2i(2, 4)

const BORDER_WALL_SOURCE_ID: int = 86
const BORDER_WALL_ATLAS_COORDS: Vector2i = Vector2i(0, 4)

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
	p_world_seed: int = 0
) -> void:
	super(
		p_map_width,
		p_map_height,
		p_floor_source_id,
		p_wall_source_id,
		p_floor_atlas_coords,
		p_wall_atlas_coords
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
					ground_layer.set_cell(cell, OCEAN_GROUND_SOURCE_ID, OCEAN_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, OCEAN_EVENT_SOURCE_ID, OCEAN_EVENT_ATLAS_COORDS, 0)

				BIOME_COAST:
					ground_layer.set_cell(cell, COAST_GROUND_SOURCE_ID, COAST_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, COAST_EVENT_SOURCE_ID, COAST_EVENT_ATLAS_COORDS, 0)

				BIOME_PLAINS:
					ground_layer.set_cell(cell, PLAINS_GROUND_SOURCE_ID, PLAINS_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, PLAINS_EVENT_SOURCE_ID, PLAINS_EVENT_ATLAS_COORDS, 0)

				BIOME_DRY_PLAINS:
					ground_layer.set_cell(cell, DRY_PLAINS_GROUND_SOURCE_ID, DRY_PLAINS_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, DRY_PLAINS_EVENT_SOURCE_ID, DRY_PLAINS_EVENT_ATLAS_COORDS, 0)

				BIOME_FOREST:
					ground_layer.set_cell(cell, FOREST_GROUND_SOURCE_ID, FOREST_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, FOREST_EVENT_SOURCE_ID, FOREST_EVENT_ATLAS_COORDS, 0)

				BIOME_DESERT:
					ground_layer.set_cell(cell, DESERT_GROUND_SOURCE_ID, DESERT_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, DESERT_EVENT_SOURCE_ID, DESERT_EVENT_ATLAS_COORDS, 0)

				BIOME_HIGHLAND:
					var terrain_highland: int = terrain_result[y][x]
					if terrain_highland == TERRAIN_ROCK:
						ground_layer.set_cell(cell, HIGHLAND_ROCK_GROUND_SOURCE_ID, HIGHLAND_ROCK_GROUND_ATLAS_COORDS, 0)
						wall_layer.set_cell(cell, HIGHLAND_ROCK_WALL_SOURCE_ID, HIGHLAND_ROCK_WALL_ATLAS_COORDS, 0)
					elif terrain_highland == TERRAIN_FOREST:
						ground_layer.set_cell(cell, HIGHLAND_FOREST_GROUND_SOURCE_ID, HIGHLAND_FOREST_GROUND_ATLAS_COORDS, 0)
						event_layer.set_cell(cell, HIGHLAND_FOREST_EVENT_SOURCE_ID, HIGHLAND_FOREST_EVENT_ATLAS_COORDS, 0)
					else:
						ground_layer.set_cell(cell, HIGHLAND_GRASS_GROUND_SOURCE_ID, HIGHLAND_GRASS_GROUND_ATLAS_COORDS, 0)
						event_layer.set_cell(cell, HIGHLAND_GRASS_EVENT_SOURCE_ID, HIGHLAND_GRASS_EVENT_ATLAS_COORDS, 0)

				BIOME_MOUNTAIN:
					var terrain_mountain: int = terrain_result[y][x]
					if terrain_mountain == TERRAIN_ROCK:
						ground_layer.set_cell(cell, MOUNTAIN_ROCK_GROUND_SOURCE_ID, MOUNTAIN_ROCK_GROUND_ATLAS_COORDS, 0)
						wall_layer.set_cell(cell, MOUNTAIN_ROCK_WALL_SOURCE_ID, MOUNTAIN_ROCK_WALL_ATLAS_COORDS, 0)
					elif terrain_mountain == TERRAIN_FOREST:
						ground_layer.set_cell(cell, MOUNTAIN_FOREST_GROUND_SOURCE_ID, MOUNTAIN_FOREST_GROUND_ATLAS_COORDS, 0)
						event_layer.set_cell(cell, MOUNTAIN_FOREST_EVENT_SOURCE_ID, MOUNTAIN_FOREST_EVENT_ATLAS_COORDS, 0)
					else:
						ground_layer.set_cell(cell, MOUNTAIN_GRASS_GROUND_SOURCE_ID, MOUNTAIN_GRASS_GROUND_ATLAS_COORDS, 0)
						event_layer.set_cell(cell, MOUNTAIN_GRASS_EVENT_SOURCE_ID, MOUNTAIN_GRASS_EVENT_ATLAS_COORDS, 0)

				BIOME_LAKE:
					ground_layer.set_cell(cell, LAKE_GROUND_SOURCE_ID, LAKE_GROUND_ATLAS_COORDS, 0)
					event_layer.set_cell(cell, LAKE_EVENT_SOURCE_ID, LAKE_EVENT_ATLAS_COORDS, 0)

	for x in range(map_width):
		wall_layer.set_cell(Vector2i(x, 0), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		wall_layer.set_cell(Vector2i(x, map_height - 1), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		wall_layer.set_cell(Vector2i(0, y), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		wall_layer.set_cell(Vector2i(map_width - 1, y), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)


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
