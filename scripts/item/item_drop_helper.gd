extends RefCounted
class_name ItemDropHelper


const INVALID_DROP_TILE: Vector2i = Vector2i(999999, 999999)


static func drop_entry_near_unit(entry: Dictionary, unit: Node, max_radius: int = 5) -> bool:
	if unit == null:
		return false

	var normalized_entry: Dictionary = _normalize_entry(entry)
	if _is_empty_entry(normalized_entry):
		return false

	var context: Dictionary = _build_drop_context(unit)
	if context.is_empty():
		return false

	var item_pickups_node: Node = context.get("item_pickups_node", null)
	var item_pickup_scene: PackedScene = context.get("item_pickup_scene", null)
	var map_id: String = String(context.get("map_id", ""))
	var origin_tile: Vector2i = context.get("origin_tile", Vector2i.ZERO)

	if item_pickups_node == null:
		return false

	# 同じスタック可能アイテムが足元にあるなら、そこへまとめる。
	if _can_stack_entry(normalized_entry):
		var stack_target = _find_stackable_pickup_on_tile(item_pickups_node, normalized_entry, origin_tile)
		if stack_target != null:
			_merge_entry_into_pickup(stack_target, normalized_entry, map_id)
			_save_item_pickups_to_world_state(item_pickups_node, map_id)
			return true

	var target_tile: Vector2i = origin_tile

	# 足元に別種類のアイテムがある場合は、周辺の空きマスにずらして落とす。
	if _has_item_pickup_on_tile(item_pickups_node, origin_tile):
		target_tile = _find_nearest_empty_drop_tile(context, origin_tile, max_radius)
	else:
		if not _is_drop_tile_valid(context, origin_tile, true):
			target_tile = _find_nearest_empty_drop_tile(context, origin_tile, max_radius)

	if target_tile == INVALID_DROP_TILE:
		return false

	if item_pickup_scene == null:
		push_warning("ItemDropHelper: item_pickup_scene が見つかりません")
		return false

	_spawn_pickup_from_entry(item_pickups_node, item_pickup_scene, normalized_entry, map_id, target_tile)
	_save_item_pickups_to_world_state(item_pickups_node, map_id)
	return true


static func _build_drop_context(unit: Node) -> Dictionary:
	var map_root: Node = _find_map_root(unit)
	if map_root == null:
		return {}

	var ground_layer: TileMapLayer = map_root.get_node_or_null("GroundLayer") as TileMapLayer
	var wall_layer: TileMapLayer = map_root.get_node_or_null("WallLayer") as TileMapLayer
	var units_node: Node = map_root.get_node_or_null("Units")
	var item_pickups_node: Node = map_root.get_node_or_null("ItemPickups")

	if ground_layer == null or item_pickups_node == null:
		return {}

	var item_pickup_scene: PackedScene = _get_object_property(map_root, "item_pickup_scene", null) as PackedScene
	var map_id: String = String(_get_object_property(map_root, "map_id", ""))

	if map_id == "":
		map_id = String(_get_object_property(unit, "map_id", ""))

	var origin_tile: Vector2i = _get_unit_tile_coords(unit)

	return {
		"map_root": map_root,
		"ground_layer": ground_layer,
		"wall_layer": wall_layer,
		"units_node": units_node,
		"item_pickups_node": item_pickups_node,
		"item_pickup_scene": item_pickup_scene,
		"map_id": map_id,
		"origin_unit": unit,
		"origin_tile": origin_tile
	}


static func _find_map_root(unit: Node) -> Node:
	var node: Node = unit

	while node != null:
		if node.has_node("GroundLayer") and node.has_node("ItemPickups"):
			return node

		node = node.get_parent()

	return null


static func _get_unit_tile_coords(unit: Node) -> Vector2i:
	if unit.has_method("get_current_tile_coords"):
		return unit.get_current_tile_coords()

	if unit.has_method("get_occupied_tile_coords"):
		return unit.get_occupied_tile_coords()

	var tile_size: int = 32
	var tile_size_value: Variant = _get_object_property(unit, "tile_size", 32)
	if tile_size_value is int or tile_size_value is float:
		tile_size = max(1, int(tile_size_value))

	return Vector2i(
		int(floor(unit.global_position.x / float(tile_size))),
		int(floor(unit.global_position.y / float(tile_size)))
	)


static func _get_object_property(obj: Object, property_name: String, default_value: Variant) -> Variant:
	if obj == null:
		return default_value

	for info in obj.get_property_list():
		if String(info.get("name", "")) == property_name:
			return obj.get(property_name)

	return default_value


static func _normalize_entry(entry: Dictionary) -> Dictionary:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return {}

	var result: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}

	if entry.has("instance_data"):
		var instance_data: Variant = entry.get("instance_data", {})
		if typeof(instance_data) == TYPE_DICTIONARY and not (instance_data as Dictionary).is_empty():
			result["instance_data"] = (instance_data as Dictionary).duplicate(true)

	return result


static func _is_empty_entry(entry: Dictionary) -> bool:
	return String(entry.get("item_id", "")) == "" or int(entry.get("amount", 0)) <= 0


static func _has_instance_data(entry: Dictionary) -> bool:
	if not entry.has("instance_data"):
		return false

	var instance_data: Variant = entry.get("instance_data", {})
	return typeof(instance_data) == TYPE_DICTIONARY and not (instance_data as Dictionary).is_empty()


static func _is_equipment_entry(entry: Dictionary) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return false

	if ItemDatabase == null:
		return false

	return ItemDatabase.get_equipment_resource(item_id) != null


static func _can_stack_entry(entry: Dictionary) -> bool:
	if _has_instance_data(entry):
		return false

	if _is_equipment_entry(entry):
		return false

	return true


static func _can_stack_world_entries(a: Dictionary, b: Dictionary) -> bool:
	if not _can_stack_entry(a):
		return false

	if not _can_stack_entry(b):
		return false

	return String(a.get("item_id", "")) == String(b.get("item_id", ""))


static func _get_pickup_tile(pickup: Node) -> Vector2i:
	var tile_value: Variant = _get_object_property(pickup, "tile_coords", null)
	if tile_value is Vector2i:
		return tile_value

	if pickup.has_method("get_save_data"):
		var data: Dictionary = pickup.get_save_data()
		return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))

	return INVALID_DROP_TILE


static func _get_pickup_entry(pickup: Node) -> Dictionary:
	if pickup.has_method("get_item_entry"):
		return pickup.get_item_entry()

	if pickup.has_method("get_save_data"):
		var data: Dictionary = pickup.get_save_data()
		data.erase("x")
		data.erase("y")
		return data

	var item_id: String = String(_get_object_property(pickup, "item_id", ""))
	var amount: int = int(_get_object_property(pickup, "amount", 0))
	if item_id == "" or amount <= 0:
		return {}

	return {
		"item_id": item_id,
		"amount": amount
	}


static func _find_stackable_pickup_on_tile(item_pickups_node: Node, entry: Dictionary, tile: Vector2i):
	if item_pickups_node == null:
		return null

	for pickup in item_pickups_node.get_children():
		if pickup == null:
			continue

		if _get_pickup_tile(pickup) != tile:
			continue

		var pickup_entry: Dictionary = _get_pickup_entry(pickup)
		if _can_stack_world_entries(entry, pickup_entry):
			return pickup

	return null


static func _has_item_pickup_on_tile(item_pickups_node: Node, tile: Vector2i) -> bool:
	if item_pickups_node == null:
		return false

	for pickup in item_pickups_node.get_children():
		if pickup == null:
			continue

		if _get_pickup_tile(pickup) == tile:
			return true

	return false


static func _merge_entry_into_pickup(pickup: Node, entry: Dictionary, map_id: String) -> void:
	var pickup_entry: Dictionary = _normalize_entry(_get_pickup_entry(pickup))
	var add_amount: int = int(entry.get("amount", 0))
	var current_amount: int = int(pickup_entry.get("amount", 0))
	pickup_entry["amount"] = current_amount + add_amount

	var tile: Vector2i = _get_pickup_tile(pickup)
	var save_entry: Dictionary = pickup_entry.duplicate(true)
	if pickup.has_method("setup_with_entry"):
		pickup.setup_with_entry(save_entry, map_id, tile)
	else:
		pickup.set("item_id", String(save_entry.get("item_id", "")))
		pickup.set("amount", int(save_entry.get("amount", 0)))
		pickup.set("map_id", map_id)
		pickup.set("tile_coords", tile)
		if pickup.has_method("apply_visual"):
			pickup.apply_visual()


static func _spawn_pickup_from_entry(
	item_pickups_node: Node,
	item_pickup_scene: PackedScene,
	entry: Dictionary,
	map_id: String,
	tile: Vector2i
) -> void:
	var pickup = item_pickup_scene.instantiate()
	item_pickups_node.add_child(pickup)

	var save_entry: Dictionary = entry.duplicate(true)
	if pickup.has_method("setup_with_entry"):
		pickup.setup_with_entry(save_entry, map_id, tile)
	else:
		pickup.setup(String(save_entry.get("item_id", "")), int(save_entry.get("amount", 1)), map_id, tile)


static func _find_nearest_empty_drop_tile(context: Dictionary, origin_tile: Vector2i, max_radius: int) -> Vector2i:
	max_radius = max(1, max_radius)

	for radius in range(1, max_radius + 1):
		var candidates: Array[Vector2i] = []

		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if abs(x) + abs(y) > radius:
					continue

				if abs(x) + abs(y) == 0:
					continue

				candidates.append(origin_tile + Vector2i(x, y))


		for tile in candidates:
			if _is_drop_tile_valid(context, tile, false):
				return tile

	return INVALID_DROP_TILE


static func _sort_tiles_for_drop(a: Vector2i, b: Vector2i, origin_tile: Vector2i) -> bool:
	var da: int = abs(a.x - origin_tile.x) + abs(a.y - origin_tile.y)
	var db: int = abs(b.x - origin_tile.x) + abs(b.y - origin_tile.y)

	if da != db:
		return da < db

	if a.y != b.y:
		return a.y < b.y

	return a.x < b.x


static func _is_drop_tile_valid(context: Dictionary, tile: Vector2i, allow_origin_unit: bool) -> bool:
	var ground_layer: TileMapLayer = context.get("ground_layer", null)
	var wall_layer: TileMapLayer = context.get("wall_layer", null)
	var units_node: Node = context.get("units_node", null)
	var item_pickups_node: Node = context.get("item_pickups_node", null)
	var origin_unit: Node = context.get("origin_unit", null)

	if ground_layer == null:
		return false

	if ground_layer.get_cell_source_id(tile) == -1:
		return false

	if wall_layer != null and wall_layer.get_cell_source_id(tile) != -1:
		return false

	if _has_item_pickup_on_tile(item_pickups_node, tile):
		return false

	if _has_blocking_unit_on_tile(units_node, tile, origin_unit, allow_origin_unit):
		return false

	return true


static func _has_blocking_unit_on_tile(units_node: Node, tile: Vector2i, origin_unit: Node, allow_origin_unit: bool) -> bool:
	if units_node == null:
		return false

	for unit in units_node.get_children():
		if unit == null:
			continue

		if allow_origin_unit and unit == origin_unit:
			continue

		var unit_tile: Vector2i = _get_unit_tile_coords(unit)
		if unit_tile == tile:
			return true

	return false


static func _save_item_pickups_to_world_state(item_pickups_node: Node, map_id: String) -> void:
	if map_id == "":
		return

	if WorldState == null:
		return

	var result: Array = []

	for pickup in item_pickups_node.get_children():
		if pickup == null:
			continue

		if pickup.has_method("get_save_data"):
			result.append(pickup.get_save_data())

	WorldState.map_item_pickups[map_id] = result
