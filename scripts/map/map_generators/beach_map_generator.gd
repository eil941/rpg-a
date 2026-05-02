extends BaseMapGenerator
class_name BeachMapGenerator

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

	var grass_noise = FastNoiseLite.new()
	grass_noise.seed = randi()
	grass_noise.frequency = 0.03
	grass_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var rock_noise = FastNoiseLite.new()
	rock_noise.seed = randi() + 1000
	rock_noise.frequency = 0.05
	rock_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# 0=左海岸, 1=上海岸, 2=右海岸, 3=下海岸
	var coast_type = randi_range(0, 3)

	# まず全体を砂で埋める
	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(TERRAIN_SAND)
		terrain_result.append(row)

	# =========================
	# 1. 海岸線を作る
	# 最大でマップの約80%近くまで海を許容
	# =========================
	match coast_type:
		0:
			_generate_left_coast()
		1:
			_generate_top_coast()
		2:
			_generate_right_coast()
		3:
			_generate_bottom_coast()

	# =========================
	# 2. 入り江を0～2個作る
	# =========================
	var inlet_count = randi_range(0, 2)
	for i in range(inlet_count):
		match coast_type:
			0:
				_carve_left_inlet()
			1:
				_carve_top_inlet()
			2:
				_carve_right_inlet()
			3:
				_carve_bottom_inlet()

	# =========================
	# 3. 岬を0～2個作る
	# =========================
	var cape_count = randi_range(0, 2)
	for i in range(cape_count):
		match coast_type:
			0:
				_push_left_cape()
			1:
				_push_top_cape()
			2:
				_push_right_cape()
			3:
				_push_bottom_cape()

	# =========================
	# 4. 草をかなり少なめに生やす
	# 海からかなり離れた場所だけ
	# 0個でも普通にあり得る
	# =========================
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_SAND:
				continue

			var sea_dist = _distance_to_nearest_sand_from_land(x, y)
			var g = (grass_noise.get_noise_2d(x, y) + 1.0) * 0.5

			if sea_dist < 11:
				continue

			if sea_dist >= 11 and sea_dist < 15:
				if g > 0.78 and randf() < 0.06:
					terrain_result[y][x] = TERRAIN_GRASS
			elif sea_dist >= 15:
				if g > 0.72 and randf() < 0.10:
					terrain_result[y][x] = TERRAIN_GRASS

	# =========================
	# 5. 岩場を少量、塊で置く
	# 水際すぎる場所は避ける
	# =========================
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_SAND and terrain_result[y][x] != TERRAIN_GRASS:
				continue

			var sea_dist = _distance_to_nearest_sand_from_land(x, y)
			var r = (rock_noise.get_noise_2d(x, y) + 1.0) * 0.5

			if sea_dist >= 3 and r > 0.90:
				terrain_result[y][x] = TERRAIN_ROCK

	# 岩を少し広げる
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_SAND and terrain_result[y][x] != TERRAIN_GRASS:
				continue

			var rock_neighbors = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					if terrain_result[y + dy][x + dx] == TERRAIN_ROCK:
						rock_neighbors += 1

			if rock_neighbors >= 3 and randf() < 0.35:
				terrain_result[y][x] = TERRAIN_ROCK

	# =========================
	# 6. 水際の草を砂へ戻す
	# =========================
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if terrain_result[y][x] != TERRAIN_GRASS:
				continue

			if _is_near_terrain(x, y, TERRAIN_SEA_SHALLOW) or _is_near_terrain(x, y, TERRAIN_SEA) or _is_near_terrain(x, y, TERRAIN_SEA_DEEP):
				terrain_result[y][x] = TERRAIN_SAND

	# =========================
	# 7. 海の深さを決める
	# 砂浜からの距離で
	# 浅い海 → 普通の海 → 深い海
	# =========================
	_apply_sea_depths()

	# =========================
	# 8. たまに海岸沿いの道を作る
	# =========================
	if randf() < 0.45:
		match coast_type:
			0, 2:
				var path_x = clampi(map_width / 2 + randi_range(-2, 2), 3, map_width - 4)
				_carve_vertical_beach_path(path_x)
			1, 3:
				var path_y = clampi(map_height / 2 + randi_range(-2, 2), 3, map_height - 4)
				_carve_horizontal_beach_path(path_y)

	# =========================
	# 9. 外周Wall
	# =========================
	for x in range(map_width):
		_set_config_cell(event_layer, Vector2i(x, 0), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)
		_set_config_cell(event_layer, Vector2i(x, map_height - 1), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		_set_config_cell(event_layer, Vector2i(0, y), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)
		_set_config_cell(event_layer, Vector2i(map_width - 1, y), "detail_border_event", 0, WALL_ATLAS_COORDS, 0)

	# =========================
	# 10. 描画
	# 海は全部同じ見た目
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var cell = Vector2i(x, y)
			var terrain = terrain_result[y][x]

			match terrain:
				TERRAIN_SEA_SHALLOW:
					_set_config_cell(ground_layer, cell, "detail_sea_shallow", 58, Vector2i(1, 4), 0)
					
				TERRAIN_SEA:
					_set_config_cell(ground_layer, cell, "detail_sea", 57, Vector2i(1, 4), 0)
					
				TERRAIN_SEA_DEEP:
					_set_config_cell(ground_layer, cell, "detail_sea_deep", 60, Vector2i(1, 4), 0)
					
				TERRAIN_SAND:
					_set_config_cell(ground_layer, cell, "detail_sand", 45, Vector2i(1, 4), 0)

				TERRAIN_GRASS:
					_set_config_cell(ground_layer, cell, "detail_grass", 48, Vector2i(1, 4), 0)

				TERRAIN_FOREST:
					_set_config_cell(ground_layer, cell, "detail_forest", 42, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					_set_config_cell(ground_layer, cell, "detail_rock_ground", 26, Vector2i(1, 4), 0)
					_set_config_cell(wall_layer, cell, "detail_rock_wall", 5, Vector2i(0, 0), 0)


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


func _generate_left_coast() -> void:
	var max_coast = max(4, int(map_width * 0.8))
	var coast_x = randi_range(4, max_coast)

	for y in range(map_height):
		coast_x += randi_range(-3, 3)
		coast_x = clampi(coast_x, 3, max_coast)

		for x in range(coast_x):
			terrain_result[y][x] = TERRAIN_SEA


func _generate_top_coast() -> void:
	var max_coast = max(4, int(map_height * 0.8))
	var coast_y = randi_range(4, max_coast)

	for x in range(map_width):
		coast_y += randi_range(-3, 3)
		coast_y = clampi(coast_y, 3, max_coast)

		for y in range(coast_y):
			terrain_result[y][x] = TERRAIN_SEA


func _generate_right_coast() -> void:
	var max_coast = max(4, int(map_width * 0.8))
	var coast_w = randi_range(4, max_coast)

	for y in range(map_height):
		coast_w += randi_range(-3, 3)
		coast_w = clampi(coast_w, 3, max_coast)

		for x in range(map_width - coast_w, map_width):
			terrain_result[y][x] = TERRAIN_SEA


func _generate_bottom_coast() -> void:
	var max_coast = max(4, int(map_height * 0.8))
	var coast_h = randi_range(4, max_coast)

	for x in range(map_width):
		coast_h += randi_range(-3, 3)
		coast_h = clampi(coast_h, 3, max_coast)

		for y in range(map_height - coast_h, map_height):
			terrain_result[y][x] = TERRAIN_SEA


func _carve_left_inlet() -> void:
	var center_y = randi_range(4, map_height - 5)
	var depth = randi_range(3, 6)
	var half_height = randi_range(2, 4)

	for y in range(center_y - half_height, center_y + half_height + 1):
		if y < 1 or y >= map_height - 1:
			continue

		var local_depth = depth - abs(y - center_y)
		local_depth = max(local_depth, 1)

		for x in range(local_depth):
			if x >= 1 and x < map_width - 1:
				terrain_result[y][x] = TERRAIN_SEA


func _carve_top_inlet() -> void:
	var center_x = randi_range(4, map_width - 5)
	var depth = randi_range(3, 6)
	var half_width = randi_range(2, 4)

	for x in range(center_x - half_width, center_x + half_width + 1):
		if x < 1 or x >= map_width - 1:
			continue

		var local_depth = depth - abs(x - center_x)
		local_depth = max(local_depth, 1)

		for y in range(local_depth):
			if y >= 1 and y < map_height - 1:
				terrain_result[y][x] = TERRAIN_SEA


func _carve_right_inlet() -> void:
	var center_y = randi_range(4, map_height - 5)
	var depth = randi_range(3, 6)
	var half_height = randi_range(2, 4)

	for y in range(center_y - half_height, center_y + half_height + 1):
		if y < 1 or y >= map_height - 1:
			continue

		var local_depth = depth - abs(y - center_y)
		local_depth = max(local_depth, 1)

		for x in range(map_width - local_depth, map_width):
			if x >= 1 and x < map_width - 1:
				terrain_result[y][x] = TERRAIN_SEA


func _carve_bottom_inlet() -> void:
	var center_x = randi_range(4, map_width - 5)
	var depth = randi_range(3, 6)
	var half_width = randi_range(2, 4)

	for x in range(center_x - half_width, center_x + half_width + 1):
		if x < 1 or x >= map_width - 1:
			continue

		var local_depth = depth - abs(x - center_x)
		local_depth = max(local_depth, 1)

		for y in range(map_height - local_depth, map_height):
			if y >= 1 and y < map_height - 1:
				terrain_result[y][x] = TERRAIN_SEA


func _push_left_cape() -> void:
	var center_y = randi_range(4, map_height - 5)
	var start_x = randi_range(3, max(4, map_width / 3))
	var half_height = randi_range(1, 3)

	for y in range(center_y - half_height, center_y + half_height + 1):
		if y < 1 or y >= map_height - 1:
			continue

		var width = start_x - abs(y - center_y)
		width = max(width, 1)

		for x in range(width):
			if terrain_result[y][x] != TERRAIN_SEA:
				terrain_result[y][x] = TERRAIN_SAND


func _push_top_cape() -> void:
	var center_x = randi_range(4, map_width - 5)
	var start_y = randi_range(3, max(4, map_height / 3))
	var half_width = randi_range(1, 3)

	for x in range(center_x - half_width, center_x + half_width + 1):
		if x < 1 or x >= map_width - 1:
			continue

		var height = start_y - abs(x - center_x)
		height = max(height, 1)

		for y in range(height):
			if terrain_result[y][x] != TERRAIN_SEA:
				terrain_result[y][x] = TERRAIN_SAND


func _push_right_cape() -> void:
	var center_y = randi_range(4, map_height - 5)
	var start_w = randi_range(3, max(4, map_width / 3))
	var half_height = randi_range(1, 3)

	for y in range(center_y - half_height, center_y + half_height + 1):
		if y < 1 or y >= map_height - 1:
			continue

		var width = start_w - abs(y - center_y)
		width = max(width, 1)

		for x in range(map_width - width, map_width):
			if terrain_result[y][x] != TERRAIN_SEA:
				terrain_result[y][x] = TERRAIN_SAND


func _push_bottom_cape() -> void:
	var center_x = randi_range(4, map_width - 5)
	var start_h = randi_range(3, max(4, map_height / 3))
	var half_width = randi_range(1, 3)

	for x in range(center_x - half_width, center_x + half_width + 1):
		if x < 1 or x >= map_width - 1:
			continue

		var height = start_h - abs(x - center_x)
		height = max(height, 1)

		for y in range(map_height - height, map_height):
			if terrain_result[y][x] != TERRAIN_SEA:
				terrain_result[y][x] = TERRAIN_SAND


func _apply_sea_depths() -> void:
	var new_map: Array = []

	var depth_noise = FastNoiseLite.new()
	depth_noise.seed = randi() + 5000
	depth_noise.frequency = 0.3
	depth_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for y in range(map_height):
		var row: Array = []
		for x in range(map_width):
			row.append(terrain_result[y][x])
		new_map.append(row)

	for y in range(map_height):
		for x in range(map_width):
			if terrain_result[y][x] != TERRAIN_SEA:
				continue

			var sand_dist = _distance_from_sea_to_nearest_sand(x, y)

			# -1.0 ～ 1.0 -> だいたい -1.5 ～ 1.5 くらいの補正
			var n = depth_noise.get_noise_2d(x, y)
			var adjusted_dist = float(sand_dist) + n * 2.0

			if adjusted_dist <= 10.0:
				new_map[y][x] = TERRAIN_SEA_SHALLOW
			elif adjusted_dist <= 30.0:
				new_map[y][x] = TERRAIN_SEA
			else:
				new_map[y][x] = TERRAIN_SEA_DEEP

	terrain_result = new_map



func _distance_from_sea_to_nearest_sand(x: int, y: int) -> int:
	var best = 999999

	for yy in range(map_height):
		for xx in range(map_width):
			if terrain_result[yy][xx] != TERRAIN_SAND:
				continue

			var dist = abs(xx - x) + abs(yy - y)
			if dist < best:
				best = dist

	return best


func _distance_to_nearest_sand_from_land(x: int, y: int) -> int:
	var best = 999999

	for yy in range(map_height):
		for xx in range(map_width):
			if terrain_result[yy][xx] != TERRAIN_SEA and terrain_result[yy][xx] != TERRAIN_SEA_SHALLOW and terrain_result[yy][xx] != TERRAIN_SEA_DEEP:
				continue

			var dist = abs(xx - x) + abs(yy - y)
			if dist < best:
				best = dist

	return best


func _is_near_terrain(x: int, y: int, target: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx = x + dx
			var ny = y + dy

			if nx < 0 or nx >= map_width or ny < 0 or ny >= map_height:
				continue

			if terrain_result[ny][nx] == target:
				return true

	return false


func _carve_horizontal_beach_path(start_y: int) -> void:
	var y = start_y

	for x in range(1, map_width - 1):
		y += randi_range(-1, 1)
		y = clampi(y, 1, map_height - 2)

		if terrain_result[y][x] != TERRAIN_SEA_SHALLOW and terrain_result[y][x] != TERRAIN_SEA and terrain_result[y][x] != TERRAIN_SEA_DEEP and terrain_result[y][x] != TERRAIN_ROCK:
			terrain_result[y][x] = TERRAIN_SAND


func _carve_vertical_beach_path(start_x: int) -> void:
	var x = start_x

	for y in range(1, map_height - 1):
		x += randi_range(-1, 1)
		x = clampi(x, 1, map_width - 2)

		if terrain_result[y][x] != TERRAIN_SEA_SHALLOW and terrain_result[y][x] != TERRAIN_SEA and terrain_result[y][x] != TERRAIN_SEA_DEEP and terrain_result[y][x] != TERRAIN_ROCK:
			terrain_result[y][x] = TERRAIN_SAND
