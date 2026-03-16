extends Node2D

@onready var tile_map = get_tree().current_scene.get_node("TileMap")
@onready var player = $Units/Unit

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 5
@export var enemy_data_list: Array[EnemyData]

@export var map_id: String = ""


const MAP_WIDTH := 50
const MAP_HEIGHT := 50

# floor.png と wall.png が別ソースである前提
const FLOOR_SOURCE_ID := 2
const WALL_SOURCE_ID := 0

const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const WALL_ATLAS_COORDS := Vector2i(0, 0)

func _ready() -> void:
	generate_map()
	spawn_random_enemies()
	#↓削除予定　Unit.gbのStart Tileなどが直ったら消す
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

func save_all_units() -> void:
	print("save_all_units called")

	if not has_node("Units"):
		print("Units node not found")
		return

	for unit in $Units.get_children():
		print("child = ", unit.name)

		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()
			

func get_random_enemy_data() -> EnemyData:
	if enemy_data_list.is_empty():
		return null

	return enemy_data_list[randi() % enemy_data_list.size()]
	
func spawn_enemy_random(used_tiles: Array[Vector2i], index: int) -> void:
	if enemy_unit_scene == null:
		return

	var enemy_data = get_random_enemy_data()
	if enemy_data == null:
		return

	var candidates = get_walkable_tiles()
	candidates.shuffle()

	for tile in candidates:
		if used_tiles.has(tile):
			continue
		
		var enemy = enemy_unit_scene.instantiate()

		enemy.start_tile = tile
		enemy.unit_id = "enemy_%d" % index
		enemy.map_id = map_id

		$Units.add_child(enemy)
		enemy.apply_enemy_data(enemy_data)
		

		used_tiles.append(tile)
		return
		
func spawn_random_enemies() -> void:
	var used_tiles: Array[Vector2i] = []

	if $Units.has_node("Player"):
		used_tiles.append($Units/Player.get_current_tile_coords())

	for i in range(enemy_spawn_count):
		spawn_enemy_random(used_tiles, i)
		
func get_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var tile = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				continue

			result.append(tile)

	return result
