extends Resource
class_name ItemSpawnRuleData

@export var rule_id: String = ""

# 基本ルールか特殊ルールか
@export var is_base_rule: bool = true

# 特殊ルール同士を重ねる時の優先度
@export var priority: int = 0

# "detail" / "dungeon"
@export var map_kind: String = ""

# ダンジョン用: "NATURAL" / "FORTIFIED" / "RUINED" / "ARTIFICIAL" / "CHAOTIC"
@export var generator_theme: String = ""

# 詳細マップ用: タイル custom data の detail_generator
@export var detail_generator: String = ""

# 特殊ルール用の適用条件
@export var difficulty_min: int = 0
@export var difficulty_max: int = 9999
@export var floor_min: int = 0
@export var floor_max: int = 9999
@export var final_floor_only: bool = false

# 生成個数の基本値
@export var base_item_count_min: int = 0
@export var base_item_count_max: int = 0

# 難易度による個数補正
@export var difficulty_item_count_scale: float = 0.0

# rarity 補正
@export_range(1.0, 10.0, 0.1) var base_rarity_target: float = 1.0
@export_range(0.0, 1.0, 0.001) var difficulty_rarity_scale: float = 0.03
@export_range(0.0, 10.0, 0.1) var final_floor_rarity_bonus: float = 0.0
@export_range(0.0, 5.0, 0.01) var rarity_step_penalty: float = 0.35

# 出現禁止
@export var blocked_categories: Array[String] = []
@export var blocked_item_ids: Array[String] = []

# カテゴリ補正
@export var category_multipliers: Dictionary = {}

# 個別アイテム重み上書き
@export var item_weight_overrides: Dictionary = {}

func matches_context(spawn_context: Dictionary) -> bool:
	var context_map_kind: String = String(spawn_context.get("map_kind", ""))
	var context_generator_theme: String = String(spawn_context.get("generator_theme", "")).strip_edges().to_upper()
	var context_detail_generator: String = String(spawn_context.get("detail_generator", "")).strip_edges().to_upper()
	var context_difficulty: int = int(spawn_context.get("difficulty", 0))
	var context_floor: int = int(spawn_context.get("floor", 0))
	var context_final_floor: bool = bool(spawn_context.get("is_final_floor", false))

	if map_kind != "" and map_kind != context_map_kind:
		return false

	if map_kind == "dungeon":
		var rule_theme: String = String(generator_theme).strip_edges().to_upper()
		if rule_theme != "" and rule_theme != context_generator_theme:
			return false

	if map_kind == "detail":
		var rule_detail_generator: String = String(detail_generator).strip_edges().to_upper()
		if rule_detail_generator != "" and rule_detail_generator != context_detail_generator:
			return false

	if context_difficulty < difficulty_min or context_difficulty > difficulty_max:
		return false

	if context_floor < floor_min or context_floor > floor_max:
		return false

	if final_floor_only and not context_final_floor:
		return false

	return true


func get_spawn_count(spawn_context: Dictionary, rng: RandomNumberGenerator) -> int:
	var min_count: int = max(base_item_count_min, 0)
	var max_count: int = max(base_item_count_max, min_count)

	var difficulty: int = int(spawn_context.get("difficulty", 0))
	if difficulty_item_count_scale > 0.0:
		var bonus: int = int(floor(float(difficulty) * difficulty_item_count_scale))
		min_count += bonus
		max_count += bonus

	max_count = max(max_count, min_count)
	return rng.randi_range(min_count, max_count)


func get_effective_rarity_target(spawn_context: Dictionary) -> float:
	var difficulty: int = int(spawn_context.get("difficulty", 0))
	var is_final_floor: bool = bool(spawn_context.get("is_final_floor", false))

	var result: float = base_rarity_target
	result += float(max(0, difficulty - 1)) * difficulty_rarity_scale

	if is_final_floor:
		result += final_floor_rarity_bonus

	return clampf(result, 1.0, 10.0)


func is_category_blocked(category: String) -> bool:
	var normalized: String = ItemCategories.normalize(category)

	for blocked in blocked_categories:
		if ItemCategories.normalize(String(blocked)) == normalized:
			return true

	return false


func is_item_blocked(item_id: String) -> bool:
	return blocked_item_ids.has(item_id)


func get_rarity_multiplier(rarity_value: int, spawn_context: Dictionary) -> float:
	var clamped_rarity: int = clampi(rarity_value, 1, 10)
	var target: float = get_effective_rarity_target(spawn_context)
	var distance: float = abs(float(clamped_rarity) - target)

	if rarity_step_penalty <= 0.0:
		return 1.0

	return 1.0 / (1.0 + distance * rarity_step_penalty)


func get_category_multiplier(category: String) -> float:
	var normalized: String = ItemCategories.normalize(category)

	for key in category_multipliers.keys():
		var key_text: String = ItemCategories.normalize(String(key))
		if key_text == normalized:
			return float(category_multipliers[key])

	return 1.0


func has_item_weight_override(item_id: String) -> bool:
	return item_weight_overrides.has(item_id)


func get_item_weight_override(item_id: String) -> int:
	if item_weight_overrides.has(item_id):
		return int(item_weight_overrides[item_id])
	return -1
