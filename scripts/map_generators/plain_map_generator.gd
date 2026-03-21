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

	# 外周用Wall
	var BORDER_WALL_SOURCE_ID := 5
	var BORDER_WALL_ATLAS_COORDS := Vector2i(0, 0)

	# =========================
	# 前半の旧ロジック
	# 今は実際の最終結果には使っていない
	# =========================
	var biome_map: Array = []
	for y in range(map_height):
		biome_map.append([])
		for x in range(map_width):
			biome_map[y].append("grass")

	for y in range(map_height):
		var coast_x := 2 + randi() % 3
		for x in range(coast_x):
			biome_map[y][x] = "sea"

	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] == "sea":
				continue

			var cell := Vector2i(x, y)
			if _is_adjacent_to_biome(cell, biome_map, "sea"):
				biome_map[y][x] = "beach"

	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass":
				continue

			var sea_distance := _distance_from_left_sea(x, biome_map, y)
			if sea_distance >= 4:
				if randf() < 0.18:
					biome_map[y][x] = "forest"

	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass":
				continue

			var cell := Vector2i(x, y)
			var sea_distance := _distance_from_left_sea(x, biome_map, y)

			if sea_distance >= 4 and _count_adjacent_biome(cell, biome_map, "forest") >= 2:
				if randf() < 0.55:
					biome_map[y][x] = "forest"

	for y in range(map_height):
		for x in range(map_width):
			if biome_map[y][x] != "grass" and biome_map[y][x] != "forest":
				continue

			var sea_distance := _distance_from_left_sea(x, biome_map, y)
			if sea_distance < 7:
				continue

			var cell := Vector2i(x, y)
			var forest_neighbors := _count_adjacent_biome(cell, biome_map, "forest")

			if forest_neighbors >= 2 and randf() < 0.22:
				biome_map[y][x] = "mountain"

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
	# 実際に使っている後半ロジック
	# =========================
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

			var dist_left := x
			var dist_right := map_width - 1 - x
			var dist_top := y
			var dist_bottom := map_height - 1 - y
			var edge_dist = min(dist_left, dist_right, dist_top, dist_bottom)

			var max_edge_dist = min(map_width, map_height) / 2.0
			var edge_factor = clamp(float(edge_dist) / max_edge_dist, 0.0, 1.0)

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

			if current == TERRAIN_GRASS and near_sea:
				current = TERRAIN_SAND
			elif current == TERRAIN_FOREST and near_sea:
				current = TERRAIN_GRASS

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
					ground_layer.set_cell(cell, 33, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 33, Vector2i(1, 4), 0)

				TERRAIN_SAND:
					ground_layer.set_cell(cell, 20, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 20, Vector2i(1, 4), 0)
					
				TERRAIN_GRASS:
					ground_layer.set_cell(cell, 22, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 22, Vector2i(1, 4), 0)
					
				TERRAIN_FOREST:
					ground_layer.set_cell(cell, 17, Vector2i(1, 4), 0)
					event_layer.set_cell(cell, 17, Vector2i(1, 4), 0)

				TERRAIN_ROCK:
					ground_layer.set_cell(cell, 6, Vector2i(1, 4), 0)
					wall_layer.set_cell(cell, 5, Vector2i(0, 0), 0)

	# =========================
	# 外周にWallを付ける
	# =========================
	
	ground_layer.set_cell(Vector2i(10,10), 30, Vector2i(1, 4), 0)
	event_layer.set_cell(Vector2i(10,10),30, Vector2i(1, 4), 0)
	
	for x in range(map_width):
		wall_layer.set_cell(Vector2i(x, 0), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		wall_layer.set_cell(Vector2i(x, map_height ), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)

	for y in range(map_height):
		wall_layer.set_cell(Vector2i(0, y), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)
		wall_layer.set_cell(Vector2i(map_width , y), BORDER_WALL_SOURCE_ID, BORDER_WALL_ATLAS_COORDS, 0)


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
