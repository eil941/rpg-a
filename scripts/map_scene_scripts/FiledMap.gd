extends Node2D

@onready var player = $Units/Unit

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var event_layer: TileMapLayer = $EventLayer
@onready var units_node: Node = $Units

@export var MAP_WIDTH = 200
@export var MAP_HEIGHT = 200
@export var map_id: String = ""

const FLOOR_SOURCE_ID = 1
const WALL_SOURCE_ID = 0
const HIGHROCK_SOURCE_ID = 5

const FLOOR_ATLAS_COORDS = Vector2i(0, 0)
const WALL_ATLAS_COORDS = Vector2i(0, 0)
const HIGHROCK_ATLAS_COORDS = Vector2i(0, 0)

@export var dungeon_entrance_count = 300

var map_generator: PlainMapGenerator
var dungeon_entrance_generator: FieldDungeonEntranceGenerator

func _ready() -> void:
	print("FIELDMAP READY START")

	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("FiledMap: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	player.map_id = map_id

	if not WorldState.field_dungeon_entrances.has(map_id):
		WorldState.field_dungeon_entrances[map_id] = []

	if WorldState.map_tile_data.has(map_id):
		load_map_tiles()
	else:
		map_generator = PlainMapGenerator.new(
			MAP_WIDTH,
			MAP_HEIGHT,
			FLOOR_SOURCE_ID,
			WALL_SOURCE_ID,
			FLOOR_ATLAS_COORDS,
			WALL_ATLAS_COORDS
		)
		map_generator.generate_map(ground_layer, wall_layer, event_layer)

		dungeon_entrance_generator = FieldDungeonEntranceGenerator.new(MAP_WIDTH, MAP_HEIGHT)
		var entrances = dungeon_entrance_generator.generate_map(
			map_id,
			ground_layer,
			wall_layer,
			event_layer,
			dungeon_entrance_count
		)

		WorldState.field_dungeon_entrances[map_id] = entrances
		save_map_tiles()

	print("FIELDMAP READY END")

func generate_map() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				wall_layer.set_cell(cell, HIGHROCK_SOURCE_ID, HIGHROCK_ATLAS_COORDS, 0)

func get_dungeon_id_at_cell(cell: Vector2i) -> String:
	if not WorldState.field_dungeon_entrances.has(map_id):
		return ""

	for entrance in WorldState.field_dungeon_entrances[map_id]:
		if entrance["x"] == cell.x and entrance["y"] == cell.y:
			return entrance["dungeon_id"]

	return ""

func try_enter_dungeon_from_player_position() -> bool:
	var current_cell = ground_layer.local_to_map(
		ground_layer.to_local(player.global_position)
	)

	var dungeon_id = get_dungeon_id_at_cell(current_cell)
	if dungeon_id == "":
		return false

	GlobalDungeon.current_dungeon_id = dungeon_id
	GlobalDungeon.current_floor = 1
	GlobalDungeon.return_field_map_id = map_id
	GlobalDungeon.return_field_cell = current_cell
	GlobalDungeon.pending_spawn_stair_type = "RETURN"

	get_tree().change_scene_to_file("res://scenes/dungeon_main.tscn")
	return true



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
