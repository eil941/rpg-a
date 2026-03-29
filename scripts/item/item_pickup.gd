extends Node2D
class_name ItemPickup

@export var item_id: String = ""
@export var amount: int = 1
@export var map_id: String = ""
@export var tile_coords: Vector2i = Vector2i.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	apply_visual()
	call_deferred("snap_to_tile")


func setup(p_item_id: String, p_amount: int, p_map_id: String, p_tile: Vector2i) -> void:
	item_id = p_item_id
	amount = p_amount
	map_id = p_map_id
	tile_coords = p_tile
	apply_visual()
	call_deferred("snap_to_tile")


func apply_visual() -> void:
	sprite.texture = ItemDatabase.get_item_icon(item_id)


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
		"item_id": item_id,
		"amount": amount,
		"x": tile_coords.x,
		"y": tile_coords.y
	}
