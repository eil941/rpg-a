@tool
extends EditorScript

# 使い方:
# 1. まだ古い SpawnRuleDatabase.gd(preload版) の状態でこのスクリプトを実行する
# 2. res://data/master/unit_spawn_rules.tsv が生成される
# 3. 生成後に SpawnRuleDatabase.gd を spawnrule_database_tsv_only.gd に置き換える
#
# 注意:
# - get_all_rules() でコメントアウトされている .tres は出力されません。
# - 出力したいルールは、一度 get_all_rules() に含めてから実行してください。


const OUTPUT_PATH: String = "res://data/master/unit_spawn_rules.tsv"

const COLUMNS: Array[String] = [
	"rule_id",
	"spawn_kind",
	"allowed_generator_types",
	"min_area_difficulty",
	"max_area_difficulty",
	"min_enemy_difficulty",
	"max_enemy_difficulty",
	"use_hour_range",
	"start_hour",
	"end_hour",
	"min_distance_from_start",
	"max_distance_from_start",
	"max_spawn_count",
	"weight",
	"enabled",
]


func _run() -> void:
	var rules: Array[SpawnRuleData] = SpawnRuleDatabase.get_all_rules()
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open: " + OUTPUT_PATH)
		return

	file.store_line("\t".join(COLUMNS))

	var exported_count: int = 0
	var skipped_count: int = 0

	for raw_rule in rules:
		var rule: SpawnRuleData = raw_rule as SpawnRuleData
		if rule == null:
			skipped_count += 1
			continue

		var row: Dictionary = _rule_to_row(rule)
		var values: Array[String] = []

		for column in COLUMNS:
			values.append(_escape_cell(str(row.get(column, ""))))

		file.store_line("\t".join(values))
		exported_count += 1

	file.flush()
	file.close()

	print("[UnitSpawnRuleTSVExporter] source rules: ", rules.size())
	print("[UnitSpawnRuleTSVExporter] exported rows: ", exported_count)
	print("[UnitSpawnRuleTSVExporter] skipped rows: ", skipped_count)
	print("[UnitSpawnRuleTSVExporter] output: ", OUTPUT_PATH)


func _rule_to_row(rule: SpawnRuleData) -> Dictionary:
	return {
		"rule_id": rule.rule_id,
		"spawn_kind": rule.spawn_kind,
		"allowed_generator_types": _join_string_array(rule.allowed_generator_types),
		"min_area_difficulty": rule.min_area_difficulty,
		"max_area_difficulty": rule.max_area_difficulty,
		"min_enemy_difficulty": rule.min_enemy_difficulty,
		"max_enemy_difficulty": rule.max_enemy_difficulty,
		"use_hour_range": rule.use_hour_range,
		"start_hour": rule.start_hour,
		"end_hour": rule.end_hour,
		"min_distance_from_start": rule.min_distance_from_start,
		"max_distance_from_start": rule.max_distance_from_start,
		"max_spawn_count": rule.max_spawn_count,
		"weight": rule.weight,
		"enabled": rule.enabled
	}


func _join_string_array(values: Array) -> String:
	var result: Array[String] = []

	for value in values:
		result.append(str(value).strip_edges().replace("\"", "").to_upper())

	return "|".join(result)


func _escape_cell(value: String) -> String:
	return value.replace("\t", " ").replace("\r", "\\n").replace("\n", "\\n")
