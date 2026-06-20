extends RefCounted
class_name ItemSpawnRuleChildTableDatabase

const CATEGORY_MULTIPLIERS_TSV := "res://data/master/item_spawn_rule_category_multipliers.tsv"
const ITEM_OVERRIDES_TSV := "res://data/master/item_spawn_rule_item_overrides.tsv"

static var _loaded: bool = false
static var _category_multipliers_by_rule: Dictionary = {}
static var _item_weight_overrides_by_rule: Dictionary = {}


static func clear_cache() -> void:
	_loaded = false
	_category_multipliers_by_rule.clear()
	_item_weight_overrides_by_rule.clear()


static func has_category_multipliers(rule_id: String) -> bool:
	_ensure_loaded()
	return _category_multipliers_by_rule.has(rule_id)


static func get_category_multipliers(rule_id: String) -> Dictionary:
	_ensure_loaded()
	if not _category_multipliers_by_rule.has(rule_id):
		return {}
	var result: Dictionary = _category_multipliers_by_rule[rule_id]
	return result.duplicate()


static func has_item_weight_overrides(rule_id: String) -> bool:
	_ensure_loaded()
	return _item_weight_overrides_by_rule.has(rule_id)


static func get_item_weight_overrides(rule_id: String) -> Dictionary:
	_ensure_loaded()
	if not _item_weight_overrides_by_rule.has(rule_id):
		return {}
	var result: Dictionary = _item_weight_overrides_by_rule[rule_id]
	return result.duplicate()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_category_multipliers()
	_load_item_weight_overrides()


static func _load_category_multipliers() -> void:
	for row in _load_tsv_if_exists(CATEGORY_MULTIPLIERS_TSV):
		var rule_id := String(row.get("rule_id", "")).strip_edges()
		var category := String(row.get("category", "")).strip_edges()
		var multiplier_text := String(row.get("multiplier", "")).strip_edges()

		if rule_id == "" or category == "":
			continue

		if not _category_multipliers_by_rule.has(rule_id):
			_category_multipliers_by_rule[rule_id] = {}

		var normalized_category := ItemCategories.normalize(category)
		_category_multipliers_by_rule[rule_id][normalized_category] = _to_float(multiplier_text, 0.0)


static func _load_item_weight_overrides() -> void:
	for row in _load_tsv_if_exists(ITEM_OVERRIDES_TSV):
		var rule_id := String(row.get("rule_id", "")).strip_edges()
		var item_id := String(row.get("item_id", "")).strip_edges()
		var weight_text := String(row.get("weight", "")).strip_edges()

		if rule_id == "" or item_id == "":
			continue

		if not _item_weight_overrides_by_rule.has(rule_id):
			_item_weight_overrides_by_rule[rule_id] = {}

		_item_weight_overrides_by_rule[rule_id][item_id] = _to_int(weight_text, 0)


static func _load_tsv_if_exists(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []

	if file.eof_reached():
		return []

	var headers := file.get_line().split("\t", true)
	var rows: Array[Dictionary] = []

	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() == "":
			continue
		if line.begins_with("#"):
			continue

		var cols := line.split("\t", true)
		var row := {}
		for i in range(headers.size()):
			var key := String(headers[i]).strip_edges()
			var value := ""
			if i < cols.size():
				value = String(cols[i])
			row[key] = value
		rows.append(row)

	return rows


static func _to_float(value: String, default_value: float = 0.0) -> float:
	if value.strip_edges() == "":
		return default_value
	return float(value)


static func _to_int(value: String, default_value: int = 0) -> int:
	if value.strip_edges() == "":
		return default_value
	return int(value)
