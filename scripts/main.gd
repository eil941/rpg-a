extends Node2D

@onready var tile_map = get_tree().current_scene.get_node("TileMap")
@onready var player = $Units/Unit


const MAP_WIDTH := 100
const MAP_HEIGHT := 100

# floor.png と wall.png が別ソースである前提
const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

func _ready() -> void:
	generate_map()
	player.position = tile_map.map_to_local(Vector2i(2, 2))

func generate_map() -> void:
	for y in range(0,MAP_HEIGHT,1):
		for x in range(0,MAP_WIDTH,1):
			var cell = Vector2i(x, y)

			# 外周は壁
			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				tile_map.set_cell(0, cell, WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)
			else:
				tile_map.set_cell(0, cell, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)

	# 内側にテスト用の壁
	for x in range(10, 20):
		tile_map.set_cell(0, Vector2i(x, 10), WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)

	for y in range(20, 30):
		tile_map.set_cell(0, Vector2i(25, y), WALL_SOURCE_ID, WALL_ATLAS_COORDS, 0)
