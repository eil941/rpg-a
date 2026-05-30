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

# 失敗/辞退した依頼を出したNPCは、指定NPCリセット完了まで新しい生成依頼を出さない。
# key = giver_unit_id, value = blocked_until_npc_reset_index
var npc_quest_generation_blocked_until_reset: Dictionary = {}



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
# マップリセット用。
# - TimeManager 側の指定間隔に到達した時点では monthly_reset_pending を立てるだけ
# - 詳細マップ・ダンジョン・固有マップ内では実データを消さない
# - プレイヤーが FieldMap に戻ったタイミングでだけ実リセットする
# - FieldMap本体、固有マップ配置、プレイヤー情報、クエスト情報は消さない
var last_monthly_reset_month_index: int = -1
var monthly_reset_pending: bool = false
var deferred_reset_map_ids: Dictionary = {}
var deferred_reset_dungeons: bool = false
var should_regenerate_field_dungeons: bool = false

# =========================
# NPC reset settings
# =========================
# インスペクター変更なしの固定設定。
# NPCリセット時にNPCごとの生成依頼キャッシュを消す。
var reset_npc_generated_quests_on_world_reset: bool = true

# 受注中の generated__ 依頼も消す。
# 受注中の生成依頼を残したい場合だけ false にする。
var reset_active_generated_quests_on_world_reset: bool = false

# NPCリセット時にNPC/商人の保存済みInventoryだけを消す。
# Unit状態そのものは残すので、HP/位置/死亡状態などを巻き込みにくい。
var reset_npc_trade_inventory_on_world_reset: bool = true

# NPCリセット専用の期間管理。
# マップ/ダンジョン/詳細マップのリセット周期とは別に、
# NPC生成依頼・商人在庫だけを更新する。
var last_npc_reset_index: int = -1
var npc_reset_pending: bool = false


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
	npc_quest_generation_blocked_until_reset.clear()

	last_monthly_reset_month_index = -1
	monthly_reset_pending = false
	deferred_reset_map_ids.clear()
	deferred_reset_dungeons = false
	should_regenerate_field_dungeons = false

	reset_npc_generated_quests_on_world_reset = true
	reset_active_generated_quests_on_world_reset = false
	reset_npc_trade_inventory_on_world_reset = true

	last_npc_reset_index = -1
	npc_reset_pending = false



func update_npc_reset_pending(current_npc_reset_index: int) -> void:
	if last_npc_reset_index < 0:
		last_npc_reset_index = current_npc_reset_index
		npc_reset_pending = false
		return

	if current_npc_reset_index > last_npc_reset_index:
		npc_reset_pending = true


func should_run_npc_reset(current_npc_reset_index: int) -> bool:
	if last_npc_reset_index < 0:
		return false

	if npc_reset_pending:
		return true

	return current_npc_reset_index > last_npc_reset_index


func mark_npc_reset_done(current_npc_reset_index: int) -> void:
	last_npc_reset_index = current_npc_reset_index
	npc_reset_pending = false


func run_npc_reset_if_needed(current_npc_reset_index: int) -> void:
	if not should_run_npc_reset(current_npc_reset_index):
		return

	# 先に完了インデックスを更新してからリセット処理を走らせる。
	# clear_npc_quest_generation_blocks() が「このリセットで解除してよいブロック」を
	# 正しく判定できるようにするため。
	mark_npc_reset_done(current_npc_reset_index)
	reset_npc_world_reset_state()
	print("[WorldState] NPC reset done index=", current_npc_reset_index)


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


func is_field_map_id(target_map_id: String) -> bool:
	return target_map_id == "FieldMap"


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

	# 重要:
	# リセット指定タイミングに到達しても、詳細マップ・ダンジョン・固有マップ内では
	# 実データを消さない。ここで消すと、ダンジョン階層移動中に
	# dungeon_data / dungeon_floor_data が消えてクラッシュする。
	#
	# 実リセットは FieldMap に戻った後だけ行う。
	if not is_field_map_id(active_map_id):
		monthly_reset_pending = true
		print("[WorldState] monthly reset pending until FieldMap. active_map_id=", active_map_id, " month=", current_month_index)
		return

	print("[WorldState] monthly reset start on FieldMap month=", current_month_index)

	var reset_map_ids: Array[String] = _collect_regenerable_map_ids()

	for target_map_id in reset_map_ids:
		clear_regenerable_map_data(target_map_id)

	# ダンジョン関連データも FieldMap に戻ってから初めて消す。
	# これにより、ダンジョン内で日付を跨いでも階層移動中にデータが消えない。
	_clear_dungeon_global_data()

	deferred_reset_map_ids.clear()
	deferred_reset_dungeons = false

	mark_monthly_reset_done(current_month_index)
	print("[WorldState] monthly reset done on FieldMap month=", current_month_index)


func apply_deferred_reset_for_left_map(left_map_id: String) -> void:
	if left_map_id == "":
		return

	# 旧仕様/古いセーブデータ互換用。
	# 新仕様では、通常は deferred_reset_map_ids を新規追加しない。
	# 実リセットは FieldMap 上の run_monthly_world_reset() でまとめて行う。
	if deferred_reset_map_ids.has(left_map_id):
		clear_regenerable_map_data(left_map_id)
		deferred_reset_map_ids.erase(left_map_id)
		print("[WorldState] deferred map reset applied left_map_id=", left_map_id)

	# ここで dungeon_data を消してはいけない。
	# ダンジョン floor_3 -> floor_4 のような階層移動でも left_map_id は dungeon 関連になるため、
	# ここで _clear_dungeon_global_data() を呼ぶと次階層生成に必要な dungeon_data が消える。
	#
	# ダンジョン全体リセットは、FieldMap に戻った後の run_monthly_world_reset() だけで行う。
	if deferred_reset_dungeons and is_dungeon_related_map_id(left_map_id):
		print("[WorldState] deferred dungeon reset kept pending until FieldMap. left_map_id=", left_map_id)


func clear_regenerable_map_data(target_map_id: String) -> void:
	if target_map_id == "":
		return

	if target_map_id == "FieldMap":
		return

	print("[WorldState] clear regenerable map data target_map_id=", target_map_id)

	var protected_active_quest_unit_ids: Dictionary = _collect_active_quest_unit_ids()

	map_tile_data.erase(target_map_id)
	map_enemy_spawns.erase(target_map_id)

	# 受注中クエストを持つNPCがいるマップでは、NPCスポーン情報を消さない。
	# ここで消すと、quest_active_data は残っていても、
	# クエストを出したNPCが再生成/消失し、クエストボードから見えなくなる。
	var has_active_quest_npc: bool = _map_has_active_quest_npc_spawn(target_map_id, protected_active_quest_unit_ids)

	if has_active_quest_npc:
		print("[WorldState] keep NPC spawns/detail config because active quest NPC exists target_map_id=", target_map_id)
	else:
		map_npc_spawns.erase(target_map_id)
		field_detail_map_data.erase(target_map_id)

	map_item_pickups.erase(target_map_id)
	map_chests.erase(target_map_id)

	var should_clear_units: bool = true

	# 固有マップは、将来的な破壊・設置などの一時変更は戻すが、
	# NPCなどの重要Unit状態は残したいので、ここではunit_statesを消さない。
	if is_unique_map_instance_map_id(target_map_id):
		should_clear_units = false

	if should_clear_units:
		_clear_unit_states_for_map(target_map_id, protected_active_quest_unit_ids)


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


func _clear_unit_states_for_map(target_map_id: String, protected_unit_ids: Dictionary = {}) -> void:
	var erase_unit_ids: Array[String] = []

	for unit_id in unit_states.keys():
		var unit_id_string: String = String(unit_id)
		if unit_id_string == "player":
			continue

		# 受注中クエストを持つNPCの状態は消さない。
		if protected_unit_ids.has(unit_id_string):
			continue

		if unit_id_string.begins_with(target_map_id + "_"):
			erase_unit_ids.append(unit_id_string)

	for unit_id_string in erase_unit_ids:
		unit_states.erase(unit_id_string)


func _should_reset_dungeon_global_data(active_map_id: String) -> bool:
	if active_map_id == "":
		return true

	return not is_dungeon_related_map_id(active_map_id)




func block_npc_quest_generation_until_reset(unit_id: String) -> void:
	unit_id = unit_id.strip_edges()
	if unit_id == "":
		return

	block_npc_quest_generation_keys_until_reset([unit_id])


func block_npc_quest_generation_keys_until_reset(block_keys: Array) -> void:
	if block_keys.is_empty():
		return

	var current_npc_reset_index: int = _get_current_npc_reset_index()
	var blocked_until_index: int = current_npc_reset_index + 1
	var saved_count: int = 0

	for raw_key in block_keys:
		var block_key: String = String(raw_key).strip_edges()
		if block_key == "":
			continue

		npc_quest_generation_blocked_until_reset[block_key] = blocked_until_index
		saved_count += 1

	print("[WorldState] block NPC quest generation keys count=", saved_count, " until_npc_reset_index=", blocked_until_index)


func is_npc_quest_generation_blocked_until_reset(unit_id: String) -> bool:
	return is_npc_quest_generation_key_blocked_until_reset(unit_id)


func is_any_npc_quest_generation_key_blocked_until_reset(block_keys: Array) -> bool:
	for raw_key in block_keys:
		var block_key: String = String(raw_key).strip_edges()
		if block_key == "":
			continue
		if is_npc_quest_generation_key_blocked_until_reset(block_key):
			return true

	return false


func is_npc_quest_generation_key_blocked_until_reset(block_key: String) -> bool:
	block_key = block_key.strip_edges()
	if block_key == "":
		return false

	if not npc_quest_generation_blocked_until_reset.has(block_key):
		return false

	var block_value: Variant = npc_quest_generation_blocked_until_reset.get(block_key, -1)

	# 旧版のbool値がセーブに残っていた場合の互換。
	if typeof(block_value) == TYPE_BOOL:
		return bool(block_value)

	var blocked_until_index: int = int(block_value)
	var current_npc_reset_index: int = _get_current_npc_reset_index()

	# 「現在の期間がまだ blocked_until_index 未満」
	# または
	# 「そのNPCリセットがまだ実行完了していない」
	# 場合はブロック継続。
	if current_npc_reset_index < blocked_until_index:
		return true

	if last_npc_reset_index < blocked_until_index:
		return true

	return false


func clear_npc_quest_generation_blocks() -> void:
	if npc_quest_generation_blocked_until_reset.is_empty():
		return

	var erase_unit_ids: Array[String] = []
	var current_npc_reset_index: int = last_npc_reset_index

	for unit_id_value in npc_quest_generation_blocked_until_reset.keys():
		var unit_id: String = String(unit_id_value)
		var block_value: Variant = npc_quest_generation_blocked_until_reset.get(unit_id, -1)

		# 旧版boolは、NPCリセットが来たら解除してよい。
		if typeof(block_value) == TYPE_BOOL:
			erase_unit_ids.append(unit_id)
			continue

		var blocked_until_index: int = int(block_value)
		if current_npc_reset_index >= blocked_until_index:
			erase_unit_ids.append(unit_id)

	for unit_id in erase_unit_ids:
		npc_quest_generation_blocked_until_reset.erase(unit_id)

	if not erase_unit_ids.is_empty():
		print("[WorldState] NPC quest generation blocks cleared count=", erase_unit_ids.size())


func _get_current_npc_reset_index() -> int:
	if TimeManager != null and TimeManager.has_method("get_npc_reset_index"):
		return int(TimeManager.get_npc_reset_index())

	return max(last_npc_reset_index, 0)


func reset_npc_world_reset_state() -> void:
	if reset_npc_generated_quests_on_world_reset:
		reset_generated_npc_quest_state()

	if reset_npc_trade_inventory_on_world_reset:
		reset_npc_trade_inventory_state()


func reset_generated_npc_quest_state() -> void:
	# NPCリセットが来たので、失敗/辞退による「次のリセットまで生成しない」ブロックを解除する。
	clear_npc_quest_generation_blocks()

	# reset_active_generated_quests_on_world_reset が false の場合、
	# 受注中クエストを持つNPCはクエストリセット対象から外す。
	#
	# 重要:
	# quest_active_data だけ残して unit_generated_quests を消すと、
	# NPC側の「提示中依頼リスト」から受注中依頼が消える。
	# さらに、マップ側のNPCスポーン情報まで消すと、
	# クエストを出したNPC自体が再生成/消失し、クエストボードからも見えなくなる。
	if reset_active_generated_quests_on_world_reset:
		unit_generated_quests.clear()
		_erase_generated_quests_from_dictionary(quest_active_data)
	else:
		_reset_generated_unit_quests_keep_active_quest_npcs()

	# 完了/失敗履歴に generated__ が残ると、
	# 再生成された同IDの依頼が非表示になるので消す。
	_erase_generated_quests_from_dictionary(quest_completed_data)
	_erase_generated_quests_from_dictionary(quest_failed_data)

	print("[WorldState] NPC generated quests reset. reset_active=", reset_active_generated_quests_on_world_reset)


func _reset_generated_unit_quests_keep_active_quest_npcs() -> void:
	var protected_unit_keys: Dictionary = _collect_active_quest_unit_ids()

	var erase_unit_keys: Array[String] = []
	for unit_key_value in unit_generated_quests.keys():
		var unit_key: String = String(unit_key_value)
		if protected_unit_keys.has(unit_key):
			continue
		erase_unit_keys.append(unit_key)

	for unit_key in erase_unit_keys:
		unit_generated_quests.erase(unit_key)

	print("[WorldState] generated quest cache reset. kept_active_quest_units=", protected_unit_keys.keys())


func _collect_active_quest_unit_ids() -> Dictionary:
	var result: Dictionary = {}

	for quest_id_value in quest_active_data.keys():
		var quest_id: String = String(quest_id_value)

		var data_value: Variant = quest_active_data.get(quest_id_value, {})
		if typeof(data_value) == TYPE_DICTIONARY:
			var data: Dictionary = data_value
			var giver_unit_id: String = String(data.get("giver_unit_id", ""))
			if giver_unit_id != "":
				result[giver_unit_id] = true

		if quest_id.begins_with("generated__"):
			var unit_key: String = _get_unit_key_from_generated_quest_id(quest_id)
			if unit_key != "":
				result[unit_key] = true

	return result


func _map_has_active_quest_npc_spawn(target_map_id: String, protected_unit_ids: Dictionary) -> bool:
	if protected_unit_ids.is_empty():
		return false

	if not map_npc_spawns.has(target_map_id):
		return false

	var spawns_value: Variant = map_npc_spawns.get(target_map_id, [])
	if typeof(spawns_value) != TYPE_ARRAY:
		return false

	var spawns: Array = spawns_value
	for spawn_value in spawns:
		if typeof(spawn_value) != TYPE_DICTIONARY:
			continue

		var spawn_data: Dictionary = spawn_value
		var unit_id: String = String(spawn_data.get("unit_id", ""))
		if protected_unit_ids.has(unit_id):
			return true

	return false


func _get_unit_key_from_generated_quest_id(quest_id: String) -> String:
	# QuestManager._make_generated_quest_id()
	# generated__%s__%s__%d
	# parts[0] = "generated"
	# parts[1] = unit_key
	# parts[2] = template_quest_id
	# parts[3] = index
	var parts: PackedStringArray = quest_id.split("__")
	if parts.size() < 4:
		return ""

	return String(parts[1])


func _erase_generated_quests_from_dictionary(target_dictionary: Dictionary) -> void:
	var erase_ids: Array[String] = []

	for quest_id_value in target_dictionary.keys():
		var quest_id: String = String(quest_id_value)
		if quest_id.begins_with("generated__"):
			erase_ids.append(quest_id)

	for quest_id in erase_ids:
		target_dictionary.erase(quest_id)


func reset_npc_trade_inventory_state() -> void:
	var reset_count: int = 0
	var protected_unit_ids: Dictionary = _collect_active_quest_unit_ids()

	for unit_id_value in unit_states.keys():
		var unit_id: String = String(unit_id_value)
		var state_value: Variant = unit_states.get(unit_id, {})

		# 受注中クエストを持つNPCは、商人在庫も含めてリセットしない。
		# クエストボード/会話側で参照するNPC状態を安定させるため。
		if protected_unit_ids.has(unit_id):
			continue

		if not _is_npc_or_merchant_unit_state(unit_id, state_value):
			continue

		if typeof(state_value) != TYPE_DICTIONARY:
			continue

		var state: Dictionary = (state_value as Dictionary).duplicate(true)

		# Inventoryだけ消す。
		# unit_states自体を消すと、NPCのHP/死亡状態/位置なども巻き込むので、
		# 売買内容のリセットとしては消しすぎになる。
		if state.has("inventory"):
			state.erase("inventory")
			unit_states[unit_id] = state
			reset_count += 1

	print("[WorldState] NPC trade inventory reset count=", reset_count)


func _is_npc_or_merchant_unit_state(unit_id: String, state_value: Variant) -> bool:
	if unit_id == "":
		return false

	if unit_id == "player":
		return false

	# UnitSpawnManager.make_npc_unit_id() は "%s_npc_%d" 形式。
	if unit_id.find("_npc_") != -1:
		return true

	if unit_id.begins_with("npc"):
		return true

	if typeof(state_value) != TYPE_DICTIONARY:
		return false

	var state: Dictionary = state_value
	var faction: String = String(state.get("faction", "")).strip_edges().to_upper()
	if faction == "NPC":
		return true

	return false


func _clear_dungeon_global_data() -> void:
	# ここでは実データを消さない。
	#
	# プレイヤーが FieldMap 表示中に月次リセット条件を満たした場合でも、
	# その場で field_dungeon_entrances / dungeon_data を消すと、
	# 画面上には古い入口が残っているのに内部データだけ消える。
	#
	# そのため、ここでは「次に FieldMap を読み込んだ時に再配置する」
	# 予約フラグだけを立てる。
	should_regenerate_field_dungeons = true
	print("[WorldState] field dungeon regeneration requested. It will run on next FieldMap load.")


func clear_field_dungeon_global_data_for_regeneration() -> void:
	# FieldMap を読み込んだ時にだけ呼ぶ。
	# ここで初めて古いダンジョン入口/ダンジョン本体データを消し、
	# FiledMap.gd 側で新しい入口を再配置する。
	dungeon_map_data.clear()
	dungeon_floor_data.clear()
	dungeon_data.clear()
	field_dungeon_entrances.clear()

	print("[WorldState] dungeon global data cleared for FieldMap regeneration.")
