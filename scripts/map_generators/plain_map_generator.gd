extends BaseMapGenerator
class_name PlainMapGenerator

const TERRAIN_SEA := 0
const TERRAIN_SAND := 1
const TERRAIN_GRASS := 2
const TERRAIN_FOREST := 3
const TERRAIN_ROCK := 4

const BIOME_SEA := 0
const BIOME_PLAINS := 1
const BIOME_MOUNTAIN := 2

var terrain_result: Array = []

func generate_map(
	ground_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	event_layer: TileMapLayer
) -> void:
	# =========================
	# タイル定義
	# 必要に応じて外部から差し替えてください
	# =========================
	var SEA_SOURCE_ID := 0
	var BEACH_SOURCE_ID := 1
	var GRASS_SOURCE_ID := 2
	var FOREST_SOURCE_ID := 3
	var MOUNTAIN_SOURCE_ID := 4

	var SEA_ATLAS_COORDS := Vector2i(0, 0)
	var BEACH_ATLAS_COORDS := Vector2i(1, 0)
	var GRASS_ATLAS_COORDS := Vector2i(2, 0)
	var FOREST_ATLAS_COORDS := Vector2i(3, 0)
	var MOUNTAIN_ATLAS_COORDS := Vector2i(4, 0)

	# =========================
	# マップサイズ
	# 既存の map_width / map_height を使う想定
	# =========================

	# 各セルの地形名を保持
	var biome_map: Array = []
	for y in range(map_height):
		biome_map.append([])
		for x in range(map_width):
			biome_map[y].append("grass")

	# =========================
	# 1. 海を作る
	# 左側から数列を海にする
	# 波打ち際を少し揺らす
	# =========================
	for y in range(map_height):
		var coast_x := 2 + randi() % 3  # 2～4列目くらいまで海
		for x in range(coast_x):
			biome_map[y][x] = "sea"

	# =========================
	# 2. 海に隣接する陸を砂浜にする
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] == "sea":
				continue

			var cell := Vector2i(x, y)
			if _is_adjacent_to_biome(cell, biome_map, "sea"):
				biome_map[y][x] = "beach"

	# =========================
	# 3. 森を作る
	# 海からある程度離れた場所だけ候補にする
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass":
				continue

			var sea_distance := _distance_from_left_sea(x, biome_map, y)

			# 海から近い場所には森を置かない
			if sea_distance >= 4:
				if randf() < 0.18:
					biome_map[y][x] = "forest"

	# 森を少し広げる
	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass":
				continue

			var cell := Vector2i(x, y)
			var sea_distance := _distance_from_left_sea(x, biome_map, y)

			if sea_distance >= 4 and _count_adjacent_biome(cell, biome_map, "forest") >= 2:
				if randf() < 0.55:
					biome_map[y][x] = "forest"

	# =========================
	# 4. 山岳を作る
	# 海から十分遠い場所にしか置かない
	# 森の奥に出やすくする
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass" and biome_map[y][x] != "forest":
				continue

			var sea_distance := _distance_from_left_sea(x, biome_map, y)

			# 海の近くには絶対置かない
			if sea_distance < 7:
				continue

			var cell := Vector2i(x, y)
			var forest_neighbors := _count_adjacent_biome(cell, biome_map, "forest")

			if forest_neighbors >= 2 and randf() < 0.22:
				biome_map[y][x] = "mountain"

	# 山岳を少し広げる
	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass" and biome_map[y][x] != "forest":
				continue

			var sea_distance := _distance_from_left_sea(x, biome_map, y)
			if sea_distance < 7:
				continue

			var cell := Vector2i(x, y)
			if _count_adjacent_biome(cell, biome_map, "mountain") >= 2:
				if randf() < 0.45:
					biome_map[y][x] = "mountain"

	# =========================
	# 5. 描画
	# 今回は全部 ground_layer に置いている
	# 必要なら山岳だけ wall_layer に分けてもよい
	# =========================
	for y in range(map_height):
		for x in range(map_width):
			var cell := Vector2i(x, y)

			match biome_map[y][x]:
				"sea":
					ground_layer.set_cell(cell, SEA_SOURCE_ID, SEA_ATLAS_COORDS, 0)
				"beach":
					ground_layer.set_cell(cell, BEACH_SOURCE_ID, BEACH_ATLAS_COORDS, 0)
				"grass":
					ground_layer.set_cell(cell, GRASS_SOURCE_ID, GRASS_ATLAS_COORDS, 0)
				"forest":
					ground_layer.set_cell(cell, FOREST_SOURCE_ID, FOREST_ATLAS_COORDS, 0)
				"mountain":
					ground_layer.set_cell(cell, MOUNTAIN_SOURCE_ID, MOUNTAIN_ATLAS_COORDS, 0)

	# =========================
	# イベント配置ひな型
	# =========================
	# event_layer.set_cell(Vector2i(5, 5), EVENT_SOURCE_ID, EVENT_ATLAS_COORDS, 0)
	var terrain_data: Array = []

	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = randi()
	biome_noise.frequency = 0.018
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var detail_noise := FastNoiseLite.new()
	detail_noise.seed = randi() + 1000
	detail_noise.frequency = 0.08
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for y in range(map_height):
		var terrain_row: Array = []

		for x in range(map_width):
			var b := (biome_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var d := (detail_noise.get_noise_2d(x, y) + 1.0) * 0.5

			# 端からの距離を使って海を大きくする
			var dist_left := x
			var dist_right := map_width - 1 - x
			var dist_top := y
			var dist_bottom := map_height - 1 - y
			var edge_dist = min(dist_left, dist_right, dist_top, dist_bottom)

			# 0.0 = 外周, 1.0 = 中央寄り
			var max_edge_dist = min(map_width, map_height) / 2.0
			var edge_factor = clamp(float(edge_dist) / max_edge_dist, 0.0, 1.0)

			# 外周ほど海になりやすくする
			# 小さいほど海寄りの値になる
			var sea_value = b * 0.55 + edge_factor * 0.45

			var biome := BIOME_PLAINS
			if sea_value < 0.35:
				biome = BIOME_SEA
			elif b > 0.75:
				biome = BIOME_MOUNTAIN
			else:
				biome = BIOME_PLAINS

			var terrain := TERRAIN_GRASS

			match biome:
				BIOME_SEA:
					if d < 0.82:
						terrain = TERRAIN_SEA
					else:
						terrain = TERRAIN_SAND

				BIOME_PLAINS:
					if d < 0.08:
						terrain = TERRAIN_SAND
					elif d < 0.72:
						terrain = TERRAIN_GRASS
					elif d < 0.90:
						terrain = TERRAIN_FOREST
					else:
						terrain = TERRAIN_ROCK

				BIOME_MOUNTAIN:
					if d < 0.12:
						terrain = TERRAIN_GRASS
					elif d < 0.38:
						terrain = TERRAIN_FOREST
					else:
						terrain = TERRAIN_ROCK

			terrain_row.append(terrain)

		terrain_data.append(terrain_row)

# 海の隣を砂浜に補正
# 森は海の近くに置かない
# 岩の近くの森も草原に落とす
	terrain_result.clear()

	for y in range(map_height):
		var row: Array = []

		for x in range(map_width):
			var current: int = terrain_data[y][x]

			var near_sea := false
			var near_rock := false

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue

					var nx := x + dx
					var ny := y + dy

					if nx < 0 or nx >= map_width or ny < 0 or ny >= map_height:
						continue
	
					var neighbor: int = terrain_data[ny][nx]

					if neighbor == TERRAIN_SEA:
						near_sea = true
					elif neighbor == TERRAIN_ROCK:
						near_rock = true

			# 海の近くは砂浜優先
			if current == TERRAIN_GRASS and near_sea:
				current = TERRAIN_SAND
			elif current == TERRAIN_FOREST and near_sea:
				current = TERRAIN_GRASS

			# 岩場の中や岩に強く接する森は草原に落とす
			if current == TERRAIN_FOREST and near_rock:
				current = TERRAIN_GRASS

			row.append(current)

		terrain_result.append(row)

	# 外周は必ず海にする
	for x in range(map_width):
		terrain_result[0][x] = TERRAIN_SEA
		terrain_result[map_height - 1][x] = TERRAIN_SEA

	for y in range(map_height):
		terrain_result[y][0] = TERRAIN_SEA
		terrain_result[y][map_width - 1] = TERRAIN_SEA

	ground_layer.clear()
	wall_layer.clear()
	event_layer.clear()

	for y in range(map_height):
		print("")
		for x in range(map_width):
			var cell := Vector2i(x, y)
			var terrain: int = terrain_result[y][x]
			printraw(str(terrain))

			match terrain:
				TERRAIN_SEA:
					ground_layer.set_cell(cell, 23, Vector2i(1, 4), 0)

				TERRAIN_SAND:
					ground_layer.set_cell(cell, 10, Vector2i(1, 4), 0)

				TERRAIN_GRASS:
					ground_layer.set_cell(cell, 12, Vector2i(1, 4), 0)

				TERRAIN_FOREST:
					ground_layer.set_cell(cell, 7, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					ground_layer.set_cell(cell, 6, Vector2i(1, 4), 0)
					#wall_layer.set_cell(cell, 9, Vector2i(1, 4), 0)
					wall_layer.set_cell(cell, 5, Vector2i(0,0), 0)
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


func _is_adjacent_to_biome(cell: Vector2i, biome_map: Array, target: String) -> bool:
	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in directions:
		var nx = cell.x + dir.x
		var ny = cell.y + dir.y

		if _is_in_bounds(nx, ny):
			if biome_map[ny][nx] == target:
				return true

	return false


func _count_adjacent_biome(cell: Vector2i, biome_map: Array, target: String) -> int:
	var count := 0
	var directions = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in directions:
		var nx = cell.x + dir.x
		var ny = cell.y + dir.y

		if _is_in_bounds(nx, ny):
			if biome_map[ny][nx] == target:
				count += 1

	return count


func _distance_from_left_sea(x: int, biome_map: Array, y: int) -> int:
	var nearest_sea_x := -1

	for sx in range(x, -1, -1):
		if biome_map[y][sx] == "sea":
			nearest_sea_x = sx
			break

	if nearest_sea_x == -1:
		return 999

	return x - nearest_sea_x
