extends Node2D
class_name SpecialMapMain

enum SpawnMode {
	FIXED,
	RANDOM_TOTAL
}

@export var map_id: String = ""
@export var unit_scene: PackedScene
@export var spawn_mode: SpawnMode = SpawnMode.FIXED
@export var unit_data_list: Array[SpecialMapUnitEntry] = []

# RANDOM_TOTAL のときだけ使用
@export var total_random_spawn_count: int = 0
@export var random_spawn_tiles: Array[Vector2i] = []

var _spawn_serial: int = 0


func _ready() -> void:
	if unit_scene == null:
		unit_scene = load("res://scenes/unit.tscn") as PackedScene

	if unit_scene == null:
		push_error("SpecialMapMain: unit_scene が設定されていません")
		return

	match spawn_mode:
		SpawnMode.FIXED:
			_spawn_fixed_units()
		SpawnMode.RANDOM_TOTAL:
			_spawn_random_total_units()

	refresh_hud()


# =========================================================
# spawn helpers
# =========================================================
func _get_units_node() -> Node:
	var units_node: Node = get_node_or_null("Units")
	if units_node == null:
		push_error("SpecialMapMain: Units ノードがありません")
	return units_node


func _get_valid_entries() -> Array[SpecialMapUnitEntry]:
	var result: Array[SpecialMapUnitEntry] = []

	for entry in unit_data_list:
		if entry == null:
			continue
		if not entry.enabled:
			continue
		if entry.get_data_resource() == null:
			continue
		result.append(entry)

	return result


func _get_available_random_tiles() -> Array[Vector2i]:
	return random_spawn_tiles.duplicate()


# =========================================================
# spawn main
# =========================================================
func _spawn_fixed_units() -> void:
	var units_node: Node = _get_units_node()
	if units_node == null:
		return

	for entry in _get_valid_entries():
		var count: int = max(0, entry.fixed_spawn_count)
		if entry.fixed_spawn_tiles.is_empty():
			continue

		var spawn_count: int = min(count, entry.fixed_spawn_tiles.size())
		for i in range(spawn_count):
			var tile: Vector2i = entry.fixed_spawn_tiles[i]
			_spawn_one_unit(units_node, entry, tile)


func _spawn_random_total_units() -> void:
	var units_node: Node = _get_units_node()
	if units_node == null:
		return

	var count: int = max(0, total_random_spawn_count)
	if count <= 0:
		return

	var available_tiles: Array[Vector2i] = _get_available_random_tiles()
	if available_tiles.is_empty():
		return

	for i in range(count):
		if available_tiles.is_empty():
			break

		var entry: SpecialMapUnitEntry = _pick_random_entry()
		if entry == null:
			return

		var tile_index: int = randi_range(0, available_tiles.size() - 1)
		var tile: Vector2i = available_tiles[tile_index]
		available_tiles.remove_at(tile_index)

		_spawn_one_unit(units_node, entry, tile)


func _pick_random_entry() -> SpecialMapUnitEntry:
	var weighted_pool: Array[SpecialMapUnitEntry] = []

	for entry in _get_valid_entries():
		var weight: int = max(1, entry.random_weight)
		for i in range(weight):
			weighted_pool.append(entry)

	if weighted_pool.is_empty():
		return null

	var index: int = randi_range(0, weighted_pool.size() - 1)
	return weighted_pool[index]


func _spawn_one_unit(units_node: Node, entry: SpecialMapUnitEntry, tile: Vector2i) -> void:
	if unit_scene == null:
		return
	if entry == null:
		return

	var unit = unit_scene.instantiate()
	if unit == null:
		return

	unit.start_tile = tile
	unit.unit_id = _make_spawned_unit_id(entry)

	match entry.spawn_kind:
		SpecialMapUnitEntry.SpawnKind.ENEMY:
			unit.enemy_data_to_apply = entry.enemy_data

		SpecialMapUnitEntry.SpawnKind.NPC:
			unit.npc_data_to_apply = entry.npc_data

	units_node.add_child(unit)


func _make_spawned_unit_id(entry: SpecialMapUnitEntry) -> String:
	_spawn_serial += 1

	var base_name: String = "unit"
	if entry != null:
		base_name = entry.get_display_name().strip_edges().replace(" ", "_")
		if base_name == "":
			base_name = "unit"

	var map_key: String = map_id
	if map_key == "":
		map_key = name

	return "%s_%s_%04d" % [map_key, base_name, _spawn_serial]


# =========================================================
# parent bridge helpers
# =========================================================
func _find_parent_with_method(method_name: String) -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method(method_name):
			return node
		node = node.get_parent()
	return null


func _call_parent_void(method_name: String, args: Array = []) -> void:
	var parent_node: Node = _find_parent_with_method(method_name)
	if parent_node == null:
		return

	parent_node.callv(method_name, args)


func _call_parent_bool(method_name: String, default_value: bool = false, args: Array = []) -> bool:
	var parent_node: Node = _find_parent_with_method(method_name)
	if parent_node == null:
		return default_value

	return bool(parent_node.callv(method_name, args))


# =========================================================
# save / load / root interface
# =========================================================
func load_map_by_path(scene_path: String) -> void:
	var parent_node: Node = _find_parent_with_method("load_map_by_path")
	if parent_node != null:
		parent_node.load_map_by_path(scene_path)
		return

	push_error("SpecialMapMain: load_map_by_path を持つ親が見つかりません: " + scene_path)


func save_all_units() -> void:
	var units_node: Node = get_node_or_null("Units")
	if units_node == null:
		return

	for child in units_node.get_children():
		if child == null:
			continue
		if not child.has_method("save_persistent_stats"):
			continue
		child.save_persistent_stats()


func find_player():
	var units_node: Node = get_node_or_null("Units")
	if units_node == null:
		return null

	for child in units_node.get_children():
		if child == null:
			continue
		if child.get("is_player_unit"):
			return child

	return null


# =========================================================
# HUD / UI bridge
# =========================================================
func refresh_hud() -> void:
	_call_parent_void("refresh_hud")


func update_hud_time() -> void:
	_call_parent_void("update_hud_time")


func update_hud_player_status() -> void:
	_call_parent_void("update_hud_player_status")


func update_hud_effects() -> void:
	_call_parent_void("update_hud_effects")


func add_hud_log(text: String) -> void:
	_call_parent_void("add_hud_log", [text])


func toggle_inventory_ui() -> void:
	_call_parent_void("toggle_inventory_ui")


func is_inventory_open() -> bool:
	return _call_parent_bool("is_inventory_open", false)


func refresh_inventory_ui() -> void:
	_call_parent_void("refresh_inventory_ui")


func open_trade_ui(player_unit, merchant_unit, return_context: Dictionary = {}) -> void:
	_call_parent_void("open_trade_ui", [player_unit, merchant_unit, return_context])


func close_trade_ui() -> void:
	_call_parent_void("close_trade_ui")


func is_trade_ui_open() -> bool:
	return _call_parent_bool("is_trade_ui_open", false)


func on_trade_ui_closed() -> void:
	_call_parent_void("on_trade_ui_closed")


func toggle_status_ui() -> void:
	_call_parent_void("toggle_status_ui")


func open_status_ui() -> void:
	_call_parent_void("open_status_ui")


func close_status_ui() -> void:
	_call_parent_void("close_status_ui")


func is_status_open() -> bool:
	return _call_parent_bool("is_status_open", false)


func is_dialog_open() -> bool:
	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		return DialogueManager.is_dialog_open()

	return _call_parent_bool("is_dialog_open", false)
