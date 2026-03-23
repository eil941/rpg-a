extends RefCounted
class_name UnitSpawnManager

var units_node: Node
var map_id: String
var walkable_tiles: Array[Vector2i]
var tile_map: TileMapLayer

func _init(
	p_units_node: Node,
	p_tile_map: TileMapLayer,
	p_map_id: String,
	p_walkable_tiles: Array[Vector2i]
) -> void:
	units_node = p_units_node
	tile_map = p_tile_map
	map_id = p_map_id
	walkable_tiles = p_walkable_tiles


func collect_used_tiles_from_units() -> Array[Vector2i]:
	var used_tiles: Array[Vector2i] = []

	for unit in units_node.get_children():
		if unit.has_method("get_current_tile_coords"):
			used_tiles.append(unit.get_current_tile_coords())

	return used_tiles


func get_random_enemy_data(enemy_data_list: Array[EnemyData]) -> EnemyData:
	if enemy_data_list.is_empty():
		return null

	return enemy_data_list[randi() % enemy_data_list.size()]


func find_enemy_data_by_id(enemy_data_list: Array[EnemyData], enemy_type_id: String) -> EnemyData:
	for data in enemy_data_list:
		if data != null and data.enemy_type_id == enemy_type_id:
			return data
	return null


func get_random_npc_data(npc_data_list: Array[NpcData]) -> NpcData:
	if npc_data_list.is_empty():
		return null

	return npc_data_list[randi() % npc_data_list.size()]


func find_npc_data_by_id(npc_data_list: Array[NpcData], npc_type_id: String) -> NpcData:
	for data in npc_data_list:
		if data != null and data.npc_type_id == npc_type_id:
			return data
	return null


func make_enemy_unit_id(index: int) -> String:
	return "%s_enemy_%d" % [map_id, index]


func make_npc_unit_id(index: int) -> String:
	return "%s_npc_%d" % [map_id, index]


func debug_unit_structure(unit: Node, label: String) -> void:
	if unit == null:
		print(label, " unit is null")
		return

	print(label, " name=", unit.name)
	print(label, " scene_file_path=", unit.scene_file_path)
	print(label, " has Inventory=", unit.has_node("Inventory"))
	print(label, " children=", unit.get_children().map(func(c): return c.name))


func ensure_inventory_node(unit: Node) -> void:
	if unit == null:
		return

	if unit.has_node("Inventory"):
		print("ensure_inventory_node: already exists on ", unit.name)
		return

	var inventory := Inventory.new()
	inventory.name = "Inventory"
	unit.add_child(inventory)

	print("ensure_inventory_node: added Inventory to ", unit.name)


func spawn_enemy_random(
	enemy_unit_scene: PackedScene,
	enemy_data_list: Array[EnemyData],
	used_tiles: Array[Vector2i],
	index: int
) -> void:
	if enemy_unit_scene == null:
		return

	var enemy_data = get_random_enemy_data(enemy_data_list)
	if enemy_data == null:
		return

	var candidates = walkable_tiles.duplicate()
	candidates.shuffle()

	for tile in candidates:
		if used_tiles.has(tile):
			continue

		var enemy = enemy_unit_scene.instantiate()
		var unique_unit_id := make_enemy_unit_id(index)

		debug_unit_structure(enemy, "SPAWN RANDOM ENEMY BEFORE")

		enemy.start_tile = tile
		enemy.unit_id = unique_unit_id
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		ensure_inventory_node(enemy)
		debug_unit_structure(enemy, "SPAWN RANDOM ENEMY AFTER")

		units_node.add_child(enemy)

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


func spawn_random_enemies(
	enemy_unit_scene: PackedScene,
	enemy_data_list: Array[EnemyData],
	enemy_spawn_count: int
) -> void:
	var used_tiles = collect_used_tiles_from_units()

	for i in range(enemy_spawn_count):
		spawn_enemy_random(enemy_unit_scene, enemy_data_list, used_tiles, i)


func spawn_saved_enemies(enemy_unit_scene: PackedScene, enemy_data_list: Array[EnemyData]) -> void:
	var saved_list = WorldState.map_enemy_spawns.get(map_id, [])

	for spawn_data in saved_list:
		print("LOAD SPAWN DATA unit_id=", spawn_data["unit_id"], " type=", spawn_data["enemy_type_id"])

		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var enemy_data = find_enemy_data_by_id(enemy_data_list, spawn_data["enemy_type_id"])
		if enemy_data == null:
			continue

		print("FOUND ENEMY DATA type=", enemy_data.enemy_type_id)

		var enemy = enemy_unit_scene.instantiate()
		debug_unit_structure(enemy, "SPAWN SAVED ENEMY BEFORE")

		enemy.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		enemy.unit_id = unit_id
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		ensure_inventory_node(enemy)
		debug_unit_structure(enemy, "SPAWN SAVED ENEMY AFTER")

		units_node.add_child(enemy)


func spawn_npc_random(
	npc_unit_scene: PackedScene,
	npc_data_list: Array[NpcData],
	used_tiles: Array[Vector2i],
	index: int
) -> void:
	if npc_unit_scene == null:
		return

	var npc_data = get_random_npc_data(npc_data_list)
	if npc_data == null:
		return

	var candidates = walkable_tiles.duplicate()
	candidates.shuffle()

	for tile in candidates:
		if used_tiles.has(tile):
			continue

		var npc = npc_unit_scene.instantiate()
		var unique_unit_id := make_npc_unit_id(index)

		debug_unit_structure(npc, "SPAWN RANDOM NPC BEFORE")

		npc.start_tile = tile
		npc.unit_id = unique_unit_id
		npc.map_id = map_id

		ensure_inventory_node(npc)
		debug_unit_structure(npc, "SPAWN RANDOM NPC AFTER")

		units_node.add_child(npc)
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


func spawn_random_npcs(
	npc_unit_scene: PackedScene,
	npc_data_list: Array[NpcData],
	npc_spawn_count: int
) -> void:
	var used_tiles = collect_used_tiles_from_units()

	for i in range(npc_spawn_count):
		spawn_npc_random(npc_unit_scene, npc_data_list, used_tiles, i)


func spawn_saved_npcs(npc_unit_scene: PackedScene, npc_data_list: Array[NpcData]) -> void:
	var saved_list = WorldState.map_npc_spawns.get(map_id, [])

	for spawn_data in saved_list:
		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var npc_data = find_npc_data_by_id(npc_data_list, spawn_data["npc_type_id"])
		if npc_data == null:
			continue

		var npc = npc_unit_scene.instantiate()
		debug_unit_structure(npc, "SPAWN SAVED NPC BEFORE")

		npc.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		npc.unit_id = unit_id
		npc.map_id = map_id

		ensure_inventory_node(npc)
		debug_unit_structure(npc, "SPAWN SAVED NPC AFTER")

		units_node.add_child(npc)
		npc.apply_npc_data(npc_data)
