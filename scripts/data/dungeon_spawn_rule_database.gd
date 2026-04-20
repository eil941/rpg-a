extends Node
class_name DungeonSpawnRuleDatabase

static func get_all_rules() -> Array[DungeonSpawnRuleData]:
	return [
		# ここに特殊ダンジョン用ルールを追加
		# preload("res://data/unit/dungeon_spawn_rule/dungeon_rule_fortified_floor_5.tres"),
	]


static func get_matching_rules(
	spawn_kind: String,
	generator_theme: String,
	layout_generator_type: String,
	floor_difficulty: int,
	floor_number: int
) -> Array[DungeonSpawnRuleData]:
	var results: Array[DungeonSpawnRuleData] = []
	var normalized_theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()
	var normalized_layout: String = String(layout_generator_type).strip_edges().replace("\"", "").to_upper()

	for rule in get_all_rules():
		if rule == null:
			continue
		if not rule.enabled:
			continue
		if rule.spawn_kind != spawn_kind:
			continue
		if not _is_rule_match(rule, normalized_theme, normalized_layout, floor_difficulty, floor_number):
			continue

		results.append(rule)

	return results


static func _is_rule_match(
	rule: DungeonSpawnRuleData,
	generator_theme: String,
	layout_generator_type: String,
	floor_difficulty: int,
	floor_number: int
) -> bool:
	if rule.allowed_generator_themes.size() > 0 and not rule.allowed_generator_themes.has(generator_theme):
		return false

	if rule.allowed_layout_generator_types.size() > 0 and not rule.allowed_layout_generator_types.has(layout_generator_type):
		return false

	if rule.min_floor_difficulty >= 0 and floor_difficulty < rule.min_floor_difficulty:
		return false

	if rule.max_floor_difficulty >= 0 and floor_difficulty > rule.max_floor_difficulty:
		return false

	if rule.min_floor_number >= 0 and floor_number < rule.min_floor_number:
		return false

	if rule.max_floor_number >= 0 and floor_number > rule.max_floor_number:
		return false

	return true
