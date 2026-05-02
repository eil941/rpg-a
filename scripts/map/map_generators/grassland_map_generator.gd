extends BaseMapGenerator
class_name GrasslandMapGenerator

const TERRAIN_SEA := 0
const TERRAIN_SAND := 1
const TERRAIN_GRASS := 2
const TERRAIN_FOREST := 3
const TERRAIN_ROCK := 4
const TERRAIN_WATER := 5

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

	randomize()

	var forest_noise := FastNoiseLite.new()
	forest_noise.seed = randi()
	forest_noise.frequency = 0.022
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var rock_noise := FastNoiseLite.new()
	rock_noise.seed = randi() + 1000
	rock_noise.frequency = 0.028
	rock_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = randi() + 2000
	detail_noise.frequency = 0.08
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# =========================
	# 1. ベース地形生成
	# 基本は草原、森と岩は塊で出す
	# =========================
	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			var f := (forest_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var r := (rock_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var d := (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var terrain := TERRAIN_GRASS

			if r > 0.86:
				terrain = TERRAIN_ROCK
			elif f > 0.68:
				terrain = TERRAIN_FOREST
			else:
				terrain = TERRAIN_GRASS

			# 細部を少し崩す
			if terrain == TERRAIN_FOREST and d < 0.08:
				terrain = TERRAIN_GRASS
			elif terrain == TERRAIN_ROCK and d < 0.18:
				terrain = TERRAIN_GRASS
			elif terrain == TERRAIN_GRASS and d > 0.97:
				terrain = TERRAIN_FOREST

			row.append(terrain)

		terrain_result.append(row)

	# =========================
	# 2. 広場を作る
	# 中央寄りに少し大きめの草地
	# =========================
	carve_clearing(Vector2i(map_width / 2, map_height / 2), 4)

	# =========================
	# 3. 池を作る
	# 1つだけ置く
	# =========================
	if randf() < 0.45:
		var pond_center := Vector2i(
			randi_range(4, map_width - 5),
			randi_range(4, map_height - 5)
		)
		var pond_radius := randi_range(2, 4)
		carve_pond(pond_center, pond_radius)

	# =========================
	# 4. 道を作る
	# 左から右にゆるく通す
	# =========================
	if randf() < 0.55:
		var path_y := clampi(map_height / 2 + randi_range(-4, 4), 2, map_height - 3)
		carve_path(path_y)

	# =========================
	# 5. 水辺補正
	# 水の隣の草を砂にする
	# 森が水に近すぎるなら草へ落とす
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var current: int = terrain_result[y][x]

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

			if current == TERRAIN_GRASS and near_water:
				terrain_result[y][x] = TERRAIN_SAND
			elif current == TERRAIN_FOREST and near_water:
				terrain_result[y][x] = TERRAIN_GRASS

	# =========================
	# 6. 外周は通れないように調整
	# 見た目は草地のままでもいいが、
	# 壁を置くので外周1マスは歩行不可扱い
	# =========================
	for x in range(map_width):
		if terrain_result[0][x] == TERRAIN_WATER:
			terrain_result[0][x] = TERRAIN_GRASS
		if terrain_result[map_height - 1][x] == TERRAIN_WATER:
			terrain_result[map_height - 1][x] = TERRAIN_GRASS

	for y in range(map_height):
		if terrain_result[y][0] == TERRAIN_WATER:
			terrain_result[y][0] = TERRAIN_GRASS
		if terrain_result[y][map_width - 1] == TERRAIN_WATER:
			terrain_result[y][map_width - 1] = TERRAIN_GRASS

	# =========================
	# 7. 描画
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var terrain: int = terrain_result[y][x]

			match terrain:
				TERRAIN_WATER:
					_set_config_cell(ground_layer, cell, "detail_water", 58, Vector2i(1, 4), 0)

				TERRAIN_SAND:
					_set_config_cell(ground_layer, cell, "detail_sand", 45, Vector2i(1, 4), 0)

				TERRAIN_GRASS:
					_set_config_cell(ground_layer, cell, "detail_grass", 48, Vector2i(1, 4), 0)

				TERRAIN_FOREST:
					_set_config_cell(ground_layer, cell, "detail_forest", 42, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					_set_config_cell(ground_layer, cell, "detail_rock_ground", 26, Vector2i(1, 4), 0)
					_set_config_cell(wall_layer, cell, "detail_rock_wall", 5, Vector2i(0, 0), 0)

	# =========================
	# 8. 外周Wall
	# =========================
	for x in range(map_width):
		_set_config_cell(event_layer, Vector2i(x, 0), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)
		_set_config_cell(event_layer, Vector2i(x, map_height - 1), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		_set_config_cell(event_layer, Vector2i(0, y), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)
		_set_config_cell(event_layer, Vector2i(map_width - 1, y), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)


func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if terrain_result.is_empty():
		return result

	for y in range(map_height):
		for x in range(map_width):
			if x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1:
				continue

			var terrain: int = terrain_result[y][x]

			if terrain == TERRAIN_SAND or terrain == TERRAIN_GRASS:
				result.append(Vector2i(x, y))

	return result


func carve_clearing(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 1 or x >= map_width - 1 or y < 1 or y >= map_height - 1:
				continue

			var dx := x - center.x
			var dy := y - center.y

			if dx * dx + dy * dy <= radius * radius:
				terrain_result[y][x] = TERRAIN_GRASS


func carve_pond(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius - 2, center.y + radius + 3):
		for x in range(center.x - radius - 2, center.x + radius + 3):
			if x < 1 or x >= map_width - 1 or y < 1 or y >= map_height - 1:
				continue

			var dx := x - center.x
			var dy := y - center.y
			var dist2 := dx * dx + dy * dy

			var noise_offset := randi_range(-2, 2)
			var water_limit := radius * radius + noise_offset
			var sand_limit := (radius + 1) * (radius + 1) + noise_offset

			if dist2 <= water_limit:
				terrain_result[y][x] = TERRAIN_WATER
			elif dist2 <= sand_limit:
				if terrain_result[y][x] == TERRAIN_GRASS and randf() < 0.65:
					terrain_result[y][x] = TERRAIN_SAND


func carve_path(start_y: int) -> void:
	var y := start_y

	for x in range(1, map_width - 1):
		y += randi_range(-1, 1)
		y = clampi(y, 1, map_height - 2)

		terrain_result[y][x] = TERRAIN_SAND

		if y > 1 and randf() < 0.35:
			terrain_result[y - 1][x] = TERRAIN_SAND
		if y < map_height - 2 and randf() < 0.35:
			terrain_result[y + 1][x] = TERRAIN_SAND
