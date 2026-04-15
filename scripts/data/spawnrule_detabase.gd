extends Node
class_name SpawnRuleDatabase

static func get_all_rules() -> Array[SpawnRuleData]:
	return [
		preload("res://data/unit/spawn_rule/spawn_rule_grass_easy.tres"),
		preload("res://data/unit/spawn_rule/spawn_rule_grass_hard.tres"),
		preload("res://data/unit/spawn_rule/spawn_rule_sand_enemy.tres"),
		preload("res://data/unit/spawn_rule/spawn_rule_forest_enemy.tres")
	]


static func get_matching_rules(
	spawn_kind: String,
	generator_type: String,
	area_difficulty: int,
	hour: int
) -> Array[SpawnRuleData]:
	var results: Array[SpawnRuleData] = []
	var normalized_generator_type: String = String(generator_type).strip_edges().replace("\"", "").to_upper()
	var rules: Array[SpawnRuleData] = get_all_rules()

	for rule in rules:
		if rule == null:
			continue
		if not rule.enabled:
			continue
		if rule.spawn_kind != spawn_kind:
			continue
		if not _is_rule_match(rule, normalized_generator_type, area_difficulty, hour):
			continue

		results.append(rule)

	return results


static func get_total_spawn_count(
	spawn_kind: String,
	generator_type: String,
	area_difficulty: int,
	hour: int
) -> int:
	var matching_rules: Array[SpawnRuleData] = get_matching_rules(
		spawn_kind,
		generator_type,
		area_difficulty,
		hour
	)

	var total: int = 0
	for rule in matching_rules:
		total += max(0, rule.max_spawn_count)

	return total


static func _is_rule_match(
	rule: SpawnRuleData,
	generator_type: String,
	area_difficulty: int,
	hour: int
) -> bool:
	if rule.allowed_generator_types.size() > 0 and not rule.allowed_generator_types.has(generator_type):
		return false

	if rule.min_area_difficulty >= 0 and area_difficulty < rule.min_area_difficulty:
		return false

	if rule.max_area_difficulty >= 0 and area_difficulty > rule.max_area_difficulty:
		return false

	if rule.use_hour_range and not _is_hour_in_range(hour, rule.start_hour, rule.end_hour):
		return false

	return true


static func _is_hour_in_range(hour: int, start_hour: int, end_hour: int) -> bool:
	if start_hour <= end_hour:
		return hour >= start_hour and hour <= end_hour
	return hour >= start_hour or hour <= end_hour
