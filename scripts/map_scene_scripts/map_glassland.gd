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


@export var MAP_WIDTH := 200
@export var MAP_HEIGHT := 200
#const MAP_WIDTH := 200
#const MAP_HEIGHT := 200

const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

var spawn_manager: UnitSpawnManager


#var map_generator: MapGenerator
var map_generator: PlainMapGenerator


func _ready() -> void:
	#map_generator = MapGenerator.new(
	#map_generator = PlainMapGenerator.new(
	#	MAP_WIDTH,
	#	MAP_HEIGHT,
	#	FLOOR_SOURCE_ID,
	#	WALL_SOURCE_ID,
	#	FLOOR_ATLAS_COORDS,
	#	WALL_ATLAS_COORDS
	#)
	
	var tile_defs = {
		"sea": {
			"source_id": 0,
			"atlas_coords": Vector2i(0, 0)
		},
		"sand": {
			"source_id": 0,
			"atlas_coords": Vector2i(1, 0)
		},
		"grass": {
			"source_id": 0,
			"atlas_coords": Vector2i(2, 0)
		},
		"forest": {
			"source_id": 0,
			"atlas_coords": Vector2i(3, 0)
		},
		"rock": {
			"source_id": 0,
			"atlas_coords": Vector2i(4, 0)
		},
		"wall": {
			"source_id": 1,
			"atlas_coords": Vector2i(0, 0)
		}
	}

	map_generator = PlainMapGenerator.new(
		MAP_WIDTH,
		MAP_HEIGHT,
		FLOOR_SOURCE_ID,
		WALL_SOURCE_ID,
		FLOOR_ATLAS_COORDS,
		WALL_ATLAS_COORDS
	)

	#map_generator.generate_map(ground_layer, wall_layer, event_layer)

	map_generator.generate_map(ground_layer,wall_layer,event_layer)

	spawn_manager = UnitSpawnManager.new(
		$Units,
		ground_layer,
		map_id,
		map_generator.get_walkable_tiles()
	)

	if WorldState.map_enemy_spawns.has(map_id):
		spawn_manager.spawn_saved_enemies(enemy_unit_scene, enemy_data_list)
	else:
		spawn_manager.spawn_random_enemies(enemy_unit_scene, enemy_data_list, enemy_spawn_count)

	if WorldState.map_npc_spawns.has(map_id):
		spawn_manager.spawn_saved_npcs(npc_unit_scene, npc_data_list)
	else:
		spawn_manager.spawn_random_npcs(npc_unit_scene, npc_data_list, npc_spawn_count)

	# ↓ 削除予定
	player.position = ground_layer.map_to_local(Vector2i(2, 2))

func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)

		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()
