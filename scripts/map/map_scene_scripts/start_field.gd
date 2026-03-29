extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var event_layer: TileMapLayer = $EventLayer
@onready var units_node: Node = $Units
@onready var item_pickups_node: Node = $ItemPickups
@onready var chests_node: Node = $Chests

@export var enemy_unit_scene: PackedScene
@export var enemy_spawn_count: int = 5
@export var enemy_data_list: Array[EnemyData]

@export var npc_unit_scene: PackedScene
@export var npc_spawn_count: int = 3
@export var npc_data_list: Array[NpcData]

@export var item_pickup_scene: PackedScene
@export var chest_scene: PackedScene

@export var map_id: String = ""

var spawn_manager: UnitSpawnManager
var item_world_manager: ItemWorldManager
var player: Node = null


func _ready() -> void:
	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("start_field: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	find_player()

	if player != null:
		player.map_id = map_id
	else:
		push_warning("start_field: player が見つかりません")

	var walkable_tiles: Array[Vector2i] = collect_walkable_tiles()

	spawn_manager = UnitSpawnManager.new(
		units_node,
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

	item_world_manager = ItemWorldManager.new(
		self,
		ground_layer,
		wall_layer,
		units_node,
		item_pickups_node,
		chests_node,
		map_id,
		item_pickup_scene,
		chest_scene
	)
	
	item_world_manager.setup_detail_map_random_spawn_with_save()
	#item_world_manager.setup_test_item_and_chest_with_save()
	#item_world_manager.spawn_fixed_test_item_and_chest()


func find_player() -> void:
	player = null

	for child in units_node.get_children():
		if child == null:
			continue
		if child.get("is_player_unit"):
			player = child
			return

	for child in units_node.get_children():
		if child == null:
			continue
		if child.name == "Unit":
			player = child
			return


func collect_walkable_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for cell in ground_layer.get_used_cells():
		if wall_layer.get_cell_source_id(cell) != -1:
			continue
		result.append(cell)

	return result


func save_all_units() -> void:
	if units_node != null:
		for unit in units_node.get_children():
			if unit != null and unit.has_method("save_persistent_stats"):
				unit.save_persistent_stats()
				
				
	if item_world_manager != null:
		item_world_manager.save_current_state()


func save_layer_data(layer: TileMapLayer) -> Array:
	var result: Array = []

	for cell in layer.get_used_cells():
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
