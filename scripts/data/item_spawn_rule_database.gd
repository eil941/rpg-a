extends Node
class_name ItemSpawnRuleDatabase

static var ITEM_SPAWN_RULES: Array[ItemSpawnRuleData] = [
	#preload("res://data/items/spawn_rules/natural_rule.tres"),
	#preload("res://data/items/spawn_rules/fortified_rule.tres"),
	#preload("res://data/items/spawn_rules/ruined_rule.tres"),
	#preload("res://data/items/spawn_rules/artificial_rule.tres"),
	#preload("res://data/items/spawn_rules/chaotic_rule.tres"),
	#preload("res://data/items/spawn_rules/detail_forest_rule.tres"),
	#preload("res://data/items/spawn_rules/detail_plains_rule.tres"),
	#preload("res://data/items/spawn_rules/detail_ruins_rule.tres"),
	#preload("res://data/items/spawn_rules/detail_cave_rule.tres"),
	#preload("res://data/items/spawn_rules/detail_default_rule.tres"),
	
	preload("res://data/items/spawn_rules/dungeon_default_rule.tres"),
	preload("res://data/items/spawn_rules/detail_default_rule.tres")
]

# =========================================
# デバッグ用レポート状態
# =========================================
static var _debug_report_active: bool = false
static var _debug_report_context: Dictionary = {}
static var _debug_report_expected_count: int = 0
static var _debug_report_generated_count: int = 0
static var _debug_report_expected_rarity_weights: Dictionary = {}
static var _debug_report_actual_rarity_counts: Dictionary = {}
static var _debug_report_expected_category_weights: Dictionary = {}
static var _debug_report_actual_category_counts: Dictionary = {}

static func get_matching_rule(spawn_context: Dictionary) -> ItemSpawnRuleData:
	var fallback_rule: ItemSpawnRuleData = null

	for rule in ITEM_SPAWN_RULES:
		if rule == null:
			continue

		if not rule.matches_context(spawn_context):
			continue

		if fallback_rule == null:
			fallback_rule = rule

		if bool(rule.is_base_rule):
			return rule

	return fallback_rule


static func get_spawn_count(spawn_context: Dictionary, rng: RandomNumberGenerator) -> int:
	var rule: ItemSpawnRuleData = get_matching_rule(spawn_context)
	if rule == null:
		if _is_debug_item_spawn_enabled():
			print("[ITEM SPAWN] rule not found. context=", str(spawn_context))
		return 0

	var count: int = rule.get_spawn_count(spawn_context, rng)

	if _is_debug_item_spawn_enabled():
		_prepare_debug_report(spawn_context, count)

		if count <= 0:
			print("[ITEM SPAWN] count=0")
			print("[ITEM SPAWN] context=", str(spawn_context))
			print("[ITEM SPAWN] rule=", rule.rule_id)

	return count


static func roll_item_entry(spawn_context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var rule: ItemSpawnRuleData = get_matching_rule(spawn_context)
	if rule == null:
		return {}

	var weighted_candidates: Array[Dictionary] = _build_weighted_candidates(rule, spawn_context)
	if weighted_candidates.is_empty():
		if _is_debug_item_spawn_enabled():
			print("[ITEM SPAWN] weighted candidates empty. context=", str(spawn_context))
		return {}

	if _is_debug_item_spawn_enabled():
		_ensure_debug_report_expected_weights(spawn_context, weighted_candidates)

	var chosen_item_id: String = _choose_weighted_item_id(weighted_candidates, rng)
	if chosen_item_id == "":
		return {}

	if _is_debug_item_spawn_enabled():
		_record_debug_spawn_result(chosen_item_id)

	return _build_inventory_entry(chosen_item_id, rng)


static func _build_weighted_candidates(rule: ItemSpawnRuleData, spawn_context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var all_item_ids: Array[String] = ItemDatabase.get_spawnable_item_ids()

	for item_id in all_item_ids:
		if item_id == "":
			continue

		var data = ItemDatabase.get_item_data(item_id)
		if data == null:
			continue

		if not (data is ItemData) and not (data is EquipmentData):
			continue

		var category: String = ItemDatabase.get_item_type(item_id)

		if rule.is_category_blocked(category):
			continue

		if rule.is_item_blocked(item_id):
			continue

		var final_weight: int = _calculate_final_weight(rule, spawn_context, item_id, data, category)
		if final_weight <= 0:
			continue

		result.append({
			"item_id": item_id,
			"category": category,
			"weight": final_weight
		})

	return result


static func _calculate_final_weight(
	rule: ItemSpawnRuleData,
	spawn_context: Dictionary,
	item_id: String,
	data,
	category: String
) -> int:
	var base_weight: int = 100
	var rarity_value: int = 1

	if data is ItemData:
		base_weight = data.get_spawn_weight_value()
		rarity_value = data.get_rarity_value()
	elif data is EquipmentData:
		if "spawn_weight" in data:
			base_weight = max(0, int(data.spawn_weight))
		if "rarity" in data:
			rarity_value = clampi(int(data.rarity), 1, 10)

	if base_weight <= 0:
		return 0

	var weight_value: float = float(base_weight)

	var rarity_multiplier: float = rule.get_rarity_multiplier(rarity_value, spawn_context)
	weight_value *= rarity_multiplier

	var category_multiplier: float = rule.get_category_multiplier(category)
	weight_value *= category_multiplier

	if rule.has_item_weight_override(item_id):
		var override_weight: int = rule.get_item_weight_override(item_id)
		if override_weight <= 0:
			return 0
		weight_value = float(override_weight)

	return max(0, int(round(weight_value)))


static func _choose_weighted_item_id(weighted_candidates: Array[Dictionary], rng: RandomNumberGenerator) -> String:
	var total_weight: int = 0

	for entry in weighted_candidates:
		var weight: int = int(entry.get("weight", 0))
		if weight > 0:
			total_weight += weight

	if total_weight <= 0:
		return ""

	var roll: int = rng.randi_range(1, total_weight)
	var accum: int = 0

	for entry in weighted_candidates:
		var weight: int = int(entry.get("weight", 0))
		if weight <= 0:
			continue

		accum += weight
		if roll <= accum:
			return String(entry.get("item_id", ""))

	return ""


static func _build_inventory_entry(item_id: String, rng: RandomNumberGenerator) -> Dictionary:
	if item_id == "":
		return {}

	var equipment_resource: EquipmentData = ItemDatabase.get_equipment_resource(item_id)
	if equipment_resource != null:
		return ItemDatabase.build_random_equipment_entry(item_id, rng)

	return {
		"item_id": item_id,
		"amount": 1
	}

# =========================================
# デバッグ
# =========================================
static func _is_debug_item_spawn_enabled() -> bool:
	return DebugSettings != null and bool(DebugSettings.debug_item_spawn)


static func _prepare_debug_report(spawn_context: Dictionary, expected_count: int) -> void:
	_debug_report_active = true
	_debug_report_context = spawn_context.duplicate(true)
	_debug_report_expected_count = max(0, expected_count)
	_debug_report_generated_count = 0
	_debug_report_expected_rarity_weights = {}
	_debug_report_actual_rarity_counts = {}
	_debug_report_expected_category_weights = {}
	_debug_report_actual_category_counts = {}

	for rarity_value in range(1, 11):
		_debug_report_expected_rarity_weights[rarity_value] = 0
		_debug_report_actual_rarity_counts[rarity_value] = 0


static func _ensure_debug_report_expected_weights(spawn_context: Dictionary, weighted_candidates: Array[Dictionary]) -> void:
	if not _debug_report_active:
		return

	if _debug_report_context != spawn_context:
		return

	var has_any_weight: bool = false
	for rarity_value in range(1, 11):
		if int(_debug_report_expected_rarity_weights.get(rarity_value, 0)) > 0:
			has_any_weight = true
			break

	if has_any_weight:
		return

	for entry in weighted_candidates:
		var item_id: String = String(entry.get("item_id", ""))
		var category: String = String(entry.get("category", ""))
		var weight: int = int(entry.get("weight", 0))
		if item_id == "" or weight <= 0:
			continue

		var rarity_value: int = clampi(ItemDatabase.get_rarity(item_id), 1, 10)
		_debug_report_expected_rarity_weights[rarity_value] = int(_debug_report_expected_rarity_weights.get(rarity_value, 0)) + weight

		var normalized_category: String = ItemCategories.normalize(category)
		_debug_report_expected_category_weights[normalized_category] = int(_debug_report_expected_category_weights.get(normalized_category, 0)) + weight

	_print_debug_expected_report()


static func _record_debug_spawn_result(item_id: String) -> void:
	if not _debug_report_active:
		return

	var rarity_value: int = clampi(ItemDatabase.get_rarity(item_id), 1, 10)
	_debug_report_actual_rarity_counts[rarity_value] = int(_debug_report_actual_rarity_counts.get(rarity_value, 0)) + 1

	var category: String = ItemCategories.normalize(ItemDatabase.get_item_type(item_id))
	_debug_report_actual_category_counts[category] = int(_debug_report_actual_category_counts.get(category, 0)) + 1

	_debug_report_generated_count += 1

	if _debug_report_generated_count >= _debug_report_expected_count:
		_print_debug_actual_report()
		_clear_debug_report()


static func _print_debug_expected_report() -> void:
	var total_weight: int = 0
	for rarity_value in range(1, 11):
		total_weight += int(_debug_report_expected_rarity_weights.get(rarity_value, 0))

	print("========================================")
	print("[ITEM SPAWN] EXPECTED REPORT")
	print("[ITEM SPAWN] map_kind=", String(_debug_report_context.get("map_kind", "")),
		" generator_theme=", String(_debug_report_context.get("generator_theme", "")),
		" detail_generator=", String(_debug_report_context.get("detail_generator", "")),
		" difficulty=", int(_debug_report_context.get("difficulty", 0)),
		" floor=", int(_debug_report_context.get("floor", 0)),
		" is_final_floor=", bool(_debug_report_context.get("is_final_floor", false)))
	print("[ITEM SPAWN] expected item count=", _debug_report_expected_count)

	if total_weight <= 0:
		print("[ITEM SPAWN] total weight = 0")
		return

	print("[ITEM SPAWN] ---- rarity probability ----")
	for rarity_value in range(1, 11):
		var rarity_weight: int = int(_debug_report_expected_rarity_weights.get(rarity_value, 0))
		var probability_percent: float = (float(rarity_weight) / float(total_weight)) * 100.0
		print("[ITEM SPAWN] rarity=", rarity_value,
			" weight=", rarity_weight,
			" probability=", snappedf(probability_percent, 0.01), "%")

	print("[ITEM SPAWN] ---- category probability ----")
	for category in _debug_report_expected_category_weights.keys():
		var category_weight: int = int(_debug_report_expected_category_weights.get(category, 0))
		var category_probability_percent: float = (float(category_weight) / float(total_weight)) * 100.0
		print("[ITEM SPAWN] category=", String(category),
			" weight=", category_weight,
			" probability=", snappedf(category_probability_percent, 0.01), "%")


static func _print_debug_actual_report() -> void:
	print("[ITEM SPAWN] ACTUAL RESULT")
	print("[ITEM SPAWN] generated item count=", _debug_report_generated_count)

	print("[ITEM SPAWN] ---- rarity actual counts ----")
	for rarity_value in range(1, 11):
		var actual_count: int = int(_debug_report_actual_rarity_counts.get(rarity_value, 0))
		print("[ITEM SPAWN] rarity=", rarity_value, " actual_count=", actual_count)

	print("[ITEM SPAWN] ---- category actual counts ----")
	for category in _debug_report_actual_category_counts.keys():
		var actual_category_count: int = int(_debug_report_actual_category_counts.get(category, 0))
		print("[ITEM SPAWN] category=", String(category), " actual_count=", actual_category_count)

	print("========================================")


static func _clear_debug_report() -> void:
	_debug_report_active = false
	_debug_report_context = {}
	_debug_report_expected_count = 0
	_debug_report_generated_count = 0
	_debug_report_expected_rarity_weights = {}
	_debug_report_actual_rarity_counts = {}
	_debug_report_expected_category_weights = {}
	_debug_report_actual_category_counts = {}
