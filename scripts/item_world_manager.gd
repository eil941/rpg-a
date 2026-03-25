extends RefCounted
class_name ItemWorldManager

var map_root: Node
var ground_layer: TileMapLayer
var wall_layer: TileMapLayer
var units_node: Node
var item_pickups_node: Node
var chests_node: Node
var map_id: String

var item_pickup_scene: PackedScene
var chest_scene: PackedScene


func _init(
	p_map_root: Node,
	p_ground_layer: TileMapLayer,
	p_wall_layer: TileMapLayer,
	p_units_node: Node,
	p_item_pickups_node: Node,
	p_chests_node: Node,
	p_map_id: String,
	p_item_pickup_scene: PackedScene,
	p_chest_scene: PackedScene
) -> void:
	map_root = p_map_root
	ground_layer = p_ground_layer
	wall_layer = p_wall_layer
	units_node = p_units_node
	item_pickups_node = p_item_pickups_node
	chests_node = p_chests_node
	map_id = p_map_id
	item_pickup_scene = p_item_pickup_scene
	chest_scene = p_chest_scene


func setup_test_item_and_chest_with_save() -> void:
	if not WorldState.map_item_pickups.has(map_id):
		WorldState.map_item_pickups[map_id] = [
			{
				"item_id": "potion",
				"amount": 1,
				"x": 12,
				"y": 12
			}
		]

	if not WorldState.map_chests.has(map_id):
		WorldState.map_chests[map_id] = [
			{
				"chest_id": "start_chest_01",
				"x": 13,
				"y": 13,
				"is_opened": false,
				"inventory": [
					{"item_id": "wood", "amount": 5},
					{"item_id": "apple", "amount": 2}
				]
			}
		]

	load_item_pickups_from_world_state()
	load_chests_from_world_state()


func clear_spawned_objects() -> void:
	if item_pickups_node != null:
		for child in item_pickups_node.get_children():
			child.queue_free()

	if chests_node != null:
		for child in chests_node.get_children():
			child.queue_free()


func load_item_pickups_from_world_state() -> void:
	if item_pickups_node == null:
		return

	for child in item_pickups_node.get_children():
		child.queue_free()

	if not WorldState.map_item_pickups.has(map_id):
		return

	for entry in WorldState.map_item_pickups[map_id]:
		spawn_item_from_save(entry)


func load_chests_from_world_state() -> void:
	if chests_node == null:
		return

	for child in chests_node.get_children():
			child.queue_free()

	if not WorldState.map_chests.has(map_id):
		return

	for entry in WorldState.map_chests[map_id]:
		spawn_chest_from_save(entry)


func spawn_item_from_save(data: Dictionary) -> void:
	if item_pickup_scene == null:
		push_error("ItemWorldManager: item_pickup_scene が未設定です")
		return

	var item_id := String(data.get("item_id", ""))
	var amount := int(data.get("amount", 1))
	var tile := Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))

	if item_id == "":
		return

	var pickup = item_pickup_scene.instantiate()
	item_pickups_node.add_child(pickup)
	pickup.setup(item_id, amount, map_id, tile)


func spawn_chest_from_save(data: Dictionary) -> void:
	if chest_scene == null:
		push_error("ItemWorldManager: chest_scene が未設定です")
		return

	var chest = chest_scene.instantiate()
	chests_node.add_child(chest)

	if chest.has_method("load_from_save_data"):
		chest.load_from_save_data(data)
	else:
		chest.tile_coords = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
		chest.is_opened = bool(data.get("is_opened", false))
		if data.has("inventory") and chest.has_node("Inventory"):
			chest.get_node("Inventory").load_inventory_data(data["inventory"])
		if chest.has_method("update_visual"):
			chest.update_visual()
		if chest.has_method("snap_to_tile"):
			chest.call_deferred("snap_to_tile")


func save_current_state() -> void:
	save_item_pickups_to_world_state()
	save_chests_to_world_state()


func save_item_pickups_to_world_state() -> void:
	var result: Array = []

	if item_pickups_node != null:
		for pickup in item_pickups_node.get_children():
			if pickup == null:
				continue
			if pickup.has_method("get_save_data"):
				result.append(pickup.get_save_data())

	WorldState.map_item_pickups[map_id] = result


func save_chests_to_world_state() -> void:
	var result: Array = []

	if chests_node != null:
		for chest in chests_node.get_children():
			if chest == null:
				continue
			if chest.has_method("get_save_data"):
				result.append(chest.get_save_data())

	WorldState.map_chests[map_id] = result
