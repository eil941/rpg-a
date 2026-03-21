extends Node2D

@onready var ground_layer: TileMapLayer = get_tree().current_scene.get_node("GroundLayer")
@onready var wall_layer: TileMapLayer = get_tree().current_scene.get_node("WallLayer")
@onready var event_layer: TileMapLayer = get_tree().current_scene.get_node("EventLayer")
@onready var player = $Units/Unit

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 5
@export var enemy_data_list: Array[EnemyData]

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 3
@export var npc_data_list: Array[NpcData]

@export var map_id: String = ""

const MAP_WIDTH := 30
const MAP_HEIGHT := 30

const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

var spawn_manager: UnitSpawnManager
var map_generator: BaseMapGenerator

func _ready() -> void:
	if GlobalDetailMap.current_detail_map_key != "":
		map_id = GlobalDetailMap.current_detail_map_key

	player.map_id = map_id

	var generator_type := GlobalDetailMap.current_generator_type
	print(generator_type,"ASDASDASDASDASDASDAS")
	
	if generator_type == "" and WorldState.field_detail_map_data.has(map_id):
		generator_type = WorldState.field_detail_map_data[map_id].get("generator_type", "plain")

	if generator_type == "":
		generator_type = "plain"
		
	
	print(generator_type,"------------------------------------------------------------------")
	map_generator = create_map_generator(generator_type)
	
	
	
	if WorldState.map_tile_data.has(map_id):
		load_map_tiles()
	else:
		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",generator_type)
		map_generator.generate_map(ground_layer, wall_layer, event_layer)
		save_map_tiles()

	var walkable_tiles: Array[Vector2i] = map_generator.get_walkable_tiles()

	spawn_manager = UnitSpawnManager.new(
		$Units,
		ground_layer,
		map_id,
		walkable_tiles
	)

	if WorldState.map_enemy_spawns.has(map_id):
		spawn_manager.spawn_saved_enemies(enemy_unit_scene, enemy_data_list)
	else:
		spawn_manager.spawn_random_enemies(enemy_unit_scene, enemy_data_list, enemy_spawn_count)

	if WorldState.map_npc_spawns.has(map_id):
		spawn_manager.spawn_saved_npcs(npc_unit_scene, npc_data_list)
	else:
		spawn_manager.spawn_random_npcs(npc_unit_scene, npc_data_list, npc_spawn_count)

func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)

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

func create_map_generator(generator_type: String):
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
			
			
	print("####################################################################")
	#return PlainMapGenerator.new(
	#	MAP_WIDTH,
	#	MAP_HEIGHT,
	#	FLOOR_SOURCE_ID,
	#	WALL_SOURCE_ID,
	#	FLOOR_ATLAS_COORDS,
	#	WALL_ATLAS_COORDS
	#)
