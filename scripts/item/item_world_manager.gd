extends RefCounted
class_name ItemWorldManager

var map_root: Node
var ground_layer: TileMapLayer
var wall_layer: TileMapLayer
var units_node: Node
var item_pickups_node: Node
var chests_node: Node
var map_id: String

var item_pickup_scene: PackedScene
var chest_scene: PackedScene
var chest_data_list: Array[ChestData]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _debug_enchant_log(message: String) -> void:
	if DebugSettings != null and DebugSettings.debug_enchant:
		print(message)


func _init(
	p_map_root: Node,
	p_ground_layer: TileMapLayer,
	p_wall_layer: TileMapLayer,
	p_units_node: Node,
	p_item_pickups_node: Node,
	p_chests_node: Node,
	p_map_id: String,
	p_item_pickup_scene: PackedScene,
	p_chest_scene: PackedScene,
	p_chest_data_list: Array[ChestData]
) -> void:
	map_root = p_map_root
	ground_layer = p_ground_layer
	wall_layer = p_wall_layer
	units_node = p_units_node
	item_pickups_node = p_item_pickups_node
	chests_node = p_chests_node
	map_id = p_map_id
	item_pickup_scene = p_item_pickup_scene
	chest_scene = p_chest_scene
	chest_data_list = p_chest_data_list

	rng.randomize()


func setup_detail_map_random_spawn_with_save(
	detail_difficulty: int = 1,
	detail_generator: String = ""
) -> void:
	var spawn_context: Dictionary = _build_detail_spawn_context(detail_difficulty, detail_generator)

	if not WorldState.map_item_pickups.has(map_id):
		WorldState.map_item_pickups[map_id] = generate_detail_map_item_data(spawn_context)

	if not WorldState.map_chests.has(map_id):
		WorldState.map_chests[map_id] = generate_detail_map_chest_data()

	load_item_pickups_from_world_state()
	load_chests_from_world_state()


func setup_dungeon_floor_random_spawn_with_save(
	dungeon_difficulty: int = 1,
	floor_number: int = 1,
	is_final_floor: bool = false,
	generator_theme: String = ""
) -> void:
	var spawn_context: Dictionary = _build_dungeon_spawn_context(
		dungeon_difficulty,
		floor_number,
		is_final_floor,
		generator_theme
	)

	if not WorldState.map_item_pickups.has(map_id):
		WorldState.map_item_pickups[map_id] = generate_dungeon_floor_item_data(spawn_context)

	if not WorldState.map_chests.has(map_id):
		WorldState.map_chests[map_id] = generate_dungeon_floor_chest_data(is_final_floor)

	load_item_pickups_from_world_state()
	load_chests_from_world_state()


func generate_detail_map_item_data(spawn_context: Dictionary) -> Array:
	var result: Array = []
	var count: int = ItemSpawnRuleDatabase.get_spawn_count(spawn_context, rng)

	var tiles: Array[Vector2i] = get_available_tiles()
	tiles.shuffle()

	for i in range(min(count, tiles.size())):
		var tile: Vector2i = tiles[i]
		var item_entry: Dictionary = ItemSpawnRuleDatabase.roll_item_entry(spawn_context, rng)
		var save_entry: Dictionary = _build_world_item_save_data(item_entry, tile)

		if not save_entry.is_empty():
			result.append(save_entry)

	return result


func generate_detail_map_chest_data() -> Array:
	var result: Array = []
	var chest_count: int = rng.randi_range(0, 1)

	if chest_count <= 0:
		return result

	var tiles: Array[Vector2i] = get_available_tiles()
	tiles.shuffle()

	for i in range(min(chest_count, tiles.size())):
		var chest_tile: Vector2i = tiles[i]
		var chest_type_id: String = choose_random_chest_type_id(false)

		result.append({
			"chest_id": "%s_chest_%d" % [map_id, i],
			"chest_type_id": chest_type_id,
			"x": chest_tile.x,
			"y": chest_tile.y,
			"is_opened": false,
			"inventory": generate_random_chest_inventory_for_type(chest_type_id, false)
		})

	return result


func generate_dungeon_floor_item_data(spawn_context: Dictionary) -> Array:
	var result: Array = []
	var count: int = ItemSpawnRuleDatabase.get_spawn_count(spawn_context, rng)

	var tiles: Array[Vector2i] = get_available_tiles()
	tiles.shuffle()

	for i in range(min(count, tiles.size())):
		var tile: Vector2i = tiles[i]
		var item_entry: Dictionary = ItemSpawnRuleDatabase.roll_item_entry(spawn_context, rng)
		var save_entry: Dictionary = _build_world_item_save_data(item_entry, tile)

		if not save_entry.is_empty():
			result.append(save_entry)

	return result


func generate_dungeon_floor_chest_data(is_final_floor: bool) -> Array:
	var result: Array = []

	var chest_count: int = 0
	if is_final_floor:
		chest_count = 1
	else:
		chest_count = rng.randi_range(0, 1)

	if chest_count <= 0:
		return result

	var tiles: Array[Vector2i] = get_available_tiles()
	tiles.shuffle()

	for i in range(min(chest_count, tiles.size())):
		var chest_tile: Vector2i = tiles[i]
		var chest_type_id: String = choose_random_chest_type_id(is_final_floor)

		result.append({
			"chest_id": "%s_chest_%d" % [map_id, i],
			"chest_type_id": chest_type_id,
			"x": chest_tile.x,
			"y": chest_tile.y,
			"is_opened": false,
			"inventory": generate_random_chest_inventory_for_type(chest_type_id, is_final_floor)
		})

	return result


func generate_random_chest_inventory_for_type(chest_type_id: String, is_final_floor: bool) -> Array:
	var result: Array = []
	var chest_data: ChestData = find_chest_data_by_type_id(chest_type_id)

	var item_count: int = 1

	if chest_data != null:
		var min_items: int = max(chest_data.loot_min_items, 0)
		var max_items: int = max(chest_data.loot_max_items, min_items)
		item_count = rng.randi_range(min_items, max_items)
	else:
		if is_final_floor:
			item_count = rng.randi_range(2, 4)
		else:
			item_count = rng.randi_range(1, 3)

	for i in range(item_count):
		var loot_category: LootCategoryEntry = choose_weighted_loot_category(chest_data)
		if loot_category == null:
			continue

		var normalized_type: String = loot_category.get_normalized_item_type()
		var item_id: String = ItemDatabase.get_random_item_id_by_type(normalized_type, rng)
		if item_id == "":
			continue

		var min_amount: int = max(loot_category.min_amount, 1)
		var max_amount: int = max(loot_category.max_amount, min_amount)
		var amount: int = rng.randi_range(min_amount, max_amount)

		var chest_entry: Dictionary = _build_inventory_entry(item_id, amount)
		_debug_enchant_log("[ENCHANT][ItemWorldManager] chest item chest_type=%s item_id=%s entry=%s" % [chest_type_id, item_id, str(chest_entry)])
		result.append(chest_entry)

	return result


func choose_weighted_loot_category(chest_data: ChestData) -> LootCategoryEntry:
	if chest_data == null:
		return null

	if chest_data.loot_categories.is_empty():
		return null

	var total_weight: int = 0

	for entry in chest_data.loot_categories:
		if entry == null:
			continue
		if entry.weight > 0:
			total_weight += entry.weight

	if total_weight <= 0:
		return null

	var roll: int = rng.randi_range(1, total_weight)
	var accum: int = 0

	for entry in chest_data.loot_categories:
		if entry == null:
			continue
		if entry.weight <= 0:
			continue

		accum += entry.weight
		if roll <= accum:
			return entry

	for entry in chest_data.loot_categories:
		if entry != null:
			return entry

	return null


func _build_detail_spawn_context(detail_difficulty: int, detail_generator: String) -> Dictionary:
	return {
		"map_kind": "detail",
		"map_id": map_id,
		"generator_theme": "",
		"detail_generator": String(detail_generator).strip_edges().to_upper(),
		"difficulty": max(0, detail_difficulty),
		"floor": 0,
		"is_final_floor": false
	}


func _build_dungeon_spawn_context(
	dungeon_difficulty: int,
	floor_number: int,
	is_final_floor: bool,
	generator_theme: String
) -> Dictionary:
	return {
		"map_kind": "dungeon",
		"map_id": map_id,
		"generator_theme": String(generator_theme).strip_edges().to_upper(),
		"detail_generator": "",
		"difficulty": max(0, dungeon_difficulty),
		"floor": max(1, floor_number),
		"is_final_floor": is_final_floor
	}


func _build_inventory_entry(item_id: String, amount: int = 1) -> Dictionary:
	if item_id == "":
		return {}

	var equipment_resource: EquipmentData = ItemDatabase.get_equipment_resource(item_id)
	if equipment_resource != null:
		var equipment_entry: Dictionary = ItemDatabase.build_random_equipment_entry(item_id, rng)
		_debug_enchant_log("[ENCHANT][ItemWorldManager] equipment spawn item_id=%s entry=%s" % [item_id, str(equipment_entry)])
		return equipment_entry

	return {
		"item_id": item_id,
		"amount": amount
	}


func _build_world_item_save_data(item_entry: Dictionary, tile: Vector2i) -> Dictionary:
	if item_entry.is_empty():
		return {}

	var save_entry: Dictionary = item_entry.duplicate(true)
	save_entry["x"] = tile.x
	save_entry["y"] = tile.y
	return save_entry


func choose_random_chest_type_id(is_final_floor: bool) -> String:
	var available_ids: Array[String] = get_available_chest_type_ids()

	if available_ids.is_empty():
		return ""

	if is_final_floor:
		if available_ids.has("treasure"):
			return "treasure"

	return available_ids[rng.randi_range(0, available_ids.size() - 1)]


func get_available_chest_type_ids() -> Array[String]:
	var result: Array[String] = []

	for data in chest_data_list:
		if data == null:
			continue

		var type_id: String = String(data.chest_type_id)
		if type_id == "":
			continue

		if not result.has(type_id):
			result.append(type_id)

	return result


func find_chest_data_by_type_id(type_id: String) -> ChestData:
	if type_id == "":
		return get_default_chest_data()

	for data in chest_data_list:
		if data == null:
			continue
		if String(data.chest_type_id) == type_id:
			return data

	return get_default_chest_data()


func get_default_chest_data() -> ChestData:
	for data in chest_data_list:
		if data != null:
			return data
	return null


func get_available_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for cell in ground_layer.get_used_cells():
		if wall_layer.get_cell_source_id(cell) != -1:
			continue
		if has_unit_on_tile(cell):
			continue
		result.append(cell)

	return result


func has_unit_on_tile(tile: Vector2i) -> bool:
	if units_node == null:
		return false

	for unit in units_node.get_children():
		if unit == null:
			continue
		if not unit.has_method("get_current_tile_coords"):
			continue
		if unit.get_current_tile_coords() == tile:
			return true

	return false


func load_item_pickups_from_world_state() -> void:
	if item_pickups_node == null:
		return

	for child in item_pickups_node.get_children():
		child.queue_free()

	if not WorldState.map_item_pickups.has(map_id):
		return

	for entry in WorldState.map_item_pickups[map_id]:
		spawn_item_from_save(entry)


func load_chests_from_world_state() -> void:
	if chests_node == null:
		return

	for child in chests_node.get_children():
		child.queue_free()

	if not WorldState.map_chests.has(map_id):
		return

	for entry in WorldState.map_chests[map_id]:
		spawn_chest_from_save(entry)


func spawn_item_from_save(data: Dictionary) -> void:
	if item_pickup_scene == null:
		push_error("ItemWorldManager: item_pickup_scene が未設定です")
		return

	var item_id: String = String(data.get("item_id", ""))
	var amount: int = int(data.get("amount", 1))
	var tile: Vector2i = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))

	if item_id == "":
		return

	var pickup = item_pickup_scene.instantiate()
	item_pickups_node.add_child(pickup)

	if pickup.has_method("setup_with_entry"):
		pickup.setup_with_entry(data.duplicate(true), map_id, tile)
	else:
		pickup.setup(item_id, amount, map_id, tile)


func spawn_chest_from_save(data: Dictionary) -> void:
	if chest_scene == null:
		push_error("ItemWorldManager: chest_scene が未設定です")
		return

	var chest = chest_scene.instantiate()

	var chest_type_id: String = String(data.get("chest_type_id", ""))

	if chest != null and chest.has_method("apply_chest_data"):
		chest.chest_data = find_chest_data_by_type_id(chest_type_id)

	chests_node.add_child(chest)

	if chest.has_method("load_from_save_data"):
		chest.load_from_save_data(data)
	else:
		chest.tile_coords = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
		chest.is_opened = bool(data.get("is_opened", false))
		if data.has("inventory") and chest.has_node("Inventory"):
			chest.get_node("Inventory").load_inventory_data(data["inventory"])
		if chest.has_method("apply_chest_data"):
			chest.apply_chest_data()
		if chest.has_method("update_visual"):
			chest.update_visual()
		if chest.has_method("snap_to_tile"):
			chest.call_deferred("snap_to_tile")


func save_current_state() -> void:
	save_item_pickups_to_world_state()
	save_chests_to_world_state()


func save_item_pickups_to_world_state() -> void:
	var result: Array = []

	if item_pickups_node != null:
		for pickup in item_pickups_node.get_children():
			if pickup == null:
				continue
			if pickup.has_method("get_save_data"):
				result.append(pickup.get_save_data())

	WorldState.map_item_pickups[map_id] = result


func save_chests_to_world_state() -> void:
	var result: Array = []

	if chests_node != null:
		for chest in chests_node.get_children():
			if chest == null:
				continue
			if chest.has_method("get_save_data"):
				result.append(chest.get_save_data())

	WorldState.map_chests[map_id] = result
