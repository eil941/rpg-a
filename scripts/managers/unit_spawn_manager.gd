extends RefCounted
class_name UnitSpawnManager

var units_node: Node
var map_id: String
var walkable_tiles: Array[Vector2i]
var tile_map: TileMapLayer
var rng := RandomNumberGenerator.new()


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
	rng.randomize()


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


func debug_unit_identity(unit: Node, label: String) -> void:
	if unit == null:
		print(label, " unit is null")
		return

	var unit_id_text: String = ""
	var map_id_text: String = ""

	if "unit_id" in unit:
		unit_id_text = String(unit.unit_id)

	if "map_id" in unit:
		map_id_text = String(unit.map_id)

	print(label, " name=", unit.name, " unit_id=", unit_id_text, " map_id=", map_id_text)


func ensure_inventory_node(unit: Node) -> void:
	if unit == null:
		return

	if unit.has_node("Inventory"):
		return

	var inventory := Inventory.new()
	inventory.name = "Inventory"
	unit.add_child(inventory)


func get_unit_inventory(unit: Node):
	if unit == null:
		return null

	if not unit.has_node("Inventory"):
		return null

	return unit.get_node("Inventory")


func inventory_has_any_items(inventory) -> bool:
	if inventory == null:
		return false

	if not inventory.has_method("get_all_items"):
		return false

	var items: Array = inventory.get_all_items()
	for entry in items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 0))
		if item_id != "" and amount > 0:
			return true

	return false


func unit_can_generate_shop_inventory_from_data(data) -> bool:
	if data == null:
		return false

	if "can_generate_shop_inventory" in data:
		return bool(data.can_generate_shop_inventory)

	return false


func get_shop_min_items_from_data(data) -> int:
	if data == null:
		return 0

	if "shop_min_items" in data:
		return int(data.shop_min_items)

	return 0


func get_shop_max_items_from_data(data) -> int:
	if data == null:
		return 0

	if "shop_max_items" in data:
		return int(data.shop_max_items)

	return 0


func get_shop_loot_categories_from_data(data) -> Array:
	if data == null:
		return []

	if "shop_loot_categories" in data:
		return data.shop_loot_categories

	return []


func get_shop_table_id_from_data(data) -> String:
	if data == null:
		return ""

	if "shop_table_id" in data:
		return String(data.shop_table_id).strip_edges()

	return ""


func choose_weighted_shop_category(data) -> LootCategoryEntry:
	if data == null:
		return null

	var shop_loot_categories: Array = get_shop_loot_categories_from_data(data)
	if shop_loot_categories.is_empty():
		return null

	var total_weight: int = 0

	for entry in shop_loot_categories:
		if entry == null:
			continue
		if entry.weight > 0:
			total_weight += entry.weight

	if total_weight <= 0:
		return null

	var roll: int = rng.randi_range(1, total_weight)
	var accum: int = 0

	for entry in shop_loot_categories:
		if entry == null:
			continue
		if entry.weight <= 0:
			continue

		accum += entry.weight
		if roll <= accum:
			return entry

	for entry in shop_loot_categories:
		if entry != null:
			return entry

	return null


func get_shop_table(shop_table_id: String) -> Dictionary:
	var normalized_id := String(shop_table_id).strip_edges()
	if normalized_id == "":
		return {}

	if GameData == null:
		return {}

	if not GameData.has_method("get_shop_table"):
		return {}

	var table_value: Variant = GameData.get_shop_table(normalized_id)
	if typeof(table_value) != TYPE_DICTIONARY:
		return {}

	var table: Dictionary = table_value
	return table


func get_shop_loot_entries(loot_table_id: String) -> Array[Dictionary]:
	var normalized_id := String(loot_table_id).strip_edges()
	if normalized_id == "":
		return []

	if GameData == null:
		return []

	if not GameData.has_method("get_shop_loot_entries"):
		return []

	var entries_value: Variant = GameData.get_shop_loot_entries(normalized_id)
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		result.append(entry)

	return result


func choose_weighted_shop_loot_entry(loot_entries: Array[Dictionary]) -> Dictionary:
	var total_weight: int = 0

	for entry in loot_entries:
		if entry.is_empty():
			continue

		total_weight += max(int(entry.get("weight", 0)), 0)

	if total_weight <= 0:
		return {}

	var roll: int = rng.randi_range(1, total_weight)
	var accum: int = 0

	for entry in loot_entries:
		if entry.is_empty():
			continue

		accum += max(int(entry.get("weight", 0)), 0)
		if roll <= accum:
			return entry

	return {}


func resolve_shop_loot_item_id(loot_entry: Dictionary) -> String:
	var item_id := String(loot_entry.get("item_id", "")).strip_edges()
	if item_id != "":
		if ItemDatabase.has_item(item_id):
			return item_id
		return ""

	var category := ItemCategories.normalize(String(loot_entry.get("category", "")))
	if category == "":
		return ""

	return ItemDatabase.get_random_item_id_by_type(category, rng)


func generate_random_shop_inventory_from_table(shop_table_id: String) -> Array:
	var result: Array = []
	var table: Dictionary = get_shop_table(shop_table_id)
	if table.is_empty():
		return result

	var loot_table_id := String(table.get("loot_table_id", "")).strip_edges()
	var loot_entries: Array[Dictionary] = get_shop_loot_entries(loot_table_id)
	if loot_entries.is_empty():
		return result

	var min_items: int = max(int(table.get("min_items", 0)), 0)
	var max_items: int = max(int(table.get("max_items", min_items)), min_items)
	var item_count: int = rng.randi_range(min_items, max_items)

	for i in range(item_count):
		var loot_entry: Dictionary = choose_weighted_shop_loot_entry(loot_entries)
		if loot_entry.is_empty():
			continue

		var item_id: String = resolve_shop_loot_item_id(loot_entry)
		if item_id == "":
			continue

		var min_amount: int = max(int(loot_entry.get("min_amount", 1)), 1)
		var max_amount: int = max(int(loot_entry.get("max_amount", min_amount)), min_amount)
		var amount: int = rng.randi_range(min_amount, max_amount)

		result.append(_build_shop_entry(item_id, amount))

	return result


func _build_shop_entry(item_id: String, amount: int) -> Dictionary:
	var equipment_resource: EquipmentData = ItemDatabase.get_equipment_resource(item_id)

	if equipment_resource != null:
		var entry: Dictionary = ItemDatabase.build_random_equipment_entry(item_id, rng)
		entry["amount"] = 1
		return entry

	return {
		"item_id": item_id,
		"amount": amount
	}


func generate_random_shop_inventory_from_data(data) -> Array:
	var result: Array = []

	if data == null:
		return result

	if not unit_can_generate_shop_inventory_from_data(data):
		return result

	var shop_table_id := get_shop_table_id_from_data(data)
	if shop_table_id != "":
		var table_inventory: Array = generate_random_shop_inventory_from_table(shop_table_id)
		if not table_inventory.is_empty():
			return table_inventory

	var min_items: int = max(get_shop_min_items_from_data(data), 0)
	var max_items: int = max(get_shop_max_items_from_data(data), min_items)
	var item_count: int = rng.randi_range(min_items, max_items)

	for i in range(item_count):
		var loot_category: LootCategoryEntry = choose_weighted_shop_category(data)
		if loot_category == null:
			continue

		var normalized_type: String = loot_category.get_normalized_item_type()
		var item_id: String = ItemDatabase.get_random_item_id_by_type(normalized_type, rng)
		if item_id == "":
			continue

		var min_amount: int = max(loot_category.min_amount, 1)
		var max_amount: int = max(loot_category.max_amount, min_amount)
		var amount: int = rng.randi_range(min_amount, max_amount)

		result.append(_build_shop_entry(item_id, amount))

	return result




func clear_runtime_state_for_new_random_unit(unit_id: String) -> void:
	if unit_id == "":
		return

	# ランダム再生成された個体に、同じ unit_id の古いクエスト・ショップ・HP等を引き継がせない。
	if WorldState.unit_states != null:
		WorldState.unit_states.erase(unit_id)

	if WorldState.unit_generated_quests != null:
		WorldState.unit_generated_quests.erase(unit_id)


func apply_generated_shop_inventory_if_needed(unit: Node, data) -> void:
	if unit == null:
		return

	if data == null:
		return

	if not unit_can_generate_shop_inventory_from_data(data):
		return

	ensure_inventory_node(unit)

	var inventory = get_unit_inventory(unit)
	if inventory == null:
		return

	if inventory_has_any_items(inventory):
		return

	var generated_inventory: Array = generate_random_shop_inventory_from_data(data)
	if generated_inventory.is_empty():
		return

	if inventory.has_method("load_inventory_data"):
		inventory.load_inventory_data(generated_inventory)
		return

	if inventory.has_method("set_item_data_at"):
		for i in range(generated_inventory.size()):
			inventory.set_item_data_at(i, generated_inventory[i])


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
		var unique_unit_id: String = make_enemy_unit_id(index)

		print("SPAWN RANDOM ENEMY GENERATED ID=", unique_unit_id, " map_id=", map_id, " index=", index)
		debug_unit_structure(enemy, "SPAWN RANDOM ENEMY BEFORE")
		debug_unit_identity(enemy, "SPAWN RANDOM ENEMY BEFORE IDENTITY")

		enemy.start_tile = tile
		enemy.unit_id = unique_unit_id
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		# New random enemies should not inherit inventory/HP from an older unit with the same generated id.
		clear_runtime_state_for_new_random_unit(unique_unit_id)

		print("SPAWN RANDOM ENEMY ASSIGNED unit_id=", enemy.unit_id, " map_id=", enemy.map_id, " enemy_type=", enemy_data.enemy_type_id)

		ensure_inventory_node(enemy)
		debug_unit_structure(enemy, "SPAWN RANDOM ENEMY AFTER")
		debug_unit_identity(enemy, "SPAWN RANDOM ENEMY AFTER IDENTITY")

		units_node.add_child(enemy)
		apply_generated_shop_inventory_if_needed(enemy, enemy_data)

		print("RANDOM SPAWN FINAL unit_id=", enemy.unit_id, " type=", enemy_data.enemy_type_id, " tile=", tile)

		used_tiles.append(tile)

		var spawn_data = {
			"unit_id": enemy.unit_id,
			"enemy_type_id": enemy_data.enemy_type_id,
			"tile_x": tile.x,
			"tile_y": tile.y,
			"is_dead": false
		}

		print("SAVE ENEMY SPAWN DATA=", spawn_data)

		if not WorldState.map_enemy_spawns.has(map_id):
			WorldState.map_enemy_spawns[map_id] = []

		WorldState.map_enemy_spawns[map_id].append(spawn_data)
		return


func spawn_random_enemies(
	enemy_unit_scene: PackedScene,
	enemy_data_list: Array[EnemyData],
	enemy_spawn_count: int
) -> void:
	var used_tiles: Array[Vector2i] = collect_used_tiles_from_units()

	for i in range(enemy_spawn_count):
		spawn_enemy_random(enemy_unit_scene, enemy_data_list, used_tiles, i)

	spawn_active_bounty_for_current_map(enemy_unit_scene, enemy_data_list)


func spawn_saved_enemies(enemy_unit_scene: PackedScene, enemy_data_list: Array[EnemyData]) -> void:
	var saved_list = WorldState.map_enemy_spawns.get(map_id, [])

	for spawn_data in saved_list:
		print("LOAD SAVED ENEMY SPAWN DATA=", spawn_data)

		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var enemy_data = find_enemy_data_by_id(enemy_data_list, spawn_data["enemy_type_id"])
		if enemy_data == null:
			continue

		print("FOUND ENEMY DATA type=", enemy_data.enemy_type_id, " for unit_id=", unit_id)

		var enemy = enemy_unit_scene.instantiate()
		debug_unit_structure(enemy, "SPAWN SAVED ENEMY BEFORE")
		debug_unit_identity(enemy, "SPAWN SAVED ENEMY BEFORE IDENTITY")

		enemy.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		enemy.unit_id = unit_id
		enemy.map_id = map_id
		enemy.enemy_data_to_apply = enemy_data

		print("SPAWN SAVED ENEMY ASSIGNED unit_id=", enemy.unit_id, " map_id=", enemy.map_id, " enemy_type=", enemy_data.enemy_type_id)

		ensure_inventory_node(enemy)
		debug_unit_structure(enemy, "SPAWN SAVED ENEMY AFTER")
		debug_unit_identity(enemy, "SPAWN SAVED ENEMY AFTER IDENTITY")

		units_node.add_child(enemy)
		apply_generated_shop_inventory_if_needed(enemy, enemy_data)

	spawn_active_bounty_for_current_map(enemy_unit_scene, enemy_data_list)


func spawn_active_bounty_for_current_map(enemy_unit_scene: PackedScene, enemy_data_list: Array[EnemyData]) -> void:
	if enemy_unit_scene == null:
		return
	if BountyManager == null:
		return

	var used_tiles: Array[Vector2i] = collect_used_tiles_from_units()
	var bounty: Dictionary = BountyManager.ensure_active_bounty_for_map(
		map_id,
		enemy_data_list,
		walkable_tiles,
		used_tiles
	)

	if bounty.is_empty():
		return

	var bounty_id: String = String(bounty.get("bounty_id", ""))
	var unit_id: String = String(bounty.get("unit_id", ""))
	if bounty_id == "":
		return
	if unit_id == "":
		unit_id = BountyManager.make_bounty_unit_id(bounty_id)

	if _has_unit_with_id(unit_id):
		return

	var enemy_type_id: String = String(bounty.get("enemy_type_id", ""))
	var enemy_data: EnemyData = find_enemy_data_by_id(enemy_data_list, enemy_type_id)
	if enemy_data == null:
		enemy_data = EnemyDatabase.get_enemy(enemy_type_id)
	if enemy_data == null:
		return

	var spawn_tile: Vector2i = WorldState.value_to_vector2i(
		bounty.get("spawn_position", {}),
		Vector2i.ZERO
	)

	var enemy = enemy_unit_scene.instantiate()
	enemy.start_tile = spawn_tile
	enemy.unit_id = unit_id
	enemy.map_id = map_id
	enemy.enemy_data_to_apply = enemy_data
	enemy.is_bounty = true
	enemy.bounty_id = bounty_id
	enemy.bounty_reward_gold = int(bounty.get("reward_gold", 0))
	enemy.bounty_stat_multiplier = float(bounty.get("stat_multiplier", 1.0))

	ensure_inventory_node(enemy)
	units_node.add_child(enemy)
	apply_generated_shop_inventory_if_needed(enemy, enemy_data)

	var bounty_display_name: String = enemy_type_id
	if enemy != null and enemy.has_method("get_talk_name"):
		bounty_display_name = String(enemy.get_talk_name())

	var discovery_log: String = "賞金首を発見: %s" % bounty_display_name
	if enemy != null and enemy.has_method("notify_hud_log"):
		enemy.notify_hud_log(discovery_log)

	print(discovery_log, " unit_id=", unit_id, " bounty_id=", bounty_id, " tile=", spawn_tile)


func _has_unit_with_id(target_unit_id: String) -> bool:
	if target_unit_id == "":
		return false

	for unit in units_node.get_children():
		if unit == null:
			continue
		if not ("unit_id" in unit):
			continue
		if String(unit.unit_id) == target_unit_id:
			return true

	return false


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
		var unique_unit_id: String = make_npc_unit_id(index)

		print("SPAWN RANDOM NPC GENERATED ID=", unique_unit_id, " map_id=", map_id, " index=", index)
		debug_unit_structure(npc, "SPAWN RANDOM NPC BEFORE")
		debug_unit_identity(npc, "SPAWN RANDOM NPC BEFORE IDENTITY")

		npc.start_tile = tile
		npc.unit_id = unique_unit_id
		npc.map_id = map_id

		# 新規ランダム生成なので、同じ unit_id に残っていた古いクエスト/ショップ/HPなどを消す。
		clear_runtime_state_for_new_random_unit(unique_unit_id)

		print("SPAWN RANDOM NPC ASSIGNED unit_id=", npc.unit_id, " map_id=", npc.map_id, " npc_type=", npc_data.npc_type_id)

		ensure_inventory_node(npc)
		debug_unit_structure(npc, "SPAWN RANDOM NPC AFTER")
		debug_unit_identity(npc, "SPAWN RANDOM NPC AFTER IDENTITY")

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

		print("SAVE NPC SPAWN DATA=", spawn_data)

		if not WorldState.map_npc_spawns.has(map_id):
			WorldState.map_npc_spawns[map_id] = []

		WorldState.map_npc_spawns[map_id].append(spawn_data)
		return


func spawn_random_npcs(
	npc_unit_scene: PackedScene,
	npc_data_list: Array[NpcData],
	npc_spawn_count: int
) -> void:
	var used_tiles: Array[Vector2i] = collect_used_tiles_from_units()

	for i in range(npc_spawn_count):
		spawn_npc_random(npc_unit_scene, npc_data_list, used_tiles, i)


func spawn_saved_npcs(npc_unit_scene: PackedScene, npc_data_list: Array[NpcData]) -> void:
	var saved_list = WorldState.map_npc_spawns.get(map_id, [])

	for spawn_data in saved_list:
		print("LOAD SAVED NPC SPAWN DATA=", spawn_data)

		if spawn_data.get("is_dead", false):
			continue

		var unit_id = spawn_data["unit_id"]

		if WorldState.unit_states.has(unit_id):
			if WorldState.unit_states[unit_id].get("is_dead", false):
				continue

		var npc_data = find_npc_data_by_id(npc_data_list, spawn_data["npc_type_id"])
		if npc_data == null:
			continue

		print("FOUND NPC DATA type=", npc_data.npc_type_id, " for unit_id=", unit_id)

		var npc = npc_unit_scene.instantiate()
		debug_unit_structure(npc, "SPAWN SAVED NPC BEFORE")
		debug_unit_identity(npc, "SPAWN SAVED NPC BEFORE IDENTITY")

		npc.start_tile = Vector2i(spawn_data["tile_x"], spawn_data["tile_y"])
		npc.unit_id = unit_id
		npc.map_id = map_id

		print("SPAWN SAVED NPC ASSIGNED unit_id=", npc.unit_id, " map_id=", npc.map_id, " npc_type=", npc_data.npc_type_id)

		ensure_inventory_node(npc)
		debug_unit_structure(npc, "SPAWN SAVED NPC AFTER")
		debug_unit_identity(npc, "SPAWN SAVED NPC AFTER IDENTITY")

		units_node.add_child(npc)
		npc.apply_npc_data(npc_data)
