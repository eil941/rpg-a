@tool
extends EditorScript

# 使い方:
# 1. まだ古い DungeonSpawnRuleDatabase.gd(preload版) の状態でこのスクリプトを実行する
# 2. res://data/master/dungeon_spawn_rules.tsv が生成される
# 3. 生成後に DungeonSpawnRuleDatabase.gd を dungeon_spawn_rule_database_tsv_only.gd に置き換える
#
# 現状 get_all_rules() が空なら、ヘッダーだけのTSVが生成されます。
# それでも正常です。


const OUTPUT_PATH: String = "res://data/master/dungeon_spawn_rules.tsv"

const COLUMNS: Array[String] = [
	"rule_id",
	"spawn_kind",
	"allowed_generator_themes",
	"allowed_layout_generator_types",
	"min_floor_difficulty",
	"max_floor_difficulty",
	"min_floor_number",
	"max_floor_number",
	"min_enemy_difficulty",
	"max_enemy_difficulty",
	"max_spawn_count",
	"weight",
	"enabled",
]


func _run() -> void:
	var rules: Array[DungeonSpawnRuleData] = DungeonSpawnRuleDatabase.get_all_rules()
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open: " + OUTPUT_PATH)
		return

	file.store_line("\t".join(COLUMNS))

	var exported_count: int = 0
	var skipped_count: int = 0

	for raw_rule in rules:
		var rule: DungeonSpawnRuleData = raw_rule as DungeonSpawnRuleData
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

	print("[DungeonSpawnRuleTSVExporter] source rules: ", rules.size())
	print("[DungeonSpawnRuleTSVExporter] exported rows: ", exported_count)
	print("[DungeonSpawnRuleTSVExporter] skipped rows: ", skipped_count)
	print("[DungeonSpawnRuleTSVExporter] output: ", OUTPUT_PATH)


func _rule_to_row(rule: DungeonSpawnRuleData) -> Dictionary:
	return {
		"rule_id": rule.rule_id,
		"spawn_kind": rule.spawn_kind,
		"allowed_generator_themes": _join_string_array(rule.allowed_generator_themes),
		"allowed_layout_generator_types": _join_string_array(rule.allowed_layout_generator_types),
		"min_floor_difficulty": rule.min_floor_difficulty,
		"max_floor_difficulty": rule.max_floor_difficulty,
		"min_floor_number": rule.min_floor_number,
		"max_floor_number": rule.max_floor_number,
		"min_enemy_difficulty": rule.min_enemy_difficulty,
		"max_enemy_difficulty": rule.max_enemy_difficulty,
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
