extends BaseMapGenerator
class_name ForestMapGenerator

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
	forest_noise.frequency = 0.02
	forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var rock_noise := FastNoiseLite.new()
	rock_noise.seed = randi() + 1000
	rock_noise.frequency = 0.03
	rock_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var water_noise := FastNoiseLite.new()
	water_noise.seed = randi() + 2000
	water_noise.frequency = 0.025
	water_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = randi() + 3000
	detail_noise.frequency = 0.08
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# =========================
	# 1. ベース生成
	# 森を主役にするが、草地も少し増やす
	# =========================
	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			var f := (forest_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var r := (rock_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var w := (water_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var d := (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			var terrain := TERRAIN_FOREST

			if r > 0.91:
				terrain = TERRAIN_ROCK
			elif w < 0.06:
				terrain = TERRAIN_WATER
			elif f < 0.24:
				terrain = TERRAIN_GRASS
			else:
				terrain = TERRAIN_FOREST

			# 細部を少し崩す
			if terrain == TERRAIN_FOREST and d < 0.08:
				terrain = TERRAIN_GRASS
			elif terrain == TERRAIN_ROCK and d < 0.12:
				terrain = TERRAIN_FOREST

			row.append(terrain)

		terrain_result.append(row)

	# =========================
	# 2. 広場を1〜3個作る
	# 木じゃないエリアを多少作る
	# =========================
	var clearing_count := randi_range(1, 3)
	for i in range(clearing_count):
		var center := Vector2i(
			randi_range(4, map_width - 5),
			randi_range(4, map_height - 5)
		)
		var radius := randi_range(3, 6)
		carve_clearing(center, radius)

	# =========================
	# 3. 池を0〜1個
	# =========================
	if randf() < 0.40:
		var pond_center := Vector2i(
			randi_range(4, map_width - 5),
			randi_range(4, map_height - 5)
		)
		var pond_radius := randi_range(2, 4)
		carve_pond(pond_center, pond_radius)

	# =========================
	# 4. 道を0〜1本
	# =========================
	if randf() < 0.45:
		if randf() < 0.5:
			var path_y := clampi(map_height / 2 + randi_range(-4, 4), 2, map_height - 3)
			carve_path_horizontal(path_y)
		else:
			var path_x := clampi(map_width / 2 + randi_range(-4, 4), 2, map_width - 3)
			carve_path_vertical(path_x)

	# =========================
	# 5. 森が密すぎる部分を少し抜く
	# 木じゃないエリアを少し増やす
	# =========================
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_FOREST:
				continue

			var forest_count := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if terrain_result[y + dy][x + dx] == TERRAIN_FOREST:
						forest_count += 1

			# 森に囲まれすぎた場所をたまに草へ落とす
			if forest_count >= 7 and randf() < 0.12:
				terrain_result[y][x] = TERRAIN_GRASS

	# =========================
	# 6. 水辺補正
	# 水辺は砂や草に寄せる
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

			if current == TERRAIN_FOREST and near_water:
				terrain_result[y][x] = TERRAIN_GRASS
			elif current == TERRAIN_GRASS and near_water:
				terrain_result[y][x] = TERRAIN_SAND

	# =========================
	# 7. 外周の水は除去
	# =========================
	for x in range(map_width):
		if terrain_result[0][x] == TERRAIN_WATER:
			terrain_result[0][x] = TERRAIN_FOREST
		if terrain_result[map_height - 1][x] == TERRAIN_WATER:
			terrain_result[map_height - 1][x] = TERRAIN_FOREST

	for y in range(map_height):
		if terrain_result[y][0] == TERRAIN_WATER:
			terrain_result[y][0] = TERRAIN_FOREST
		if terrain_result[y][map_width - 1] == TERRAIN_WATER:
			terrain_result[y][map_width - 1] = TERRAIN_FOREST

	# =========================
	# 8. 描画
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
	# 9. 外周Wall
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
				if terrain_result[y][x] == TERRAIN_GRASS and randf() < 0.60:
					terrain_result[y][x] = TERRAIN_SAND


func carve_path_horizontal(start_y: int) -> void:
	var y := start_y

	for x in range(1, map_width - 1):
		y += randi_range(-1, 1)
		y = clampi(y, 1, map_height - 2)

		terrain_result[y][x] = TERRAIN_SAND

		if y > 1 and randf() < 0.35:
			terrain_result[y - 1][x] = TERRAIN_SAND
		if y < map_height - 2 and randf() < 0.35:
			terrain_result[y + 1][x] = TERRAIN_SAND


func carve_path_vertical(start_x: int) -> void:
	var x := start_x

	for y in range(1, map_height - 1):
		x += randi_range(-1, 1)
		x = clampi(x, 1, map_width - 2)

		terrain_result[y][x] = TERRAIN_SAND

		if x > 1 and randf() < 0.35:
			terrain_result[y][x - 1] = TERRAIN_SAND
		if x < map_width - 2 and randf() < 0.35:
			terrain_result[y][x + 1] = TERRAIN_SAND
