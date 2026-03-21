extends BaseMapGenerator
class_name SeaMapGenerator

const TERRAIN_SEA_SHALLOW = 0
const TERRAIN_SEA = 1
const TERRAIN_SEA_DEEP = 2
const TERRAIN_SAND = 3
const TERRAIN_GRASS = 4
const TERRAIN_FOREST = 5
const TERRAIN_ROCK = 6
const TERRAIN_WATER = 7

var terrain_result: Array = []


func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	var WALL_SOURCE_ID = 5
	var WALL_ATLAS_COORDS = Vector2i(0, 0)

	terrain_result.clear()
	ground_layer.clear()
	wall_layer.clear()
	event_layer.clear()

	randomize()

	var sea_noise = FastNoiseLite.new()
	sea_noise.seed = randi()
	sea_noise.frequency = 0.04
	sea_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var reef_noise = FastNoiseLite.new()
	reef_noise.seed = randi() + 1000
	reef_noise.frequency = 0.08
	reef_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# =========================
	# 1. 全体を深い海で埋める
	# =========================
	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(TERRAIN_SEA_DEEP)
		terrain_result.append(row)

	# =========================
	# 2. 一部だけ普通の海の塊を作る
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var n = (sea_noise.get_noise_2d(x, y) + 1.0) * 0.5

			if n > 0.70:
				terrain_result[y][x] = TERRAIN_SEA

	# 普通の海を少し広げて塊感を出す
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_SEA_DEEP:
				continue

			var sea_neighbors = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if terrain_result[y + dy][x + dx] == TERRAIN_SEA:
						sea_neighbors += 1

			if sea_neighbors >= 4 and randf() < 0.45:
				terrain_result[y][x] = TERRAIN_SEA

	# =========================
	# 3. 島を10%で1個だけ作る
	# =========================
	if randf() < 0.10:
		var center = Vector2i(
			randi_range(7, map_width - 8),
			randi_range(7, map_height - 8)
		)

		var radius = 3
		var size_roll = randf()

		if size_roll < 0.45:
			radius = 2   # 小さめ
		elif size_roll < 0.80:
			radius = 3   # やや小さめ
		else:
			radius = randi_range(4, 6)   # 中くらい

		_carve_island(center, radius)

	# =========================
	# 4. 岩礁を少し置く
	# 浅い海や普通の海の一部に出す
	# =========================
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_SEA_SHALLOW and terrain_result[y][x] != TERRAIN_SEA:
				continue

			var r = (reef_noise.get_noise_2d(x, y) + 1.0) * 0.5
			if r > 0.95 and randf() < 0.25:
				terrain_result[y][x] = TERRAIN_ROCK

	# =========================
	# 5. 外周Wall
	# =========================
	for x in range(map_width):
		event_layer.set_cell(Vector2i(x, 0),0, WALL_ATLAS_COORDS, 0)
		event_layer.set_cell(Vector2i(x, map_height - 1), 0, WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		event_layer.set_cell(Vector2i(0, y), 0, WALL_ATLAS_COORDS, 0)
		event_layer.set_cell(Vector2i(map_width - 1, y), 0, WALL_ATLAS_COORDS, 0)
	# =========================
	# 6. 描画
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var cell = Vector2i(x, y)
			var terrain = terrain_result[y][x]

			match terrain:
				TERRAIN_SEA_SHALLOW:
					ground_layer.set_cell(cell, 58, Vector2i(1, 4), 0)

				TERRAIN_SEA:
					ground_layer.set_cell(cell, 57, Vector2i(1, 4), 0)

				TERRAIN_SEA_DEEP:
					ground_layer.set_cell(cell, 60, Vector2i(1, 4), 0)

				TERRAIN_SAND:
					ground_layer.set_cell(cell, 45, Vector2i(1, 4), 0)

				TERRAIN_GRASS:
					ground_layer.set_cell(cell, 48, Vector2i(1, 4), 0)

				TERRAIN_FOREST:
					ground_layer.set_cell(cell, 42, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					ground_layer.set_cell(cell, 26, Vector2i(1, 4), 0)
					wall_layer.set_cell(cell, 5, Vector2i(0, 0), 0)


func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if terrain_result.is_empty():
		return result

	for y in range(map_height):
		for x in range(map_width):
			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				continue

			var terrain = terrain_result[y][x]
			if terrain == TERRAIN_SAND or terrain == TERRAIN_GRASS:
				result.append(Vector2i(x, y))

	return result


func _carve_island(center: Vector2i, radius: int) -> void:
	var shape_noise = FastNoiseLite.new()
	shape_noise.seed = randi() + 7000
	shape_noise.frequency = 0.18
	shape_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for y in range(center.y - radius - 8, center.y + radius + 9):
		for x in range(center.x - radius - 8, center.x + radius + 9):
			if x < 1 or x >= map_width - 1 or y < 1 or y >= map_height - 1:
				continue

			var dx = x - center.x
			var dy = y - center.y
			var dist = sqrt(float(dx * dx + dy * dy))

			# 島の形を崩すノイズ
			var n = shape_noise.get_noise_2d(x, y)

			# 半径そのものを場所ごとに揺らす
			var grass_radius = float(radius) + n * 3.0
			var sand_radius = float(radius + 1) + n * 2.7
			var shallow_radius = float(radius + 3) + n * 2.2
			var normal_radius = float(radius + 6) + n * 1.8

			if dist <= grass_radius:
				terrain_result[y][x] = TERRAIN_GRASS
			elif dist <= sand_radius:
				terrain_result[y][x] = TERRAIN_SAND
			elif dist <= shallow_radius:
				terrain_result[y][x] = TERRAIN_SEA_SHALLOW
			elif dist <= normal_radius:
				if terrain_result[y][x] == TERRAIN_SEA_DEEP:
					terrain_result[y][x] = TERRAIN_SEA
