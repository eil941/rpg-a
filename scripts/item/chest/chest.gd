extends Node2D
class_name Chest

@export var chest_id: String = ""
@export var tile_coords: Vector2i = Vector2i.ZERO
@export var is_opened: bool = false
@export var chest_data: ChestData

@onready var inventory: Inventory = $Inventory
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	apply_chest_data()
	update_visual()
	call_deferred("snap_to_tile")


func setup(p_tile: Vector2i) -> void:
	tile_coords = p_tile
	apply_chest_data()
	update_visual()
	call_deferred("snap_to_tile")


func apply_chest_data() -> void:
	if chest_data == null:
		return

	if inventory == null:
		return

	var target_slots: int = max(chest_data.slot_count, 1)

	if inventory.has_method("resize_inventory"):
		inventory.resize_inventory(target_slots)
	else:
		inventory.max_slots = target_slots
		if inventory.has_method("initialize_empty_slots"):
			inventory.initialize_empty_slots()


func open_chest(player) -> void:
	if player == null:
		return

	if player.inventory == null:
		return

	var inventory_ui = find_inventory_ui()
	if inventory_ui == null:
		if player.has_method("notify_hud_log"):
			player.notify_hud_log("InventoryUI が見つかりません")
		return

	is_opened = true
	update_visual()

	if _is_inventory_empty():
		if player.has_method("notify_hud_log"):
			player.notify_hud_log("%s は空だった" % get_inventory_title())

	await inventory_ui.open_chest_mode(player.inventory, player, inventory, self)

	if player.has_method("notify_inventory_refresh"):
		player.notify_inventory_refresh()


func _is_inventory_empty() -> bool:
	if inventory == null:
		return true

	var items: Array[Dictionary] = inventory.get_all_items()

	for entry in items:
		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 0))

		if item_id != "" and amount > 0:
			return false

	return true


func get_inventory_title() -> String:
	if chest_data != null:
		var name_text: String = String(chest_data.chest_name)
		if name_text != "":
			return name_text

	return "Chest"


func can_player_put_item(item_id: String) -> bool:
	if item_id == "":
		return false

	if chest_data == null:
		return true

	if not chest_data.can_put_items:
		return false

	return is_item_allowed(item_id)


func can_player_take_item(item_id: String) -> bool:
	if item_id == "":
		return false

	if chest_data == null:
		return true

	if not chest_data.can_take_items:
		return false

	return true


func is_item_allowed(item_id: String) -> bool:
	if item_id == "":
		return false

	if chest_data == null:
		return true

	var item_type: String = ItemDatabase.get_item_type(item_id)

	if chest_data.has_denied_item_type(item_type):
		return false

	return chest_data.has_allowed_item_type(item_type)


func update_visual() -> void:
	if sprite != null and chest_data != null:
		if is_opened:
			if chest_data.opened_texture != null:
				sprite.texture = chest_data.opened_texture
		else:
			if chest_data.closed_texture != null:
				sprite.texture = chest_data.closed_texture

	if sprite == null:
		if is_opened:
			modulate = Color(0.8, 0.8, 0.8)
		else:
			modulate = Color(1, 1, 1)
		return

	if is_opened:
		sprite.modulate = Color(0.8, 0.8, 0.8)
	else:
		sprite.modulate = Color(1, 1, 1)


func snap_to_tile() -> void:
	if not is_inside_tree():
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var map_root: Node = parent_node.get_parent()
	if map_root == null:
		return

	var ground_layer = map_root.get_node_or_null("GroundLayer")
	if ground_layer == null:
		return

	global_position = ground_layer.to_global(ground_layer.map_to_local(tile_coords))


func find_inventory_ui():
	var node: Node = self

	while node != null:
		var ui = node.get_node_or_null("GameHUD/InventoryUI")
		if ui != null:
			return ui

		ui = node.get_node_or_null("InventoryUI")
		if ui != null:
			return ui

		node = node.get_parent()

	return null


func get_save_data() -> Dictionary:
	var chest_type_id: String = ""
	if chest_data != null:
		chest_type_id = String(chest_data.chest_type_id)

	return {
		"chest_id": chest_id,
		"chest_type_id": chest_type_id,
		"x": tile_coords.x,
		"y": tile_coords.y,
		"is_opened": is_opened,
		"inventory": inventory.save_inventory_data()
	}


func load_from_save_data(data: Dictionary) -> void:
	tile_coords = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	is_opened = bool(data.get("is_opened", false))

	apply_chest_data()

	if data.has("inventory"):
		inventory.load_inventory_data(data["inventory"])

	update_visual()
	call_deferred("snap_to_tile")
