extends RefCounted
class_name BountyManager

const STATE_ACTIVE: String = "active"
const STATE_DEFEATED: String = "defeated"
const STATE_EXPIRED: String = "expired"

const MIN_DURATION_DAYS: int = 3
const MAX_DURATION_DAYS: int = 7
const MIN_STAT_MULTIPLIER: float = 1.4
const MAX_STAT_MULTIPLIER: float = 2.0


static func ensure_active_bounty_for_map(
	map_id: String,
	enemy_data_list: Array[EnemyData],
	walkable_tiles: Array[Vector2i],
	used_tiles: Array[Vector2i]
) -> Dictionary:
	var normalized_map_id: String = map_id.strip_edges()
	if normalized_map_id == "":
		return {}

	expire_bounties()

	var existing: Dictionary = get_active_bounty_for_map(normalized_map_id)
	if not existing.is_empty():
		return existing

	var current_day: int = get_current_day()
	if _has_unexpired_bounty_for_map(normalized_map_id, current_day):
		return {}

	if not _is_bounty_eligible_map(normalized_map_id):
		return {}

	if enemy_data_list.is_empty() or walkable_tiles.is_empty():
		return {}

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var enemy_data: EnemyData = enemy_data_list[rng.randi_range(0, enemy_data_list.size() - 1)]
	if enemy_data == null:
		return {}

	var spawn_tile: Vector2i = _pick_spawn_tile(walkable_tiles, used_tiles, rng)
	if spawn_tile == Vector2i(999999, 999999):
		return {}

	var duration_days: int = rng.randi_range(MIN_DURATION_DAYS, MAX_DURATION_DAYS)
	var stat_multiplier: float = rng.randf_range(MIN_STAT_MULTIPLIER, MAX_STAT_MULTIPLIER)
	stat_multiplier = snappedf(stat_multiplier, 0.05)
	var reward_gold: int = _roll_reward_gold(enemy_data, stat_multiplier, rng)
	var bounty_id: String = _make_bounty_id(normalized_map_id, current_day, rng)

	var bounty: Dictionary = {
		"bounty_id": bounty_id,
		"enemy_type_id": enemy_data.enemy_type_id,
		"map_id": normalized_map_id,
		"spawn_position": {
			"x": spawn_tile.x,
			"y": spawn_tile.y
		},
		"start_day": current_day,
		"end_day": current_day + duration_days - 1,
		"reward_gold": reward_gold,
		"stat_multiplier": stat_multiplier,
		"state": STATE_ACTIVE,
		"is_defeated": false,
		"unit_id": make_bounty_unit_id(bounty_id)
	}

	WorldState.bounty_data[bounty_id] = bounty
	print("[BountyManager] generated bounty_id=", bounty_id, " map_id=", normalized_map_id, " enemy_type_id=", enemy_data.enemy_type_id)
	return bounty


static func get_active_bounty_for_map(map_id: String) -> Dictionary:
	var current_day: int = get_current_day()
	var normalized_map_id: String = map_id.strip_edges()

	for bounty_id in WorldState.bounty_data.keys():
		var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(bounty_id, {}))
		if bounty.is_empty():
			continue
		if String(bounty.get("map_id", "")) != normalized_map_id:
			continue
		if _is_bounty_active_on_day(bounty, current_day):
			return bounty.duplicate(true)

	return {}


static func get_active_bounties() -> Array[Dictionary]:
	expire_bounties()

	var result: Array[Dictionary] = []
	var current_day: int = get_current_day()

	for bounty_id in WorldState.bounty_data.keys():
		var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(bounty_id, {}))
		if bounty.is_empty():
			continue
		if _is_bounty_active_on_day(bounty, current_day):
			result.append(bounty.duplicate(true))

	return result


static func mark_bounty_defeated(bounty_id: String) -> Dictionary:
	var normalized_id: String = bounty_id.strip_edges()
	if normalized_id == "":
		return {}
	if not WorldState.bounty_data.has(normalized_id):
		return {}

	var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(normalized_id, {}))
	if bounty.is_empty():
		return {}

	bounty["state"] = STATE_DEFEATED
	bounty["is_defeated"] = true
	bounty["defeated_day"] = get_current_day()
	WorldState.bounty_data[normalized_id] = bounty

	print("[BountyManager] defeated bounty_id=", normalized_id)
	return bounty.duplicate(true)


static func expire_bounties() -> void:
	var current_day: int = get_current_day()

	for bounty_id in WorldState.bounty_data.keys():
		var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(bounty_id, {}))
		if bounty.is_empty():
			continue
		if String(bounty.get("state", STATE_ACTIVE)) != STATE_ACTIVE:
			continue
		if current_day <= int(bounty.get("end_day", current_day)):
			continue

		bounty["state"] = STATE_EXPIRED
		bounty["expired_day"] = current_day
		WorldState.bounty_data[bounty_id] = bounty

		var unit_id: String = String(bounty.get("unit_id", make_bounty_unit_id(String(bounty_id))))
		if unit_id != "":
			WorldState.unit_states.erase(unit_id)

		print("[BountyManager] expired bounty_id=", bounty_id)


static func expire_bounties_and_remove_runtime(tree: SceneTree) -> void:
	expire_bounties()
	if tree == null:
		return

	var current_day: int = get_current_day()
	for unit in tree.get_nodes_in_group("units"):
		if unit == null:
			continue
		if not _get_object_bool_property(unit, "is_bounty", false):
			continue

		var bounty_id: String = _get_object_string_property(unit, "bounty_id", "")
		if bounty_id == "":
			continue
		if not WorldState.bounty_data.has(bounty_id):
			continue

		var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(bounty_id, {}))
		if _is_bounty_active_on_day(bounty, current_day):
			continue

		unit.queue_free()


static func build_bounty_board_text() -> String:
	var active_bounties: Array[Dictionary] = get_active_bounties()
	if active_bounties.is_empty():
		return "現在発生中の賞金首はいません。"

	var lines: Array[String] = []
	lines.append("発生中の賞金首")

	var current_day: int = get_current_day()
	for bounty in active_bounties:
		var enemy_type_id: String = String(bounty.get("enemy_type_id", ""))
		var enemy_name: String = _format_bounty_display_name(_get_enemy_display_name(enemy_type_id))
		var map_id: String = String(bounty.get("map_id", ""))
		var remaining_days: int = max(0, int(bounty.get("end_day", current_day)) - current_day + 1)
		var reward_gold: int = int(bounty.get("reward_gold", 0))

		lines.append(
			"- %s / 場所: %s / 残り: %d日 / 報酬: gold x%d" %
			[enemy_name, map_id, remaining_days, reward_gold]
		)

	return "\n".join(lines)


static func make_bounty_unit_id(bounty_id: String) -> String:
	return "bounty_unit_" + _sanitize_id(bounty_id)


static func get_current_day() -> int:
	if TimeManager != null and TimeManager.has_method("get_day"):
		return int(TimeManager.get_day())
	return 1


static func _has_unexpired_bounty_for_map(map_id: String, current_day: int) -> bool:
	for bounty_id in WorldState.bounty_data.keys():
		var bounty: Dictionary = _as_dictionary(WorldState.bounty_data.get(bounty_id, {}))
		if bounty.is_empty():
			continue
		if String(bounty.get("map_id", "")) != map_id:
			continue
		if current_day <= int(bounty.get("end_day", current_day)):
			return true

	return false


static func _is_bounty_active_on_day(bounty: Dictionary, day: int) -> bool:
	if bounty.is_empty():
		return false
	if String(bounty.get("state", STATE_ACTIVE)) != STATE_ACTIVE:
		return false
	if bool(bounty.get("is_defeated", false)):
		return false
	return day >= int(bounty.get("start_day", day)) and day <= int(bounty.get("end_day", day))


static func _is_bounty_eligible_map(map_id: String) -> bool:
	if WorldState != null and WorldState.has_method("is_regenerable_map_id"):
		return bool(WorldState.is_regenerable_map_id(map_id))

	return map_id != "" and map_id != "FieldMap"


static func _pick_spawn_tile(
	walkable_tiles: Array[Vector2i],
	used_tiles: Array[Vector2i],
	rng: RandomNumberGenerator
) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for tile in walkable_tiles:
		if used_tiles.has(tile):
			continue
		candidates.append(tile)

	if candidates.is_empty():
		candidates = walkable_tiles.duplicate()

	if candidates.is_empty():
		return Vector2i(999999, 999999)

	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func _roll_reward_gold(enemy_data: EnemyData, stat_multiplier: float, rng: RandomNumberGenerator) -> int:
	var base_difficulty: int = 1
	var max_hp: int = 10
	if enemy_data != null:
		base_difficulty = max(1, int(enemy_data.base_difficulty))
		max_hp = max(1, int(enemy_data.max_hp))

	var base_reward: int = base_difficulty * 50 + max_hp * 2
	var multiplier_bonus: int = int(round(100.0 * stat_multiplier))
	var random_bonus: int = rng.randi_range(25, 125)
	return max(25, base_reward + multiplier_bonus + random_bonus)


static func _make_bounty_id(map_id: String, current_day: int, rng: RandomNumberGenerator) -> String:
	return "bounty_%s_day_%d_%d" % [
		_sanitize_id(map_id),
		current_day,
		rng.randi_range(1000, 9999)
	]


static func _sanitize_id(value: String) -> String:
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


static func _get_enemy_display_name(enemy_type_id: String) -> String:
	var enemy_data: EnemyData = EnemyDatabase.get_enemy(enemy_type_id)
	if enemy_data == null:
		return enemy_type_id
	if enemy_data.enemy_name != "":
		return enemy_data.enemy_name
	return enemy_type_id


static func _format_bounty_display_name(base_name: String) -> String:
	var display_name: String = base_name.strip_edges()
	if display_name.begins_with("賞金首: "):
		return display_name
	if display_name == "":
		display_name = "不明な敵"
	return "賞金首: " + display_name


static func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


static func _get_object_string_property(target: Object, property_name: String, fallback: String) -> String:
	if target == null:
		return fallback
	if not _object_has_property(target, property_name):
		return fallback
	return String(target.get(property_name)).strip_edges()


static func _get_object_bool_property(target: Object, property_name: String, fallback: bool) -> bool:
	if target == null:
		return fallback
	if not _object_has_property(target, property_name):
		return fallback
	return bool(target.get(property_name))


static func _object_has_property(target: Object, property_name: String) -> bool:
	if target == null:
		return false

	for info in target.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false
