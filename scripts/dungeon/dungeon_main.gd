extends Node2D

@onready var player = $Units/Unit

@onready var ground_layer: TileMapLayer = get_node_or_null("GroundLayer")
@onready var wall_layer: TileMapLayer = get_node_or_null("WallLayer")
@onready var event_layer: TileMapLayer = get_node_or_null("EventLayer")
@onready var units_node: Node = get_node_or_null("Units")
@onready var item_pickups_node: Node = get_node_or_null("ItemPickups")
@onready var chests_node: Node = get_node_or_null("Chests")

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 0

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 0
@export var npc_data_list: Array[NpcData]

@export var item_pickup_scene: PackedScene
@export var chest_scene: PackedScene
@export var chest_data_list: Array[ChestData]

# 通常階の敵スポーン数は Inspector で調整
@export var normal_enemy_spawn_min: int = 4
@export var normal_enemy_spawn_max: int = 8

@export var map_id: String = ""

@export var MIN_MAP_WIDTH: int = 30
@export var MAX_MAP_WIDTH: int = 60
@export var MIN_MAP_HEIGHT: int = 30
@export var MAX_MAP_HEIGHT: int = 60

@export var stairs_trigger_on_touch: bool = false

const EVENT_RETURN_STAIRS_SOURCE_ID: int = 3
const EVENT_NEXT_STAIRS_SOURCE_ID: int = 6

var spawn_manager: UnitSpawnManager
var map_generator: BaseDungeonGenerator
var item_world_manager: ItemWorldManager


func _ready() -> void:
	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("DungeonMain: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	if GlobalDungeon.current_dungeon_id == "":
		push_error("DungeonMain: current_dungeon_id が空です")
		return

	map_id = GlobalDungeon.current_dungeon_id + "_floor_" + str(GlobalDungeon.current_floor)
	player.map_id = map_id

	_ensure_floor_data_exists(map_id)

	var floor_data: Dictionary = WorldState.dungeon_floor_data[map_id]
	var generator_theme: String = String(floor_data.get("generator_theme", "NATURAL")).strip_edges().replace("\"", "").to_upper()
	var layout_generator_type: String = String(floor_data.get("layout_generator_type", "ROOM")).strip_edges().replace("\"", "").to_upper()
	var is_bottom_floor: bool = bool(floor_data.get("is_bottom", false))
	var map_width: int = int(floor_data.get("map_width", MIN_MAP_WIDTH))
	var map_height: int = int(floor_data.get("map_height", MIN_MAP_HEIGHT))

	GlobalDungeon.current_generator_theme = generator_theme
	GlobalDungeon.current_layout_generator_type = layout_generator_type
	GlobalDungeon.current_generator_type = generator_theme

	var dungeon_info: Dictionary = WorldState.dungeon_data[GlobalDungeon.current_dungeon_id]
	var difficulty: int = int(dungeon_info.get("difficulty", 50))
	var effective_difficulty: int = clampi(difficulty + (GlobalDungeon.current_floor - 1), 1, 100)

	notify_hud_log(
		"第" + str(GlobalDungeon.current_floor) +
		"階: " + generator_theme +
		" / " + layout_generator_type +
		" / 難易度 " + str(effective_difficulty)
	)

	map_generator = create_map_generator(layout_generator_type, map_width, map_height)

	if WorldState.map_tile_data.has(map_id):
		load_map_tiles()
	else:
		map_generator.generate_map(ground_layer, wall_layer, event_layer, is_bottom_floor)
		save_map_tiles()

	var current_enemy_spawn_count: int = enemy_spawn_count
	var current_npc_spawn_count: int = npc_spawn_count

	var enemy_type_ids: Array = floor_data.get("enemy_type_ids", [])
	var npc_type_ids: Array = floor_data.get("npc_type_ids", [])

	var current_enemy_data_list: Array[EnemyData] = filter_enemy_data_by_ids(enemy_type_ids)
	var current_npc_data_list: Array[NpcData] = npc_data_list

	current_enemy_spawn_count = int(floor_data.get("enemy_spawn_count", enemy_spawn_count))
	current_npc_spawn_count = int(floor_data.get("npc_spawn_count", npc_spawn_count))

	if npc_type_ids.size() > 0:
		current_npc_data_list = filter_npc_data_by_ids(npc_type_ids)

	var walkable_tiles: Array[Vector2i] = map_generator.get_walkable_tiles()

	spawn_manager = UnitSpawnManager.new(
		$Units,
		ground_layer,
		map_id,
		walkable_tiles
	)

	if WorldState.map_enemy_spawns.has(map_id):
		spawn_manager.spawn_saved_enemies(enemy_unit_scene, current_enemy_data_list)
	elif current_enemy_spawn_count > 0 and current_enemy_data_list.size() > 0:
		spawn_manager.spawn_random_enemies(
			enemy_unit_scene,
			current_enemy_data_list,
			current_enemy_spawn_count
		)

	if current_npc_spawn_count > 0 and current_npc_data_list.size() > 0:
		if WorldState.map_npc_spawns.has(map_id):
			spawn_manager.spawn_saved_npcs(npc_unit_scene, current_npc_data_list)
		else:
			spawn_manager.spawn_random_npcs(
				npc_unit_scene,
				current_npc_data_list,
				current_npc_spawn_count
			)

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

	var item_spawn_dungeon_kind: String = _get_item_spawn_dungeon_kind(layout_generator_type)

	item_world_manager.setup_dungeon_floor_random_spawn_with_save(
		effective_difficulty,
		GlobalDungeon.current_floor,
		is_bottom_floor,
		item_spawn_dungeon_kind
	)

	place_player_on_pending_stair()


func _ensure_floor_data_exists(floor_map_id: String) -> void:
	if WorldState.dungeon_floor_data.has(floor_map_id):
		return

	if not WorldState.dungeon_data.has(GlobalDungeon.current_dungeon_id):
		push_error("Dungeon data not found: " + GlobalDungeon.current_dungeon_id)
		return

	var dungeon_info: Dictionary = WorldState.dungeon_data[GlobalDungeon.current_dungeon_id]
	var max_floor: int = int(dungeon_info.get("max_floor", 3))
	var difficulty: int = int(dungeon_info.get("difficulty", 50))

	var generator_theme: String = _get_effective_dungeon_theme(dungeon_info)
	var layout_generator_type: String = choose_random_layout_generator_type(generator_theme)
	var is_bottom: bool = GlobalDungeon.current_floor >= max_floor

	var map_width: int = randi_range(MIN_MAP_WIDTH, MAX_MAP_WIDTH)
	var map_height: int = randi_range(MIN_MAP_HEIGHT, MAX_MAP_HEIGHT)

	var enemy_config: Dictionary = choose_enemy_config_for_floor(
		GlobalDungeon.current_floor,
		difficulty,
		generator_theme,
		layout_generator_type
	)

	WorldState.dungeon_floor_data[floor_map_id] = {
		"dungeon_id": GlobalDungeon.current_dungeon_id,
		"floor": GlobalDungeon.current_floor,
		"generator_theme": generator_theme,
		"layout_generator_type": layout_generator_type,
		"generator_type": layout_generator_type,
		"is_bottom": is_bottom,
		"map_width": map_width,
		"map_height": map_height,
		"enemy_spawn_count": enemy_config["enemy_spawn_count"],
		"enemy_type_ids": enemy_config["enemy_type_ids"],
		"selected_rule_id": String(enemy_config.get("selected_rule_id", "")),
		"npc_spawn_count": 0,
		"npc_type_ids": []
	}


func _get_effective_dungeon_theme(dungeon_info: Dictionary) -> String:
	if GlobalDungeon.current_generator_theme != "":
		return String(GlobalDungeon.current_generator_theme).strip_edges().replace("\"", "").to_upper()

	var theme: String = String(dungeon_info.get("generator_theme", "NATURAL")).strip_edges().replace("\"", "").to_upper()
	return theme


func choose_random_layout_generator_type(generator_theme: String) -> String:
	var candidates: Array[String] = get_layout_candidates_for_theme(generator_theme)
	if candidates.is_empty():
		return "ROOM"
	return candidates[randi_range(0, candidates.size() - 1)]


func get_layout_candidates_for_theme(generator_theme: String) -> Array[String]:
	var normalized_theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()

	match normalized_theme:
		"NATURAL":
			return ["ROOM", "CAVE", "RUINS"]
		"FORTIFIED":
			return ["RUINS", "CROSS", "ARENA"]
		"RUINED":
			return ["RUINS", "ROOM", "MAZE"]
		"ARTIFICIAL":
			return ["CROSS", "ARENA", "LINEAR", "RINGS"]
		"CHAOTIC":
			return ["LINEAR", "RINGS", "MAZE", "CAVE"]

	return ["ROOM", "CAVE", "RUINS"]


func _get_item_spawn_dungeon_kind(layout_generator_type: String) -> String:
	var kind_text: String = String(layout_generator_type).strip_edges().replace("\"", "").to_lower()

	match kind_text:
		"cave":
			return "cave"
		"ruins":
			return "ruins"
		"maze":
			return "maze"
		"room":
			return "maze"
		"cross":
			return "maze"
		"arena":
			return "ruins"
		"linear":
			return "maze"
		"rings":
			return "maze"
		_:
			return "cave"


func choose_enemy_config_for_floor(
	floor: int,
	difficulty: int,
	generator_theme: String,
	layout_generator_type: String
) -> Dictionary:
	var effective_difficulty: int = clampi(difficulty + (floor - 1), 1, 100)
	var context: Dictionary = {
		"generator_theme": String(generator_theme).strip_edges().replace("\"", "").to_upper(),
		"layout_generator_type": String(layout_generator_type).strip_edges().replace("\"", "").to_upper(),
		"floor_difficulty": effective_difficulty,
		"floor_number": floor
	}

	var selected_rule: DungeonSpawnRuleData = _get_best_matching_dungeon_spawn_rule("ENEMY", context)
	if selected_rule != null:
		print("dungeon special rule selected = ", selected_rule.rule_id)
		return _build_enemy_config_from_rule(selected_rule, context)

	print("dungeon special rule selected = null -> use normal spawn")
	return _build_normal_enemy_config_for_floor(context)


func _build_enemy_config_from_rule(rule: DungeonSpawnRuleData, context: Dictionary) -> Dictionary:
	var weighted_enemy_ids: Array[String] = _build_weighted_enemy_type_ids_from_rule(rule, context)

	if weighted_enemy_ids.is_empty():
		return _build_normal_enemy_config_for_floor(context)

	return {
		"enemy_spawn_count": max(0, rule.max_spawn_count),
		"enemy_type_ids": weighted_enemy_ids,
		"selected_rule_id": rule.rule_id
	}


func _build_normal_enemy_config_for_floor(context: Dictionary) -> Dictionary:
	var weighted_enemy_ids: Array[String] = _build_weighted_enemy_type_ids_for_normal_spawn(context)
	var spawn_count: int = _get_default_dungeon_enemy_spawn_count(context)

	if weighted_enemy_ids.is_empty():
		return {
			"enemy_spawn_count": 0,
			"enemy_type_ids": []
		}

	return {
		"enemy_spawn_count": spawn_count,
		"enemy_type_ids": weighted_enemy_ids
	}


func _get_default_dungeon_enemy_spawn_count(_context: Dictionary) -> int:
	if enemy_spawn_count > 0:
		return enemy_spawn_count

	var min_count: int = mini(normal_enemy_spawn_min, normal_enemy_spawn_max)
	var max_count: int = maxi(normal_enemy_spawn_min, normal_enemy_spawn_max)
	return randi_range(min_count, max_count)


func _build_weighted_enemy_type_ids_for_normal_spawn(context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var all_enemy_data: Array[EnemyData] = EnemyDatabase.get_all_enemy_data()

	for data in all_enemy_data:
		if data == null:
			continue
		if not _is_dungeon_enemy_allowed_for_normal_spawn(data, context):
			continue

		var entry_weight: int = _calculate_dungeon_normal_enemy_entry_weight(data, context)
		if entry_weight <= 0:
			continue

		var enemy_id: String = String(data.enemy_type_id)
		for i in range(entry_weight):
			result.append(enemy_id)

	return result


func _is_dungeon_enemy_allowed_for_normal_spawn(data: EnemyData, context: Dictionary) -> bool:
	var generator_theme: String = String(context.get("generator_theme", ""))
	var layout_generator_type: String = String(context.get("layout_generator_type", ""))
	var floor_difficulty: int = int(context.get("floor_difficulty", 1))

	var spawn_generator_tags: Array = _get_array_property(data, "spawn_generator_tags")
	if spawn_generator_tags.size() > 0:
		var has_match: bool = false
		if spawn_generator_tags.has(generator_theme):
			has_match = true
		if spawn_generator_tags.has(layout_generator_type):
			has_match = true
		if not has_match:
			return false

	var base_difficulty: int = int(_get_property_or_default(data, "base_difficulty", 1))
	var diff_gap: int = absi(base_difficulty - floor_difficulty)

	if diff_gap >= 5:
		return false

	return true


func _calculate_dungeon_normal_enemy_entry_weight(data: EnemyData, context: Dictionary) -> int:
	var floor_difficulty: int = int(context.get("floor_difficulty", 1))
	var base_difficulty: int = int(_get_property_or_default(data, "base_difficulty", 1))
	var rarity: int = int(_get_property_or_default(data, "rarity", 1))

	var diff_gap: int = absi(base_difficulty - floor_difficulty)
	var result: int = 0

	if diff_gap == 0:
		result = 85
	elif diff_gap <= 2:
		result = 12
	elif diff_gap <= 4:
		result = 3
	else:
		result = 0

	if result <= 0:
		return 0

	result *= max(1, 6 - rarity)
	return clampi(result, 1, 200)


func _get_best_matching_dungeon_spawn_rule(spawn_kind: String, context: Dictionary) -> DungeonSpawnRuleData:
	var generator_theme: String = String(context.get("generator_theme", ""))
	var layout_generator_type: String = String(context.get("layout_generator_type", ""))
	var floor_difficulty: int = int(context.get("floor_difficulty", 1))
	var floor_number: int = int(context.get("floor_number", 1))

	var all_results: Array[DungeonSpawnRuleData] = DungeonSpawnRuleDatabase.get_matching_rules(
		spawn_kind,
		generator_theme,
		layout_generator_type,
		floor_difficulty,
		floor_number
	)

	if all_results.is_empty():
		return null

	var best_rule: DungeonSpawnRuleData = all_results[0]

	for i in range(1, all_results.size()):
		var rule: DungeonSpawnRuleData = all_results[i]
		if _is_dungeon_rule_better(rule, best_rule):
			best_rule = rule

	return best_rule


func _is_dungeon_rule_better(a: DungeonSpawnRuleData, b: DungeonSpawnRuleData) -> bool:
	var a_width: int = _get_dungeon_rule_difficulty_range_width(a)
	var b_width: int = _get_dungeon_rule_difficulty_range_width(b)

	if a_width != b_width:
		return a_width < b_width

	if a.min_floor_difficulty != b.min_floor_difficulty:
		return a.min_floor_difficulty > b.min_floor_difficulty

	var a_floor_width: int = _get_dungeon_rule_floor_range_width(a)
	var b_floor_width: int = _get_dungeon_rule_floor_range_width(b)

	if a_floor_width != b_floor_width:
		return a_floor_width < b_floor_width

	return false


func _get_dungeon_rule_difficulty_range_width(rule: DungeonSpawnRuleData) -> int:
	var min_value: int = rule.min_floor_difficulty
	var max_value: int = rule.max_floor_difficulty

	if min_value < 0 and max_value < 0:
		return 999999

	if min_value < 0:
		min_value = 0

	if max_value < 0:
		max_value = 999999

	return max_value - min_value + 1


func _get_dungeon_rule_floor_range_width(rule: DungeonSpawnRuleData) -> int:
	var min_value: int = rule.min_floor_number
	var max_value: int = rule.max_floor_number

	if min_value < 0 and max_value < 0:
		return 999999

	if min_value < 0:
		min_value = 1

	if max_value < 0:
		max_value = 999999

	return max_value - min_value + 1


func _build_weighted_enemy_type_ids_from_rule(rule: DungeonSpawnRuleData, context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var all_enemy_data: Array[EnemyData] = EnemyDatabase.get_all_enemy_data()

	for data in all_enemy_data:
		if data == null:
			continue
		if not _is_dungeon_enemy_allowed_by_rule_and_context(data, rule, context):
			continue

		var entry_weight: int = _calculate_dungeon_enemy_entry_weight(data, rule, context)
		if entry_weight <= 0:
			continue

		var enemy_id: String = String(data.enemy_type_id)
		for i in range(entry_weight):
			result.append(enemy_id)

	return result


func _is_dungeon_enemy_allowed_by_rule_and_context(data: EnemyData, rule: DungeonSpawnRuleData, context: Dictionary) -> bool:
	var generator_theme: String = String(context.get("generator_theme", ""))
	var layout_generator_type: String = String(context.get("layout_generator_type", ""))

	var spawn_generator_tags: Array = _get_array_property(data, "spawn_generator_tags")
	if spawn_generator_tags.size() > 0:
		var has_match: bool = false
		if spawn_generator_tags.has(generator_theme):
			has_match = true
		if spawn_generator_tags.has(layout_generator_type):
			has_match = true
		if not has_match:
			return false

	var base_difficulty: int = int(_get_property_or_default(data, "base_difficulty", 0))

	if rule.min_enemy_difficulty >= 0 and base_difficulty < rule.min_enemy_difficulty:
		return false

	if rule.max_enemy_difficulty >= 0 and base_difficulty > rule.max_enemy_difficulty:
		return false

	return true


func _calculate_dungeon_enemy_entry_weight(data: EnemyData, rule: DungeonSpawnRuleData, context: Dictionary) -> int:
	var floor_difficulty: int = int(context.get("floor_difficulty", 1))
	var base_difficulty: int = int(_get_property_or_default(data, "base_difficulty", 1))
	var rarity: int = int(_get_property_or_default(data, "rarity", 1))

	var diff_gap: int = absi(floor_difficulty - base_difficulty)
	var result: int = 0

	if diff_gap == 0:
		result = 85
	elif diff_gap <= 2:
		result = 12
	elif diff_gap <= 4:
		result = 3
	else:
		result = 0

	if result <= 0:
		return 0

	result += max(0, rule.weight - 1) * 10

	result *= max(1, 6 - rarity)
	return clampi(result, 1, 200)


func can_trigger_stairs_on_touch() -> bool:
	return stairs_trigger_on_touch


func place_player_on_pending_stair() -> void:
	var stair_type: String = GlobalDungeon.pending_spawn_stair_type
	var target_cell: Vector2i = Vector2i(-1, -1)

	if stair_type == "NEXT":
		target_cell = find_event_cell_by_source_id(EVENT_NEXT_STAIRS_SOURCE_ID)
	else:
		target_cell = find_event_cell_by_source_id(EVENT_RETURN_STAIRS_SOURCE_ID)

	if target_cell.x == -1:
		push_warning("DungeonMain: spawn stair not found. stair_type=" + stair_type)
		return

	player.global_position = ground_layer.to_global(ground_layer.map_to_local(target_cell))
	player.target_position = player.global_position
	player.is_moving = false
	player.is_transitioning = false
	player.repeat_timer = 0.0
	player.velocity = Vector2.ZERO

	if player.has_method("reset_after_map_transition"):
		player.reset_after_map_transition()


func find_event_cell_by_source_id(source_id: int) -> Vector2i:
	var used_cells: Array = event_layer.get_used_cells()

	for cell in used_cells:
		if event_layer.get_cell_source_id(cell) == source_id:
			return cell

	return Vector2i(-1, -1)


func try_use_dungeon_stairs_from_player_position() -> bool:
	var current_cell: Vector2i = ground_layer.local_to_map(
		ground_layer.to_local(player.global_position)
	)

	var event_source_id: int = event_layer.get_cell_source_id(current_cell)

	if event_source_id == 3 or event_source_id == 6:
		player.is_transitioning = true
		player.is_moving = false
		player.repeat_timer = 0.0
		player.velocity = Vector2.ZERO
		player.target_position = player.global_position

	if event_source_id == 3:
		if GlobalDungeon.current_floor <= 1:
			save_all_units()
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = GlobalDungeon.return_field_cell
			request_map_change("res://scenes/field_map.tscn")
			return true
		else:
			save_all_units()
			GlobalDungeon.current_floor -= 1
			GlobalDungeon.pending_spawn_stair_type = "NEXT"
			request_map_change("res://scenes/dungeon_main.tscn")
			return true

	if event_source_id == 6:
		save_all_units()
		GlobalDungeon.current_floor += 1
		GlobalDungeon.pending_spawn_stair_type = "RETURN"
		request_map_change("res://scenes/dungeon_main.tscn")
		return true

	return false


func request_map_change(next_scene: String) -> bool:
	var node: Node = self

	while node != null:
		if node.has_method("load_map_by_path"):
			node.load_map_by_path(next_scene)
			return true
		node = node.get_parent()

	push_error("DungeonMain: load_map_by_path を持つ親が見つかりません")
	return false


func save_all_units() -> void:
	if not has_node("Units"):
		return

	for unit in $Units.get_children():
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


func create_map_generator(generator_type: String, map_width: int, map_height: int) -> BaseDungeonGenerator:
	generator_type = generator_type.strip_edges().replace("\"", "").to_upper()

	match generator_type:
		"ROOM":
			return RoomDungeonGenerator.new(map_width, map_height)
		"CAVE":
			return CaveDungeonGenerator.new(map_width, map_height)
		"MAZE":
			return MazeDungeonGenerator.new(map_width, map_height)
		"RUINS":
			return RuinsDungeonGenerator.new(map_width, map_height)
		"CROSS":
			return CrossDungeonGenerator.new(map_width, map_height)
		"ARENA":
			return ArenaDungeonGenerator.new(map_width, map_height)
		"LINEAR":
			return LinearDungeonGenerator.new(map_width, map_height)
		"RINGS":
			return RingsDungeonGenerator.new(map_width, map_height)

	return RoomDungeonGenerator.new(map_width, map_height)


func notify_hud_log(text: String) -> void:
	var node: Node = self

	while node != null:
		if node.has_method("add_hud_log"):
			node.add_hud_log(text)
			return
		node = node.get_parent()


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


func filter_enemy_data_by_ids(type_ids: Array) -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	for type_id in type_ids:
		var enemy_id: String = String(type_id)
		var data: EnemyData = EnemyDatabase.get_enemy_data_by_id(enemy_id)
		if data == null:
			continue
		result.append(data)

	return result


func filter_npc_data_by_ids(type_ids: Array) -> Array[NpcData]:
	var result: Array[NpcData] = []

	for data in npc_data_list:
		if data == null:
			continue
		if type_ids.has(data.npc_type_id):
			result.append(data)

	return result
