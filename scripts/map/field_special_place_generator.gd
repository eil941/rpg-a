extends RefCounted
class_name FieldSpecialPlaceGenerator

const BIOME_OCEAN: int = 0
const BIOME_COAST: int = 1
const BIOME_PLAINS: int = 2
const BIOME_FOREST: int = 3
const BIOME_DESERT: int = 4
const BIOME_HIGHLAND: int = 5
const BIOME_MOUNTAIN: int = 6
const BIOME_LAKE: int = 7
const BIOME_DRY_PLAINS: int = 8

const TERRAIN_SEA: int = 0
const TERRAIN_SAND: int = 1
const TERRAIN_GRASS: int = 2
const TERRAIN_FOREST: int = 3
const TERRAIN_ROCK: int = 4
const TERRAIN_LAKE: int = 5

var map_width: int
var map_height: int
var biome_result: Array
var terrain_result: Array
var rng: RandomNumberGenerator

func _init(
	p_map_width: int,
	p_map_height: int,
	p_biome_result: Array,
	p_terrain_result: Array,
	p_seed: int = 0
) -> void:
	map_width = p_map_width
	map_height = p_map_height
	biome_result = p_biome_result
	terrain_result = p_terrain_result

	rng = RandomNumberGenerator.new()
	rng.seed = p_seed


func generate_all_places() -> Array:
	var results: Array = []
	var placed_points: Array = []

	var start_place: Dictionary = generate_one_place(
		"start",
		[BIOME_PLAINS, BIOME_FOREST],
		8,
		0,
		placed_points,
		6,
		"res://scenes/start_map.tscn"
	)
	if not start_place.is_empty():
		results.append(start_place)
		placed_points.append(Vector2i(start_place["x"], start_place["y"]))

	var towns: Array = generate_places(
		"town",
		[
			{"place_id": "town_1", "enter_scene": "res://scenes/town_1.tscn"},
			{"place_id": "town_2", "enter_scene": "res://scenes/town_2.tscn"}
		],
		[BIOME_PLAINS],
		24,
		placed_points,
		6
	)
	for place in towns:
		results.append(place)
		placed_points.append(Vector2i(place["x"], place["y"]))

	var villages: Array = generate_places(
		"village",
		[
			{"place_id": "village_1", "enter_scene": "res://scenes/village_1.tscn"},
			{"place_id": "village_2", "enter_scene": "res://scenes/village_2.tscn"},
			{"place_id": "village_3", "enter_scene": "res://scenes/village_3.tscn"},
			{"place_id": "village_4", "enter_scene": "res://scenes/village_4.tscn"},
			{"place_id": "village_5", "enter_scene": "res://scenes/village_5.tscn"}
		],
		[BIOME_PLAINS, BIOME_FOREST],
		14,
		placed_points,
		5
	)
	for place in villages:
		results.append(place)
		placed_points.append(Vector2i(place["x"], place["y"]))

	var castles: Array = generate_places(
		"castle",
		[
			{"place_id": "castle_1", "enter_scene": "res://scenes/castle_1.tscn"},
			{"place_id": "castle_2", "enter_scene": "res://scenes/castle_2.tscn"}
		],
		[BIOME_HIGHLAND, BIOME_MOUNTAIN],
		28,
		placed_points,
		5
	)
	for place in castles:
		results.append(place)
		placed_points.append(Vector2i(place["x"], place["y"]))

	var unique_dungeons: Array = generate_places(
		"unique_dungeon",
		[
			{"place_id": "unique_dungeon_1", "enter_scene": "res://scenes/unique_dungeon_1.tscn"},
			{"place_id": "unique_dungeon_2", "enter_scene": "res://scenes/unique_dungeon_2.tscn"},
			{"place_id": "unique_dungeon_3", "enter_scene": "res://scenes/unique_dungeon_3.tscn"},
			{"place_id": "unique_dungeon_4", "enter_scene": "res://scenes/unique_dungeon_4.tscn"}
		],
		[BIOME_MOUNTAIN, BIOME_DESERT, BIOME_FOREST],
		18,
		placed_points,
		5
	)
	for place in unique_dungeons:
		results.append(place)
		placed_points.append(Vector2i(place["x"], place["y"]))

	var special_maps: Array = generate_places(
		"special_map",
		[
			{"place_id": "special_map_1", "enter_scene": "res://scenes/special_map_1.tscn"},
			{"place_id": "special_map_2", "enter_scene": "res://scenes/special_map_2.tscn"},
			{"place_id": "special_map_3", "enter_scene": "res://scenes/special_map_3.tscn"}
		],
		[BIOME_DESERT, BIOME_LAKE, BIOME_FOREST, BIOME_HIGHLAND],
		20,
		placed_points,
		4
	)
	for place in special_maps:
		results.append(place)
		placed_points.append(Vector2i(place["x"], place["y"]))

	return results


func generate_places(
	place_type: String,
	place_defs: Array,
	allowed_biomes: Array,
	min_distance: int,
	existing_points: Array,
	margin: int = 5
) -> Array:
	var results: Array = []
	var local_points: Array = []

	var candidates: Array = _collect_candidates(allowed_biomes, margin)
	candidates = _sort_candidates_by_score(candidates)

	for i in range(place_defs.size()):
		if candidates.is_empty():
			break

		var place_def: Dictionary = place_defs[i]
		var selected_index: int = -1

		for j in range(candidates.size()):
			var candidate: Dictionary = candidates[j]
			var point: Vector2i = candidate["pos"]

			if not _is_far_enough(point, existing_points, min_distance):
				continue

			if not _is_far_enough(point, local_points, min_distance):
				continue

			selected_index = j
			break

		if selected_index == -1:
			continue

		var selected: Dictionary = candidates[selected_index]
		var selected_point: Vector2i = selected["pos"]

		var place: Dictionary = {
			"type": place_type,
			"place_id": place_def["place_id"],
			"x": selected_point.x,
			"y": selected_point.y,
			"biome": biome_result[selected_point.y][selected_point.x],
			"enter_scene": place_def["enter_scene"]
		}

		results.append(place)
		local_points.append(selected_point)

	return results


func generate_one_place(
	place_type: String,
	allowed_biomes: Array,
	margin: int,
	min_distance: int,
	existing_points: Array,
	neighbor_same_biome_min: int = 5,
	enter_scene: String = ""
) -> Dictionary:
	var candidates: Array = _collect_candidates(allowed_biomes, margin)
	var filtered: Array = []

	for candidate in candidates:
		var point: Vector2i = candidate["pos"]
		var same_biome_neighbors: int = _count_same_biome_neighbors(point.x, point.y, biome_result[point.y][point.x])

		if same_biome_neighbors < neighbor_same_biome_min:
			continue

		if min_distance > 0 and not _is_far_enough(point, existing_points, min_distance):
			continue

		filtered.append(candidate)

	filtered = _sort_candidates_by_score(filtered)

	if filtered.is_empty():
		return {}

	var selected: Dictionary = filtered[0]
	var pos: Vector2i = selected["pos"]

	return {
		"type": place_type,
		"place_id": place_type + "_1",
		"x": pos.x,
		"y": pos.y,
		"biome": biome_result[pos.y][pos.x],
		"enter_scene": enter_scene
	}


func _collect_candidates(allowed_biomes: Array, margin: int) -> Array:
	var candidates: Array = []

	for y in range(margin, map_height - margin):
		for x in range(margin, map_width - margin):
			var biome: int = biome_result[y][x]

			if not allowed_biomes.has(biome):
				continue

			if not _is_walkable_for_place(x, y):
				continue

			var same_biome_neighbors: int = _count_same_biome_neighbors(x, y, biome)
			if same_biome_neighbors < 4:
				continue

			var score: int = _score_candidate(x, y)

			candidates.append({
				"pos": Vector2i(x, y),
				"score": score
			})

	candidates.shuffle()
	return candidates


func _sort_candidates_by_score(candidates: Array) -> Array:
	var copied: Array = candidates.duplicate()

	copied.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"]
	)

	return copied


func _score_candidate(x: int, y: int) -> int:
	var biome: int = biome_result[y][x]
	var score: int = 0

	score += _count_same_biome_neighbors(x, y, biome) * 10
	score += _count_walkable_neighbors(x, y) * 4

	var near_lake: bool = _has_biome_in_radius(x, y, BIOME_LAKE, 4)
	var near_ocean: bool = _has_biome_in_radius(x, y, BIOME_OCEAN, 4)
	var near_mountain: bool = _has_biome_in_radius(x, y, BIOME_MOUNTAIN, 3)
	var near_highland: bool = _has_biome_in_radius(x, y, BIOME_HIGHLAND, 3)

	if biome == BIOME_PLAINS:
		score += 20

	if biome == BIOME_FOREST:
		score += 10

	if biome == BIOME_HIGHLAND:
		score += 12

	if near_lake:
		score += 8

	if near_ocean:
		score += 4

	if near_mountain:
		score += 6

	if near_highland:
		score += 6

	return score


func _is_walkable_for_place(x: int, y: int) -> bool:
	var terrain: int = terrain_result[y][x]
	return terrain == TERRAIN_SAND or terrain == TERRAIN_GRASS


func _count_same_biome_neighbors(x: int, y: int, biome_type: int) -> int:
	var count: int = 0

	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var nx: int = x + dx
			var ny: int = y + dy

			if not _is_in_bounds(nx, ny):
				continue

			if biome_result[ny][nx] == biome_type:
				count += 1

	return count


func _count_walkable_neighbors(x: int, y: int) -> int:
	var count: int = 0

	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if dx == 0 and dy == 0:
				continue

			var nx: int = x + dx
			var ny: int = y + dy

			if not _is_in_bounds(nx, ny):
				continue

			if _is_walkable_for_place(nx, ny):
				count += 1

	return count


func _has_biome_in_radius(x: int, y: int, biome_type: int, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue

			var nx: int = x + dx
			var ny: int = y + dy

			if not _is_in_bounds(nx, ny):
				continue

			if biome_result[ny][nx] == biome_type:
				return true

	return false


func _is_far_enough(point: Vector2i, other_points: Array, min_distance: int) -> bool:
	for other in other_points:
		var other_point: Vector2i = other
		if point.distance_to(other_point) < float(min_distance):
			return false
	return true


func _is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < map_width and y >= 0 and y < map_height
