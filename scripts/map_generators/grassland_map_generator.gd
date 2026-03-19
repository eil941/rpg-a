extends BaseMapGenerator
class_name GrasslandMapGenerator

const TERRAIN_SEA := 0
const TERRAIN_SAND := 1
const TERRAIN_GRASS := 2
const TERRAIN_FOREST := 3
const TERRAIN_ROCK := 4
const TERRAIN_WATER := 5

const BIOME_SEA := 0
const BIOME_PLAINS := 1
const BIOME_MOUNTAIN := 2

var terrain_result: Array = []

func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	var WALL_SOURCE_ID := 5
	var WALL_ATLAS_COORDS := Vector2i(0, 0)

	terrain_result.clear()
	ground_layer.clear()
	wall_layer.clear()
	event_layer.clear()

	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = randi()
	biome_noise.frequency = 0.03
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = randi() + 1000
	detail_noise.frequency = 0.08
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			var b := (biome_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var d := (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var terrain := TERRAIN_GRASS

			if b < 0.10:
				terrain = TERRAIN_WATER
			elif b < 0.16:
				terrain = TERRAIN_SAND
			elif b < 0.72:
				terrain = TERRAIN_GRASS
			elif b < 0.88:
				terrain = TERRAIN_FOREST
			else:
				terrain = TERRAIN_ROCK

			# 細部を少し崩す
			if terrain == TERRAIN_GRASS and d > 0.93:
				terrain = TERRAIN_FOREST
			elif terrain == TERRAIN_FOREST and d < 0.08:
				terrain = TERRAIN_GRASS
			elif terrain == TERRAIN_ROCK and d < 0.15:
				terrain = TERRAIN_GRASS

			row.append(terrain)

		terrain_result.append(row)

	# 水の隣の草を砂にする
	for y in range(map_height):
		for x in range(map_width):
			if terrain_result[y][x] != TERRAIN_GRASS:
				continue

			var near_water := false

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue

					var nx := x + dx
					var ny := y + dy

					if nx < 0 or nx >= map_width or ny < 0 or ny >= map_height:
						continue

					if terrain_result[ny][nx] == TERRAIN_WATER:
						near_water = true
						break

				if near_water:
					break

			if near_water:
				terrain_result[y][x] = TERRAIN_SAND

	

	# 描画
	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var terrain: int = terrain_result[y][x]

			match terrain:
				TERRAIN_WATER:
					ground_layer.set_cell(cell, 37, Vector2i(1, 4), 0)

				TERRAIN_SAND:
					ground_layer.set_cell(cell, 20, Vector2i(1, 4), 0)

				TERRAIN_GRASS:
					ground_layer.set_cell(cell, 29, Vector2i(1, 4), 0)

				TERRAIN_FOREST:
					ground_layer.set_cell(cell, 17, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					ground_layer.set_cell(cell, 6, Vector2i(1, 4), 0)
					wall_layer.set_cell(cell, 5, Vector2i(0, 0), 0)


# 外周は歩けないようにWall
	for x in range(map_width):
		event_layer.set_cell(Vector2i(x, 0), 0, WALL_ATLAS_COORDS, 0)
		event_layer.set_cell(Vector2i(x, map_height - 1), 0, WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		event_layer.set_cell(Vector2i(0, y), 0, WALL_ATLAS_COORDS, 0)
		event_layer.set_cell(Vector2i(map_width - 1, y), 0, WALL_ATLAS_COORDS, 0)


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
