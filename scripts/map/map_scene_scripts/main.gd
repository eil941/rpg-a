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
@export var enemy_data_list: Array[EnemyData]

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 10
@export var npc_data_list: Array[NpcData]

@export var item_pickup_scene: PackedScene
@export var chest_scene: PackedScene
@export var chest_data_list: Array[ChestData]

@export var map_id: String = ""

const MAP_WIDTH := 30
const MAP_HEIGHT := 30

const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

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

	# =========================
	# マップ本体
	# =========================
	if use_generated_map:
		map_generator = create_map_generator(generator_type)

		if WorldState.map_tile_data.has(map_id):
			load_map_tiles()
		else:
			map_generator.generate_map(ground_layer, wall_layer, event_layer)
			save_map_tiles()
	else:
		map_generator = null

		# Main.tscn に置いてある既存マップをそのまま使う
		# 初回だけ現在の状態を保存
		if not WorldState.map_tile_data.has(map_id):
			save_map_tiles()

	# =========================
	# enemy / npc 生成設定
	# =========================
	var current_enemy_spawn_count: int = enemy_spawn_count
	var current_npc_spawn_count: int = npc_spawn_count

	var current_enemy_data_list: Array[EnemyData] = enemy_data_list
	var current_npc_data_list: Array[NpcData] = npc_data_list

	# 生成マップモードの時だけ detail_config で上書きする
	# 既存マップモードでは inspector の値をそのまま使う
	if use_generated_map and WorldState.field_detail_map_data.has(map_id):
		var detail_config = WorldState.field_detail_map_data[map_id]

		current_enemy_spawn_count = int(detail_config.get("enemy_spawn_count", enemy_spawn_count))
		current_npc_spawn_count = int(detail_config.get("npc_spawn_count", npc_spawn_count))

		var enemy_type_ids = detail_config.get("enemy_type_ids", [])
		var npc_type_ids = detail_config.get("npc_type_ids", [])

		if enemy_type_ids.size() > 0:
			current_enemy_data_list = filter_enemy_data_by_ids(enemy_type_ids)

		if npc_type_ids.size() > 0:
			current_npc_data_list = filter_npc_data_by_ids(npc_type_ids)

	print("inspector enemy_spawn_count = ", enemy_spawn_count)
	print("inspector npc_spawn_count = ", npc_spawn_count)
	print("current_enemy_spawn_count = ", current_enemy_spawn_count)
	print("current_npc_spawn_count = ", current_npc_spawn_count)
	print("current_enemy_data_list size = ", current_enemy_data_list.size())
	print("current_npc_data_list size = ", current_npc_data_list.size())

	# =========================
	# 歩行可能タイル
	# =========================
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

	# =========================
	# enemy / npc 生成本体
	# 保存済みがあれば読む / なければ初回生成
	# =========================
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
