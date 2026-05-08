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

# =========================
# Monthly reset / regeneration
# =========================
# 30日ごとのリセット用。
# - 詳細マップ・ダンジョンはロードでは消さない
# - 月次リセット時に消す
# - プレイヤーがそのマップ内にいる場合は、出るまでリセットを保留する
var last_monthly_reset_month_index: int = -1
var monthly_reset_pending: bool = false
var deferred_reset_map_ids: Dictionary = {}
var deferred_reset_dungeons: bool = false
var should_regenerate_field_dungeons: bool = false


func reset_for_new_game() -> void:
	unit_states.clear()
	map_enemy_spawns.clear()
	map_npc_spawns.clear()
	map_tile_data.clear()
	dungeon_map_data.clear()
	field_detail_map_data.clear()
	field_dungeon_entrances.clear()
	dungeon_data.clear()
	dungeon_floor_data.clear()
	field_special_places.clear()
	unique_map_instances.clear()
	map_item_pickups.clear()
	map_chests.clear()

	quest_active_data.clear()
	quest_completed_data.clear()
	quest_failed_data.clear()
	unit_generated_quests.clear()

	last_monthly_reset_month_index = -1
	monthly_reset_pending = false
	deferred_reset_map_ids.clear()
	deferred_reset_dungeons = false
	should_regenerate_field_dungeons = false


func update_monthly_reset_pending(current_month_index: int) -> void:
	if last_monthly_reset_month_index < 0:
		last_monthly_reset_month_index = current_month_index
		monthly_reset_pending = false
		return

	if current_month_index > last_monthly_reset_month_index:
		monthly_reset_pending = true


func should_run_monthly_reset(current_month_index: int) -> bool:
	if last_monthly_reset_month_index < 0:
		return false

	if monthly_reset_pending:
		return true

	return current_month_index > last_monthly_reset_month_index


func mark_monthly_reset_done(current_month_index: int) -> void:
	last_monthly_reset_month_index = current_month_index
	monthly_reset_pending = false


func is_regenerable_detail_map_id(target_map_id: String) -> bool:
	if target_map_id == "":
		return false

	if target_map_id == "FieldMap":
		return false

	return target_map_id.begins_with("field_")


func is_unique_map_instance_map_id(target_map_id: String) -> bool:
	if target_map_id == "":
		return false

	return target_map_id.begins_with("unique_")


func is_dungeon_related_map_id(target_map_id: String) -> bool:
	if target_map_id == "":
		return false

	if target_map_id.begins_with("dungeon_"):
		return true

	if target_map_id.find("_dungeon_") != -1:
		return true

	if target_map_id.find("Dungeon") != -1:
		return true

	if target_map_id.find("dungeon") != -1:
		return true

	return false


func is_regenerable_map_id(target_map_id: String) -> bool:
	if is_regenerable_detail_map_id(target_map_id):
		return true

	if is_unique_map_instance_map_id(target_map_id):
		return true

	if is_dungeon_related_map_id(target_map_id):
		return true

	return false


func run_monthly_world_reset(active_map_id: String, current_month_index: int) -> void:
	if not should_run_monthly_reset(current_month_index):
		return

	print("[WorldState] monthly reset start active_map_id=", active_map_id, " month=", current_month_index)

	var reset_map_ids: Array[String] = _collect_regenerable_map_ids()

	for target_map_id in reset_map_ids:
		if target_map_id == active_map_id:
			deferred_reset_map_ids[target_map_id] = true
			print("[WorldState] defer reset active map=", target_map_id)
			continue

		clear_regenerable_map_data(target_map_id)

	if _should_reset_dungeon_global_data(active_map_id):
		_clear_dungeon_global_data()
	else:
		deferred_reset_dungeons = true
		print("[WorldState] defer dungeon global reset active_map_id=", active_map_id)

	mark_monthly_reset_done(current_month_index)
	print("[WorldState] monthly reset done month=", current_month_index)


func apply_deferred_reset_for_left_map(left_map_id: String) -> void:
	if left_map_id == "":
		return

	if deferred_reset_map_ids.has(left_map_id):
		clear_regenerable_map_data(left_map_id)
		deferred_reset_map_ids.erase(left_map_id)
		print("[WorldState] deferred map reset applied left_map_id=", left_map_id)

	if deferred_reset_dungeons and is_dungeon_related_map_id(left_map_id):
		_clear_dungeon_global_data()
		deferred_reset_dungeons = false
		print("[WorldState] deferred dungeon global reset applied")


func clear_regenerable_map_data(target_map_id: String) -> void:
	if target_map_id == "":
		return

	if target_map_id == "FieldMap":
		return

	print("[WorldState] clear regenerable map data target_map_id=", target_map_id)

	map_tile_data.erase(target_map_id)
	map_enemy_spawns.erase(target_map_id)
	map_npc_spawns.erase(target_map_id)
	map_item_pickups.erase(target_map_id)
	map_chests.erase(target_map_id)
	field_detail_map_data.erase(target_map_id)

	var should_clear_units: bool = true

	# 固有マップは、将来的な破壊・設置などの一時変更は戻すが、
	# NPCなどの重要Unit状態は残したいので、ここではunit_statesを消さない。
	if is_unique_map_instance_map_id(target_map_id):
		should_clear_units = false

	if should_clear_units:
		_clear_unit_states_for_map(target_map_id)


func _collect_regenerable_map_ids() -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}

	var sources: Array[Dictionary] = [
		map_tile_data,
		map_enemy_spawns,
		map_npc_spawns,
		map_item_pickups,
		map_chests,
		field_detail_map_data
	]

	for source in sources:
		for map_key in source.keys():
			var target_map_id: String = String(map_key)
			if seen.has(target_map_id):
				continue
			if not is_regenerable_map_id(target_map_id):
				continue

			seen[target_map_id] = true
			result.append(target_map_id)

	for unit_id in unit_states.keys():
		var unit_id_string: String = String(unit_id)
		var guessed_map_id: String = _guess_map_id_from_unit_id(unit_id_string)
		if guessed_map_id == "":
			continue
		if seen.has(guessed_map_id):
			continue
		if not is_regenerable_map_id(guessed_map_id):
			continue

		seen[guessed_map_id] = true
		result.append(guessed_map_id)

	return result


func _guess_map_id_from_unit_id(unit_id_string: String) -> String:
	if unit_id_string.begins_with("field_"):
		var parts: PackedStringArray = unit_id_string.split("_")
		if parts.size() >= 3:
			return "%s_%s_%s" % [parts[0], parts[1], parts[2]]

	if unit_id_string.begins_with("unique_"):
		var marker_index: int = unit_id_string.find("_field_")
		if marker_index != -1:
			var rest: String = unit_id_string.substr(marker_index + String("_field_").length())
			var rest_parts: PackedStringArray = rest.split("_")
			if rest_parts.size() >= 2:
				return unit_id_string.substr(0, marker_index + String("_field_").length() + rest_parts[0].length() + 1 + rest_parts[1].length())

	if unit_id_string.find("dungeon") != -1:
		var split_index: int = unit_id_string.find("_unit_")
		if split_index != -1:
			return unit_id_string.substr(0, split_index)

	return ""


func _clear_unit_states_for_map(target_map_id: String) -> void:
	var erase_unit_ids: Array[String] = []

	for unit_id in unit_states.keys():
		var unit_id_string: String = String(unit_id)
		if unit_id_string == "player":
			continue
		if unit_id_string.begins_with(target_map_id + "_"):
			erase_unit_ids.append(unit_id_string)

	for unit_id_string in erase_unit_ids:
		unit_states.erase(unit_id_string)


func _should_reset_dungeon_global_data(active_map_id: String) -> bool:
	if active_map_id == "":
		return true

	return not is_dungeon_related_map_id(active_map_id)


func _clear_dungeon_global_data() -> void:
	dungeon_map_data.clear()
	dungeon_floor_data.clear()
	dungeon_data.clear()
	field_dungeon_entrances.clear()

	# FieldMap本体や固有マップ配置は維持し、
	# 次にFieldMapを開いた時にダンジョン入口だけ再抽選する。
	should_regenerate_field_dungeons = true

	print("[WorldState] dungeon global data cleared. Field dungeons will be regenerated.")
