extends Node2D

@onready var tile_map = get_tree().current_scene.get_node("TileMap")
@onready var player = $Units/Unit

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 5
@export var enemy_data_list: Array[EnemyData]

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 3
@export var npc_data_list: Array[NpcData]

@export var map_id: String = ""

const MAP_WIDTH := 50
const MAP_HEIGHT := 50

const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

func _ready() -> void:
	generate_map()

	if WorldState.map_enemy_spawns.has(map_id):
		spawn_saved_enemies()
	else:
		spawn_random_enemies()

	var used_tiles = collect_used_tiles_from_units()

	if WorldState.map_npc_spawns.has(map_id):
		spawn_saved_npcs()
	else:
		spawn_random_npcs(used_tiles)

	# ↓ 削除予定
	player.position = tile_map.map_to_local(Vector2i(2, 2))
	
	

func generate_map() -> void:
	for y in range(0, MAP_HEIGHT, 1):
		for x in range(0, MAP_WIDTH, 1):
			var cell = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				tile_map.set_cell(0, cell, WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)
			else:
				tile_map.set_cell(0, cell, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)

	for x in range(10, 20):
		tile_map.set_cell(0, Vector2i(x, 10), WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)

	for y in range(20, 30):
		tile_map.set_cell(0, Vector2i(25, y), WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)

func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)

		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()

func get_random_enemy_data() -> EnemyData:
	if enemy_data_list.is_empty():
		return null

	return enemy_data_list[randi() % enemy_data_list.size()]

func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				continue

			result.append(tile)

	return result

func find_enemy_data_by_id(enemy_type_id: String) -> EnemyData:
	for data in enemy_data_list:
		if data != null and data.enemy_type_id == enemy_type_id:
			return data
	return null

func spawn_enemy_random(used_tiles: Array[Vector2i], index: int) -> void:
	if enemy_unit_scene == null:
		return

	var enemy_data = get_random_enemy_data()
	if enemy_data == null:
		return

	var candidates = get_walkable_tiles()
	candidates.shuffle()

	for tile in candidates:
		if used_tiles.has(tile):
			continue

		var enemy = enemy_unit_scene.instantiate()

		enemy.start_tile = tile
		enemy.unit_id = "enemy_%d" % index
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		$Units.add_child(enemy)

		print("RANDOM SPAWN unit_id=", enemy.unit_id, " type=", enemy_data.enemy_type_id)

		used_tiles.append(tile)

		var spawn_data = {
			"unit_id": enemy.unit_id,
			"enemy_type_id": enemy_data.enemy_type_id,
			"tile_x": tile.x,
			"tile_y": tile.y,
			"is_dead": false
		}

		if not WorldState.map_enemy_spawns.has(map_id):
			WorldState.map_enemy_spawns[map_id] = []

		WorldState.map_enemy_spawns[map_id].append(spawn_data)
		return

func spawn_random_enemies() -> void:
	var used_tiles: Array[Vector2i] = []

	if $Units.has_node("Unit"):
		used_tiles.append($Units/Unit.get_current_tile_coords())

	for i in range(enemy_spawn_count):
		spawn_enemy_random(used_tiles, i)

func spawn_saved_enemies() -> void:
	var saved_list = WorldState.map_enemy_spawns.get(map_id, [])

	for spawn_data in saved_list:
		print("LOAD SPAWN DATA unit_id=", spawn_data["unit_id"], " type=", spawn_data["enemy_type_id"])

		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var enemy_data = find_enemy_data_by_id(spawn_data["enemy_type_id"])
		if enemy_data == null:
			continue

		print("FOUND ENEMY DATA type=", enemy_data.enemy_type_id)

		var enemy = enemy_unit_scene.instantiate()
		enemy.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		enemy.unit_id = unit_id
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		$Units.add_child(enemy)

func find_npc_data_by_id(npc_type_id: String) -> NpcData:
	for data in npc_data_list:
		if data != null and data.npc_type_id == npc_type_id:
			return data
	return null

func get_random_npc_data() -> NpcData:
	if npc_data_list.is_empty():
		return null

	return npc_data_list[randi() % npc_data_list.size()]

func spawn_npc_random(used_tiles: Array[Vector2i], index: int) -> void:
	if npc_unit_scene == null:
		return

	var npc_data = get_random_npc_data()
	if npc_data == null:
		return

	var candidates = get_walkable_tiles()
	candidates.shuffle()

	for tile in candidates:
		if used_tiles.has(tile):
			continue

		var npc = npc_unit_scene.instantiate()

		npc.start_tile = tile
		npc.unit_id = "npc_%d" % index
		npc.map_id = map_id

		$Units.add_child(npc)
		npc.apply_npc_data(npc_data)

		used_tiles.append(tile)

		var spawn_data = {
			"unit_id": npc.unit_id,
			"npc_type_id": npc_data.npc_type_id,
			"tile_x": tile.x,
			"tile_y": tile.y,
			"is_dead": false
		}

		if not WorldState.map_npc_spawns.has(map_id):
			WorldState.map_npc_spawns[map_id] = []

		WorldState.map_npc_spawns[map_id].append(spawn_data)
		return

func spawn_random_npcs(used_tiles: Array[Vector2i]) -> void:
	for i in range(npc_spawn_count):
		spawn_npc_random(used_tiles, i)

func spawn_saved_npcs() -> void:
	var saved_list = WorldState.map_npc_spawns.get(map_id, [])

	for spawn_data in saved_list:
		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var npc_data = find_npc_data_by_id(spawn_data["npc_type_id"])
		if npc_data == null:
			continue

		var npc = npc_unit_scene.instantiate()
		npc.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		npc.unit_id = unit_id
		npc.map_id = map_id

		$Units.add_child(npc)
		npc.apply_npc_data(npc_data)

func collect_used_tiles_from_units() -> Array[Vector2i]:
	var used_tiles: Array[Vector2i] = []

	for unit in $Units.get_children():
		if unit.has_method("get_current_tile_coords"):
			used_tiles.append(unit.get_current_tile_coords())

	return used_tiles
