extends Node

var unit_states: Dictionary = {}

var map_enemy_spawns: Dictionary = {}
var map_npc_spawns: Dictionary = {}

var map_tile_data: Dictionary = {}
var dungeon_map_data: Dictionary = {}

var field_detail_map_data: Dictionary = {}

var field_dungeon_entrances: Dictionary = {}
var dungeon_data: Dictionary = {}
var dungeon_floor_data: Dictionary = {}

var field_special_places: Dictionary = {}

# 固有詳細マップ配置インスタンス
# instance_id -> Dictionary
var unique_map_instances: Dictionary = {}

var map_item_pickups: Dictionary = {}
var map_chests: Dictionary = {}

# =========================
# Quest
# =========================
var quest_active_data: Dictionary = {}
var quest_completed_data: Dictionary = {}
var quest_failed_data: Dictionary = {}

# unitごとの提示依頼キャッシュ
# unit_id -> Array[Dictionary]
var unit_generated_quests: Dictionary = {}



func clear_enemy_spawns() -> void:
	map_enemy_spawns.clear()
	unit_states.clear()


# =========================
# Unique detail map instance
# =========================
func make_unique_detail_map_id(unique_map_id: String, field_tile: Vector2i) -> String:
	var safe_unique_id: String = _sanitize_id(unique_map_id)
	return "unique_%s_field_%d_%d" % [
		safe_unique_id,
		field_tile.x,
		field_tile.y
	]


func make_unique_map_instance_id(field_tile: Vector2i, unique_map_id: String) -> String:
	var safe_unique_id: String = _sanitize_id(unique_map_id)
	return "field_%d_%d_%s" % [
		field_tile.x,
		field_tile.y,
		safe_unique_id
	]


func ensure_unique_map_instance(
	return_field_map_id: String,
	return_field_tile: Vector2i,
	place: Dictionary
) -> Dictionary:
	var unique_map_id: String = String(place.get("unique_map_id", "")).strip_edges()
	if unique_map_id == "":
		unique_map_id = String(place.get("place_id", "")).strip_edges()
	if unique_map_id == "":
		unique_map_id = "unknown_unique_map"

	var scene_path: String = String(place.get("scene_path", "")).strip_edges()
	if scene_path == "":
		scene_path = String(place.get("enter_scene", "")).strip_edges()

	if scene_path == "":
		push_error("WorldState.ensure_unique_map_instance: scene_path / enter_scene が空です")
		return {}

	var instance_id: String = String(place.get("instance_id", "")).strip_edges()
	if instance_id == "":
		instance_id = make_unique_map_instance_id(return_field_tile, unique_map_id)

	if unique_map_instances.has(instance_id):
		return unique_map_instances[instance_id]

	var entry_spawn_tile: Vector2i = value_to_vector2i(
		place.get("entry_spawn_tile", Vector2i(5, 8)),
		Vector2i(5, 8)
	)

	var return_spawn_tile: Vector2i = value_to_vector2i(
		place.get("return_spawn_tile", return_field_tile),
		return_field_tile
	)

	var detail_map_id: String = String(place.get("map_id", "")).strip_edges()
	if detail_map_id == "":
		detail_map_id = make_unique_detail_map_id(unique_map_id, return_field_tile)

	var return_scene_path: String = String(
		place.get("return_scene_path", "res://scenes/field_map.tscn")
	).strip_edges()

	var instance: Dictionary = {
		"instance_id": instance_id,
		"unique_map_id": unique_map_id,
		"scene_path": scene_path,
		"enter_scene": scene_path,
		"map_id": detail_map_id,

		"return_field_map_id": return_field_map_id,
		"return_scene_path": return_scene_path,
		"return_field_tile": return_field_tile,
		"return_spawn_tile": return_spawn_tile,

		"entry_spawn_tile": entry_spawn_tile,
		"area_difficulty": int(place.get("difficulty", 0)),
		"place_type": String(place.get("type", "")),
		"place_id": String(place.get("place_id", ""))
	}

	unique_map_instances[instance_id] = instance
	return instance


func value_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(value) == TYPE_VECTOR2I:
		return value

	if typeof(value) == TYPE_VECTOR2:
		var vector_value: Vector2 = value
		return Vector2i(int(vector_value.x), int(vector_value.y))

	if typeof(value) == TYPE_DICTIONARY:
		var dict_value: Dictionary = value
		return Vector2i(
			int(dict_value.get("x", fallback.x)),
			int(dict_value.get("y", fallback.y))
		)

	return fallback


func _sanitize_id(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	result = result.replace("res://", "")
	result = result.replace(".tscn", "")
	result = result.replace("/", "_")
	result = result.replace("\\", "_")
	result = result.replace(" ", "_")
	result = result.replace("-", "_")
	result = result.replace(".", "_")
	result = result.replace(":", "_")

	while result.find("__") != -1:
		result = result.replace("__", "_")

	result = result.strip_edges()
	if result == "":
		result = "unknown"

	return result
