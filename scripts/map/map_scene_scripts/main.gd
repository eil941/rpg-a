extends Node2D

@onready var player = $Units/Unit
@onready var ground_layer: TileMapLayer = get_node_or_null("GroundLayer")
@onready var wall_layer: TileMapLayer = get_node_or_null("WallLayer")
@onready var event_layer: TileMapLayer = get_node_or_null("EventLayer")
@onready var units_node: Node = get_node_or_null("Units")
@onready var item_pickups_node: Node = get_node_or_null("ItemPickups")
@onready var chests_node: Node = get_node_or_null("Chests")

@export var enemy_unit_scene: PackedScene
@export var npc_unit_scene: PackedScene

@export var item_pickup_scene: PackedScene
@export var chest_scene: PackedScene
@export var chest_data_list: Array[ChestData]

@export var fallback_enemy_spawn_count: int = 0
@export var fallback_npc_spawn_count: int = 0

@export var map_id: String = ""

const MAP_WIDTH: int = 30
const MAP_HEIGHT: int = 30

const FLOOR_SOURCE_ID: int = 2
const WALL_SOURCE_ID: int = 0

const FLOOR_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const WALL_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

var spawn_manager: UnitSpawnManager
var map_generator: BaseMapGenerator
var item_world_manager: ItemWorldManager


func _ready() -> void:
	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("Main: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	if GlobalDetailMap.current_detail_map_key != "":
		map_id = GlobalDetailMap.current_detail_map_key

	player.map_id = map_id

	var generator_type: String = get_effective_generator_type()
	var use_generated_map: bool = is_valid_generator_type(generator_type)

	print("MAIN map_id = ", map_id)
	print("MAIN generator_type = [", generator_type, "]")
	print("MAIN use_generated_map = ", use_generated_map)

	_ensure_detail_map_config(generator_type)
	_log_entered_area_difficulty()

	if use_generated_map:
		map_generator = create_map_generator(generator_type)

		if WorldState.map_tile_data.has(map_id):
			load_map_tiles()
		else:
			map_generator.generate_map(ground_layer, wall_layer, event_layer)
			save_map_tiles()
	else:
		map_generator = null
		if not WorldState.map_tile_data.has(map_id):
			save_map_tiles()

	var walkable_tiles: Array[Vector2i] = []
	if use_generated_map and map_generator != null:
		walkable_tiles = map_generator.get_walkable_tiles()
	else:
		walkable_tiles = collect_walkable_tiles_from_existing_map()

	spawn_manager = UnitSpawnManager.new(
		$Units,
		ground_layer,
		map_id,
		walkable_tiles
	)

	var spawn_context: Dictionary = _build_spawn_context(generator_type)

	var all_enemy_data: Array[EnemyData] = EnemyDatabase.get_all_enemy_data()
	var all_npc_data: Array[NpcData] = NpcDatabase.get_all_npc_data()

	var current_enemy_spawn_count: int = fallback_enemy_spawn_count
	var current_npc_spawn_count: int = fallback_npc_spawn_count
	var current_enemy_data_list: Array[EnemyData] = all_enemy_data
	var current_npc_data_list: Array[NpcData] = all_npc_data

	var enemy_pool_info: Dictionary = _build_enemy_spawn_pool(spawn_context, all_enemy_data)
	if enemy_pool_info.get("count", 0) > 0 and enemy_pool_info.get("pool", []).size() > 0:
		current_enemy_spawn_count = int(enemy_pool_info.get("count", 0))
		current_enemy_data_list = enemy_pool_info.get("pool", [])

	var npc_pool_info: Dictionary = _build_npc_spawn_pool(spawn_context, all_npc_data)
	if npc_pool_info.get("count", 0) > 0 and npc_pool_info.get("pool", []).size() > 0:
		current_npc_spawn_count = int(npc_pool_info.get("count", 0))
		current_npc_data_list = npc_pool_info.get("pool", [])

	print("spawn_context = ", spawn_context)
	print("current_enemy_spawn_count = ", current_enemy_spawn_count)
	print("current_npc_spawn_count = ", current_npc_spawn_count)
	print("current_enemy_data_list size = ", current_enemy_data_list.size())
	print("current_npc_data_list size = ", current_npc_data_list.size())

	if WorldState.map_enemy_spawns.has(map_id):
		print("LOAD ENEMIES map_id=", map_id)
		spawn_manager.spawn_saved_enemies(enemy_unit_scene, current_enemy_data_list)
	elif current_enemy_spawn_count > 0:
		print("SPAWN RANDOM ENEMIES map_id=", map_id)
		spawn_manager.spawn_random_enemies(
			enemy_unit_scene,
			current_enemy_data_list,
			current_enemy_spawn_count
		)
	else:
		print("SKIP ENEMY SPAWN map_id=", map_id)

	if WorldState.map_npc_spawns.has(map_id):
		print("LOAD NPCS map_id=", map_id)
		spawn_manager.spawn_saved_npcs(npc_unit_scene, current_npc_data_list)
	elif current_npc_spawn_count > 0:
		print("SPAWN RANDOM NPCS map_id=", map_id)
		spawn_manager.spawn_random_npcs(
			npc_unit_scene,
			current_npc_data_list,
			current_npc_spawn_count
		)
	else:
		print("SKIP NPC SPAWN map_id=", map_id)

	item_world_manager = ItemWorldManager.new(
		self,
		ground_layer,
		wall_layer,
		units_node,
		item_pickups_node,
		chests_node,
		map_id,
		item_pickup_scene,
		chest_scene,
		chest_data_list
	)
	item_world_manager.setup_detail_map_random_spawn_with_save()

	if player != null and player.has_method("reset_after_map_transition"):
		player.reset_after_map_transition()

	print("GlobalDetailMap.current_area_difficulty = ", GlobalDetailMap.current_area_difficulty)
	if WorldState.field_detail_map_data.has(map_id):
		print("saved area_difficulty = ", WorldState.field_detail_map_data[map_id].get("area_difficulty", null))


func _log_entered_area_difficulty() -> void:
	var difficulty: int = int(GlobalDetailMap.current_area_difficulty)

	if WorldState.field_detail_map_data.has(map_id):
		var saved_difficulty: int = int(WorldState.field_detail_map_data[map_id].get("area_difficulty", difficulty))
		if saved_difficulty > 0:
			difficulty = saved_difficulty

	var message: String = "このエリアの難易度: " + str(difficulty)

	var hud = get_tree().get_root().find_child("GameHUD", true, false)
	if hud != null and hud.has_method("add_log"):
		hud.add_log(message)
	else:
		print(message)


func _ensure_detail_map_config(generator_type: String) -> void:
	if map_id == "":
		return

	var normalized_generator_type: String = String(generator_type).strip_edges().replace("\"", "").to_upper()
	var current_area_difficulty: int = int(GlobalDetailMap.current_area_difficulty)

	if not WorldState.field_detail_map_data.has(map_id):
		WorldState.field_detail_map_data[map_id] = {
			"generator_type": normalized_generator_type,
			"area_difficulty": current_area_difficulty
		}
		return

	var detail_config: Dictionary = WorldState.field_detail_map_data[map_id]

	if not detail_config.has("generator_type") or String(detail_config.get("generator_type", "")).strip_edges() == "":
		detail_config["generator_type"] = normalized_generator_type

	if not detail_config.has("area_difficulty"):
		detail_config["area_difficulty"] = current_area_difficulty
	else:
		var saved_area_difficulty: int = int(detail_config.get("area_difficulty", 0))
		if saved_area_difficulty <= 0 and current_area_difficulty > 0:
			detail_config["area_difficulty"] = current_area_difficulty

	WorldState.field_detail_map_data[map_id] = detail_config


func _build_spawn_context(generator_type: String) -> Dictionary:
	var normalized_generator_type: String = String(generator_type).strip_edges().replace("\"", "").to_upper()
	var area_difficulty: int = int(GlobalDetailMap.current_area_difficulty)

	if WorldState.field_detail_map_data.has(map_id):
		var saved_area_difficulty: int = int(WorldState.field_detail_map_data[map_id].get("area_difficulty", area_difficulty))
		if saved_area_difficulty > 0:
			area_difficulty = saved_area_difficulty

	var current_hour: int = 12
	if TimeManager != null and TimeManager.has_method("get_hour"):
		current_hour = int(TimeManager.get_hour())

	return {
		"generator_type": normalized_generator_type,
		"area_difficulty": area_difficulty,
		"hour": current_hour
	}


func _build_enemy_spawn_pool(context: Dictionary, all_enemy_data: Array[EnemyData]) -> Dictionary:
	var selected_rule: SpawnRuleData = _get_best_matching_spawn_rule("ENEMY", context)
	var pool: Array[EnemyData] = []
	var total_spawn_count: int = 0

	if selected_rule == null:
		print("enemy selected rule = null")
		return {
			"count": 0,
			"pool": pool
		}

	print("enemy selected rule = ", selected_rule.rule_id, " max_spawn_count=", selected_rule.max_spawn_count, " weight=", selected_rule.weight)

	total_spawn_count = max(0, selected_rule.max_spawn_count)

	for data in all_enemy_data:
		if data == null:
			continue
		if not _is_enemy_allowed_by_rule_and_context(data, selected_rule, context):
			continue

		var entry_weight: int = _calculate_enemy_entry_weight(data, selected_rule, context)
		_append_weighted_enemy(pool, data, entry_weight)

	return {
		"count": total_spawn_count,
		"pool": pool
	}


func _build_npc_spawn_pool(context: Dictionary, all_npc_data: Array[NpcData]) -> Dictionary:
	var selected_rule: SpawnRuleData = _get_best_matching_spawn_rule("NPC", context)
	var pool: Array[NpcData] = []
	var total_spawn_count: int = 0

	if selected_rule == null:
		print("npc selected rule = null")
		return {
			"count": 0,
			"pool": pool
		}

	print("npc selected rule = ", selected_rule.rule_id, " max_spawn_count=", selected_rule.max_spawn_count, " weight=", selected_rule.weight)

	total_spawn_count = max(0, selected_rule.max_spawn_count)

	for data in all_npc_data:
		if data == null:
			continue
		if not _is_npc_allowed_by_rule_and_context(data, selected_rule, context):
			continue

		var entry_weight: int = _calculate_npc_entry_weight(data, selected_rule, context)
		_append_weighted_npc(pool, data, entry_weight)

	return {
		"count": total_spawn_count,
		"pool": pool
	}


func _get_best_matching_spawn_rule(spawn_kind: String, context: Dictionary) -> SpawnRuleData:
	var generator_type: String = String(context.get("generator_type", ""))
	var area_difficulty: int = int(context.get("area_difficulty", 0))
	var hour: int = int(context.get("hour", 12))

	var all_results: Array[SpawnRuleData] = SpawnRuleDatabase.get_matching_rules(
		spawn_kind,
		generator_type,
		area_difficulty,
		hour
	)

	var candidates: Array[SpawnRuleData] = []
	for rule in all_results:
		if rule == null:
			continue
		if _rule_requires_distance_filter(rule):
			print("SKIP RULE (distance handled by field difficulty): ", rule.rule_id)
			continue
		candidates.append(rule)

	if candidates.is_empty():
		return null

	var best_rule: SpawnRuleData = candidates[0]

	for i in range(1, candidates.size()):
		var rule: SpawnRuleData = candidates[i]
		if _is_rule_better(rule, best_rule):
			best_rule = rule

	return best_rule


func _is_rule_better(a: SpawnRuleData, b: SpawnRuleData) -> bool:
	var a_width: int = _get_rule_area_range_width(a)
	var b_width: int = _get_rule_area_range_width(b)

	if a_width != b_width:
		return a_width < b_width

	if a.min_area_difficulty != b.min_area_difficulty:
		return a.min_area_difficulty > b.min_area_difficulty

	return false


func _get_rule_area_range_width(rule: SpawnRuleData) -> int:
	var min_value: int = rule.min_area_difficulty
	var max_value: int = rule.max_area_difficulty

	if min_value < 0 and max_value < 0:
		return 999999

	if min_value < 0:
		min_value = 0

	if max_value < 0:
		max_value = 999999

	return max_value - min_value + 1


func _rule_requires_distance_filter(rule: SpawnRuleData) -> bool:
	return rule.min_distance_from_start >= 0 or rule.max_distance_from_start >= 0


func _is_enemy_allowed_by_rule_and_context(data: EnemyData, rule: SpawnRuleData, context: Dictionary) -> bool:
	var generator_type: String = String(context.get("generator_type", ""))

	var spawn_generator_tags: Array = _get_array_property(data, "spawn_generator_tags")
	if spawn_generator_tags.size() > 0 and not spawn_generator_tags.has(generator_type):
		return false

	var base_difficulty: int = int(_get_property_or_default(data, "base_difficulty", 0))

	if rule.min_enemy_difficulty >= 0 and base_difficulty < rule.min_enemy_difficulty:
		return false

	if rule.max_enemy_difficulty >= 0 and base_difficulty > rule.max_enemy_difficulty:
		return false

	return true


func _is_npc_allowed_by_rule_and_context(data: NpcData, rule: SpawnRuleData, context: Dictionary) -> bool:
	var generator_type: String = String(context.get("generator_type", ""))

	var spawn_generator_tags: Array = _get_array_property(data, "spawn_generator_tags")
	if spawn_generator_tags.size() > 0 and not spawn_generator_tags.has(generator_type):
		return false

	return true


func _calculate_enemy_entry_weight(data: EnemyData, rule: SpawnRuleData, context: Dictionary) -> int:
	var result: int = max(1, rule.weight)
	var hour: int = int(context.get("hour", 12))
	var is_nocturnal: bool = bool(_get_property_or_default(data, "is_nocturnal", false))
	var rarity: int = int(_get_property_or_default(data, "rarity", 1))

	if is_nocturnal and (hour >= 18 or hour <= 5):
		result += 2

	result *= max(1, 6 - rarity)
	return clampi(result, 1, 20)


func _calculate_npc_entry_weight(data: NpcData, rule: SpawnRuleData, context: Dictionary) -> int:
	var result: int = max(1, rule.weight)
	var rarity: int = int(_get_property_or_default(data, "rarity", 1))

	result *= max(1, 6 - rarity)
	return clampi(result, 1, 20)


func _append_weighted_enemy(pool: Array[EnemyData], data: EnemyData, weight: int) -> void:
	var safe_weight: int = clampi(weight, 1, 20)
	for i in range(safe_weight):
		pool.append(data)


func _append_weighted_npc(pool: Array[NpcData], data: NpcData, weight: int) -> void:
	var safe_weight: int = clampi(weight, 1, 20)
	for i in range(safe_weight):
		pool.append(data)


func _get_property_or_default(obj: Object, property_name: String, default_value: Variant) -> Variant:
	if obj == null:
		return default_value

	for info in obj.get_property_list():
		if String(info.get("name", "")) == property_name:
			return obj.get(property_name)

	return default_value


func _get_array_property(obj: Object, property_name: String) -> Array:
	var value: Variant = _get_property_or_default(obj, property_name, [])
	if value is Array:
		return value
	return []


func get_effective_generator_type() -> String:
	var generator_type: String = String(GlobalDetailMap.current_generator_type).strip_edges().replace("\"", "").to_upper()

	if generator_type == "" and WorldState.field_detail_map_data.has(map_id):
		var detail_config: Dictionary = WorldState.field_detail_map_data[map_id]
		generator_type = String(detail_config.get("generator_type", "")).strip_edges().replace("\"", "").to_upper()

	return generator_type


func is_valid_generator_type(generator_type: String) -> bool:
	match generator_type:
		"GRASS", "SAND", "FOREST", "BEACH", "SEA":
			return true

	return false


func collect_walkable_tiles_from_existing_map() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var used_cells: Array[Vector2i] = ground_layer.get_used_cells()

	for cell in used_cells:
		var ground_source_id: int = ground_layer.get_cell_source_id(cell)
		if ground_source_id == -1:
			continue

		var wall_source_id: int = wall_layer.get_cell_source_id(cell)
		if wall_source_id != -1:
			continue

		result.append(cell)

	print("EXISTING MAP walkable_tiles size = ", result.size())
	return result


func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)
		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()

	if item_world_manager != null:
		item_world_manager.save_current_state()


func save_layer_data(layer: TileMapLayer) -> Array:
	var result: Array = []
	var used_cells: Array = layer.get_used_cells()

	for cell in used_cells:
		var source_id: int = layer.get_cell_source_id(cell)
		if source_id == -1:
			continue

		var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
		var alternative: int = layer.get_cell_alternative_tile(cell)

		result.append({
			"x": cell.x,
			"y": cell.y,
			"source_id": source_id,
			"atlas_x": atlas_coords.x,
			"atlas_y": atlas_coords.y,
			"alternative": alternative
		})

	return result


func load_layer_data(layer: TileMapLayer, data: Array) -> void:
	layer.clear()

	for cell_data in data:
		var cell: Vector2i = Vector2i(cell_data["x"], cell_data["y"])
		var source_id: int = cell_data["source_id"]
		var atlas_coords: Vector2i = Vector2i(cell_data["atlas_x"], cell_data["atlas_y"])
		var alternative: int = cell_data["alternative"]

		layer.set_cell(cell, source_id, atlas_coords, alternative)


func save_map_tiles() -> void:
	WorldState.map_tile_data[map_id] = {
		"ground": save_layer_data(ground_layer),
		"wall": save_layer_data(wall_layer),
		"event": save_layer_data(event_layer)
	}


func load_map_tiles() -> void:
	if not WorldState.map_tile_data.has(map_id):
		return

	var data: Dictionary = WorldState.map_tile_data[map_id]

	load_layer_data(ground_layer, data.get("ground", []))
	load_layer_data(wall_layer, data.get("wall", []))
	load_layer_data(event_layer, data.get("event", []))


func create_map_generator(generator_type: String) -> BaseMapGenerator:
	generator_type = generator_type.strip_edges().replace("\"", "").to_upper()
	print("normalized=[" + generator_type + "]")

	match generator_type:
		"GRASS":
			return GrasslandMapGenerator.new(
				MAP_WIDTH,
				MAP_HEIGHT,
				FLOOR_SOURCE_ID,
				WALL_SOURCE_ID,
				FLOOR_ATLAS_COORDS,
				WALL_ATLAS_COORDS
			)

		"SAND":
			return BeachMapGenerator.new(
				MAP_WIDTH,
				MAP_HEIGHT,
				FLOOR_SOURCE_ID,
				WALL_SOURCE_ID,
				FLOOR_ATLAS_COORDS,
				WALL_ATLAS_COORDS
			)

		"FOREST":
			return ForestMapGenerator.new(
				MAP_WIDTH,
				MAP_HEIGHT,
				FLOOR_SOURCE_ID,
				WALL_SOURCE_ID,
				FLOOR_ATLAS_COORDS,
				WALL_ATLAS_COORDS
			)

		"BEACH":
			return BeachMapGenerator.new(
				MAP_WIDTH,
				MAP_HEIGHT,
				FLOOR_SOURCE_ID,
				WALL_SOURCE_ID,
				FLOOR_ATLAS_COORDS,
				WALL_ATLAS_COORDS
			)

		"SEA":
			return SeaMapGenerator.new(
				MAP_WIDTH,
				MAP_HEIGHT,
				FLOOR_SOURCE_ID,
				WALL_SOURCE_ID,
				FLOOR_ATLAS_COORDS,
				WALL_ATLAS_COORDS
			)

	push_error("UNKNOWN GENERATOR TYPE: " + generator_type)
	return null
