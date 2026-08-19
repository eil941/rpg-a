extends Node

const SAVE_VERSION: int = 3
const DEFAULT_SAVE_PATH: String = "user://save_001.dat"

const WORLD_STATE_PROPS: Array[String] = [
	"unit_states",
	"map_enemy_spawns",
	"map_npc_spawns",
	"map_tile_data",
	"dungeon_map_data",
	"field_detail_map_data",
	"field_dungeon_entrances",
	"dungeon_data",
	"dungeon_floor_data",
	"field_special_places",
	"unique_map_instances",
	"map_item_pickups",
	"map_chests",
	"bounty_data",
	"quest_active_data",
	"quest_completed_data",
	"quest_failed_data",
	"unit_generated_quests",
	"last_monthly_reset_month_index",
	"monthly_reset_pending",
	"deferred_reset_map_ids",
	"deferred_reset_dungeons"
]

const PLAYER_DATA_PROPS: Array[String] = [
	"max_hp",
	"hp",
	"attack",
	"defense",
	"speed",
	"extended_stats_data",
	"skills_data",
	"skill_state_data",
	"current_map_id",
	"current_tile",
	"last_map_id",
	"last_tile",
	"map_positions",
	"inventory_data",
	"equipment_data",
	"effect_runtimes_data",
	"last_effect_update_time",
	"debug_start_items_applied"
]

const GLOBAL_DETAIL_MAP_PROPS: Array[String] = [
	"current_detail_map_key",
	"current_generator_type",
	"from_field_tile",
	"current_area_difficulty",
	"current_unique_map_instance_id",
	"current_unique_map_id",
	"current_return_scene_path",
	"current_return_field_map_id",
	"pending_resolve_return_from_unique_map",
	"pending_return_unique_map_id",
	"pending_return_unique_scene_path"
]

const GLOBAL_DUNGEON_PROPS: Array[String] = [
	"current_dungeon_id",
	"current_floor",
	"return_field_map_id",
	"return_field_cell",
	"pending_spawn_stair_type"
]

var pending_loaded_game: bool = false
var pending_loaded_map_scene_path: String = ""
var pending_loaded_map_id: String = ""

var debug_print_non_player_units_on_save: bool = true
var debug_print_non_player_units_limit: int = 50


func has_save_file(save_path: String = DEFAULT_SAVE_PATH) -> bool:
	return FileAccess.file_exists(save_path)


func delete_save_file(save_path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(save_path):
		return true

	var absolute_path: String = ProjectSettings.globalize_path(save_path)
	var error: Error = DirAccess.remove_absolute(absolute_path)
	return error == OK


func save_current_game(current_map: Node = null, save_path: String = DEFAULT_SAVE_PATH) -> bool:
	if current_map == null:
		current_map = _find_current_map_from_tree()

	if current_map != null and current_map.has_method("save_all_units"):
		current_map.save_all_units()

	if debug_print_non_player_units_on_save:
		_debug_print_non_player_units_on_map(current_map)

	_save_current_player_position_to_player_data(current_map)

	var current_map_scene_path: String = ""
	var current_map_id: String = ""

	if current_map != null:
		current_map_scene_path = String(current_map.scene_file_path).strip_edges()

		var map_id_value: Variant = current_map.get("map_id")
		if map_id_value != null:
			current_map_id = String(map_id_value)

	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"saved_unix_time": Time.get_unix_time_from_system(),
		"saved_datetime": Time.get_datetime_string_from_system(false, true),
		"current_map_scene_path": current_map_scene_path,
		"current_map_id": current_map_id,
		"world_state": _snapshot_object(WorldState, WORLD_STATE_PROPS),
		"player_data": _snapshot_object(PlayerData, PLAYER_DATA_PROPS),
		"time_manager": {
			"world_time_seconds": TimeManager.world_time_seconds
		},
		"global_detail_map": _snapshot_object(GlobalDetailMap, GLOBAL_DETAIL_MAP_PROPS),
		"global_dungeon": _snapshot_optional_autoload("GlobalDungeon", GLOBAL_DUNGEON_PROPS)
	}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: セーブファイルを開けません: " + save_path)
		return false

	file.store_var(save_data)
	file.close()

	print("[SaveManager] saved path=", save_path)
	print("[SaveManager] current_map_scene_path=", current_map_scene_path, " current_map_id=", current_map_id)

	return true


func request_load_game(save_path: String = DEFAULT_SAVE_PATH) -> bool:
	var save_data: Dictionary = load_save_data(save_path)
	if save_data.is_empty():
		return false

	_apply_save_data(save_data)

	pending_loaded_game = true
	pending_loaded_map_scene_path = String(save_data.get("current_map_scene_path", "")).strip_edges()
	pending_loaded_map_id = String(save_data.get("current_map_id", "")).strip_edges()

	print("[SaveManager] load requested map_scene=", pending_loaded_map_scene_path, " map_id=", pending_loaded_map_id)
	return true


func load_save_data(save_path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		push_warning("SaveManager: セーブファイルがありません: " + save_path)
		return {}

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: セーブファイルを読めません: " + save_path)
		return {}

	var value: Variant = file.get_var()
	file.close()

	if typeof(value) != TYPE_DICTIONARY:
		push_error("SaveManager: セーブデータがDictionaryではありません")
		return {}

	var save_data: Dictionary = value
	var version: int = int(save_data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveManager: セーブデータのバージョンが現在より新しいです version=" + str(version))

	return save_data


func has_pending_loaded_game() -> bool:
	return pending_loaded_game


func consume_pending_loaded_map_scene_path() -> String:
	var scene_path: String = pending_loaded_map_scene_path

	pending_loaded_game = false
	pending_loaded_map_scene_path = ""
	pending_loaded_map_id = ""

	return scene_path


func start_new_game(initial_map_scene_path: String) -> void:
	reset_runtime_state_for_new_game()

	pending_loaded_game = true
	pending_loaded_map_scene_path = initial_map_scene_path
	pending_loaded_map_id = ""

	if WorldState != null and WorldState.has_method("mark_monthly_reset_done"):
		WorldState.mark_monthly_reset_done(TimeManager.get_month_index())


func reset_runtime_state_for_new_game() -> void:
	if WorldState != null and WorldState.has_method("reset_for_new_game"):
		WorldState.reset_for_new_game()

	if PlayerData != null and PlayerData.has_method("reset_for_new_game"):
		PlayerData.reset_for_new_game()

	if TimeManager != null and TimeManager.has_method("reset_time"):
		TimeManager.reset_time()

	_reset_global_detail_map()
	_reset_global_dungeon()
	_clear_global_player_spawn_for_loaded_game()

	pending_loaded_game = false
	pending_loaded_map_scene_path = ""
	pending_loaded_map_id = ""

	print("[SaveManager] runtime state reset for new game")


func _apply_save_data(save_data: Dictionary) -> void:
	_apply_object_snapshot(WorldState, save_data.get("world_state", {}), WORLD_STATE_PROPS)
	_apply_object_snapshot(PlayerData, save_data.get("player_data", {}), PLAYER_DATA_PROPS)
	_apply_object_snapshot(GlobalDetailMap, save_data.get("global_detail_map", {}), GLOBAL_DETAIL_MAP_PROPS)

	var time_data_value: Variant = save_data.get("time_manager", {})
	if typeof(time_data_value) == TYPE_DICTIONARY:
		var time_data: Dictionary = time_data_value
		TimeManager.world_time_seconds = float(time_data.get("world_time_seconds", 0.0))
		TimeManager.is_resolving_turn = false

	var global_dungeon: Node = get_node_or_null("/root/GlobalDungeon")
	if global_dungeon != null:
		_apply_object_snapshot(global_dungeon, save_data.get("global_dungeon", {}), GLOBAL_DUNGEON_PROPS)

	# GlobalPlayerSpawn は保存・復元しない。
	# これはシーン移動直後だけ使う一時スポーン情報なので、
	# ロード時に残っていると入口・階段・spawn_x/y に引っ張られて、
	# セーブ地点とは別タイルから開始する原因になる。
	_clear_global_player_spawn_for_loaded_game()

	print("[SaveManager] save data applied")


func _save_current_player_position_to_player_data(current_map: Node) -> void:
	if current_map == null:
		return

	var map_id_value: Variant = current_map.get("map_id")
	if map_id_value == null:
		return

	var current_map_id: String = String(map_id_value).strip_edges()
	if current_map_id == "":
		return

	var units_node: Node = current_map.get_node_or_null("Units")
	if units_node == null:
		return

	var player_unit: Node = null

	for child in units_node.get_children():
		if child == null:
			continue

		var is_player_value: Variant = child.get("is_player_unit")
		if is_player_value != null and bool(is_player_value):
			player_unit = child
			break

	if player_unit == null:
		return

	var current_tile: Vector2i = Vector2i.ZERO

	if player_unit.has_method("get_current_tile_coords"):
		current_tile = player_unit.get_current_tile_coords()
	else:
		var start_tile_value: Variant = player_unit.get("start_tile")
		if start_tile_value != null and typeof(start_tile_value) == TYPE_VECTOR2I:
			current_tile = start_tile_value

	PlayerData.current_map_id = current_map_id
	PlayerData.current_tile = current_tile
	PlayerData.last_map_id = current_map_id
	PlayerData.last_tile = current_tile
	PlayerData.map_positions[current_map_id] = current_tile

	print("[SaveManager] saved current player tile map_id=", current_map_id, " tile=", current_tile)


func debug_print_current_map_non_player_units() -> void:
	var current_map: Node = _find_current_map_from_tree()
	_debug_print_non_player_units_on_map(current_map)


func _debug_print_non_player_units_on_map(current_map: Node) -> void:
	if current_map == null:
		print("[UNIT DEBUG] current_map is null")
		return

	var map_id: String = _get_object_string_property(current_map, "map_id", "")
	var units_node: Node = current_map.get_node_or_null("Units")

	if units_node == null:
		print("[UNIT DEBUG] map_id=", map_id, " Units node not found")
		return

	var printed_count: int = 0
	var total_non_player_count: int = 0

	print("[UNIT DEBUG] ===== non-player units on map start =====")
	print("[UNIT DEBUG] map_id=", map_id, " units_node=", units_node)

	for child in units_node.get_children():
		if child == null:
			continue

		var is_player_unit: bool = _get_object_bool_property(child, "is_player_unit", false)
		if is_player_unit:
			continue

		total_non_player_count += 1

		if printed_count >= debug_print_non_player_units_limit:
			continue

		printed_count += 1
		_debug_print_one_non_player_unit(child, map_id)

	print("[UNIT DEBUG] non_player_count=", total_non_player_count, " printed=", printed_count)
	print("[UNIT DEBUG] ===== non-player units on map end =====")


func _debug_print_one_non_player_unit(unit: Node, fallback_map_id: String) -> void:
	var unit_id: String = _get_object_string_property(unit, "unit_id", unit.name)
	var unit_name: String = _get_unit_debug_name(unit)
	var unit_map_id: String = _get_object_string_property(unit, "map_id", fallback_map_id)
	var tile_text: String = _get_unit_tile_text(unit)
	var hp_text: String = _get_unit_hp_text(unit)
	var status_texts: Array[String] = _collect_unit_status_debug_texts(unit)
	var saved_state_text: String = _get_saved_unit_state_debug_text(unit_id)

	print("[UNIT DEBUG] unit_id=", unit_id)
	print("             name=", unit_name, " map_id=", unit_map_id, " tile=", tile_text)
	print("             hp=", hp_text)
	print("             runtime_status=", status_texts)
	print("             saved_state=", saved_state_text)


func _get_unit_debug_name(unit: Node) -> String:
	var display_name: String = _get_object_string_property(unit, "display_name", "")
	if display_name != "":
		return display_name

	var unit_name: String = _get_object_string_property(unit, "unit_name", "")
	if unit_name != "":
		return unit_name

	var character_name: String = _get_object_string_property(unit, "character_name", "")
	if character_name != "":
		return character_name

	return unit.name


func _get_unit_tile_text(unit: Node) -> String:
	if unit.has_method("get_current_tile_coords"):
		var value: Variant = unit.call("get_current_tile_coords")
		if typeof(value) == TYPE_VECTOR2I:
			return str(value)

	var start_tile_value: Variant = _get_object_property(unit, "start_tile", null)
	if typeof(start_tile_value) == TYPE_VECTOR2I:
		return str(start_tile_value)

	return "unknown"


func _get_unit_hp_text(unit: Node) -> String:
	var hp_text: String = _get_first_number_text_from_unit_or_stats(
		unit,
		["hp", "current_hp"],
		"?"
	)

	var max_hp_text: String = _get_first_number_text_from_unit_or_stats(
		unit,
		["max_hp", "maximum_hp"],
		"?"
	)

	return hp_text + " / " + max_hp_text


func _get_first_number_text_from_unit_or_stats(unit: Node, property_names: Array[String], fallback: String) -> String:
	for property_name in property_names:
		var value: Variant = _get_object_property(unit, property_name, null)
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			return str(value)

	var stats_node: Node = unit.get_node_or_null("Stats")
	if stats_node != null:
		for property_name in property_names:
			var value_from_stats: Variant = _get_object_property(stats_node, property_name, null)
			if typeof(value_from_stats) == TYPE_INT or typeof(value_from_stats) == TYPE_FLOAT:
				return str(value_from_stats)

	return fallback


func _collect_unit_status_debug_texts(unit: Node) -> Array[String]:
	var result: Array[String] = []

	var property_names: Array[String] = [
		"effect_runtimes_data",
		"effect_runtimes",
		"active_effects",
		"status_effects",
		"active_statuses",
		"status_ailments",
		"status_tags",
		"buffs",
		"debuffs"
	]

	for property_name in property_names:
		var value: Variant = _get_object_property(unit, property_name, null)
		if _variant_has_debug_content(value):
			result.append(property_name + "=" + _short_variant_string(value, 400))

	var child_nodes: Array[Node] = unit.get_children()
	for child in child_nodes:
		if child == null:
			continue

		var child_name_lower: String = String(child.name).to_lower()
		if child_name_lower.find("effect") == -1 and child_name_lower.find("status") == -1:
			continue

		for property_name in property_names:
			var child_value: Variant = _get_object_property(child, property_name, null)
			if _variant_has_debug_content(child_value):
				result.append(str(child.name) + "." + property_name + "=" + _short_variant_string(child_value, 400))

	if unit.has_method("get_effect_runtimes_save_data"):
		var method_value: Variant = unit.call("get_effect_runtimes_save_data")
		if _variant_has_debug_content(method_value):
			result.append("get_effect_runtimes_save_data()=" + _short_variant_string(method_value, 400))

	if unit.has_method("get_status_debug_data"):
		var status_debug_value: Variant = unit.call("get_status_debug_data")
		if _variant_has_debug_content(status_debug_value):
			result.append("get_status_debug_data()=" + _short_variant_string(status_debug_value, 400))

	return result


func _get_saved_unit_state_debug_text(unit_id: String) -> String:
	if WorldState == null:
		return "WorldState=null"

	if not WorldState.unit_states.has(unit_id):
		return "not saved"

	var saved_state_value: Variant = WorldState.unit_states[unit_id]
	if typeof(saved_state_value) != TYPE_DICTIONARY:
		return _short_variant_string(saved_state_value, 400)

	var saved_state: Dictionary = saved_state_value
	var parts: Array[String] = []

	if saved_state.has("hp"):
		parts.append("hp=" + str(saved_state["hp"]))

	if saved_state.has("current_hp"):
		parts.append("current_hp=" + str(saved_state["current_hp"]))

	if saved_state.has("tile"):
		parts.append("tile=" + str(saved_state["tile"]))

	if saved_state.has("current_tile"):
		parts.append("current_tile=" + str(saved_state["current_tile"]))

	var status_keys: Array[String] = [
		"effect_runtimes_data",
		"effect_runtimes",
		"active_effects",
		"status_effects",
		"active_statuses",
		"status_ailments",
		"status_tags",
		"buffs",
		"debuffs"
	]

	for status_key in status_keys:
		if saved_state.has(status_key):
			parts.append(status_key + "=" + _short_variant_string(saved_state[status_key], 400))

	parts.append("keys=" + str(saved_state.keys()))

	return "{ " + ", ".join(parts) + " }"


func _variant_has_debug_content(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL:
			return false
		TYPE_ARRAY:
			var array_value: Array = value
			return not array_value.is_empty()
		TYPE_DICTIONARY:
			var dictionary_value: Dictionary = value
			return not dictionary_value.is_empty()
		TYPE_STRING:
			var string_value: String = value
			return string_value.strip_edges() != ""
		TYPE_STRING_NAME:
			var string_name_value: StringName = value
			return String(string_name_value).strip_edges() != ""
		_:
			return true


func _short_variant_string(value: Variant, max_length: int) -> String:
	var text: String = str(value)

	if text.length() <= max_length:
		return text

	return text.substr(0, max_length) + "...[truncated]"


func _get_object_string_property(target: Object, property_name: String, fallback: String) -> String:
	var value: Variant = _get_object_property(target, property_name, null)
	if value == null:
		return fallback

	return String(value).strip_edges()


func _get_object_bool_property(target: Object, property_name: String, fallback: bool) -> bool:
	var value: Variant = _get_object_property(target, property_name, null)
	if value == null:
		return fallback

	if typeof(value) == TYPE_BOOL:
		return bool(value)

	return fallback


func _get_object_property(target: Object, property_name: String, fallback: Variant) -> Variant:
	if target == null:
		return fallback

	if not _object_has_property(target, property_name):
		return fallback

	return target.get(property_name)


func _snapshot_optional_autoload(autoload_name: String, props: Array[String]) -> Dictionary:
	var node: Node = get_node_or_null("/root/" + autoload_name)
	if node == null:
		return {}

	return _snapshot_object(node, props)


func _snapshot_object(target: Object, props: Array[String]) -> Dictionary:
	var result: Dictionary = {}

	if target == null:
		return result

	for prop_name in props:
		if not _object_has_property(target, prop_name):
			continue

		result[prop_name] = _deep_copy_variant(target.get(prop_name))

	return result


func _apply_object_snapshot(target: Object, snapshot_value: Variant, props: Array[String]) -> void:
	if target == null:
		return

	if typeof(snapshot_value) != TYPE_DICTIONARY:
		return

	var snapshot: Dictionary = snapshot_value

	for prop_name in props:
		if not snapshot.has(prop_name):
			continue

		if not _object_has_property(target, prop_name):
			continue

		target.set(prop_name, _deep_copy_variant(snapshot[prop_name]))


func _object_has_property(target: Object, prop_name: String) -> bool:
	if target == null:
		return false

	for info in target.get_property_list():
		if String(info.get("name", "")) == prop_name:
			return true

	return false


func _deep_copy_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			return dict_value.duplicate(true)
		TYPE_ARRAY:
			var array_value: Array = value
			return array_value.duplicate(true)
		_:
			return value


func _reset_global_detail_map() -> void:
	if GlobalDetailMap == null:
		return

	if "current_detail_map_key" in GlobalDetailMap:
		GlobalDetailMap.current_detail_map_key = ""

	if "current_generator_type" in GlobalDetailMap:
		GlobalDetailMap.current_generator_type = ""

	if "from_field_tile" in GlobalDetailMap:
		GlobalDetailMap.from_field_tile = Vector2i.ZERO

	if "current_area_difficulty" in GlobalDetailMap:
		GlobalDetailMap.current_area_difficulty = 0

	if GlobalDetailMap.has_method("clear_unique_map_context"):
		GlobalDetailMap.clear_unique_map_context()

	if GlobalDetailMap.has_method("clear_pending_unique_map_return"):
		GlobalDetailMap.clear_pending_unique_map_return()


func _reset_global_dungeon() -> void:
	var global_dungeon: Node = get_node_or_null("/root/GlobalDungeon")
	if global_dungeon == null:
		return

	if "current_dungeon_id" in global_dungeon:
		global_dungeon.current_dungeon_id = ""

	if "current_floor" in global_dungeon:
		global_dungeon.current_floor = 1

	if "return_field_map_id" in global_dungeon:
		global_dungeon.return_field_map_id = ""

	if "return_field_cell" in global_dungeon:
		global_dungeon.return_field_cell = Vector2i.ZERO

	if "pending_spawn_stair_type" in global_dungeon:
		global_dungeon.pending_spawn_stair_type = ""


func _clear_global_player_spawn_for_loaded_game() -> void:
	var global_player_spawn: Node = get_node_or_null("/root/GlobalPlayerSpawn")
	if global_player_spawn == null:
		return

	if "has_next_tile" in global_player_spawn:
		global_player_spawn.has_next_tile = false

	if "next_tile" in global_player_spawn:
		global_player_spawn.next_tile = Vector2i.ZERO

	print("[SaveManager] GlobalPlayerSpawn cleared for loaded game")


func _find_current_map_from_tree() -> Node:
	var root: Window = get_tree().root
	if root == null:
		return null

	return _find_current_map_recursive(root)


func _find_current_map_recursive(node: Node) -> Node:
	if node == null:
		return null

	var current_map_value: Variant = node.get("current_map")
	if current_map_value != null and current_map_value is Node:
		return current_map_value

	var container: Node = node.get_node_or_null("CurrentMapContainer")
	if container != null and container.get_child_count() > 0:
		return container.get_child(0)

	for child in node.get_children():
		var found: Node = _find_current_map_recursive(child)
		if found != null:
			return found

	return null
