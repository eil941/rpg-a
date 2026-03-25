extends Node2D

@onready var player = $Units/Unit

@onready var ground_layer: TileMapLayer = get_node_or_null("GroundLayer")
@onready var wall_layer: TileMapLayer = get_node_or_null("WallLayer")
@onready var event_layer: TileMapLayer = get_node_or_null("EventLayer")
@onready var units_node: Node = get_node_or_null("Units")

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 5
@export var enemy_data_list: Array[EnemyData]

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 0
@export var npc_data_list: Array[NpcData]

@export var map_id: String = ""

@export var MIN_MAP_WIDTH: int = 30
@export var MAX_MAP_WIDTH: int = 60
@export var MIN_MAP_HEIGHT: int = 30
@export var MAX_MAP_HEIGHT: int = 60

@export var stairs_trigger_on_touch: bool = false

const EVENT_RETURN_STAIRS_SOURCE_ID = 3
const EVENT_NEXT_STAIRS_SOURCE_ID = 6

var spawn_manager: UnitSpawnManager
var map_generator: BaseDungeonGenerator


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

	var floor_data = WorldState.dungeon_floor_data[map_id]
	var generator_type = floor_data.get("generator_type", "ROOM")
	var is_bottom_floor = floor_data.get("is_bottom", false)
	var map_width = int(floor_data.get("map_width", MIN_MAP_WIDTH))
	var map_height = int(floor_data.get("map_height", MIN_MAP_HEIGHT))

	var dungeon_info = WorldState.dungeon_data[GlobalDungeon.current_dungeon_id]
	var difficulty = int(dungeon_info.get("difficulty", 50))
	var effective_difficulty = clampi(difficulty + (GlobalDungeon.current_floor - 1), 1, 100)


	notify_hud_log(
		"第" + str(GlobalDungeon.current_floor) +
		"階: " + String(generator_type) +
		" / 難易度 " + str(effective_difficulty) +
		" (" + str(map_width) + "x" + str(map_height) + ") を生成"
	)

	map_generator = create_map_generator(generator_type, map_width, map_height)

	if WorldState.map_tile_data.has(map_id):
		load_map_tiles()
	else:
		map_generator.generate_map(ground_layer, wall_layer, event_layer, is_bottom_floor)
		save_map_tiles()

	var current_enemy_spawn_count = enemy_spawn_count
	var current_npc_spawn_count = npc_spawn_count

	var current_enemy_data_list: Array[EnemyData] = enemy_data_list
	var current_npc_data_list: Array[NpcData] = npc_data_list

	current_enemy_spawn_count = int(floor_data.get("enemy_spawn_count", enemy_spawn_count))
	current_npc_spawn_count = int(floor_data.get("npc_spawn_count", npc_spawn_count))

	var enemy_type_ids = floor_data.get("enemy_type_ids", [])
	var npc_type_ids = floor_data.get("npc_type_ids", [])

	if enemy_type_ids.size() > 0:
		current_enemy_data_list = filter_enemy_data_by_ids(enemy_type_ids)

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
	else:
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

	place_player_on_pending_stair()


func _ensure_floor_data_exists(floor_map_id: String) -> void:
	if WorldState.dungeon_floor_data.has(floor_map_id):
		return

	if not WorldState.dungeon_data.has(GlobalDungeon.current_dungeon_id):
		push_error("Dungeon data not found: " + GlobalDungeon.current_dungeon_id)
		return

	var dungeon_info = WorldState.dungeon_data[GlobalDungeon.current_dungeon_id]
	var max_floor = int(dungeon_info.get("max_floor", 3))
	var difficulty = int(dungeon_info.get("difficulty", 50))

	var generator_type = choose_random_dungeon_generator_type()
	var is_bottom = GlobalDungeon.current_floor >= max_floor

	var map_width = randi_range(MIN_MAP_WIDTH, MAX_MAP_WIDTH)
	var map_height = randi_range(MIN_MAP_HEIGHT, MAX_MAP_HEIGHT)

	var enemy_config = choose_enemy_config_for_floor(GlobalDungeon.current_floor, difficulty)

	WorldState.dungeon_floor_data[floor_map_id] = {
		"dungeon_id": GlobalDungeon.current_dungeon_id,
		"floor": GlobalDungeon.current_floor,
		"generator_type": generator_type,
		"is_bottom": is_bottom,
		"map_width": map_width,
		"map_height": map_height,
		"enemy_spawn_count": enemy_config["enemy_spawn_count"],
		"enemy_type_ids": enemy_config["enemy_type_ids"],
		"npc_spawn_count": 0,
		"npc_type_ids": []
	}


func choose_random_dungeon_generator_type() -> String:
	var types = ["ROOM", "CAVE", "RUINS", "CROSS", "ARENA", "LINEAR", "RINGS"]
	return types[randi_range(0, types.size() - 1)]


func can_trigger_stairs_on_touch() -> bool:
	return stairs_trigger_on_touch


func place_player_on_pending_stair() -> void:
	var stair_type = GlobalDungeon.pending_spawn_stair_type
	var target_cell = Vector2i(-1, -1)

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

	print("DUNGEON PLAYER SPAWN stair_type=", stair_type, " target_cell=", target_cell)


func find_event_cell_by_source_id(source_id: int) -> Vector2i:
	var used_cells = event_layer.get_used_cells()

	for cell in used_cells:
		if event_layer.get_cell_source_id(cell) == source_id:
			return cell

	return Vector2i(-1, -1)


func try_use_dungeon_stairs_from_player_position() -> bool:
	var current_cell = ground_layer.local_to_map(
		ground_layer.to_local(player.global_position)
	)

	var event_source_id = event_layer.get_cell_source_id(current_cell)
	print("DUNGEON STAIRS CHECK current_cell=", current_cell, " source_id=", event_source_id)

	if event_source_id == 3 or event_source_id == 6:
		player.is_transitioning = true
		player.is_moving = false
		player.repeat_timer = 0.0
		player.velocity = Vector2.ZERO
		player.target_position = player.global_position

	if event_source_id == 3:
		print("RETURN STAIRS USED")

		if GlobalDungeon.current_floor <= 1:
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = GlobalDungeon.return_field_cell
			request_map_change("res://scenes/field_map.tscn")
			return true
		else:
			GlobalDungeon.current_floor -= 1
			GlobalDungeon.pending_spawn_stair_type = "NEXT"
			request_map_change("res://scenes/dungeon_main.tscn")
			return true

	if event_source_id == 6:
		print("NEXT STAIRS USED")

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


func save_layer_data(layer: TileMapLayer) -> Array:
	var result: Array = []
	var used_cells = layer.get_used_cells()

	for cell in used_cells:
		var source_id = layer.get_cell_source_id(cell)
		if source_id == -1:
			continue

		var atlas_coords = layer.get_cell_atlas_coords(cell)
		var alternative = layer.get_cell_alternative_tile(cell)

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
		var cell = Vector2i(cell_data["x"], cell_data["y"])
		var source_id = cell_data["source_id"]
		var atlas_coords = Vector2i(cell_data["atlas_x"], cell_data["atlas_y"])
		var alternative = cell_data["alternative"]

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

	var data = WorldState.map_tile_data[map_id]

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


func choose_enemy_config_for_floor(floor: int, difficulty: int) -> Dictionary:
	var depth_bonus = max(0, floor - 1)
	var effective_difficulty = clampi(difficulty + (floor - 1), 1, 100)
	
	if effective_difficulty <= 20:
		return {
			"enemy_spawn_count": 10 + depth_bonus,
			"enemy_type_ids": ["slime"]
		}

	if effective_difficulty <= 40:
		return {
			"enemy_spawn_count": 15 + depth_bonus,
			"enemy_type_ids": ["slime", "bat"]
		}

	if effective_difficulty <= 60:
		return {
			"enemy_spawn_count": 20 + depth_bonus,
			"enemy_type_ids": ["slime", "bat", "orc"]
		}

	if effective_difficulty <= 80:
		return {
			"enemy_spawn_count": 25 + depth_bonus,
			"enemy_type_ids": ["bat", "orc"]
		}

	return {
		"enemy_spawn_count": 30 + depth_bonus,
		"enemy_type_ids": ["orc"]
	}


func filter_enemy_data_by_ids(type_ids: Array) -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	for data in enemy_data_list:
		if data == null:
			continue
		if type_ids.has(data.enemy_type_id):
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
