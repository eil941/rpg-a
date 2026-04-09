extends Node2D
class_name ItemPickup

@export var item_id: String = ""
@export var amount: int = 1
@export var map_id: String = ""
@export var tile_coords: Vector2i = Vector2i.ZERO

var item_entry: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var enchant_overlay: ColorRect = _get_or_create_enchant_overlay()


func _ready() -> void:
	apply_visual()
	call_deferred("snap_to_tile")


func setup(p_item_id: String, p_amount: int, p_map_id: String, p_tile: Vector2i) -> void:
	item_id = p_item_id
	amount = p_amount
	map_id = p_map_id
	tile_coords = p_tile

	item_entry = {
		"item_id": item_id,
		"amount": amount
	}

	apply_visual()
	call_deferred("snap_to_tile")


func setup_with_entry(entry: Dictionary, p_map_id: String, p_tile: Vector2i) -> void:
	item_entry = entry.duplicate(true)
	item_id = String(item_entry.get("item_id", ""))
	amount = int(item_entry.get("amount", 1))
	map_id = p_map_id
	tile_coords = p_tile

	apply_visual()
	call_deferred("snap_to_tile")


func get_item_entry() -> Dictionary:
	if item_entry.is_empty():
		return {
			"item_id": item_id,
			"amount": amount
		}

	return item_entry.duplicate(true)


func apply_visual() -> void:
	sprite.texture = ItemDatabase.get_item_icon(item_id)
	_update_enchant_overlay()


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
	var data: Dictionary = get_item_entry()
	data["x"] = tile_coords.x
	data["y"] = tile_coords.y
	return data


func _has_enchantments() -> bool:
	var entry: Dictionary = get_item_entry()
	var instance_data: Variant = entry.get("instance_data", {})

	if typeof(instance_data) != TYPE_DICTIONARY:
		return false

	var enchantments: Variant = instance_data.get("enchantments", [])
	if not (enchantments is Array):
		return false

	return not enchantments.is_empty()


func _get_or_create_enchant_overlay() -> ColorRect:
	var existing: Node = get_node_or_null("EnchantOverlay")
	if existing is ColorRect:
		return existing

	var rect := ColorRect.new()
	rect.name = "EnchantOverlay"
	rect.color = Color(0.7, 0.35, 0.95, 0.28)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	add_child(rect)
	return rect


func _update_enchant_overlay() -> void:
	if enchant_overlay == null:
		return

	var texture: Texture2D = sprite.texture
	if texture == null:
		enchant_overlay.visible = false
		return

	var size: Vector2 = texture.get_size()
	enchant_overlay.size = size
	enchant_overlay.position = -size * 0.5
	enchant_overlay.visible = _has_enchantments()
