extends Node

var current_detail_map_key: String = ""
var current_generator_type: String = ""
var from_field_tile: Vector2i = Vector2i.ZERO
var current_area_difficulty: int = 0

var current_unique_map_instance_id: String = ""
var current_unique_map_id: String = ""
var current_return_scene_path: String = "res://scenes/field_map.tscn"
var current_return_field_map_id: String = ""

# 固有マップ開始などで、fieldmap上の戻り先がまだ分からない時に使う
var pending_resolve_return_from_unique_map: bool = false
var pending_return_unique_map_id: String = ""
var pending_return_unique_scene_path: String = ""


func begin_pending_unique_map_return(unique_map_id: String, unique_scene_path: String) -> void:
	pending_resolve_return_from_unique_map = true
	pending_return_unique_map_id = unique_map_id.strip_edges()
	pending_return_unique_scene_path = unique_scene_path.strip_edges()


func clear_pending_unique_map_return() -> void:
	pending_resolve_return_from_unique_map = false
	pending_return_unique_map_id = ""
	pending_return_unique_scene_path = ""


func clear_unique_map_context() -> void:
	current_unique_map_instance_id = ""
	current_unique_map_id = ""
	current_return_scene_path = "res://scenes/field_map.tscn"
	current_return_field_map_id = ""
	clear_pending_unique_map_return()
