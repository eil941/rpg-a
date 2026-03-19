extends Node2D

@onready var ground_layer: TileMapLayer = get_tree().current_scene.get_node("GroundLayer")
@onready var wall_layer: TileMapLayer = get_tree().current_scene.get_node("WallLayer")
@onready var event_layer: TileMapLayer = get_tree().current_scene.get_node("EventLayer")
@onready var player = $Units/Unit

@export var MAP_WIDTH := 200
@export var MAP_HEIGHT := 200
#const MAP_WIDTH := 200
#const MAP_HEIGHT := 200
@export var map_id: String = ""

const FLOOR_SOURCE_ID := 1
const WALL_SOURCE_ID := 0
const HIGHROCK_SOURCE_ID := 5

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)
const HIGHROCK_ATLAS_COORDS := Vector2i(0, 0)

var map_generator: PlainMapGenerator




func _ready() -> void:
	player.map_id = map_id
	
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
		save_map_tiles()

	

func generate_map() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				wall_layer.set_cell(cell, HIGHROCK_SOURCE_ID, HIGHROCK_ATLAS_COORDS, 0)


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
