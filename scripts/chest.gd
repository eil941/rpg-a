extends Node2D
class_name Chest

@export var chest_id: String = ""
@export var tile_coords: Vector2i = Vector2i.ZERO
@export var is_opened: bool = false

@onready var inventory: Inventory = $Inventory
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	update_visual()
	call_deferred("snap_to_tile")


func setup(p_tile: Vector2i) -> void:
	tile_coords = p_tile
	update_visual()
	call_deferred("snap_to_tile")


func open_chest(player) -> void:
	if player == null:
		return
	if player.inventory == null:
		return

	var items = inventory.get_all_items()

	if items.is_empty():
		player.notify_hud_log("宝箱は空だった")
		return

	for entry in items:
		var item_id := String(entry.get("item_id", ""))
		var amount := int(entry.get("amount", 0))

		if item_id == "" or amount <= 0:
			continue

		var added = player.inventory.add_item(item_id, amount)
		if added:
			player.notify_hud_log("%s を %d 個手に入れた" % [
				ItemDatabase.get_display_name(item_id),
				amount
			])

	inventory.clear_inventory()
	is_opened = true
	update_visual()

	if player.has_method("notify_inventory_refresh"):
		player.notify_inventory_refresh()


func update_visual() -> void:
	if is_opened:
		modulate = Color(0.8, 0.8, 0.8)
	else:
		modulate = Color(1, 1, 1)


func snap_to_tile() -> void:
	if not is_inside_tree():
		return

	var map_root = get_parent().get_parent()
	if map_root == null:
		return

	var ground_layer = map_root.get_node_or_null("GroundLayer")
	if ground_layer == null:
		return

	global_position = ground_layer.to_global(ground_layer.map_to_local(tile_coords))


func get_save_data() -> Dictionary:
	return {
		"chest_id": chest_id,
		"x": tile_coords.x,
		"y": tile_coords.y,
		"is_opened": is_opened,
		"inventory": inventory.save_inventory_data()
	}


func load_from_save_data(data: Dictionary) -> void:
	tile_coords = Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
	is_opened = bool(data.get("is_opened", false))

	if data.has("inventory"):
		inventory.load_inventory_data(data["inventory"])

	update_visual()
	call_deferred("snap_to_tile")
