extends Node2D

@onready var tile_map: TileMapLayer = get_tree().current_scene.get_node("TileMap")
@onready var player = $Units/Unit

const MAP_WIDTH := 100
const MAP_HEIGHT := 100

const FLOOR_SOURCE_ID := 1
const WALL_SOURCE_ID := 0
const HIGHROCK_SOURCE_ID := 5

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)
const HIGHROCK_ATLAS_COORDS := Vector2i(0, 0)

func _ready() -> void:
	generate_map()

	if GlobalPlayerSpawn.has_next_tile:
		player.global_position = $TileMap.to_global($TileMap.map_to_local(GlobalPlayerSpawn.next_tile))
		GlobalPlayerSpawn.has_next_tile = false
	else:
		player.global_position = $TileMap.to_global($TileMap.map_to_local(Vector2i(2, 2)))

func generate_map() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell = Vector2i(x, y)
			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				tile_map.set_cell(cell, HIGHROCK_SOURCE_ID, HIGHROCK_ATLAS_COORDS, 0)
			else:
				# tile_map.set_cell(cell, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)
				tile_map.set_cell(cell, randi_range(2, 8), FLOOR_ATLAS_COORDS, 0)

func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)

		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()
