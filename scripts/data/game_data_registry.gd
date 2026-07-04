extends Node

const DEFAULT_ITEM_CATEGORY_ID: String = "misc"
const DEFAULT_UNIT_RACE_ID: String = "UNKNOWN"
const DEFAULT_UNIT_FACTION_ID: String = "NEUTRAL"
const DEFAULT_FACTION_RELATION: String = "NEUTRAL"
const DEFAULT_ELEMENT_TYPE_ID: String = "neutral"
const DEFAULT_DAMAGE_TYPE_ID: String = "physical"
const BUILTIN_ITEM_CATEGORY_FALLBACKS: Array[Dictionary] = [
	{
		"category_id": "material",
		"display_name": "素材",
		"sort_order": 10,
		"show_in_inventory": true,
		"default_usable": false,
		"default_can_sell": true,
		"default_max_stack": 99,
		"description": "クラフトや収集に使う素材カテゴリ。"
	},
	{
		"category_id": "consumable",
		"display_name": "消耗品",
		"sort_order": 20,
		"show_in_inventory": true,
		"default_usable": true,
		"default_can_sell": true,
		"default_max_stack": 99,
		"description": "使用すると効果を発揮する消耗品カテゴリ。"
	},
	{
		"category_id": "equipment",
		"display_name": "装備品",
		"sort_order": 30,
		"show_in_inventory": true,
		"default_usable": false,
		"default_can_sell": true,
		"default_max_stack": 1,
		"description": "武器、防具、アクセサリなどの装備カテゴリ。"
	},
	{
		"category_id": "misc",
		"display_name": "その他",
		"sort_order": 900,
		"show_in_inventory": true,
		"default_usable": false,
		"default_can_sell": true,
		"default_max_stack": 99,
		"description": "他のカテゴリに当てはまらない汎用カテゴリ。"
	}
]
const BUILTIN_UNIT_RACE_FALLBACKS: Array[Dictionary] = [
	{
		"race_id": "UNKNOWN",
		"display_name": "不明",
		"sort_order": 0,
		"description": "未設定または未定義の種族"
	}
]
const BUILTIN_UNIT_FACTION_FALLBACKS: Array[Dictionary] = [
	{
		"faction_id": "PLAYER",
		"display_name": "プレイヤー",
		"sort_order": 10,
		"description": "プレイヤー陣営"
	},
	{
		"faction_id": "NPC",
		"display_name": "NPC",
		"sort_order": 20,
		"description": "既存NPC陣営"
	},
	{
		"faction_id": "ENEMY",
		"display_name": "敵",
		"sort_order": 30,
		"description": "既存敵陣営"
	},
	{
		"faction_id": "NEUTRAL",
		"display_name": "中立",
		"sort_order": 40,
		"description": "中立陣営"
	}
]
const BUILTIN_FACTION_RELATION_FALLBACKS: Array[Dictionary] = [
	{"from_faction": "PLAYER", "to_faction": "PLAYER", "relation": "FRIENDLY"},
	{"from_faction": "PLAYER", "to_faction": "NPC", "relation": "FRIENDLY"},
	{"from_faction": "PLAYER", "to_faction": "ENEMY", "relation": "HOSTILE"},
	{"from_faction": "PLAYER", "to_faction": "NEUTRAL", "relation": "NEUTRAL"},
	{"from_faction": "NPC", "to_faction": "PLAYER", "relation": "FRIENDLY"},
	{"from_faction": "NPC", "to_faction": "NPC", "relation": "FRIENDLY"},
	{"from_faction": "NPC", "to_faction": "ENEMY", "relation": "HOSTILE"},
	{"from_faction": "NPC", "to_faction": "NEUTRAL", "relation": "NEUTRAL"},
	{"from_faction": "ENEMY", "to_faction": "PLAYER", "relation": "HOSTILE"},
	{"from_faction": "ENEMY", "to_faction": "NPC", "relation": "HOSTILE"},
	{"from_faction": "ENEMY", "to_faction": "ENEMY", "relation": "FRIENDLY"},
	{"from_faction": "ENEMY", "to_faction": "NEUTRAL", "relation": "NEUTRAL"},
	{"from_faction": "NEUTRAL", "to_faction": "PLAYER", "relation": "NEUTRAL"},
	{"from_faction": "NEUTRAL", "to_faction": "NPC", "relation": "NEUTRAL"},
	{"from_faction": "NEUTRAL", "to_faction": "ENEMY", "relation": "NEUTRAL"},
	{"from_faction": "NEUTRAL", "to_faction": "NEUTRAL", "relation": "FRIENDLY"}
]
const BUILTIN_ELEMENT_TYPE_FALLBACKS: Array[Dictionary] = [
	{
		"element_id": "neutral",
		"display_name": "無",
		"sort_order": 0,
		"description": "通常属性または属性なし"
	}
]
const BUILTIN_DAMAGE_TYPE_FALLBACKS: Array[Dictionary] = [
	{
		"damage_type_id": "physical",
		"display_name": "physical",
		"sort_order": 10,
		"description": "Default physical damage classification"
	}
]
const BUILTIN_STATUS_EFFECT_TYPE_FALLBACKS: Array[Dictionary] = [
	{
		"status_id": "poison",
		"display_name": "毒",
		"sort_order": 10,
		"category": "debuff",
		"default_duration": 10.0,
		"stackable": false,
		"description": "継続ダメージを与える状態異常"
	},
	{
		"status_id": "paralysis",
		"display_name": "麻痺",
		"sort_order": 20,
		"category": "debuff",
		"default_duration": 5.0,
		"stackable": false,
		"description": "行動不能になる状態異常"
	},
	{
		"status_id": "burning",
		"display_name": "火傷",
		"sort_order": 30,
		"category": "debuff",
		"default_duration": 10.0,
		"stackable": false,
		"description": "火傷による継続ダメージ"
	},
	{
		"status_id": "frostbite",
		"display_name": "凍傷",
		"sort_order": 40,
		"category": "debuff",
		"default_duration": 10.0,
		"stackable": false,
		"description": "凍傷による継続ダメージ"
	},
	{
		"status_id": "sleep",
		"display_name": "睡眠",
		"sort_order": 50,
		"category": "debuff",
		"default_duration": 5.0,
		"stackable": false,
		"description": "眠って行動不能になる状態異常"
	},
	{
		"status_id": "confusion",
		"display_name": "混乱",
		"sort_order": 60,
		"category": "debuff",
		"default_duration": 5.0,
		"stackable": false,
		"description": "行動が乱れる状態異常"
	},
	{
		"status_id": "blind",
		"display_name": "暗闇",
		"sort_order": 70,
		"category": "debuff",
		"default_duration": 8.0,
		"stackable": false,
		"description": "命中や視界に影響する状態異常"
	},
	{
		"status_id": "hallucination",
		"display_name": "幻覚",
		"sort_order": 80,
		"category": "debuff",
		"default_duration": 8.0,
		"stackable": false,
		"description": "視覚や認識に影響する状態異常"
	},
	{
		"status_id": "curse",
		"display_name": "呪い",
		"sort_order": 90,
		"category": "debuff",
		"default_duration": 10.0,
		"stackable": false,
		"description": "呪い状態"
	}
]

var item_categories: Dictionary = {}
var _item_category_ids_from_tsv: Dictionary = {}
var unit_races: Dictionary = {}
var unit_factions: Dictionary = {}
var faction_relations: Dictionary = {}
var element_types: Dictionary = {}
var damage_types: Dictionary = {}
var status_effect_types: Dictionary = {}
var localization_texts: Dictionary = {}
var dialogue_sets: Dictionary = {}
var dialogue_lines_by_set: Dictionary = {}
var skills: Dictionary = {}
var skill_levels_by_skill: Dictionary = {}
var skill_effect_links_by_skill: Dictionary = {}
var skill_requirements_by_skill: Dictionary = {}
var unit_skill_tables: Dictionary = {}
var unit_skill_entries_by_table: Dictionary = {}
var chest_tables: Dictionary = {}
var chest_loot_tables: Dictionary = {}
var shop_tables: Dictionary = {}
var shop_loot_tables: Dictionary = {}
var initial_inventory_tables: Dictionary = {}
var initial_inventory_entries: Dictionary = {}
var items: Dictionary = {}
var effects: Dictionary = {}
var quests: Dictionary = {}
var enemies: Dictionary = {}
var npcs: Dictionary = {}
var enchantments: Dictionary = {}
var dungeon_spawn_rules: Dictionary = {}
var unit_spawn_rules: Dictionary = {}
var npc_quest_links: Array[Dictionary] = []
var npc_quest_links_by_npc: Dictionary = {}

var item_effect_links: Dictionary = {}

var item_spawn_rules: Array[ItemSpawnRuleData] = []
var item_spawn_rule_category_multipliers: Dictionary = {}
var item_spawn_rule_item_overrides: Dictionary = {}
var _warned_unknown_item_categories: Dictionary = {}
var _warned_unknown_unit_races: Dictionary = {}
var _warned_unknown_unit_factions: Dictionary = {}
var _warned_missing_faction_relations: Dictionary = {}
var _warned_unknown_element_types: Dictionary = {}
var _warned_unknown_damage_types: Dictionary = {}
var _warned_unknown_status_effect_types: Dictionary = {}


func _ready() -> void:
	load_all()
	validate_all()


func load_all() -> void:
	item_categories.clear()
	_item_category_ids_from_tsv.clear()
	unit_races.clear()
	unit_factions.clear()
	faction_relations.clear()
	element_types.clear()
	damage_types.clear()
	status_effect_types.clear()
	localization_texts.clear()
	dialogue_sets.clear()
	dialogue_lines_by_set.clear()
	skills.clear()
	skill_levels_by_skill.clear()
	skill_effect_links_by_skill.clear()
	skill_requirements_by_skill.clear()
	unit_skill_tables.clear()
	unit_skill_entries_by_table.clear()
	chest_tables.clear()
	chest_loot_tables.clear()
	shop_tables.clear()
	shop_loot_tables.clear()
	initial_inventory_tables.clear()
	initial_inventory_entries.clear()
	items.clear()
	effects.clear()
	quests.clear()
	enemies.clear()
	npcs.clear()
	enchantments.clear()
	item_effect_links.clear()
	npc_quest_links.clear()
	npc_quest_links_by_npc.clear()
	item_spawn_rules.clear()
	item_spawn_rule_category_multipliers.clear()
	item_spawn_rule_item_overrides.clear()
	dungeon_spawn_rules.clear()
	unit_spawn_rules.clear()
	_warned_unknown_item_categories.clear()
	_warned_unknown_unit_races.clear()
	_warned_unknown_unit_factions.clear()
	_warned_missing_faction_relations.clear()
	_warned_unknown_element_types.clear()
	_warned_unknown_damage_types.clear()
	_warned_unknown_status_effect_types.clear()

	_load_item_categories()
	_load_status_effect_types()
	_load_element_types()
	_load_damage_types()
	_load_localization_texts()
	_load_dialogue_sets()
	_load_dialogue_lines()
	_load_skills()
	_load_skill_levels()
	_load_items()
	_load_equipment()
	_load_chest_tables()
	_load_chest_loot_tables()
	_load_shop_tables()
	_load_shop_loot_tables()
	_load_initial_inventory_tables()
	_load_initial_inventory_entries()
	_load_item_effects()
	_load_item_effect_links()
	_apply_item_effect_links()
	_load_skill_effect_links()
	_load_enchantments()
	_load_dungeon_spawn_rules()
	_load_unit_spawn_rules()
	_load_unit_races()
	_load_unit_factions()
	_load_faction_relations()
	_load_unit_skill_tables()
	_load_unit_skill_entries()
	_load_enemies()
	_load_npcs()
	_load_quests()
	_load_npc_quest_links()
	_load_skill_requirements()
	_load_item_spawn_rule_category_multipliers()
	_load_item_spawn_rule_item_overrides()
	_load_item_spawn_rules()


	# 確認したいときだけ有効化
	debug_print_loaded_data()

func get_item(item_id: String):
	return items.get(item_id)


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func get_all_items() -> Array:
	return items.values()


func get_item_category(category_id: String) -> Dictionary:
	var normalized_id := _normalize_item_category_id(category_id)
	if normalized_id == "":
		normalized_id = DEFAULT_ITEM_CATEGORY_ID

	if item_categories.has(normalized_id):
		return item_categories[normalized_id].duplicate(true)

	_warn_unknown_item_category(category_id, "get_item_category")

	if item_categories.has(DEFAULT_ITEM_CATEGORY_ID):
		return item_categories[DEFAULT_ITEM_CATEGORY_ID].duplicate(true)

	return _make_item_category_entry(
		DEFAULT_ITEM_CATEGORY_ID,
		"その他",
		900,
		true,
		false,
		true,
		99,
		"他のカテゴリに当てはまらない汎用カテゴリ。"
	)


func get_all_item_categories() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for category in item_categories.values():
		if typeof(category) != TYPE_DICTIONARY:
			continue

		result.append(category.duplicate(true))

	result.sort_custom(Callable(self, "_sort_item_category_entries"))
	return result


func has_item_category(category_id: String) -> bool:
	var normalized_id := _normalize_item_category_id(category_id)
	if normalized_id == "":
		return false

	return item_categories.has(normalized_id)


func get_unit_race(race_id: String) -> Dictionary:
	var normalized_id := _normalize_unit_race_id(race_id)
	if normalized_id == "":
		normalized_id = DEFAULT_UNIT_RACE_ID

	if unit_races.has(normalized_id):
		return unit_races[normalized_id].duplicate(true)

	_warn_unknown_unit_race(race_id, "get_unit_race")

	if unit_races.has(DEFAULT_UNIT_RACE_ID):
		return unit_races[DEFAULT_UNIT_RACE_ID].duplicate(true)

	return _make_unit_race_entry(
		DEFAULT_UNIT_RACE_ID,
		"不明",
		0,
		"未設定または未定義の種族"
	)


func get_all_unit_races() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for race in unit_races.values():
		if typeof(race) != TYPE_DICTIONARY:
			continue

		result.append(race.duplicate(true))

	result.sort_custom(Callable(self, "_sort_unit_race_entries"))
	return result


func has_unit_race(race_id: String) -> bool:
	var normalized_id := _normalize_unit_race_id(race_id)
	if normalized_id == "":
		return false

	return unit_races.has(normalized_id)


func get_unit_faction(faction_id: String) -> Dictionary:
	var normalized_id := _normalize_unit_faction_id(faction_id)
	if normalized_id == "":
		normalized_id = DEFAULT_UNIT_FACTION_ID

	if unit_factions.has(normalized_id):
		return unit_factions[normalized_id].duplicate(true)

	_warn_unknown_unit_faction(faction_id, "get_unit_faction")

	if unit_factions.has(DEFAULT_UNIT_FACTION_ID):
		return unit_factions[DEFAULT_UNIT_FACTION_ID].duplicate(true)

	return _make_unit_faction_entry(
		DEFAULT_UNIT_FACTION_ID,
		"中立",
		40,
		"中立陣営"
	)


func get_all_unit_factions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for faction in unit_factions.values():
		if typeof(faction) != TYPE_DICTIONARY:
			continue

		result.append(faction.duplicate(true))

	result.sort_custom(Callable(self, "_sort_unit_faction_entries"))
	return result


func has_unit_faction(faction_id: String) -> bool:
	var normalized_id := _normalize_unit_faction_id(faction_id)
	if normalized_id == "":
		return false

	return unit_factions.has(normalized_id)


func get_element_type(element_id: String) -> Dictionary:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		normalized_id = DEFAULT_ELEMENT_TYPE_ID

	if element_types.has(normalized_id):
		return element_types[normalized_id].duplicate(true)

	_warn_unknown_element_type(element_id, "get_element_type")

	if element_types.has(DEFAULT_ELEMENT_TYPE_ID):
		return element_types[DEFAULT_ELEMENT_TYPE_ID].duplicate(true)

	return _make_element_type_entry(
		DEFAULT_ELEMENT_TYPE_ID,
		"無",
		0,
		"通常属性または属性なし"
	)


func get_all_element_types() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for element in element_types.values():
		if typeof(element) != TYPE_DICTIONARY:
			continue

		result.append(element.duplicate(true))

	result.sort_custom(Callable(self, "_sort_element_type_entries"))
	return result


func has_element_type(element_id: String) -> bool:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		return false

	return element_types.has(normalized_id)


func get_element_display_name(element_id: String) -> String:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		return ""

	if not has_element_type(normalized_id):
		_warn_unknown_element_type(element_id, "get_element_display_name")
		return normalized_id

	var element_type: Dictionary = get_element_type(normalized_id)
	var display_name := String(element_type.get("display_name", "")).strip_edges()
	if display_name != "":
		return display_name

	return normalized_id


func get_element_description(element_id: String) -> String:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		return ""

	if not has_element_type(normalized_id):
		_warn_unknown_element_type(element_id, "get_element_description")
		return ""

	var element_type: Dictionary = get_element_type(normalized_id)
	return String(element_type.get("description", ""))


func get_damage_type(damage_type_id: String) -> Dictionary:
	var normalized_id := _normalize_damage_type_id(damage_type_id)
	if normalized_id == "":
		normalized_id = DEFAULT_DAMAGE_TYPE_ID

	if damage_types.has(normalized_id):
		return damage_types[normalized_id].duplicate(true)

	_warn_unknown_damage_type(damage_type_id, "get_damage_type")

	if damage_types.has(DEFAULT_DAMAGE_TYPE_ID):
		return damage_types[DEFAULT_DAMAGE_TYPE_ID].duplicate(true)

	return _make_damage_type_entry(
		DEFAULT_DAMAGE_TYPE_ID,
		DEFAULT_DAMAGE_TYPE_ID,
		10,
		"Default physical damage classification"
	)


func get_all_damage_types() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for damage_type in damage_types.values():
		if typeof(damage_type) != TYPE_DICTIONARY:
			continue

		result.append(damage_type.duplicate(true))

	result.sort_custom(Callable(self, "_sort_damage_type_entries"))
	return result


func has_damage_type(damage_type_id: String) -> bool:
	var normalized_id := _normalize_damage_type_id(damage_type_id)
	if normalized_id == "":
		return false

	return damage_types.has(normalized_id)


func get_status_effect_type(status_id: String) -> Dictionary:
	var normalized_id := _normalize_status_effect_id(status_id)
	if status_effect_types.has(normalized_id):
		return status_effect_types[normalized_id].duplicate(true)

	_warn_unknown_status_effect_type(status_id, "get_status_effect_type")

	return _make_status_effect_type_entry(
		normalized_id,
		normalized_id,
		9999,
		"neutral",
		0.0,
		false,
		""
	)


func get_all_status_effect_types() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for status_effect in status_effect_types.values():
		if typeof(status_effect) != TYPE_DICTIONARY:
			continue

		result.append(status_effect.duplicate(true))

	result.sort_custom(Callable(self, "_sort_status_effect_type_entries"))
	return result


func has_status_effect_type(status_id: String) -> bool:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		return false

	return status_effect_types.has(normalized_id)


func get_status_effect_display_name(status_id: String) -> String:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		return ""

	var status_effect := get_status_effect_type(normalized_id)
	var display_name := String(status_effect.get("display_name", "")).strip_edges()
	if display_name != "":
		return display_name

	return normalized_id


func get_status_effect_description(status_id: String) -> String:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		return ""

	var status_effect := get_status_effect_type(normalized_id)
	return String(status_effect.get("description", ""))


func get_status_effect_category(status_id: String) -> String:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		return "neutral"

	var status_effect := get_status_effect_type(normalized_id)
	return _normalize_status_effect_category(String(status_effect.get("category", "neutral")))


func get_localized_text(text_key: String, locale: String = "ja", fallback: String = "") -> String:
	var normalized_key := text_key.strip_edges()
	if normalized_key == "":
		return fallback

	var entry_value: Variant = localization_texts.get(normalized_key, {})
	if typeof(entry_value) != TYPE_DICTIONARY:
		return fallback

	var entry: Dictionary = entry_value
	var normalized_locale := locale.strip_edges().to_lower()
	if normalized_locale == "":
		normalized_locale = "ja"

	var localized_text := String(entry.get(normalized_locale, ""))
	if localized_text.strip_edges() != "":
		return localized_text

	var ja_text := String(entry.get("ja", ""))
	if ja_text.strip_edges() != "":
		return ja_text

	return fallback


func has_localized_text(text_key: String) -> bool:
	var normalized_key := text_key.strip_edges()
	if normalized_key == "":
		return false

	return localization_texts.has(normalized_key)


func get_all_localization_texts() -> Dictionary:
	return localization_texts.duplicate(true)


func has_dialogue_set(dialogue_set_id: String) -> bool:
	var normalized_id := dialogue_set_id.strip_edges()
	if normalized_id == "":
		return false

	return dialogue_sets.has(normalized_id)


func get_dialogue_set(dialogue_set_id: String) -> Dictionary:
	var normalized_id := dialogue_set_id.strip_edges()
	if normalized_id == "":
		return {}

	var set_value: Variant = dialogue_sets.get(normalized_id, {})
	if typeof(set_value) != TYPE_DICTIONARY:
		return {}

	var set_entry: Dictionary = set_value
	return set_entry.duplicate(true)


func get_dialogue_lines(dialogue_set_id: String, context: String = "") -> Array[Dictionary]:
	var normalized_id := dialogue_set_id.strip_edges()
	if normalized_id == "":
		return []

	if not has_dialogue_set(normalized_id):
		return []

	var entries_value: Variant = dialogue_lines_by_set.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var normalized_context: String = context.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		if normalized_context != "" and String(entry.get("context", "")).strip_edges().to_lower() != normalized_context:
			continue

		result.append(entry.duplicate(true))

	return result


func get_dialogue_line_text_keys(dialogue_set_id: String, context: String = "") -> Array[String]:
	var result: Array[String] = []

	for line in get_dialogue_lines(dialogue_set_id, context):
		var text_key: String = String(line.get("text_key", "")).strip_edges()
		if text_key == "":
			continue

		result.append(text_key)

	return result


func get_random_dialogue_text(
	dialogue_set_id: String,
	context: String = "greeting",
	locale: String = "ja",
	fallback: String = ""
) -> String:
	var lines: Array[Dictionary] = get_dialogue_lines(dialogue_set_id, context)
	if lines.is_empty():
		return fallback

	var total_weight: float = 0.0
	for line in lines:
		var weight: float = max(0.0, float(line.get("weight", 0.0)))
		total_weight += weight

	if total_weight <= 0.0:
		return fallback

	var roll: float = randf() * total_weight
	var cursor: float = 0.0
	for line in lines:
		var weight: float = max(0.0, float(line.get("weight", 0.0)))
		if weight <= 0.0:
			continue

		cursor += weight
		if roll <= cursor:
			var text_key: String = String(line.get("text_key", "")).strip_edges()
			return get_localized_text(text_key, locale, fallback)

	var last_line: Dictionary = lines[lines.size() - 1]
	var last_text_key: String = String(last_line.get("text_key", "")).strip_edges()
	return get_localized_text(last_text_key, locale, fallback)


func has_skill(skill_id: String) -> bool:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "":
		return false

	return skills.has(normalized_id)


func get_skill(skill_id: String) -> Dictionary:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "":
		return {}

	var skill_value: Variant = skills.get(normalized_id, {})
	if typeof(skill_value) != TYPE_DICTIONARY:
		return {}

	var skill: Dictionary = skill_value
	return skill.duplicate(true)


func get_all_skills() -> Dictionary:
	return skills.duplicate(true)


func get_skill_level(skill_id: String, level: int) -> Dictionary:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "" or level < 1:
		return {}

	var level_map_value: Variant = skill_levels_by_skill.get(normalized_id, {})
	if typeof(level_map_value) != TYPE_DICTIONARY:
		return {}

	var level_map: Dictionary = level_map_value
	var level_value: Variant = level_map.get(level, {})
	if typeof(level_value) != TYPE_DICTIONARY:
		return {}

	var level_entry: Dictionary = level_value
	return level_entry.duplicate(true)


func get_skill_exp_to_next(skill_id: String, level: int) -> int:
	var level_entry: Dictionary = get_skill_level(skill_id, level)
	if level_entry.is_empty():
		return 0

	return maxi(0, int(level_entry.get("exp_to_next", 0)))


func get_skill_levels(skill_id: String) -> Array[Dictionary]:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "":
		return []

	var level_map_value: Variant = skill_levels_by_skill.get(normalized_id, {})
	if typeof(level_map_value) != TYPE_DICTIONARY:
		return []

	var result: Array[Dictionary] = []
	var level_map: Dictionary = level_map_value
	for level_value in level_map.values():
		if typeof(level_value) != TYPE_DICTIONARY:
			continue

		var level_entry: Dictionary = level_value
		result.append(level_entry.duplicate(true))

	result.sort_custom(Callable(self, "_sort_skill_level_entries"))
	return result


func get_skill_effect_links(skill_id: String, level: int = 0, trigger: String = "") -> Array[Dictionary]:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "":
		return []

	var entries_value: Variant = skill_effect_links_by_skill.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var normalized_trigger: String = trigger.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		if level > 0:
			var min_level: int = int(entry.get("min_level", 1))
			var max_level: int = int(entry.get("max_level", min_level))
			if level < min_level or level > max_level:
				continue

		if normalized_trigger != "" and String(entry.get("trigger", "")).strip_edges().to_lower() != normalized_trigger:
			continue

		result.append(entry.duplicate(true))

	result.sort_custom(Callable(self, "_sort_ordered_entries"))
	return result


func get_skill_requirements(skill_id: String, requirement_kind: String = "") -> Array[Dictionary]:
	var normalized_id: String = skill_id.strip_edges()
	if normalized_id == "":
		return []

	var entries_value: Variant = skill_requirements_by_skill.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var normalized_kind: String = requirement_kind.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		if normalized_kind != "" and String(entry.get("requirement_kind", "")).strip_edges().to_lower() != normalized_kind:
			continue

		result.append(entry.duplicate(true))

	return result


func has_unit_skill_table(skill_table_id: String) -> bool:
	var normalized_id: String = skill_table_id.strip_edges()
	if normalized_id == "":
		return false

	return unit_skill_tables.has(normalized_id)


func get_unit_skill_table(skill_table_id: String) -> Dictionary:
	var normalized_id: String = skill_table_id.strip_edges()
	if normalized_id == "":
		return {}

	var table_value: Variant = unit_skill_tables.get(normalized_id, {})
	if typeof(table_value) != TYPE_DICTIONARY:
		return {}

	var table: Dictionary = table_value
	return table.duplicate(true)


func get_unit_skill_entries(skill_table_id: String) -> Array[Dictionary]:
	var normalized_id: String = skill_table_id.strip_edges()
	if normalized_id == "":
		return []

	var entries_value: Variant = unit_skill_entries_by_table.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		result.append(entry.duplicate(true))

	return result


func build_initial_dynamic_skills(skill_table_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var normalized_id: String = skill_table_id.strip_edges()
	if normalized_id == "":
		return {}

	if not has_unit_skill_table(normalized_id):
		return {}

	var local_rng: RandomNumberGenerator = rng
	if local_rng == null:
		local_rng = RandomNumberGenerator.new()
		local_rng.randomize()

	var result: Dictionary = {}
	var entries: Array[Dictionary] = get_unit_skill_entries(normalized_id)
	for entry in entries:
		if not bool(entry.get("enabled", true)):
			continue

		var chance_percent: float = clampf(float(entry.get("chance_percent", 100.0)), 0.0, 100.0)
		if chance_percent <= 0.0:
			continue

		if chance_percent < 100.0:
			var chance_roll: float = local_rng.randf() * 100.0
			if chance_roll > chance_percent:
				continue

		var resolved_skill_id: String = _resolve_unit_skill_entry_skill_id(entry, local_rng)
		if resolved_skill_id == "":
			continue

		var dynamic_entry: Dictionary = _build_dynamic_skill_entry(resolved_skill_id, entry, local_rng)
		_merge_dynamic_skill_entry(result, dynamic_entry)

	return result


func _resolve_unit_skill_entry_skill_id(entry: Dictionary, rng: RandomNumberGenerator) -> String:
	var pick_type: String = String(entry.get("pick_type", "SKILL")).strip_edges().to_upper()
	if pick_type == "SKILL":
		var skill_id: String = String(entry.get("skill_id", "")).strip_edges()
		if skill_id == "" or not has_skill(skill_id):
			return ""
		return skill_id

	if pick_type == "CATEGORY":
		var skill_category: String = String(entry.get("skill_category", "")).strip_edges().to_lower()
		return _pick_skill_id_by_category(skill_category, rng)

	push_warning("unit_skill_entries unknown pick_type at runtime: " + pick_type)
	return ""


func _pick_skill_id_by_category(skill_category: String, rng: RandomNumberGenerator) -> String:
	var normalized_category: String = _normalize_skill_category(skill_category, "unit_skill_entries skill_category")
	if normalized_category == "":
		return ""

	var candidates: Array[Dictionary] = []
	var total_weight: float = 0.0
	for skill_value in skills.values():
		if typeof(skill_value) != TYPE_DICTIONARY:
			continue

		var skill: Dictionary = skill_value
		if String(skill.get("category", "")).strip_edges().to_lower() != normalized_category:
			continue

		var skill_id: String = String(skill.get("skill_id", "")).strip_edges()
		if skill_id == "":
			continue

		var weight: float = maxf(0.0, float(skill.get("weight", 1.0)))
		if weight <= 0.0:
			continue

		candidates.append({
			"skill_id": skill_id,
			"weight": weight
		})
		total_weight += weight

	if candidates.is_empty() or total_weight <= 0.0:
		push_warning("unit_skill_entries CATEGORY has no enabled skills: " + normalized_category)
		return ""

	var roll: float = rng.randf() * total_weight
	var cursor: float = 0.0
	for candidate in candidates:
		var weight: float = maxf(0.0, float(candidate.get("weight", 0.0)))
		if weight <= 0.0:
			continue

		cursor += weight
		if roll <= cursor:
			return String(candidate.get("skill_id", "")).strip_edges()

	var last_candidate: Dictionary = candidates[candidates.size() - 1]
	return String(last_candidate.get("skill_id", "")).strip_edges()


func _build_dynamic_skill_entry(skill_id: String, entry: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var learned: bool = bool(entry.get("learned", false))
	var level_min: int = maxi(0, int(entry.get("level_min", 0)))
	var level_max: int = maxi(level_min, int(entry.get("level_max", level_min)))
	var level: int = 0

	if learned:
		level_min = maxi(1, level_min)
		var skill: Dictionary = get_skill(skill_id)
		var skill_max_level: int = maxi(1, int(skill.get("max_level", level_max)))
		level_max = mini(maxi(level_min, level_max), skill_max_level)
		if level_max > level_min:
			level = rng.randi_range(level_min, level_max)
		else:
			level = level_min

	var exp_min: int = maxi(0, int(entry.get("exp_min", 0)))
	var exp_max: int = maxi(exp_min, int(entry.get("exp_max", exp_min)))
	var exp: int = exp_min
	if exp_max > exp_min:
		exp = rng.randi_range(exp_min, exp_max)

	return {
		"skill_id": skill_id,
		"learned": learned,
		"value": level,
		"growth": exp
	}


func _merge_dynamic_skill_entry(dynamic_skill_map: Dictionary, new_entry: Dictionary) -> void:
	var skill_id: String = String(new_entry.get("skill_id", "")).strip_edges()
	if skill_id == "":
		return

	if not dynamic_skill_map.has(skill_id):
		dynamic_skill_map[skill_id] = new_entry.duplicate(true)
		return

	var existing_value: Variant = dynamic_skill_map.get(skill_id, {})
	if typeof(existing_value) != TYPE_DICTIONARY:
		dynamic_skill_map[skill_id] = new_entry.duplicate(true)
		return

	var existing_entry: Dictionary = existing_value
	if _is_better_dynamic_skill_entry(new_entry, existing_entry):
		dynamic_skill_map[skill_id] = new_entry.duplicate(true)


func _is_better_dynamic_skill_entry(new_entry: Dictionary, existing_entry: Dictionary) -> bool:
	var new_learned: bool = bool(new_entry.get("learned", false))
	var existing_learned: bool = bool(existing_entry.get("learned", false))
	if new_learned != existing_learned:
		return new_learned

	var new_level: int = int(new_entry.get("value", 0))
	var existing_level: int = int(existing_entry.get("value", 0))
	if new_level != existing_level:
		return new_level > existing_level

	var new_exp: int = int(new_entry.get("growth", 0))
	var existing_exp: int = int(existing_entry.get("growth", 0))
	return new_exp > existing_exp


func get_faction_relation(from_faction: String, to_faction: String) -> String:
	var from_id := _normalize_loaded_unit_faction(from_faction, "faction_relations.tsv from_faction")
	var to_id := _normalize_loaded_unit_faction(to_faction, "faction_relations.tsv to_faction")

	var row_value: Variant = faction_relations.get(from_id, {})
	if typeof(row_value) != TYPE_DICTIONARY:
		_warn_missing_faction_relation(from_id, to_id)
		return DEFAULT_FACTION_RELATION

	var row: Dictionary = row_value
	var relation := _normalize_faction_relation_text(String(row.get(to_id, "")))
	if relation == "":
		_warn_missing_faction_relation(from_id, to_id)
		return DEFAULT_FACTION_RELATION

	return relation


func get_all_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []

	for quest in quests.values():
		result.append(quest)

	return result


func get_quest(quest_id: String) -> QuestData:
	return quests.get(quest_id, null) as QuestData


func has_quest(quest_id: String) -> bool:
	return quests.has(quest_id)


func get_enemy(enemy_type_id: String) -> EnemyData:
	return enemies.get(enemy_type_id, null) as EnemyData


func has_enemy(enemy_type_id: String) -> bool:
	return enemies.has(enemy_type_id)


func get_all_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	for enemy in enemies.values():
		var enemy_data := enemy as EnemyData
		if enemy_data == null:
			continue
		result.append(enemy_data)

	return result


func get_npc(npc_type_id: String) -> NpcData:
	return npcs.get(npc_type_id, null) as NpcData


func has_npc(npc_type_id: String) -> bool:
	return npcs.has(npc_type_id)


func get_all_npcs() -> Array[NpcData]:
	var result: Array[NpcData] = []

	for npc in npcs.values():
		var npc_data := npc as NpcData
		if npc_data == null:
			continue
		result.append(npc_data)

	return result


func get_enchantment(enchant_id: String) -> EnchantmentData:
	return enchantments.get(enchant_id, null) as EnchantmentData


func has_enchantment(enchant_id: String) -> bool:
	return enchantments.has(enchant_id)


func get_all_enchantments() -> Array[EnchantmentData]:
	var result: Array[EnchantmentData] = []

	for enchantment in enchantments.values():
		var enchantment_data := enchantment as EnchantmentData
		if enchantment_data == null:
			continue
		result.append(enchantment_data)

	return result


func get_chest_table(chest_id: String) -> Dictionary:
	var normalized_id := _normalize_chest_id(chest_id)
	if normalized_id == "":
		return {}

	var table_value: Variant = chest_tables.get(normalized_id, {})
	if typeof(table_value) != TYPE_DICTIONARY:
		return {}

	var table: Dictionary = table_value
	return table.duplicate(true)


func has_chest_table(chest_id: String) -> bool:
	var normalized_id := _normalize_chest_id(chest_id)
	if normalized_id == "":
		return false

	return chest_tables.has(normalized_id)


func get_all_chest_tables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for table_value in chest_tables.values():
		if typeof(table_value) != TYPE_DICTIONARY:
			continue

		var table: Dictionary = table_value
		result.append(table.duplicate(true))

	result.sort_custom(Callable(self, "_sort_chest_table_entries"))
	return result


func get_chest_loot_entries(loot_table_id: String) -> Array[Dictionary]:
	var normalized_id := _normalize_chest_id(loot_table_id)
	if normalized_id == "":
		return []

	var entries_value: Variant = chest_loot_tables.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		result.append(entry.duplicate(true))

	return result


func get_shop_table(shop_table_id: String) -> Dictionary:
	var normalized_id := _normalize_shop_id(shop_table_id)
	if normalized_id == "":
		return {}

	var table_value: Variant = shop_tables.get(normalized_id, {})
	if typeof(table_value) != TYPE_DICTIONARY:
		return {}

	var table: Dictionary = table_value
	return table.duplicate(true)


func has_shop_table(shop_table_id: String) -> bool:
	var normalized_id := _normalize_shop_id(shop_table_id)
	if normalized_id == "":
		return false

	return shop_tables.has(normalized_id)


func get_all_shop_tables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for table_value in shop_tables.values():
		if typeof(table_value) != TYPE_DICTIONARY:
			continue

		var table: Dictionary = table_value
		result.append(table.duplicate(true))

	result.sort_custom(Callable(self, "_sort_shop_table_entries"))
	return result


func get_shop_loot_entries(loot_table_id: String) -> Array[Dictionary]:
	var normalized_id := _normalize_shop_id(loot_table_id)
	if normalized_id == "":
		return []

	var entries_value: Variant = shop_loot_tables.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		result.append(entry.duplicate(true))

	return result


func get_initial_inventory_table(inventory_table_id: String) -> Dictionary:
	var normalized_id := _normalize_inventory_table_id(inventory_table_id)
	if normalized_id == "":
		return {}

	var table_value: Variant = initial_inventory_tables.get(normalized_id, {})
	if typeof(table_value) != TYPE_DICTIONARY:
		return {}

	var table: Dictionary = table_value
	return table.duplicate(true)


func has_initial_inventory_table(inventory_table_id: String) -> bool:
	var normalized_id := _normalize_inventory_table_id(inventory_table_id)
	if normalized_id == "":
		return false

	return initial_inventory_tables.has(normalized_id)


func get_all_initial_inventory_tables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for table_value in initial_inventory_tables.values():
		if typeof(table_value) != TYPE_DICTIONARY:
			continue

		var table: Dictionary = table_value
		result.append(table.duplicate(true))

	result.sort_custom(Callable(self, "_sort_initial_inventory_table_entries"))
	return result


func get_initial_inventory_entries(inventory_table_id: String) -> Array[InitialInventoryEntry]:
	var normalized_id := _normalize_inventory_table_id(inventory_table_id)
	if normalized_id == "":
		return []

	var entries_value: Variant = initial_inventory_entries.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[InitialInventoryEntry] = []
	var entries: Array = entries_value
	for entry_value in entries:
		var entry := entry_value as InitialInventoryEntry
		if entry == null:
			continue

		result.append(entry.duplicate(true) as InitialInventoryEntry)

	return result


func get_npc_quest_links(npc_type_id: String) -> Array[Dictionary]:
	var normalized_id := npc_type_id.strip_edges()
	if normalized_id == "":
		return []

	var entries_value: Variant = npc_quest_links_by_npc.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		return []

	var result: Array[Dictionary] = []
	var entries: Array = entries_value
	for entry_value in entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_value
		result.append(entry.duplicate(true))

	return result


func has_npc_quest_links(npc_type_id: String) -> bool:
	return not get_npc_quest_links(npc_type_id).is_empty()


func get_all_npc_quest_links() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in npc_quest_links:
		result.append(entry.duplicate(true))

	return result


func get_unit_spawn_rule(rule_id: String) -> SpawnRuleData:
	return unit_spawn_rules.get(rule_id, null) as SpawnRuleData


func has_unit_spawn_rule(rule_id: String) -> bool:
	return unit_spawn_rules.has(rule_id)


func get_all_unit_spawn_rules() -> Array[SpawnRuleData]:
	var result: Array[SpawnRuleData] = []

	for rule in unit_spawn_rules.values():
		var rule_data := rule as SpawnRuleData
		if rule_data == null:
			continue
		result.append(rule_data)

	return result


func get_dungeon_spawn_rule(rule_id: String) -> DungeonSpawnRuleData:
	return dungeon_spawn_rules.get(rule_id, null) as DungeonSpawnRuleData


func has_dungeon_spawn_rule(rule_id: String) -> bool:
	return dungeon_spawn_rules.has(rule_id)


func get_all_dungeon_spawn_rules() -> Array[DungeonSpawnRuleData]:
	var result: Array[DungeonSpawnRuleData] = []

	for rule in dungeon_spawn_rules.values():
		var rule_data := rule as DungeonSpawnRuleData
		if rule_data == null:
			continue
		result.append(rule_data)

	return result


func get_all_item_spawn_rules() -> Array[ItemSpawnRuleData]:
	return item_spawn_rules.duplicate()


func get_item_spawn_rule(rule_id: String) -> ItemSpawnRuleData:
	for rule in item_spawn_rules:
		if rule == null:
			continue
		if rule.rule_id == rule_id:
			return rule

	return null


func has_item_spawn_rule(rule_id: String) -> bool:
	return get_item_spawn_rule(rule_id) != null


func get_item_spawn_rule_category_multipliers(rule_id: String) -> Dictionary:
	var normalized_id := _normalize_item_spawn_rule_id(rule_id)
	if normalized_id == "":
		return {}

	var entries_value: Variant = item_spawn_rule_category_multipliers.get(normalized_id, {})
	if typeof(entries_value) != TYPE_DICTIONARY:
		return {}

	var entries: Dictionary = entries_value
	return entries.duplicate(true)


func get_item_spawn_rule_item_overrides(rule_id: String) -> Dictionary:
	var normalized_id := _normalize_item_spawn_rule_id(rule_id)
	if normalized_id == "":
		return {}

	var entries_value: Variant = item_spawn_rule_item_overrides.get(normalized_id, {})
	if typeof(entries_value) != TYPE_DICTIONARY:
		return {}

	var entries: Dictionary = entries_value
	return entries.duplicate(true)


# ============================================================
# TSV読み込み
# ============================================================

func _load_tsv(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("TSV not found: " + path)
		return []

	if file.eof_reached():
		return []

	var header_line := file.get_line()
	var headers := header_line.split("\t", true)

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


func _load_optional_tsv(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []

	return _load_tsv(path)

# ============================================================
# 型変換
# ============================================================

func _get_string(row: Dictionary, key: String, default_value: String = "") -> String:
	return String(row.get(key, default_value))


func _append_dictionary_array_entry(target: Dictionary, key: String, entry: Dictionary) -> void:
	if not target.has(key):
		target[key] = []

	var entries_value: Variant = target.get(key, [])
	if typeof(entries_value) != TYPE_ARRAY:
		target[key] = []
		entries_value = target[key]

	var entries: Array = entries_value
	entries.append(entry)


func _to_bool(value: String) -> bool:
	var text := value.strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"


func _to_int(value: String, default_value: int = 0) -> int:
	if value.strip_edges() == "":
		return default_value

	return int(value)


func _to_float(value: String, default_value: float = 0.0) -> float:
	if value.strip_edges() == "":
		return default_value

	return float(value)


func _split_list(value: String) -> Array[String]:
	var result: Array[String] = []
	value = value.strip_edges()

	if value == "":
		return result

	for part in value.split("|", false):
		var text := String(part).strip_edges()

		if text != "":
			result.append(text)

	return result


func _split_int_list(value: String) -> Array[int]:
	var result: Array[int] = []

	for text in _split_list(value):
		result.append(int(text))

	return result


func _split_float_dict(value: String) -> Dictionary:
	var result: Dictionary = {}
	value = value.strip_edges()

	if value == "":
		return result

	for entry in value.split("|", false):
		var entry_text := String(entry).strip_edges()
		if entry_text == "":
			continue

		var parts := entry_text.split("=", true)
		if parts.size() < 2:
			continue

		var key := String(parts[0]).strip_edges()
		var number_text := String(parts[1]).strip_edges()
		if key == "":
			continue

		result[key] = _to_float(number_text, 0.0)

	return result


func _split_int_dict(value: String) -> Dictionary:
	var result: Dictionary = {}
	value = value.strip_edges()

	if value == "":
		return result

	for entry in value.split("|", false):
		var entry_text := String(entry).strip_edges()
		if entry_text == "":
			continue

		var parts := entry_text.split("=", true)
		if parts.size() < 2:
			continue

		var key := String(parts[0]).strip_edges()
		var number_text := String(parts[1]).strip_edges()
		if key == "":
			continue

		result[key] = _to_int(number_text, 0)

	return result


func _load_resource_or_null(path: String):
	path = path.strip_edges()

	if path == "":
		return null

	var resource = load(path)
	if resource == null:
		push_warning("resource load failed: " + path)

	return resource


func _normalize_item_category_id(category_id: String) -> String:
	return category_id.strip_edges().to_lower()


func _normalize_unit_race_id(race_id: String) -> String:
	return race_id.strip_edges().to_upper()


func _normalize_unit_faction_id(faction_id: String) -> String:
	return faction_id.strip_edges().to_upper()


func _normalize_element_type_id(element_id: String) -> String:
	return element_id.strip_edges().to_lower()


func _normalize_damage_type_id(damage_type_id: String) -> String:
	return damage_type_id.strip_edges().to_lower()


func _normalize_status_effect_id(status_id: String) -> String:
	return status_id.strip_edges()


func _normalize_chest_id(chest_id: String) -> String:
	return chest_id.strip_edges()


func _normalize_shop_id(shop_id: String) -> String:
	return shop_id.strip_edges()


func _normalize_inventory_table_id(inventory_table_id: String) -> String:
	return inventory_table_id.strip_edges()


func _normalize_item_spawn_rule_id(rule_id: String) -> String:
	return rule_id.strip_edges()


func _normalize_faction_relation_text(relation: String) -> String:
	var normalized := relation.strip_edges().to_upper()
	match normalized:
		"FRIENDLY", "NEUTRAL", "HOSTILE":
			return normalized
		_:
			return ""


func _normalize_status_effect_category(category: String) -> String:
	var normalized := category.strip_edges().to_lower()
	match normalized:
		"buff", "debuff", "neutral":
			return normalized
		_:
			return "neutral"


func _sort_item_category_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("category_id", "")) < String(b.get("category_id", ""))

	return order_a < order_b


func _sort_unit_race_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("race_id", "")) < String(b.get("race_id", ""))

	return order_a < order_b


func _sort_unit_faction_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("faction_id", "")) < String(b.get("faction_id", ""))

	return order_a < order_b


func _sort_element_type_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("element_id", "")) < String(b.get("element_id", ""))

	return order_a < order_b


func _sort_damage_type_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("damage_type_id", "")) < String(b.get("damage_type_id", ""))

	return order_a < order_b


func _sort_status_effect_type_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("sort_order", 0))
	var order_b := int(b.get("sort_order", 0))

	if order_a == order_b:
		return String(a.get("status_id", "")) < String(b.get("status_id", ""))

	return order_a < order_b


func _sort_skill_level_entries(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("level", 0)) < int(b.get("level", 0))


func _sort_ordered_entries(a: Dictionary, b: Dictionary) -> bool:
	var order_a := int(a.get("order", 0))
	var order_b := int(b.get("order", 0))

	if order_a == order_b:
		return String(a.get("entry_id", a.get("effect_id", ""))) < String(b.get("entry_id", b.get("effect_id", "")))

	return order_a < order_b


func _sort_chest_table_entries(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("chest_id", "")) < String(b.get("chest_id", ""))


func _sort_shop_table_entries(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("shop_table_id", "")) < String(b.get("shop_table_id", ""))


func _sort_initial_inventory_table_entries(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("inventory_table_id", "")) < String(b.get("inventory_table_id", ""))


func _make_item_category_entry(
	category_id: String,
	display_name: String,
	sort_order: int,
	show_in_inventory: bool,
	default_usable: bool,
	default_can_sell: bool,
	default_max_stack: int,
	description: String
) -> Dictionary:
	return {
		"category_id": category_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"show_in_inventory": show_in_inventory,
		"default_usable": default_usable,
		"default_can_sell": default_can_sell,
		"default_max_stack": default_max_stack,
		"description": description
	}


func _make_unit_race_entry(
	race_id: String,
	display_name: String,
	sort_order: int,
	description: String
) -> Dictionary:
	return {
		"race_id": race_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"description": description
	}


func _make_unit_faction_entry(
	faction_id: String,
	display_name: String,
	sort_order: int,
	description: String
) -> Dictionary:
	return {
		"faction_id": faction_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"description": description
	}


func _make_element_type_entry(
	element_id: String,
	display_name: String,
	sort_order: int,
	description: String
) -> Dictionary:
	return {
		"element_id": element_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"description": description
	}


func _make_damage_type_entry(
	damage_type_id: String,
	display_name: String,
	sort_order: int,
	description: String
) -> Dictionary:
	return {
		"damage_type_id": damage_type_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"description": description
	}


func _make_status_effect_type_entry(
	status_id: String,
	display_name: String,
	sort_order: int,
	category: String,
	default_duration: float,
	stackable: bool,
	description: String
) -> Dictionary:
	return {
		"status_id": status_id,
		"display_name": display_name,
		"sort_order": sort_order,
		"category": _normalize_status_effect_category(category),
		"default_duration": default_duration,
		"stackable": stackable,
		"description": description
	}


func _make_chest_table_entry(
	chest_id: String,
	display_name: String,
	slot_count: int,
	min_items: int,
	max_items: int,
	gold_min: int,
	gold_max: int,
	loot_table_id: String,
	description: String
) -> Dictionary:
	return {
		"chest_id": chest_id,
		"display_name": display_name,
		"slot_count": slot_count,
		"min_items": min_items,
		"max_items": max_items,
		"gold_min": gold_min,
		"gold_max": gold_max,
		"loot_table_id": loot_table_id,
		"description": description
	}


func _make_chest_loot_entry(
	loot_table_id: String,
	category: String,
	item_id: String,
	weight: int,
	min_amount: int,
	max_amount: int
) -> Dictionary:
	return {
		"loot_table_id": loot_table_id,
		"category": category,
		"item_id": item_id,
		"weight": weight,
		"min_amount": min_amount,
		"max_amount": max_amount
	}


func _make_shop_table_entry(
	shop_table_id: String,
	display_name: String,
	min_items: int,
	max_items: int,
	loot_table_id: String,
	description: String
) -> Dictionary:
	return {
		"shop_table_id": shop_table_id,
		"display_name": display_name,
		"min_items": min_items,
		"max_items": max_items,
		"loot_table_id": loot_table_id,
		"description": description
	}


func _make_shop_loot_entry(
	loot_table_id: String,
	category: String,
	item_id: String,
	weight: int,
	min_amount: int,
	max_amount: int
) -> Dictionary:
	return {
		"loot_table_id": loot_table_id,
		"category": category,
		"item_id": item_id,
		"weight": weight,
		"min_amount": min_amount,
		"max_amount": max_amount
	}


func _make_initial_inventory_table_entry(
	inventory_table_id: String,
	display_name: String,
	description: String
) -> Dictionary:
	return {
		"inventory_table_id": inventory_table_id,
		"display_name": display_name,
		"description": description
	}


func _register_item_category(category: Dictionary, from_tsv: bool = false) -> void:
	var category_id := _normalize_item_category_id(String(category.get("category_id", "")))
	if category_id == "":
		push_warning("item category_id is empty")
		return

	if item_categories.has(category_id):
		push_warning("duplicate item category_id: " + category_id)
		return

	var entry := category.duplicate(true)
	entry["category_id"] = category_id
	item_categories[category_id] = entry

	if from_tsv:
		_item_category_ids_from_tsv[category_id] = true


func _register_unit_race(race: Dictionary) -> void:
	var race_id := _normalize_unit_race_id(String(race.get("race_id", "")))
	if race_id == "":
		push_warning("unit race_id is empty")
		return

	if unit_races.has(race_id):
		push_warning("duplicate unit race_id: " + race_id)
		return

	var entry := race.duplicate(true)
	entry["race_id"] = race_id
	unit_races[race_id] = entry


func _register_unit_faction(faction: Dictionary) -> void:
	var faction_id := _normalize_unit_faction_id(String(faction.get("faction_id", "")))
	if faction_id == "":
		push_warning("unit faction_id is empty")
		return

	if unit_factions.has(faction_id):
		push_warning("duplicate unit faction_id: " + faction_id)
		return

	var entry := faction.duplicate(true)
	entry["faction_id"] = faction_id
	unit_factions[faction_id] = entry


func _register_element_type(element: Dictionary) -> void:
	var element_id := _normalize_element_type_id(String(element.get("element_id", "")))
	if element_id == "":
		push_warning("element_id is empty")
		return

	if element_types.has(element_id):
		push_warning("duplicate element_id: " + element_id)
		return

	var entry := element.duplicate(true)
	entry["element_id"] = element_id
	element_types[element_id] = entry


func _register_damage_type(damage_type: Dictionary) -> void:
	var damage_type_id := _normalize_damage_type_id(String(damage_type.get("damage_type_id", "")))
	if damage_type_id == "":
		push_warning("damage_type_id is empty")
		return

	if damage_types.has(damage_type_id):
		push_warning("duplicate damage_type_id: " + damage_type_id)
		return

	var entry := damage_type.duplicate(true)
	entry["damage_type_id"] = damage_type_id
	damage_types[damage_type_id] = entry


func _register_status_effect_type(status_effect: Dictionary) -> void:
	var status_id := _normalize_status_effect_id(String(status_effect.get("status_id", "")))
	if status_id == "":
		push_warning("status_id is empty")
		return

	if status_effect_types.has(status_id):
		push_warning("duplicate status_id: " + status_id)
		return

	var entry := status_effect.duplicate(true)
	entry["status_id"] = status_id
	entry["category"] = _normalize_status_effect_category(String(entry.get("category", "neutral")))
	status_effect_types[status_id] = entry


func _register_chest_table(chest_table: Dictionary) -> void:
	var chest_id := _normalize_chest_id(String(chest_table.get("chest_id", "")))
	if chest_id == "":
		push_warning("chest_id is empty")
		return

	if chest_tables.has(chest_id):
		push_warning("duplicate chest_id: " + chest_id)
		return

	var entry := chest_table.duplicate(true)
	entry["chest_id"] = chest_id
	chest_tables[chest_id] = entry


func _register_chest_loot_entry(loot_entry: Dictionary) -> void:
	var loot_table_id := _normalize_chest_id(String(loot_entry.get("loot_table_id", "")))
	if loot_table_id == "":
		push_warning("chest loot_table_id is empty")
		return

	var entries_value: Variant = chest_loot_tables.get(loot_table_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		entries_value = []

	var entries: Array = entries_value
	var entry := loot_entry.duplicate(true)
	entry["loot_table_id"] = loot_table_id
	entries.append(entry)
	chest_loot_tables[loot_table_id] = entries


func _register_shop_table(shop_table: Dictionary) -> void:
	var shop_table_id := _normalize_shop_id(String(shop_table.get("shop_table_id", "")))
	if shop_table_id == "":
		push_warning("shop_table_id is empty")
		return

	if shop_tables.has(shop_table_id):
		push_warning("duplicate shop_table_id: " + shop_table_id)
		return

	var entry := shop_table.duplicate(true)
	entry["shop_table_id"] = shop_table_id
	shop_tables[shop_table_id] = entry


func _register_shop_loot_entry(loot_entry: Dictionary) -> void:
	var loot_table_id := _normalize_shop_id(String(loot_entry.get("loot_table_id", "")))
	if loot_table_id == "":
		push_warning("shop loot_table_id is empty")
		return

	var entries_value: Variant = shop_loot_tables.get(loot_table_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		entries_value = []

	var entries: Array = entries_value
	var entry := loot_entry.duplicate(true)
	entry["loot_table_id"] = loot_table_id
	entries.append(entry)
	shop_loot_tables[loot_table_id] = entries


func _register_initial_inventory_table(inventory_table: Dictionary) -> void:
	var inventory_table_id := _normalize_inventory_table_id(String(inventory_table.get("inventory_table_id", "")))
	if inventory_table_id == "":
		push_warning("initial inventory_table_id is empty")
		return

	if initial_inventory_tables.has(inventory_table_id):
		push_warning("duplicate initial inventory_table_id: " + inventory_table_id)
		return

	var entry := inventory_table.duplicate(true)
	entry["inventory_table_id"] = inventory_table_id
	initial_inventory_tables[inventory_table_id] = entry


func _register_initial_inventory_entry(inventory_table_id: String, entry: InitialInventoryEntry) -> void:
	var normalized_id := _normalize_inventory_table_id(inventory_table_id)
	if normalized_id == "":
		push_warning("initial inventory entry has empty inventory_table_id")
		return

	if entry == null:
		return

	var entries_value: Variant = initial_inventory_entries.get(normalized_id, [])
	if typeof(entries_value) != TYPE_ARRAY:
		entries_value = []

	var entries: Array = entries_value
	entries.append(entry)
	initial_inventory_entries[normalized_id] = entries


func _set_faction_relation(from_faction: String, to_faction: String, relation: String) -> void:
	var from_id := _normalize_loaded_unit_faction(from_faction, "faction_relations.tsv from_faction")
	var to_id := _normalize_loaded_unit_faction(to_faction, "faction_relations.tsv to_faction")
	var relation_text := _normalize_faction_relation_text(relation)
	if relation_text == "":
		push_warning("unknown faction relation: " + relation + " from=" + from_id + " to=" + to_id + " -> " + DEFAULT_FACTION_RELATION)
		relation_text = DEFAULT_FACTION_RELATION

	if not faction_relations.has(from_id):
		faction_relations[from_id] = {}

	var row_value: Variant = faction_relations[from_id]
	if typeof(row_value) != TYPE_DICTIONARY:
		row_value = {}
		faction_relations[from_id] = row_value

	var row: Dictionary = row_value
	row[to_id] = relation_text


func _ensure_builtin_item_category_fallbacks() -> void:
	for fallback in BUILTIN_ITEM_CATEGORY_FALLBACKS:
		var category_id := _normalize_item_category_id(String(fallback.get("category_id", "")))
		if category_id == "" or item_categories.has(category_id):
			continue

		item_categories[category_id] = fallback.duplicate(true)


func _ensure_builtin_unit_race_fallbacks() -> void:
	for fallback in BUILTIN_UNIT_RACE_FALLBACKS:
		var race_id := _normalize_unit_race_id(String(fallback.get("race_id", "")))
		if race_id == "" or unit_races.has(race_id):
			continue

		unit_races[race_id] = fallback.duplicate(true)


func _ensure_builtin_unit_faction_fallbacks() -> void:
	for fallback in BUILTIN_UNIT_FACTION_FALLBACKS:
		var faction_id := _normalize_unit_faction_id(String(fallback.get("faction_id", "")))
		if faction_id == "" or unit_factions.has(faction_id):
			continue

		unit_factions[faction_id] = fallback.duplicate(true)


func _ensure_builtin_faction_relation_fallbacks() -> void:
	for fallback in BUILTIN_FACTION_RELATION_FALLBACKS:
		var from_id := _normalize_unit_faction_id(String(fallback.get("from_faction", "")))
		var to_id := _normalize_unit_faction_id(String(fallback.get("to_faction", "")))
		var relation := _normalize_faction_relation_text(String(fallback.get("relation", "")))
		if from_id == "" or to_id == "" or relation == "":
			continue

		var row_value: Variant = faction_relations.get(from_id, {})
		if typeof(row_value) == TYPE_DICTIONARY:
			var row: Dictionary = row_value
			if row.has(to_id):
				continue

		_set_faction_relation(from_id, to_id, relation)


func _ensure_builtin_element_type_fallbacks() -> void:
	for fallback in BUILTIN_ELEMENT_TYPE_FALLBACKS:
		var element_id := _normalize_element_type_id(String(fallback.get("element_id", "")))
		if element_id == "" or element_types.has(element_id):
			continue

		element_types[element_id] = fallback.duplicate(true)


func _ensure_builtin_damage_type_fallbacks() -> void:
	for fallback in BUILTIN_DAMAGE_TYPE_FALLBACKS:
		var damage_type_id := _normalize_damage_type_id(String(fallback.get("damage_type_id", "")))
		if damage_type_id == "" or damage_types.has(damage_type_id):
			continue

		damage_types[damage_type_id] = fallback.duplicate(true)


func _ensure_builtin_status_effect_type_fallbacks() -> void:
	for fallback in BUILTIN_STATUS_EFFECT_TYPE_FALLBACKS:
		var status_id := _normalize_status_effect_id(String(fallback.get("status_id", "")))
		if status_id == "" or status_effect_types.has(status_id):
			continue

		status_effect_types[status_id] = fallback.duplicate(true)


func _warn_unknown_item_category(category_id: String, context: String = "") -> void:
	var normalized_id := _normalize_item_category_id(category_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_item_categories.has(key):
		return

	_warned_unknown_item_categories[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown item category" + context_text + ": " + category_id + " -> " + DEFAULT_ITEM_CATEGORY_ID)


func _warn_unknown_unit_race(race_id: String, context: String = "") -> void:
	var normalized_id := _normalize_unit_race_id(race_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_unit_races.has(key):
		return

	_warned_unknown_unit_races[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown unit race" + context_text + ": " + race_id + " -> " + DEFAULT_UNIT_RACE_ID)


func _warn_unknown_unit_faction(faction_id: String, context: String = "") -> void:
	var normalized_id := _normalize_unit_faction_id(faction_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_unit_factions.has(key):
		return

	_warned_unknown_unit_factions[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown unit faction" + context_text + ": " + faction_id + " -> " + DEFAULT_UNIT_FACTION_ID)


func _warn_missing_faction_relation(from_faction: String, to_faction: String) -> void:
	var key := from_faction + "->" + to_faction
	if _warned_missing_faction_relations.has(key):
		return

	_warned_missing_faction_relations[key] = true
	push_warning("missing faction relation: " + key + " -> " + DEFAULT_FACTION_RELATION)


func _warn_unknown_element_type(element_id: String, context: String = "") -> void:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_element_types.has(key):
		return

	_warned_unknown_element_types[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown element type" + context_text + ": " + element_id + " -> " + DEFAULT_ELEMENT_TYPE_ID)


func _warn_unknown_damage_type(damage_type_id: String, context: String = "") -> void:
	var normalized_id := _normalize_damage_type_id(damage_type_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_damage_types.has(key):
		return

	_warned_unknown_damage_types[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown damage type" + context_text + ": " + damage_type_id + " -> " + DEFAULT_DAMAGE_TYPE_ID)


func _warn_unknown_status_effect_type(status_id: String, context: String = "") -> void:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		normalized_id = "<empty>"

	var key := context + ":" + normalized_id
	if _warned_unknown_status_effect_types.has(key):
		return

	_warned_unknown_status_effect_types[key] = true

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown status effect type" + context_text + ": " + status_id + " (kept status_id)")


func _normalize_loaded_item_category(category_id: String, item_id: String) -> String:
	var normalized_id := _normalize_item_category_id(category_id)
	if normalized_id == "":
		return DEFAULT_ITEM_CATEGORY_ID

	if has_item_category(normalized_id):
		return normalized_id

	_warn_unknown_item_category(category_id, "items.tsv item_id=" + item_id)
	return DEFAULT_ITEM_CATEGORY_ID


func _normalize_loaded_unit_race(race_id: String, context: String) -> String:
	var normalized_id := _normalize_unit_race_id(race_id)
	if normalized_id == "":
		return DEFAULT_UNIT_RACE_ID

	if has_unit_race(normalized_id):
		return normalized_id

	_warn_unknown_unit_race(race_id, context)
	return DEFAULT_UNIT_RACE_ID


func _normalize_loaded_unit_faction(faction_id: String, context: String) -> String:
	var normalized_id := _normalize_unit_faction_id(faction_id)
	if normalized_id == "":
		return DEFAULT_UNIT_FACTION_ID

	if has_unit_faction(normalized_id):
		return normalized_id

	_warn_unknown_unit_faction(faction_id, context)
	return DEFAULT_UNIT_FACTION_ID


func _normalize_loaded_element_type(element_id: String, context: String) -> String:
	var normalized_id := _normalize_element_type_id(element_id)
	if normalized_id == "":
		return DEFAULT_ELEMENT_TYPE_ID

	if has_element_type(normalized_id):
		return normalized_id

	_warn_unknown_element_type(element_id, context)
	return DEFAULT_ELEMENT_TYPE_ID


func _normalize_loaded_damage_type(damage_type_id: String, context: String) -> String:
	var normalized_id := _normalize_damage_type_id(damage_type_id)
	if normalized_id == "":
		return DEFAULT_DAMAGE_TYPE_ID

	if has_damage_type(normalized_id):
		return normalized_id

	_warn_unknown_damage_type(damage_type_id, context)
	return DEFAULT_DAMAGE_TYPE_ID


func _normalize_loaded_shop_table_id(shop_table_id: String, context: String) -> String:
	var normalized_id := _normalize_shop_id(shop_table_id)
	if normalized_id == "":
		return ""

	if has_shop_table(normalized_id):
		return normalized_id

	push_warning("unknown shop_table_id (" + context + "): " + shop_table_id + " -> fallback columns")
	return ""


func _normalize_loaded_initial_inventory_table_id(inventory_table_id: String, context: String) -> String:
	var normalized_id := _normalize_inventory_table_id(inventory_table_id)
	if normalized_id == "":
		return ""

	if has_initial_inventory_table(normalized_id):
		return normalized_id

	push_warning("unknown initial_inventory_table_id (" + context + "): " + inventory_table_id + " -> fallback columns")
	return ""


func _normalize_damage_mode(value: String, context: String = "") -> String:
	var normalized_value := value.strip_edges().to_lower()
	if normalized_value == "":
		return "direct"

	match normalized_value:
		"direct", "calculated":
			return normalized_value

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	push_warning("unknown damage_mode" + context_text + ": " + value + " -> direct")
	return "direct"


func _normalize_calculated_power(value: String, context: String = "") -> float:
	var normalized_value := value.strip_edges()
	if normalized_value == "":
		return 1.0

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	if not normalized_value.is_valid_float():
		push_warning("invalid calculated_power" + context_text + ": " + value + " -> 1.0")
		return 1.0

	var power := float(normalized_value)
	if power <= 0.0:
		push_warning("invalid calculated_power" + context_text + ": " + value + " -> 1.0")
		return 1.0

	return power


func _normalize_damage_float(value: String, default_value: float, context: String = "", should_clamp_unit: bool = false) -> float:
	var normalized_value := value.strip_edges()
	if normalized_value == "":
		return default_value

	var context_text := ""
	if context != "":
		context_text = " (" + context + ")"

	if not normalized_value.is_valid_float():
		push_warning("invalid damage value" + context_text + ": " + value + " -> " + str(default_value))
		return default_value

	var parsed_value := float(normalized_value)
	if should_clamp_unit:
		return clamp(parsed_value, 0.0, 1.0)

	return parsed_value


func _normalize_trigger_chance(value: String, context: String = "") -> float:
	return _normalize_damage_float(value, 1.0, context, true)


func _normalize_allowed_text(value: String, allowed_values: Array, fallback: String, context: String) -> String:
	var normalized_value := value.strip_edges().to_lower()
	if normalized_value == "":
		return fallback

	if allowed_values.has(normalized_value):
		return normalized_value

	push_warning("unknown " + context + ": " + value + " -> " + fallback)
	return fallback


func _normalize_skill_category(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["combat", "movement", "work", "life"], "", context)


func _normalize_skill_kind(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["active", "passive"], "passive", context)


func _normalize_skill_target_type(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["self", "enemy", "ally", "tile", "none"], "none", context)


func _normalize_skill_effect_polarity(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["damage", "heal", "buff", "debuff", "utility", "passive"], "utility", context)


func _normalize_skill_cost_type(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["none", "hp", "mp", "stamina", "hunger"], "none", context)


func _normalize_skill_trigger(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["on_cast", "passive", "on_attack_hit", "on_turn_start", "on_turn_end"], "", context)


func _normalize_skill_requirement_kind(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["learn", "upgrade", "use"], "", context)


func _normalize_skill_requirement_type(value: String, context: String) -> String:
	return _normalize_allowed_text(value, ["unit_level", "skill_level", "item", "faction", "quest", "none"], "none", context)


func _normalize_unit_skill_pick_type(value: String, context: String) -> String:
	var normalized_value := value.strip_edges().to_upper()
	if normalized_value == "":
		return "SKILL"

	match normalized_value:
		"SKILL", "CATEGORY":
			return normalized_value
		_:
			push_warning("unknown " + context + ": " + value + " -> SKILL")
			return "SKILL"


func _normalize_loaded_skill_table_id(skill_table_id: String, context: String) -> String:
	var normalized_id := skill_table_id.strip_edges()
	if normalized_id == "":
		return ""

	if has_unit_skill_table(normalized_id):
		return normalized_id

	push_warning("unknown skill_table_id (" + context + "): " + skill_table_id + " -> empty")
	return ""


func _warn_unknown_element_resistance_keys(resistances: Dictionary, context: String) -> void:
	for key in resistances.keys():
		var element_id := _normalize_element_type_id(String(key))
		if element_id == "" or has_element_type(element_id):
			continue

		var warn_key := context + ":element_resistances:" + element_id
		if _warned_unknown_element_types.has(warn_key):
			continue

		_warned_unknown_element_types[warn_key] = true
		push_warning("unknown element resistance key (" + context + "): " + String(key) + " (kept multiplier)")


func _get_item_category_defaults_for_item(category_id: String) -> Dictionary:
	var defaults := {
		"default_max_stack": 99,
		"default_usable": false,
		"default_can_sell": true
	}

	var normalized_id := _normalize_item_category_id(category_id)
	if normalized_id == "":
		return defaults

	if not _item_category_ids_from_tsv.has(normalized_id):
		return defaults

	var category_value: Variant = item_categories.get(normalized_id, {})
	if typeof(category_value) != TYPE_DICTIONARY:
		return defaults

	var category: Dictionary = category_value
	defaults["default_max_stack"] = int(category.get("default_max_stack", defaults["default_max_stack"]))
	defaults["default_usable"] = bool(category.get("default_usable", defaults["default_usable"]))
	defaults["default_can_sell"] = bool(category.get("default_can_sell", defaults["default_can_sell"]))
	return defaults


func _warn_unknown_status_effect_type_if_needed(status_id: String, context: String) -> void:
	var normalized_id := _normalize_status_effect_id(status_id)
	if normalized_id == "":
		return

	if has_status_effect_type(normalized_id):
		return

	_warn_unknown_status_effect_type(status_id, context)


func _split_texture_array(value: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []

	for path in _split_list(value):
		var texture := _load_resource_or_null(path) as Texture2D
		if texture == null:
			continue
		result.append(texture)

	return result


func _split_initial_inventory_entries(value: String) -> Array[InitialInventoryEntry]:
	var result: Array[InitialInventoryEntry] = []
	value = value.strip_edges()

	if value == "":
		return result

	for entry_text in value.split(";", false):
		var text := String(entry_text).strip_edges()
		if text == "":
			continue

		var parts := text.split(",", true)
		if parts.size() < 1:
			continue

		var entry := InitialInventoryEntry.new()
		entry.item_id = String(parts[0]).strip_edges()

		if parts.size() >= 2:
			entry.amount_min = _to_int(String(parts[1]), 1)
		if parts.size() >= 3:
			entry.amount_max = _to_int(String(parts[2]), entry.amount_min)
		if parts.size() >= 4:
			entry.chance = _to_float(String(parts[3]), 1.0)
		if parts.size() >= 5:
			entry.roll_equipment_enchantments = _to_bool(String(parts[4]))

		if entry.item_id != "":
			result.append(entry)

	return result


func _get_initial_inventory_entries_for_loaded_unit(
	inventory_table_id: String,
	fallback_items: String,
	context: String
) -> Array[InitialInventoryEntry]:
	var normalized_id := _normalize_loaded_initial_inventory_table_id(inventory_table_id, context)
	if normalized_id != "":
		var table_entries := get_initial_inventory_entries(normalized_id)
		if not table_entries.is_empty():
			return table_entries

		push_warning("initial_inventory_table_id (" + context + "): " + normalized_id + " has no entries -> fallback columns")

	return _split_initial_inventory_entries(fallback_items)


func _split_loot_categories(value: String) -> Array[LootCategoryEntry]:
	var result: Array[LootCategoryEntry] = []
	value = value.strip_edges()

	if value == "":
		return result

	for entry_text in value.split(";", false):
		var text := String(entry_text).strip_edges()
		if text == "":
			continue

		var parts := text.split(",", true)
		if parts.size() < 1:
			continue

		var entry := LootCategoryEntry.new()
		entry.item_type = String(parts[0]).strip_edges()

		if parts.size() >= 2:
			entry.weight = _to_int(String(parts[1]), 100)
		if parts.size() >= 3:
			entry.min_amount = _to_int(String(parts[2]), 1)
		if parts.size() >= 4:
			entry.max_amount = _to_int(String(parts[3]), entry.min_amount)

		if entry.item_type != "":
			result.append(entry)

	return result


# ============================================================
# StatusEffectTypes
# ============================================================

func _load_status_effect_types() -> void:
	var rows := _load_optional_tsv("res://data/master/status_effect_types.tsv")

	for row in rows:
		var status_id := _normalize_status_effect_id(_get_string(row, "status_id"))
		if status_id == "":
			push_warning("status_effect_types.tsv has empty status_id")
			continue

		var display_name := _get_string(row, "display_name", status_id).strip_edges()
		if display_name == "":
			display_name = status_id

		_register_status_effect_type(_make_status_effect_type_entry(
			status_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_get_string(row, "category", "neutral"),
			_to_float(_get_string(row, "default_duration"), 0.0),
			_to_bool(_get_string(row, "stackable", "false")),
			_get_string(row, "description")
		))

	_ensure_builtin_status_effect_type_fallbacks()


# ============================================================
# ItemData
# ============================================================

func _load_item_categories() -> void:
	var rows := _load_optional_tsv("res://data/master/item_categories.tsv")

	for row in rows:
		var category_id := _normalize_item_category_id(_get_string(row, "category_id"))
		if category_id == "":
			push_warning("item_categories.tsv has empty category_id")
			continue

		var display_name := _get_string(row, "display_name", category_id).strip_edges()
		if display_name == "":
			display_name = category_id

		_register_item_category(_make_item_category_entry(
			category_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_to_bool(_get_string(row, "show_in_inventory", "true")),
			_to_bool(_get_string(row, "default_usable", "false")),
			_to_bool(_get_string(row, "default_can_sell", "true")),
			_to_int(_get_string(row, "default_max_stack"), 99),
			_get_string(row, "description")
		), true)

	_ensure_builtin_item_category_fallbacks()


func _load_items() -> void:
	var rows := _load_tsv("res://data/master/items.tsv")

	for row in rows:
		var item := ItemData.new()

		item.item_id = _get_string(row, "item_id")
		item.display_name = _get_string(row, "display_name")
		item.description = _get_string(row, "description")
		var category_text := _get_string(row, "category")
		item.category = _normalize_loaded_item_category(category_text, item.item_id)
		var category_defaults := _get_item_category_defaults_for_item(category_text)
		var max_stack_text := _get_string(row, "max_stack")
		if max_stack_text.strip_edges() == "":
			item.max_stack = int(category_defaults.get("default_max_stack", 99))
		else:
			item.max_stack = _to_int(max_stack_text, 99)
		var usable_text := _get_string(row, "usable")
		if usable_text.strip_edges() == "":
			item.usable = bool(category_defaults.get("default_usable", false))
		else:
			item.usable = _to_bool(usable_text)
		item.base_price = _to_int(_get_string(row, "base_price"), 0)
		var can_sell_text := _get_string(row, "can_sell")
		if can_sell_text.strip_edges() == "":
			item.can_sell = bool(category_defaults.get("default_can_sell", true))
		else:
			item.can_sell = _to_bool(can_sell_text)
		item.rarity = _to_int(_get_string(row, "rarity"), 1)
		item.spawn_weight = _to_int(_get_string(row, "spawn_weight"), 100)
		item.use_flags = _to_int(_get_string(row, "use_flags"), 0)
		item.target_flags = _to_int(_get_string(row, "target_flags"), 0)

		var icon_path := _get_string(row, "icon_path").strip_edges()
		if icon_path != "":
			item.icon = load(icon_path)

		_register_item(item)


func _register_item(item: ItemData) -> void:
	if item == null:
		return

	if item.item_id == "":
		push_error("item_id is empty")
		return

	if items.has(item.item_id):
		push_error("duplicate item_id: " + item.item_id)
		return

	items[item.item_id] = item


# ============================================================
# EquipmentData
# ============================================================

func _load_equipment() -> void:
	var rows := _load_tsv("res://data/master/equipment.tsv")

	for row in rows:
		var item_id := _get_string(row, "item_id").strip_edges()

		if item_id == "":
			push_error("equipment item_id is empty")
			continue

		var base_item: ItemData = items.get(item_id)

		if base_item == null:
			push_error("equipment item_id not found in items.tsv: " + item_id)
			continue

		var equip := EquipmentData.new()
		_copy_item_fields(base_item, equip)

		equip.slot_type = _equipment_slot_from_text(_get_string(row, "slot_type", "HAND"))
		equip.max_hp_bonus = _to_int(_get_string(row, "max_hp_bonus"), 0)
		equip.attack_bonus = _to_int(_get_string(row, "attack_bonus"), 0)
		equip.defense_bonus = _to_int(_get_string(row, "defense_bonus"), 0)
		equip.speed_bonus = _to_int(_get_string(row, "speed_bonus"), 0)
		equip.attack_type_id = _get_string(row, "attack_type_id", "melee")
		equip.attack_element = _normalize_loaded_element_type(
			_get_string(row, "attack_element", equip.attack_element),
			"equipment.tsv item_id=" + item_id + " attack_element"
		)
		equip.attack_damage_type = _normalize_loaded_damage_type(
			_get_string(row, "attack_damage_type", equip.attack_damage_type),
			"equipment.tsv item_id=" + item_id + " attack_damage_type"
		)
		equip.attack_min_range = _to_int(_get_string(row, "attack_min_range"), 1)
		equip.attack_max_range = _to_int(_get_string(row, "attack_max_range"), 1)
		equip.combat_style = _combat_style_from_text(_get_string(row, "combat_style", "AUTO"))
		equip.move_style = _move_style_from_text(_get_string(row, "move_style", "AUTO"))

		items[item_id] = equip


func _copy_item_fields(src: ItemData, dst: ItemData) -> void:
	dst.item_id = src.item_id
	dst.display_name = src.display_name
	dst.description = src.description
	dst.icon = src.icon
	dst.category = src.category
	dst.max_stack = src.max_stack
	dst.usable = src.usable
	dst.base_price = src.base_price
	dst.can_sell = src.can_sell
	dst.rarity = src.rarity
	dst.spawn_weight = src.spawn_weight
	dst.use_flags = src.use_flags
	dst.target_flags = src.target_flags
	dst.effects = src.effects


func _equipment_slot_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"HAND":
			return EquipmentData.EquipmentSlot.HAND
		"HEAD":
			return EquipmentData.EquipmentSlot.HEAD
		"BODY":
			return EquipmentData.EquipmentSlot.BODY
		"HANDS":
			return EquipmentData.EquipmentSlot.HANDS
		"WAIST":
			return EquipmentData.EquipmentSlot.WAIST
		"FEET":
			return EquipmentData.EquipmentSlot.FEET
		"ACCESSORY":
			return EquipmentData.EquipmentSlot.ACCESSORY
		_:
			return EquipmentData.EquipmentSlot.HAND


func _combat_style_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"MELEE":
			return EquipmentData.AICombatStyle.MELEE
		"MID":
			return EquipmentData.AICombatStyle.MID
		"LONG":
			return EquipmentData.AICombatStyle.LONG
		"SUPPORTER":
			return EquipmentData.AICombatStyle.SUPPORTER
		"HIT_AND_RUN":
			return EquipmentData.AICombatStyle.HIT_AND_RUN
		"DEFENSIVE":
			return EquipmentData.AICombatStyle.DEFENSIVE
		_:
			return EquipmentData.AICombatStyle.AUTO


func _move_style_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"APPROACH":
			return EquipmentData.AIMoveStyle.APPROACH
		"KEEP_DISTANCE":
			return EquipmentData.AIMoveStyle.KEEP_DISTANCE
		"FLEE":
			return EquipmentData.AIMoveStyle.FLEE
		"HOLD":
			return EquipmentData.AIMoveStyle.HOLD
		_:
			return EquipmentData.AIMoveStyle.AUTO


# ============================================================
# Chest tables
# ============================================================

func _load_chest_tables() -> void:
	var rows := _load_optional_tsv("res://data/master/chest_tables.tsv")

	for row in rows:
		var chest_id := _normalize_chest_id(_get_string(row, "chest_id"))
		if chest_id == "":
			push_warning("chest_tables.tsv has empty chest_id")
			continue

		var display_name := _get_string(row, "display_name", chest_id).strip_edges()
		if display_name == "":
			display_name = chest_id

		var slot_count: int = max(_to_int(_get_string(row, "slot_count"), 12), 0)
		var min_items: int = max(_to_int(_get_string(row, "min_items"), 1), 0)
		var max_items: int = max(_to_int(_get_string(row, "max_items"), min_items), min_items)
		var gold_min: int = max(_to_int(_get_string(row, "gold_min"), 0), 0)
		var gold_max: int = max(_to_int(_get_string(row, "gold_max"), gold_min), gold_min)
		var loot_table_id := _normalize_chest_id(_get_string(row, "loot_table_id", chest_id))
		if loot_table_id == "":
			loot_table_id = chest_id

		_register_chest_table(_make_chest_table_entry(
			chest_id,
			display_name,
			slot_count,
			min_items,
			max_items,
			gold_min,
			gold_max,
			loot_table_id,
			_get_string(row, "description")
		))


func _load_chest_loot_tables() -> void:
	var rows := _load_optional_tsv("res://data/master/chest_loot_tables.tsv")

	for row in rows:
		var loot_table_id := _normalize_chest_id(_get_string(row, "loot_table_id"))
		if loot_table_id == "":
			push_warning("chest_loot_tables.tsv has empty loot_table_id")
			continue

		var category := _normalize_item_category_id(_get_string(row, "category"))
		var item_id := _get_string(row, "item_id").strip_edges()
		var context := "chest_loot_tables.tsv loot_table_id=" + loot_table_id

		if category == "" and item_id == "":
			push_warning(context + " has neither category nor item_id")
			continue

		if category != "" and not has_item_category(category):
			_warn_unknown_item_category(category, context)
			category = DEFAULT_ITEM_CATEGORY_ID

		if item_id != "" and not has_item(item_id):
			push_warning(context + " item_id not found: " + item_id)

		var weight: int = max(_to_int(_get_string(row, "weight"), 100), 0)
		var min_amount: int = max(_to_int(_get_string(row, "min_amount"), 1), 1)
		var max_amount: int = max(_to_int(_get_string(row, "max_amount"), min_amount), min_amount)

		_register_chest_loot_entry(_make_chest_loot_entry(
			loot_table_id,
			category,
			item_id,
			weight,
			min_amount,
			max_amount
		))


func _load_shop_tables() -> void:
	var rows := _load_optional_tsv("res://data/master/shop_tables.tsv")

	for row in rows:
		var shop_table_id := _normalize_shop_id(_get_string(row, "shop_table_id"))
		if shop_table_id == "":
			push_warning("shop_tables.tsv has empty shop_table_id")
			continue

		var display_name := _get_string(row, "display_name", shop_table_id).strip_edges()
		if display_name == "":
			display_name = shop_table_id

		var min_items: int = max(_to_int(_get_string(row, "min_items"), 0), 0)
		var max_items: int = max(_to_int(_get_string(row, "max_items"), min_items), min_items)
		var loot_table_id := _normalize_shop_id(_get_string(row, "loot_table_id", shop_table_id))
		if loot_table_id == "":
			loot_table_id = shop_table_id

		_register_shop_table(_make_shop_table_entry(
			shop_table_id,
			display_name,
			min_items,
			max_items,
			loot_table_id,
			_get_string(row, "description")
		))


func _load_shop_loot_tables() -> void:
	var rows := _load_optional_tsv("res://data/master/shop_loot_tables.tsv")

	for row in rows:
		var loot_table_id := _normalize_shop_id(_get_string(row, "loot_table_id"))
		if loot_table_id == "":
			push_warning("shop_loot_tables.tsv has empty loot_table_id")
			continue

		var category := _normalize_item_category_id(_get_string(row, "category"))
		var item_id := _get_string(row, "item_id").strip_edges()
		var context := "shop_loot_tables.tsv loot_table_id=" + loot_table_id

		if category == "" and item_id == "":
			push_warning(context + " has neither category nor item_id")
			continue

		if category != "" and not has_item_category(category):
			_warn_unknown_item_category(category, context)
			category = DEFAULT_ITEM_CATEGORY_ID

		if item_id != "" and not has_item(item_id):
			push_warning(context + " item_id not found: " + item_id)

		var weight: int = max(_to_int(_get_string(row, "weight"), 100), 0)
		var min_amount: int = max(_to_int(_get_string(row, "min_amount"), 1), 1)
		var max_amount: int = max(_to_int(_get_string(row, "max_amount"), min_amount), min_amount)

		_register_shop_loot_entry(_make_shop_loot_entry(
			loot_table_id,
			category,
			item_id,
			weight,
			min_amount,
			max_amount
		))


func _load_initial_inventory_tables() -> void:
	var rows := _load_optional_tsv("res://data/master/initial_inventory_tables.tsv")

	for row in rows:
		var inventory_table_id := _normalize_inventory_table_id(_get_string(row, "inventory_table_id"))
		if inventory_table_id == "":
			push_warning("initial_inventory_tables.tsv has empty inventory_table_id")
			continue

		var display_name := _get_string(row, "display_name", inventory_table_id).strip_edges()
		if display_name == "":
			display_name = inventory_table_id

		_register_initial_inventory_table(_make_initial_inventory_table_entry(
			inventory_table_id,
			display_name,
			_get_string(row, "description")
		))


func _load_initial_inventory_entries() -> void:
	var rows := _load_optional_tsv("res://data/master/initial_inventory_entries.tsv")

	for row in rows:
		var inventory_table_id := _normalize_inventory_table_id(_get_string(row, "inventory_table_id"))
		if inventory_table_id == "":
			push_warning("initial_inventory_entries.tsv has empty inventory_table_id")
			continue

		var context := "initial_inventory_entries.tsv inventory_table_id=" + inventory_table_id
		if not has_initial_inventory_table(inventory_table_id):
			push_warning(context + " not found in initial_inventory_tables")
			continue

		var item_id := _get_string(row, "item_id").strip_edges()
		if item_id == "":
			push_warning(context + " has empty item_id")
			continue

		if not has_item(item_id):
			push_warning(context + " item_id not found: " + item_id)

		var min_amount: int = max(_to_int(_get_string(row, "min_amount"), 1), 1)
		var max_amount: int = max(_to_int(_get_string(row, "max_amount"), min_amount), min_amount)
		var drop_chance: float = clamp(_to_float(_get_string(row, "drop_chance"), 1.0), 0.0, 1.0)
		var guaranteed := _to_bool(_get_string(row, "guaranteed", "false"))
		var roll_equipment_enchantments := _to_bool(_get_string(row, "roll_equipment_enchantments", "true"))

		var entry := InitialInventoryEntry.new()
		entry.item_id = item_id
		entry.amount_min = min_amount
		entry.amount_max = max_amount
		entry.chance = 1.0 if guaranteed else drop_chance
		entry.roll_equipment_enchantments = roll_equipment_enchantments

		_register_initial_inventory_entry(inventory_table_id, entry)


# ============================================================
# ItemEffectData
# ============================================================

func _load_item_effects() -> void:
	var rows := _load_tsv("res://data/master/item_effects.tsv")

	for row in rows:
		var effect_id := _get_string(row, "effect_id").strip_edges()

		if effect_id == "":
			push_error("effect_id is empty")
			continue

		if effects.has(effect_id):
			push_error("duplicate effect_id: " + effect_id)
			continue

		var effect := _build_item_effect(row)
		effects[effect_id] = effect


func _build_item_effect(row: Dictionary) -> ItemEffectData:
	var effect := ItemEffectData.new()
	var effect_id := _get_string(row, "effect_id").strip_edges()
	var effect_type := _get_string(row, "effect_type").strip_edges()

	match effect_type:
		"restore_resource":
			effect.effect_type = ItemEffectData.EffectType.RESTORE_RESOURCE
			effect.resource_type = _resource_type_from_text(_get_string(row, "resource_type", "hp"))
			effect.value_mode = _value_mode_from_text(_get_string(row, "value_mode", "flat"))
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)
			effect.percent_value = _to_float(_get_string(row, "percent_value"), 0.0)

		"cure_status":
			effect.effect_type = ItemEffectData.EffectType.CURE_STATUS
			effect.status_id = StringName(_get_string(row, "status_id"))

		"apply_status":
			effect.effect_type = ItemEffectData.EffectType.APPLY_STATUS
			effect.status_id = StringName(_get_string(row, "status_id"))
			effect.status_power = _to_int(_get_string(row, "status_power"), 0)
			effect.duration_type = _duration_type_from_text(_get_string(row, "duration_type", "none"))
			effect.duration_value = _to_float(_get_string(row, "duration_value"), 0.0)

		"apply_modifier":
			effect.effect_type = ItemEffectData.EffectType.APPLY_MODIFIER
			effect.modifier_kind = _modifier_kind_from_text(_get_string(row, "modifier_kind", "buff"))
			effect.stat_name = StringName(_get_string(row, "stat_name"))
			effect.stat_flat = _to_int(_get_string(row, "stat_flat"), 0)
			effect.stat_percent = _to_float(_get_string(row, "stat_percent"), 0.0)
			effect.duration_type = _duration_type_from_text(_get_string(row, "duration_type", "none"))
			effect.duration_value = _to_float(_get_string(row, "duration_value"), 0.0)

		"deal_damage":
			effect.effect_type = ItemEffectData.EffectType.DEAL_DAMAGE
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)
			effect.damage_element = _normalize_loaded_element_type(
				_get_string(row, "damage_element", effect.damage_element),
				"item_effects.tsv effect_id=" + effect_id + " damage_element"
			)
			effect.damage_type = _normalize_loaded_damage_type(
				_get_string(row, "damage_type", effect.damage_type),
				"item_effects.tsv effect_id=" + effect_id + " damage_type"
			)
			effect.damage_mode = _normalize_damage_mode(
				_get_string(row, "damage_mode", effect.damage_mode),
				"item_effects.tsv effect_id=" + effect_id
			)
			effect.calculated_power = _normalize_calculated_power(
				_get_string(row, "calculated_power", str(effect.calculated_power)),
				"item_effects.tsv effect_id=" + effect_id
			)
			effect.bonus_accuracy = _normalize_damage_float(
				_get_string(row, "bonus_accuracy", str(effect.bonus_accuracy)),
				0.0,
				"item_effects.tsv effect_id=" + effect_id + " bonus_accuracy"
			)
			effect.bonus_crit_rate = _normalize_damage_float(
				_get_string(row, "bonus_crit_rate", str(effect.bonus_crit_rate)),
				0.0,
				"item_effects.tsv effect_id=" + effect_id + " bonus_crit_rate"
			)
			effect.ignore_defense_rate = _normalize_damage_float(
				_get_string(row, "ignore_defense_rate", str(effect.ignore_defense_rate)),
				0.0,
				"item_effects.tsv effect_id=" + effect_id + " ignore_defense_rate",
				true
			)
			effect.fixed_damage_bonus = _normalize_damage_float(
				_get_string(row, "fixed_damage_bonus", str(effect.fixed_damage_bonus)),
				0.0,
				"item_effects.tsv effect_id=" + effect_id + " fixed_damage_bonus"
			)

		"grant_item":
			effect.effect_type = ItemEffectData.EffectType.GRANT_ITEM
			effect.grant_item_id = _get_string(row, "grant_item_id")
			effect.grant_item_amount = _to_int(_get_string(row, "grant_item_amount"), 1)

		"grant_currency":
			effect.effect_type = ItemEffectData.EffectType.GRANT_CURRENCY
			effect.grant_currency_amount = _to_int(_get_string(row, "grant_currency_amount"), 0)

		"teleport":
			effect.effect_type = ItemEffectData.EffectType.TELEPORT
			effect.teleport_mode = _teleport_mode_from_text(_get_string(row, "teleport_mode", "random"))
			effect.teleport_min_range = _to_int(_get_string(row, "teleport_min_range"), 0)
			effect.teleport_max_range = _to_int(_get_string(row, "teleport_max_range"), 999)
			effect.warp_point_id = StringName(_get_string(row, "warp_point_id"))

		"permanent_stat_growth":
			effect.effect_type = ItemEffectData.EffectType.PERMANENT_STAT_GROWTH
			effect.stat_name = StringName(_get_string(row, "stat_name"))
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)

		"learn_skill":
			effect.effect_type = ItemEffectData.EffectType.LEARN_SKILL
			effect.skill_id = StringName(_get_string(row, "skill_id"))

		"unlock_recipe":
			effect.effect_type = ItemEffectData.EffectType.UNLOCK_RECIPE
			effect.recipe_id = StringName(_get_string(row, "recipe_id"))

		"identify_item":
			effect.effect_type = ItemEffectData.EffectType.IDENTIFY_ITEM
			effect.identify_all = _to_bool(_get_string(row, "identify_all", "false"))

		"read_document":
			effect.effect_type = ItemEffectData.EffectType.READ_DOCUMENT
			effect.document_text = _get_string(row, "document_text")

		"spawn_object":
			effect.effect_type = ItemEffectData.EffectType.SPAWN_OBJECT
			effect.spawn_object_id = StringName(_get_string(row, "spawn_object_id"))

		"none", "":
			effect.effect_type = ItemEffectData.EffectType.NONE

		_:
			push_error("unknown effect_type: " + effect_type)
			effect.effect_type = ItemEffectData.EffectType.NONE

	effect.trigger_chance = _normalize_trigger_chance(
		_get_string(row, "trigger_chance", str(effect.trigger_chance)),
		"item_effects.tsv effect_id=" + effect_id + " trigger_chance"
	)

	if effect.uses_status_id():
		_warn_unknown_status_effect_type_if_needed(String(effect.status_id), "item_effects.tsv effect_id=" + effect_id)

	var curse_random_status_count_text := _get_string(row, "curse_random_status_count")
	if curse_random_status_count_text.strip_edges() != "":
		effect.curse_random_status_count = _to_int(curse_random_status_count_text, effect.curse_random_status_count)

	var curse_status_pool_text := _get_string(row, "curse_status_pool")
	if curse_status_pool_text.strip_edges() != "":
		var pool: Array[StringName] = []
		for status_text in _split_list(curse_status_pool_text):
			_warn_unknown_status_effect_type_if_needed(status_text, "item_effects.tsv effect_id=" + effect_id + " curse_status_pool")
			pool.append(StringName(status_text))
		effect.curse_status_pool = pool

	var curse_status_power_overrides_text := _get_string(row, "curse_status_power_overrides")
	if curse_status_power_overrides_text.strip_edges() != "":
		effect.curse_status_power_overrides = _split_int_list(curse_status_power_overrides_text)

	var curse_duration_type_overrides_text := _get_string(row, "curse_duration_type_overrides")
	if curse_duration_type_overrides_text.strip_edges() != "":
		var duration_types: Array[int] = []
		for duration_type_text in _split_list(curse_duration_type_overrides_text):
			duration_types.append(_duration_type_from_text(duration_type_text))
		effect.curse_duration_type_overrides = duration_types

	var curse_duration_value_overrides_text := _get_string(row, "curse_duration_value_overrides")
	if curse_duration_value_overrides_text.strip_edges() != "":
		var duration_values: Array[float] = []
		for duration_value_text in _split_list(curse_duration_value_overrides_text):
			duration_values.append(_to_float(duration_value_text, 0.0))
		effect.curse_duration_value_overrides = duration_values


	return effect


func _resource_type_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"hp":
			return ItemEffectData.ResourceType.HP
		"mp":
			return ItemEffectData.ResourceType.MP
		"stamina":
			return ItemEffectData.ResourceType.STAMINA
		"hunger":
			return ItemEffectData.ResourceType.HUNGER
		_:
			return ItemEffectData.ResourceType.HP


func _value_mode_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"flat":
			return ItemEffectData.ValueMode.FLAT
		"percent":
			return ItemEffectData.ValueMode.PERCENT
		"full":
			return ItemEffectData.ValueMode.FULL
		_:
			return ItemEffectData.ValueMode.FLAT


func _duration_type_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"time":
			return ItemEffectData.DurationType.TIME
		"turn":
			return ItemEffectData.DurationType.TURN
		"action":
			return ItemEffectData.DurationType.ACTION
		"none", "":
			return ItemEffectData.DurationType.NONE
		_:
			return ItemEffectData.DurationType.NONE


func _modifier_kind_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"buff":
			return ItemEffectData.ModifierKind.BUFF
		"debuff":
			return ItemEffectData.ModifierKind.DEBUFF
		_:
			return ItemEffectData.ModifierKind.BUFF


func _teleport_mode_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"random":
			return ItemEffectData.TeleportMode.RANDOM
		"point":
			return ItemEffectData.TeleportMode.POINT
		"home":
			return ItemEffectData.TeleportMode.HOME
		"dungeon_exit":
			return ItemEffectData.TeleportMode.DUNGEON_EXIT
		_:
			return ItemEffectData.TeleportMode.RANDOM


# ============================================================
# ItemEffectLink
# ============================================================

func _load_item_effect_links() -> void:
	var rows := _load_tsv("res://data/master/item_effect_links.tsv")

	for row in rows:
		var item_id := _get_string(row, "item_id").strip_edges()
		var effect_id := _get_string(row, "effect_id").strip_edges()
		var order := _to_int(_get_string(row, "order"), 0)

		if item_id == "" or effect_id == "":
			push_error("item_effect_links has empty item_id or effect_id")
			continue

		if not item_effect_links.has(item_id):
			item_effect_links[item_id] = []

		item_effect_links[item_id].append({
			"effect_id": effect_id,
			"order": order
		})


func _apply_item_effect_links() -> void:
	for item_id in item_effect_links.keys():
		var item: ItemData = items.get(item_id)

		if item == null:
			push_error("effect link item not found: " + String(item_id))
			continue

		var links: Array = item_effect_links[item_id]
		links.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))

		item.effects.clear()

		for link in links:
			var effect_id := String(link["effect_id"])
			var effect: ItemEffectData = effects.get(effect_id)

			if effect == null:
				push_error("effect not found: " + effect_id)
				continue

			item.effects.append(effect)






# ============================================================
# SpawnRuleData
# ============================================================

func _load_unit_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/unit_spawn_rules.tsv")

	for row in rows:
		var rule := _build_unit_spawn_rule_data(row)

		if rule.rule_id == "":
			push_error("unit spawn rule_id is empty")
			continue

		if unit_spawn_rules.has(rule.rule_id):
			push_error("duplicate unit spawn rule_id: " + rule.rule_id)
			continue

		unit_spawn_rules[rule.rule_id] = rule


func _build_unit_spawn_rule_data(row: Dictionary) -> SpawnRuleData:
	var rule := SpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.spawn_kind = _get_string(row, "spawn_kind", rule.spawn_kind).strip_edges().replace("\"", "").to_upper()
	rule.allowed_generator_types = _split_upper_list(_get_string(row, "allowed_generator_types"))
	rule.min_area_difficulty = _to_int(_get_string(row, "min_area_difficulty"), rule.min_area_difficulty)
	rule.max_area_difficulty = _to_int(_get_string(row, "max_area_difficulty"), rule.max_area_difficulty)
	rule.min_enemy_difficulty = _to_int(_get_string(row, "min_enemy_difficulty"), rule.min_enemy_difficulty)
	rule.max_enemy_difficulty = _to_int(_get_string(row, "max_enemy_difficulty"), rule.max_enemy_difficulty)
	rule.use_hour_range = _to_bool(_get_string(row, "use_hour_range", "false"))
	rule.start_hour = _to_int(_get_string(row, "start_hour"), rule.start_hour)
	rule.end_hour = _to_int(_get_string(row, "end_hour"), rule.end_hour)
	rule.min_distance_from_start = _to_int(_get_string(row, "min_distance_from_start"), rule.min_distance_from_start)
	rule.max_distance_from_start = _to_int(_get_string(row, "max_distance_from_start"), rule.max_distance_from_start)
	rule.max_spawn_count = _to_int(_get_string(row, "max_spawn_count"), rule.max_spawn_count)
	rule.weight = _to_int(_get_string(row, "weight"), rule.weight)
	rule.enabled = _to_bool(_get_string(row, "enabled", "true"))

	return rule


# ============================================================
# DungeonSpawnRuleData
# ============================================================

func _load_dungeon_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/dungeon_spawn_rules.tsv")

	for row in rows:
		var rule := _build_dungeon_spawn_rule_data(row)

		if rule.rule_id == "":
			push_error("rule_id is empty")
			continue

		if dungeon_spawn_rules.has(rule.rule_id):
			push_error("duplicate dungeon spawn rule_id: " + rule.rule_id)
			continue

		dungeon_spawn_rules[rule.rule_id] = rule


func _build_dungeon_spawn_rule_data(row: Dictionary) -> DungeonSpawnRuleData:
	var rule := DungeonSpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.spawn_kind = _get_string(row, "spawn_kind", rule.spawn_kind).strip_edges().replace("\"", "").to_upper()
	rule.allowed_generator_themes = _split_upper_list(_get_string(row, "allowed_generator_themes"))
	rule.allowed_layout_generator_types = _split_upper_list(_get_string(row, "allowed_layout_generator_types"))
	rule.min_floor_difficulty = _to_int(_get_string(row, "min_floor_difficulty"), rule.min_floor_difficulty)
	rule.max_floor_difficulty = _to_int(_get_string(row, "max_floor_difficulty"), rule.max_floor_difficulty)
	rule.min_floor_number = _to_int(_get_string(row, "min_floor_number"), rule.min_floor_number)
	rule.max_floor_number = _to_int(_get_string(row, "max_floor_number"), rule.max_floor_number)
	rule.min_enemy_difficulty = _to_int(_get_string(row, "min_enemy_difficulty"), rule.min_enemy_difficulty)
	rule.max_enemy_difficulty = _to_int(_get_string(row, "max_enemy_difficulty"), rule.max_enemy_difficulty)
	rule.max_spawn_count = _to_int(_get_string(row, "max_spawn_count"), rule.max_spawn_count)
	rule.weight = _to_int(_get_string(row, "weight"), rule.weight)
	rule.enabled = _to_bool(_get_string(row, "enabled", "true"))

	return rule


func _split_upper_list(value: String) -> Array[String]:
	var result: Array[String] = []
	value = value.strip_edges()

	if value == "":
		return result

	for part in value.split("|", false):
		var text := String(part).strip_edges().replace("\"", "").to_upper()
		if text == "":
			continue
		result.append(text)

	return result


# ============================================================
# EnchantmentData
# ============================================================

func _load_enchantments() -> void:
	var rows := _load_tsv("res://data/master/enchantments.tsv")

	for row in rows:
		var enchantment := _build_enchantment_data(row)

		if enchantment.enchant_id == "":
			push_error("enchant_id is empty")
			continue

		if enchantments.has(enchantment.enchant_id):
			push_error("duplicate enchant_id: " + enchantment.enchant_id)
			continue

		enchantments[enchantment.enchant_id] = enchantment


func _build_enchantment_data(row: Dictionary) -> EnchantmentData:
	var enchantment := EnchantmentData.new()

	enchantment.enchant_id = _get_string(row, "enchant_id")
	enchantment.display_name = _get_string(row, "display_name", enchantment.display_name)
	enchantment.description = _get_string(row, "description", enchantment.description).replace("\\n", "\n")
	enchantment.effect_type = _to_int(_get_string(row, "effect_type"), int(enchantment.effect_type))
	enchantment.stat_name = _get_string(row, "stat_name", enchantment.stat_name)
	enchantment.min_value = _to_int(_get_string(row, "min_value"), enchantment.min_value)
	enchantment.max_value = _to_int(_get_string(row, "max_value"), enchantment.max_value)
	enchantment.weight = _to_int(_get_string(row, "weight"), enchantment.weight)
	enchantment.allowed_slot_flags = _to_int(_get_string(row, "allowed_slot_flags"), enchantment.allowed_slot_flags)
	enchantment.price_bonus_at_min_value = _to_int(_get_string(row, "price_bonus_at_min_value"), enchantment.price_bonus_at_min_value)
	enchantment.price_bonus_at_max_value = _to_int(_get_string(row, "price_bonus_at_max_value"), enchantment.price_bonus_at_max_value)

	return enchantment


# ============================================================
# UnitRaces
# ============================================================

func _load_unit_races() -> void:
	var rows := _load_optional_tsv("res://data/master/unit_races.tsv")

	for row in rows:
		var race_id := _normalize_unit_race_id(_get_string(row, "race_id"))
		if race_id == "":
			push_warning("unit_races.tsv has empty race_id")
			continue

		var display_name := _get_string(row, "display_name", race_id).strip_edges()
		if display_name == "":
			display_name = race_id

		_register_unit_race(_make_unit_race_entry(
			race_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_get_string(row, "description")
		))

	_ensure_builtin_unit_race_fallbacks()


# ============================================================
# UnitFactions
# ============================================================

func _load_unit_factions() -> void:
	var rows := _load_optional_tsv("res://data/master/unit_factions.tsv")

	for row in rows:
		var faction_id := _normalize_unit_faction_id(_get_string(row, "faction_id"))
		if faction_id == "":
			push_warning("unit_factions.tsv has empty faction_id")
			continue

		var display_name := _get_string(row, "display_name", faction_id).strip_edges()
		if display_name == "":
			display_name = faction_id

		_register_unit_faction(_make_unit_faction_entry(
			faction_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_get_string(row, "description")
		))

	_ensure_builtin_unit_faction_fallbacks()


func _load_faction_relations() -> void:
	var rows := _load_optional_tsv("res://data/master/faction_relations.tsv")

	for row in rows:
		var from_faction := _get_string(row, "from_faction")
		var to_faction := _get_string(row, "to_faction")
		if from_faction.strip_edges() == "" or to_faction.strip_edges() == "":
			push_warning("faction_relations.tsv has empty from_faction or to_faction")
			continue

		_set_faction_relation(
			from_faction,
			to_faction,
			_get_string(row, "relation", DEFAULT_FACTION_RELATION)
		)

	_ensure_builtin_faction_relation_fallbacks()


# ============================================================
# ElementTypes
# ============================================================

func _load_element_types() -> void:
	var rows := _load_optional_tsv("res://data/master/element_types.tsv")

	for row in rows:
		var element_id := _normalize_element_type_id(_get_string(row, "element_id"))
		if element_id == "":
			push_warning("element_types.tsv has empty element_id")
			continue

		var display_name := _get_string(row, "display_name", element_id).strip_edges()
		if display_name == "":
			display_name = element_id

		_register_element_type(_make_element_type_entry(
			element_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_get_string(row, "description")
		))

	_ensure_builtin_element_type_fallbacks()


# ============================================================
# DamageTypes
# ============================================================

func _load_damage_types() -> void:
	var rows := _load_optional_tsv("res://data/master/damage_types.tsv")

	for row in rows:
		var damage_type_id := _normalize_damage_type_id(_get_string(row, "damage_type_id"))
		if damage_type_id == "":
			push_warning("damage_types.tsv has empty damage_type_id")
			continue

		var display_name := _get_string(row, "display_name", damage_type_id).strip_edges()
		if display_name == "":
			display_name = damage_type_id

		_register_damage_type(_make_damage_type_entry(
			damage_type_id,
			display_name,
			_to_int(_get_string(row, "sort_order"), 0),
			_get_string(row, "description")
		))

	_ensure_builtin_damage_type_fallbacks()


# ============================================================
# LocalizationTexts
# ============================================================

func _load_localization_texts() -> void:
	var rows := _load_optional_tsv("res://data/master/localization_texts.tsv")

	for row in rows:
		var text_key := _get_string(row, "text_key").strip_edges()
		if text_key == "":
			push_warning("localization_texts.tsv has empty text_key")
			continue

		if localization_texts.has(text_key):
			push_warning("duplicate localization text_key: " + text_key)
			continue

		var enabled := _to_bool(_get_string(row, "enabled", "true"))
		if not enabled:
			continue

		localization_texts[text_key] = {
			"text_key": text_key,
			"ja": _get_string(row, "ja"),
			"en": _get_string(row, "en"),
			"notes": _get_string(row, "notes"),
			"enabled": true
		}


# ============================================================
# Dialogue
# ============================================================

func _load_dialogue_sets() -> void:
	var rows := _load_optional_tsv("res://data/master/dialogue_sets.tsv")

	for row in rows:
		var dialogue_set_id := _get_string(row, "dialogue_set_id").strip_edges()
		if dialogue_set_id == "":
			push_warning("dialogue_sets.tsv has empty dialogue_set_id")
			continue

		if dialogue_sets.has(dialogue_set_id):
			push_warning("duplicate dialogue_set_id: " + dialogue_set_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		dialogue_sets[dialogue_set_id] = {
			"dialogue_set_id": dialogue_set_id,
			"usage": _get_string(row, "usage"),
			"notes": _get_string(row, "notes"),
			"enabled": true
		}


func _load_dialogue_lines() -> void:
	var rows := _load_optional_tsv("res://data/master/dialogue_lines.tsv")

	for row in rows:
		var dialogue_set_id := _get_string(row, "dialogue_set_id").strip_edges()
		var line_id := _get_string(row, "line_id").strip_edges()
		var context := _get_string(row, "context").strip_edges().to_lower()
		var text_key := _get_string(row, "text_key").strip_edges()

		if dialogue_set_id == "" or line_id == "" or context == "" or text_key == "":
			push_warning("dialogue_lines.tsv has empty required value")
			continue

		if not has_dialogue_set(dialogue_set_id):
			push_warning("dialogue_lines.tsv dialogue_set_id not found or disabled: " + dialogue_set_id)
			continue

		if not has_localized_text(text_key):
			push_warning("dialogue_lines.tsv text_key not found or disabled: " + text_key)

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var entry: Dictionary = {
			"dialogue_set_id": dialogue_set_id,
			"line_id": line_id,
			"context": context,
			"text_key": text_key,
			"weight": max(0.0, _to_float(_get_string(row, "weight"), 1.0)),
			"enabled": true
		}

		if not dialogue_lines_by_set.has(dialogue_set_id):
			dialogue_lines_by_set[dialogue_set_id] = []

		var entries_value: Variant = dialogue_lines_by_set.get(dialogue_set_id, [])
		if typeof(entries_value) != TYPE_ARRAY:
			dialogue_lines_by_set[dialogue_set_id] = []
			entries_value = dialogue_lines_by_set[dialogue_set_id]

		var entries: Array = entries_value
		entries.append(entry)


# ============================================================
# Skills
# ============================================================

func _load_skills() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/skills.tsv")

	for row in rows:
		var skill_id: String = _get_string(row, "skill_id").strip_edges()
		if skill_id == "":
			push_warning("skills.tsv has empty skill_id")
			continue

		if skills.has(skill_id):
			push_warning("duplicate skill_id: " + skill_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var display_name_key: String = _get_string(row, "display_name_key").strip_edges()
		var description_key: String = _get_string(row, "description_key").strip_edges()
		if display_name_key != "" and not has_localized_text(display_name_key):
			push_warning("skills.tsv display_name_key not found or disabled: " + display_name_key)
		if description_key != "" and not has_localized_text(description_key):
			push_warning("skills.tsv description_key not found or disabled: " + description_key)

		var context: String = "skills.tsv skill_id=" + skill_id
		skills[skill_id] = {
			"skill_id": skill_id,
			"category": _normalize_skill_category(_get_string(row, "category"), context + " category"),
			"skill_kind": _normalize_skill_kind(_get_string(row, "skill_kind"), context + " skill_kind"),
			"target_type": _normalize_skill_target_type(_get_string(row, "target_type"), context + " target_type"),
			"effect_polarity": _normalize_skill_effect_polarity(_get_string(row, "effect_polarity"), context + " effect_polarity"),
			"display_name_key": display_name_key,
			"description_key": description_key,
			"max_level": maxi(1, _to_int(_get_string(row, "max_level"), 1)),
			"notes": _get_string(row, "notes"),
			"enabled": true
		}


func _load_skill_levels() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/skill_levels.tsv")

	for row in rows:
		var skill_id: String = _get_string(row, "skill_id").strip_edges()
		if skill_id == "":
			push_warning("skill_levels.tsv has empty skill_id")
			continue

		if not has_skill(skill_id):
			push_warning("skill_levels.tsv skill_id not found or disabled: " + skill_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var level: int = maxi(1, _to_int(_get_string(row, "level"), 1))
		var skill: Dictionary = get_skill(skill_id)
		var max_level: int = int(skill.get("max_level", level))
		if level > max_level:
			push_warning("skill_levels.tsv level exceeds max_level: " + skill_id + " level=" + str(level))
			continue

		if not skill_levels_by_skill.has(skill_id):
			skill_levels_by_skill[skill_id] = {}

		var level_map_value: Variant = skill_levels_by_skill.get(skill_id, {})
		if typeof(level_map_value) != TYPE_DICTIONARY:
			skill_levels_by_skill[skill_id] = {}
			level_map_value = skill_levels_by_skill[skill_id]

		var level_map: Dictionary = level_map_value
		if level_map.has(level):
			push_warning("duplicate skill level: " + skill_id + " level=" + str(level))
			continue

		var context: String = "skill_levels.tsv skill_id=" + skill_id + " level=" + str(level)
		level_map[level] = {
			"skill_id": skill_id,
			"level": level,
			"cost_type": _normalize_skill_cost_type(_get_string(row, "cost_type"), context + " cost_type"),
			"cost_amount": maxf(0.0, _to_float(_get_string(row, "cost_amount"), 0.0)),
			"cooldown": maxf(0.0, _to_float(_get_string(row, "cooldown"), 0.0)),
			"power": _to_float(_get_string(row, "power"), 0.0),
			"duration": maxf(0.0, _to_float(_get_string(row, "duration"), 0.0)),
			"range": maxf(0.0, _to_float(_get_string(row, "range"), 0.0)),
			"success_rate": clampf(_to_float(_get_string(row, "success_rate"), 1.0), 0.0, 1.0),
			"exp_to_next": maxi(0, _to_int(_get_string(row, "exp_to_next"), 0)),
			"enabled": true
		}


func _load_skill_effect_links() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/skill_effect_links.tsv")

	for row in rows:
		var skill_id: String = _get_string(row, "skill_id").strip_edges()
		var effect_id: String = _get_string(row, "effect_id").strip_edges()
		if skill_id == "" or effect_id == "":
			push_warning("skill_effect_links.tsv has empty skill_id or effect_id")
			continue

		if not has_skill(skill_id):
			push_warning("skill_effect_links.tsv skill_id not found or disabled: " + skill_id)
			continue

		if not effects.has(effect_id):
			push_warning("skill_effect_links.tsv effect_id not found: " + effect_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var min_level: int = maxi(1, _to_int(_get_string(row, "min_level"), 1))
		var max_level: int = maxi(min_level, _to_int(_get_string(row, "max_level"), min_level))
		var skill: Dictionary = get_skill(skill_id)
		var skill_max_level: int = int(skill.get("max_level", max_level))
		if max_level > skill_max_level:
			push_warning("skill_effect_links.tsv max_level exceeds skill max_level: " + skill_id + " max_level=" + str(max_level))
			continue

		var context: String = "skill_effect_links.tsv skill_id=" + skill_id + " effect_id=" + effect_id
		var trigger: String = _normalize_skill_trigger(_get_string(row, "trigger"), context + " trigger")
		if trigger == "":
			push_warning("skill_effect_links.tsv has empty or invalid trigger: " + skill_id + " effect_id=" + effect_id)
			continue

		var entry: Dictionary = {
			"skill_id": skill_id,
			"min_level": min_level,
			"max_level": max_level,
			"trigger": trigger,
			"effect_id": effect_id,
			"chance_percent": clampf(_to_float(_get_string(row, "chance_percent"), 100.0), 0.0, 100.0),
			"order": maxi(1, _to_int(_get_string(row, "order"), 1)),
			"enabled": true
		}
		_append_dictionary_array_entry(skill_effect_links_by_skill, skill_id, entry)


func _load_skill_requirements() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/skill_requirements.tsv")

	for row in rows:
		var skill_id: String = _get_string(row, "skill_id").strip_edges()
		if skill_id == "":
			push_warning("skill_requirements.tsv has empty skill_id")
			continue

		if not has_skill(skill_id):
			push_warning("skill_requirements.tsv skill_id not found or disabled: " + skill_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var context: String = "skill_requirements.tsv skill_id=" + skill_id
		var requirement_kind: String = _normalize_skill_requirement_kind(_get_string(row, "requirement_kind"), context + " requirement_kind")
		if requirement_kind == "":
			push_warning("skill_requirements.tsv has empty or invalid requirement_kind: " + skill_id)
			continue

		var entry: Dictionary = {
			"skill_id": skill_id,
			"requirement_kind": requirement_kind,
			"requirement_type": _normalize_skill_requirement_type(_get_string(row, "requirement_type"), context + " requirement_type"),
			"target_id": _get_string(row, "target_id").strip_edges(),
			"required_value": maxf(0.0, _to_float(_get_string(row, "required_value"), 0.0)),
			"enabled": true
		}
		_append_dictionary_array_entry(skill_requirements_by_skill, skill_id, entry)


func _load_unit_skill_tables() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/unit_skill_tables.tsv")

	for row in rows:
		var skill_table_id: String = _get_string(row, "skill_table_id").strip_edges()
		if skill_table_id == "":
			push_warning("unit_skill_tables.tsv has empty skill_table_id")
			continue

		if unit_skill_tables.has(skill_table_id):
			push_warning("duplicate unit skill_table_id: " + skill_table_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		unit_skill_tables[skill_table_id] = {
			"skill_table_id": skill_table_id,
			"usage": _get_string(row, "usage").strip_edges().to_lower(),
			"notes": _get_string(row, "notes"),
			"enabled": true
		}


func _load_unit_skill_entries() -> void:
	var rows: Array[Dictionary] = _load_optional_tsv("res://data/master/unit_skill_entries.tsv")

	for row in rows:
		var skill_table_id: String = _get_string(row, "skill_table_id").strip_edges()
		var entry_id: String = _get_string(row, "entry_id").strip_edges()
		if skill_table_id == "" or entry_id == "":
			push_warning("unit_skill_entries.tsv has empty skill_table_id or entry_id")
			continue

		if not has_unit_skill_table(skill_table_id):
			push_warning("unit_skill_entries.tsv skill_table_id not found or disabled: " + skill_table_id)
			continue

		if not _to_bool(_get_string(row, "enabled", "true")):
			continue

		var context: String = "unit_skill_entries.tsv skill_table_id=" + skill_table_id + " entry_id=" + entry_id
		var pick_type: String = _normalize_unit_skill_pick_type(_get_string(row, "pick_type"), context + " pick_type")
		var skill_id: String = _get_string(row, "skill_id").strip_edges()
		var skill_category: String = _normalize_skill_category(_get_string(row, "skill_category"), context + " skill_category")

		if pick_type == "SKILL":
			if skill_id == "" or not has_skill(skill_id):
				push_warning("unit_skill_entries.tsv skill_id not found or disabled: " + skill_id)
				continue
			skill_category = ""
		elif skill_category == "":
			push_warning("unit_skill_entries.tsv CATEGORY row has empty or invalid skill_category: " + skill_table_id + " entry=" + entry_id)
			continue

		var level_min: int = maxi(0, _to_int(_get_string(row, "level_min"), 0))
		var level_max: int = maxi(level_min, _to_int(_get_string(row, "level_max"), level_min))
		var learned: bool = _to_bool(_get_string(row, "learned", "false"))
		if learned and level_min < 1:
			level_min = 1
			level_max = maxi(level_max, level_min)

		if pick_type == "SKILL":
			var skill: Dictionary = get_skill(skill_id)
			level_max = mini(level_max, int(skill.get("max_level", level_max)))

		var entry: Dictionary = {
			"skill_table_id": skill_table_id,
			"entry_id": entry_id,
			"pick_type": pick_type,
			"skill_id": skill_id,
			"skill_category": skill_category,
			"learned": learned,
			"level_min": level_min,
			"level_max": level_max,
			"exp_min": maxi(0, _to_int(_get_string(row, "exp_min"), 0)),
			"exp_max": maxi(0, _to_int(_get_string(row, "exp_max"), 0)),
			"chance_percent": clampf(_to_float(_get_string(row, "chance_percent"), 100.0), 0.0, 100.0),
			"weight": maxf(0.0, _to_float(_get_string(row, "weight"), 0.0)),
			"enabled": true
		}
		if int(entry.get("exp_max", 0)) < int(entry.get("exp_min", 0)):
			entry["exp_max"] = entry.get("exp_min", 0)

		_append_dictionary_array_entry(unit_skill_entries_by_table, skill_table_id, entry)


# ============================================================
# EnemyData
# ============================================================

func _load_enemies() -> void:
	var rows := _load_tsv("res://data/master/enemies.tsv")

	for row in rows:
		var enemy := _build_enemy_data(row)

		if enemy.enemy_type_id == "":
			push_error("enemy_type_id is empty")
			continue

		if enemies.has(enemy.enemy_type_id):
			push_error("duplicate enemy_type_id: " + enemy.enemy_type_id)
			continue

		enemies[enemy.enemy_type_id] = enemy


func _build_enemy_data(row: Dictionary) -> EnemyData:
	var enemy := EnemyData.new()

	enemy.enemy_type_id = _get_string(row, "enemy_type_id")
	enemy.enemy_name = _get_string(row, "enemy_name", enemy.enemy_name)

	enemy.base_difficulty = _to_int(_get_string(row, "base_difficulty"), enemy.base_difficulty)
	enemy.spawn_generator_tags = _split_list(_get_string(row, "spawn_generator_tags"))
	enemy.habitat_tags = _split_list(_get_string(row, "habitat_tags"))
	enemy.rarity = _to_int(_get_string(row, "rarity"), enemy.rarity)
	enemy.can_be_quest_target = _to_bool(_get_string(row, "can_be_quest_target", "true"))
	enemy.quest_rank = _to_int(_get_string(row, "quest_rank"), enemy.quest_rank)
	enemy.is_nocturnal = _to_bool(_get_string(row, "is_nocturnal", "false"))

	enemy.faction = _normalize_loaded_unit_faction(_get_string(row, "faction", enemy.faction), "enemies.tsv enemy_type_id=" + enemy.enemy_type_id)
	enemy.race = _normalize_loaded_unit_race(_get_string(row, "race"), "enemies.tsv enemy_type_id=" + enemy.enemy_type_id)

	enemy.max_hp = _to_int(_get_string(row, "max_hp"), enemy.max_hp)
	enemy.attack = _to_int(_get_string(row, "attack"), enemy.attack)
	enemy.defense = _to_int(_get_string(row, "defense"), enemy.defense)
	enemy.speed = _to_float(_get_string(row, "speed"), enemy.speed)

	enemy.accuracy = _to_float(_get_string(row, "accuracy"), enemy.accuracy)
	enemy.evasion = _to_float(_get_string(row, "evasion"), enemy.evasion)
	enemy.crit_rate = _to_float(_get_string(row, "crit_rate"), enemy.crit_rate)
	enemy.crit_damage = _to_float(_get_string(row, "crit_damage"), enemy.crit_damage)
	enemy.luck = _to_int(_get_string(row, "luck"), enemy.luck)

	enemy.element = _normalize_loaded_element_type(_get_string(row, "element", enemy.element), "enemies.tsv enemy_type_id=" + enemy.enemy_type_id)
	enemy.default_attack_element = _normalize_loaded_element_type(_get_string(row, "default_attack_element", enemy.default_attack_element), "enemies.tsv enemy_type_id=" + enemy.enemy_type_id + " default_attack_element")
	enemy.default_attack_damage_type = _normalize_loaded_damage_type(_get_string(row, "default_attack_damage_type", enemy.default_attack_damage_type), "enemies.tsv enemy_type_id=" + enemy.enemy_type_id + " default_attack_damage_type")
	enemy.element_resistances = _split_float_dict(_get_string(row, "element_resistances"))
	_warn_unknown_element_resistance_keys(enemy.element_resistances, "enemies.tsv enemy_type_id=" + enemy.enemy_type_id)

	enemy.strength = _to_int(_get_string(row, "strength"), enemy.strength)
	enemy.vitality = _to_int(_get_string(row, "vitality"), enemy.vitality)
	enemy.agility = _to_int(_get_string(row, "agility"), enemy.agility)
	enemy.dexterity = _to_int(_get_string(row, "dexterity"), enemy.dexterity)
	enemy.intelligence = _to_int(_get_string(row, "intelligence"), enemy.intelligence)
	enemy.spirit = _to_int(_get_string(row, "spirit"), enemy.spirit)
	enemy.sense = _to_int(_get_string(row, "sense"), enemy.sense)
	enemy.charm = _to_int(_get_string(row, "charm"), enemy.charm)

	enemy.gathering = _to_int(_get_string(row, "gathering"), enemy.gathering)
	enemy.investigation = _to_int(_get_string(row, "investigation"), enemy.investigation)
	enemy.stealth = _to_int(_get_string(row, "stealth"), enemy.stealth)
	enemy.trap_disarm = _to_int(_get_string(row, "trap_disarm"), enemy.trap_disarm)
	enemy.fishing = _to_int(_get_string(row, "fishing"), enemy.fishing)
	enemy.appraisal = _to_int(_get_string(row, "appraisal"), enemy.appraisal)
	enemy.cooking = _to_int(_get_string(row, "cooking"), enemy.cooking)
	enemy.repair = _to_int(_get_string(row, "repair"), enemy.repair)
	enemy.smithing = _to_int(_get_string(row, "smithing"), enemy.smithing)
	enemy.alchemy = _to_int(_get_string(row, "alchemy"), enemy.alchemy)
	enemy.negotiation = _to_int(_get_string(row, "negotiation"), enemy.negotiation)
	enemy.speech = _to_int(_get_string(row, "speech"), enemy.speech)
	enemy.medical = _to_int(_get_string(row, "medical"), enemy.medical)

	enemy.equipped_weapon = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_weapon"))
	enemy.equipped_armor = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_armor"))
	enemy.equipped_accessory = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory"))

	enemy.equipped_right_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_right_hand"))
	enemy.equipped_left_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_left_hand"))
	enemy.equipped_head = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_head"))
	enemy.equipped_body = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_body"))
	enemy.equipped_hands = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_hands"))
	enemy.equipped_waist = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_waist"))
	enemy.equipped_feet = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_feet"))
	enemy.equipped_accessory_1 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_1"))
	enemy.equipped_accessory_2 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_2"))
	enemy.equipped_accessory_3 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_3"))
	enemy.equipped_accessory_4 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_4"))

	enemy.initial_inventory_table_id = _normalize_loaded_initial_inventory_table_id(
		_get_string(row, "initial_inventory_table_id", enemy.initial_inventory_table_id),
		"enemies.tsv enemy_type_id=" + enemy.enemy_type_id
	)
	enemy.initial_inventory_items = _get_initial_inventory_entries_for_loaded_unit(
		enemy.initial_inventory_table_id,
		_get_string(row, "initial_inventory_items"),
		"enemies.tsv enemy_type_id=" + enemy.enemy_type_id
	)
	enemy.drop_inventory_on_death = _to_bool(_get_string(row, "drop_inventory_on_death", "true"))
	enemy.drop_equipped_items_on_death = _to_bool(_get_string(row, "drop_equipped_items_on_death", "true"))
	enemy.death_inventory_drop_radius = _to_int(_get_string(row, "death_inventory_drop_radius"), enemy.death_inventory_drop_radius)
	enemy.attacked_by_player_behavior = _load_resource_or_null(_get_string(row, "attacked_by_player_behavior_path")) as AttackedBehaviorData

	enemy.override_combat_style = _to_bool(_get_string(row, "override_combat_style", "false"))
	enemy.combat_style = _to_int(_get_string(row, "combat_style"), enemy.combat_style)
	enemy.override_move_style = _to_bool(_get_string(row, "override_move_style", "false"))
	enemy.move_style = _to_int(_get_string(row, "move_style"), enemy.move_style)

	enemy.talk_display_name = _get_string(row, "talk_display_name", enemy.talk_display_name)
	enemy.talk_greeting_text = _get_string(row, "talk_greeting_text", enemy.talk_greeting_text).replace("\\n", "\n")
	enemy.skill_table_id = _normalize_loaded_skill_table_id(
		_get_string(row, "skill_table_id", enemy.skill_table_id),
		"enemies.tsv enemy_type_id=" + enemy.enemy_type_id
	)
	enemy.talk_portrait = _load_resource_or_null(_get_string(row, "talk_portrait_path")) as Texture2D
	enemy.unit_roles = _to_int(_get_string(row, "unit_roles"), enemy.unit_roles)
	enemy.friendliness = _to_int(_get_string(row, "friendliness"), enemy.friendliness)

	enemy.disable_hunger_decay = _to_bool(_get_string(row, "disable_hunger_decay", "true"))
	enemy.auto_eat_food_when_hungry = _to_bool(_get_string(row, "auto_eat_food_when_hungry", "false"))
	enemy.auto_generate_food_when_hungry = _to_bool(_get_string(row, "auto_generate_food_when_hungry", "false"))
	enemy.auto_generated_food_item_id = _get_string(row, "auto_generated_food_item_id", enemy.auto_generated_food_item_id)
	enemy.can_offer_request = _to_bool(_get_string(row, "can_offer_request", "false"))

	enemy.can_trade = _to_bool(_get_string(row, "can_trade", "false"))
	enemy.can_receive_order = _to_bool(_get_string(row, "can_receive_order", "false"))
	enemy.extra_interact_actions = _split_list(_get_string(row, "extra_interact_actions"))
	enemy.can_generate_shop_inventory = _to_bool(_get_string(row, "can_generate_shop_inventory", "false"))
	enemy.shop_min_items = _to_int(_get_string(row, "shop_min_items"), enemy.shop_min_items)
	enemy.shop_max_items = _to_int(_get_string(row, "shop_max_items"), enemy.shop_max_items)

	enemy.request_description = _get_string(row, "request_description", enemy.request_description).replace("\\n", "\n")
	enemy.request_accept_text = _get_string(row, "request_accept_text", enemy.request_accept_text).replace("\\n", "\n")
	enemy.request_decline_text = _get_string(row, "request_decline_text", enemy.request_decline_text).replace("\\n", "\n")
	enemy.random_talk_texts = _split_list(_get_string(row, "random_talk_texts"))

	enemy.animation_profile = _load_resource_or_null(_get_string(row, "animation_profile_path")) as AnimationProfile
	enemy.sprite_scale = Vector2(
		_to_float(_get_string(row, "sprite_scale_x"), 1.0),
		_to_float(_get_string(row, "sprite_scale_y"), 1.0)
	)

	enemy.idle_right_frames = _split_texture_array(_get_string(row, "idle_right_frames"))
	enemy.walk_right_frames = _split_texture_array(_get_string(row, "walk_right_frames"))
	enemy.idle_left_frames = _split_texture_array(_get_string(row, "idle_left_frames"))
	enemy.walk_left_frames = _split_texture_array(_get_string(row, "walk_left_frames"))
	enemy.idle_down_frames = _split_texture_array(_get_string(row, "idle_down_frames"))
	enemy.walk_down_frames = _split_texture_array(_get_string(row, "walk_down_frames"))
	enemy.idle_up_frames = _split_texture_array(_get_string(row, "idle_up_frames"))
	enemy.walk_up_frames = _split_texture_array(_get_string(row, "walk_up_frames"))

	return enemy



# ============================================================
# NpcData
# ============================================================

func _load_npcs() -> void:
	var rows := _load_tsv("res://data/master/npcs.tsv")

	for row in rows:
		var npc := _build_npc_data(row)

		if npc.npc_type_id == "":
			push_error("npc_type_id is empty")
			continue

		if npcs.has(npc.npc_type_id):
			push_error("duplicate npc_type_id: " + npc.npc_type_id)
			continue

		npcs[npc.npc_type_id] = npc


func _build_npc_data(row: Dictionary) -> NpcData:
	var npc := NpcData.new()

	npc.npc_name = _get_string(row, "npc_name", npc.npc_name)
	npc.npc_type_id = _get_string(row, "npc_type_id")
	npc.faction = _normalize_loaded_unit_faction(_get_string(row, "faction", npc.faction), "npcs.tsv npc_type_id=" + npc.npc_type_id)
	npc.race = _normalize_loaded_unit_race(_get_string(row, "race"), "npcs.tsv npc_type_id=" + npc.npc_type_id)

	npc.base_difficulty = _to_int(_get_string(row, "base_difficulty"), npc.base_difficulty)
	npc.spawn_generator_tags = _split_list(_get_string(row, "spawn_generator_tags"))
	npc.rarity = _to_int(_get_string(row, "rarity"), npc.rarity)
	npc.is_nocturnal = _to_bool(_get_string(row, "is_nocturnal", "false"))

	npc.max_hp = _to_int(_get_string(row, "max_hp"), npc.max_hp)
	npc.attack = _to_int(_get_string(row, "attack"), npc.attack)
	npc.defense = _to_int(_get_string(row, "defense"), npc.defense)
	npc.speed = _to_float(_get_string(row, "speed"), npc.speed)

	npc.accuracy = _to_float(_get_string(row, "accuracy"), npc.accuracy)
	npc.evasion = _to_float(_get_string(row, "evasion"), npc.evasion)
	npc.crit_rate = _to_float(_get_string(row, "crit_rate"), npc.crit_rate)
	npc.crit_damage = _to_float(_get_string(row, "crit_damage"), npc.crit_damage)
	npc.luck = _to_int(_get_string(row, "luck"), npc.luck)

	npc.element = _normalize_loaded_element_type(_get_string(row, "element", npc.element), "npcs.tsv npc_type_id=" + npc.npc_type_id)
	npc.default_attack_element = _normalize_loaded_element_type(_get_string(row, "default_attack_element", npc.default_attack_element), "npcs.tsv npc_type_id=" + npc.npc_type_id + " default_attack_element")
	npc.default_attack_damage_type = _normalize_loaded_damage_type(_get_string(row, "default_attack_damage_type", npc.default_attack_damage_type), "npcs.tsv npc_type_id=" + npc.npc_type_id + " default_attack_damage_type")
	npc.element_resistances = _split_float_dict(_get_string(row, "element_resistances"))
	_warn_unknown_element_resistance_keys(npc.element_resistances, "npcs.tsv npc_type_id=" + npc.npc_type_id)

	npc.strength = _to_int(_get_string(row, "strength"), npc.strength)
	npc.vitality = _to_int(_get_string(row, "vitality"), npc.vitality)
	npc.agility = _to_int(_get_string(row, "agility"), npc.agility)
	npc.dexterity = _to_int(_get_string(row, "dexterity"), npc.dexterity)
	npc.intelligence = _to_int(_get_string(row, "intelligence"), npc.intelligence)
	npc.spirit = _to_int(_get_string(row, "spirit"), npc.spirit)
	npc.sense = _to_int(_get_string(row, "sense"), npc.sense)
	npc.charm = _to_int(_get_string(row, "charm"), npc.charm)

	npc.gathering = _to_int(_get_string(row, "gathering"), npc.gathering)
	npc.investigation = _to_int(_get_string(row, "investigation"), npc.investigation)
	npc.stealth = _to_int(_get_string(row, "stealth"), npc.stealth)
	npc.trap_disarm = _to_int(_get_string(row, "trap_disarm"), npc.trap_disarm)
	npc.fishing = _to_int(_get_string(row, "fishing"), npc.fishing)
	npc.appraisal = _to_int(_get_string(row, "appraisal"), npc.appraisal)
	npc.cooking = _to_int(_get_string(row, "cooking"), npc.cooking)
	npc.repair = _to_int(_get_string(row, "repair"), npc.repair)
	npc.smithing = _to_int(_get_string(row, "smithing"), npc.smithing)
	npc.alchemy = _to_int(_get_string(row, "alchemy"), npc.alchemy)
	npc.negotiation = _to_int(_get_string(row, "negotiation"), npc.negotiation)
	npc.speech = _to_int(_get_string(row, "speech"), npc.speech)
	npc.medical = _to_int(_get_string(row, "medical"), npc.medical)

	npc.equipped_weapon = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_weapon"))
	npc.equipped_armor = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_armor"))
	npc.equipped_accessory = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory"))
	npc.equipped_right_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_right_hand"))
	npc.equipped_left_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_left_hand"))
	npc.equipped_head = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_head"))
	npc.equipped_body = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_body"))
	npc.equipped_hands = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_hands"))
	npc.equipped_waist = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_waist"))
	npc.equipped_feet = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_feet"))
	npc.equipped_accessory_1 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_1"))
	npc.equipped_accessory_2 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_2"))
	npc.equipped_accessory_3 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_3"))
	npc.equipped_accessory_4 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_4"))

	npc.initial_inventory_table_id = _normalize_loaded_initial_inventory_table_id(
		_get_string(row, "initial_inventory_table_id", npc.initial_inventory_table_id),
		"npcs.tsv npc_type_id=" + npc.npc_type_id
	)
	npc.initial_inventory_items = _get_initial_inventory_entries_for_loaded_unit(
		npc.initial_inventory_table_id,
		_get_string(row, "initial_inventory_items"),
		"npcs.tsv npc_type_id=" + npc.npc_type_id
	)
	npc.drop_inventory_on_death = _to_bool(_get_string(row, "drop_inventory_on_death", "true"))
	npc.drop_equipped_items_on_death = _to_bool(_get_string(row, "drop_equipped_items_on_death", "true"))
	npc.death_inventory_drop_radius = _to_int(_get_string(row, "death_inventory_drop_radius"), npc.death_inventory_drop_radius)
	npc.attacked_by_player_behavior = _load_resource_or_null(_get_string(row, "attacked_by_player_behavior_path")) as AttackedBehaviorData

	npc.override_combat_style = _to_bool(_get_string(row, "override_combat_style", "false"))
	npc.combat_style = _to_int(_get_string(row, "combat_style"), npc.combat_style)
	npc.override_move_style = _to_bool(_get_string(row, "override_move_style", "true"))
	npc.move_style = _to_int(_get_string(row, "move_style"), npc.move_style)

	npc.talk_display_name = _get_string(row, "talk_display_name", npc.talk_display_name)
	npc.talk_greeting_text = _get_string(row, "talk_greeting_text", npc.talk_greeting_text).replace("\\n", "\n")
	npc.dialogue_set_id = _get_string(row, "dialogue_set_id", npc.dialogue_set_id).strip_edges()
	npc.skill_table_id = _normalize_loaded_skill_table_id(
		_get_string(row, "skill_table_id", npc.skill_table_id),
		"npcs.tsv npc_type_id=" + npc.npc_type_id
	)
	npc.talk_portrait = _load_resource_or_null(_get_string(row, "talk_portrait_path")) as Texture2D
	npc.unit_roles = _to_int(_get_string(row, "unit_roles"), npc.unit_roles)
	npc.friendliness = _to_int(_get_string(row, "friendliness"), npc.friendliness)

	npc.disable_hunger_decay = _to_bool(_get_string(row, "disable_hunger_decay", "false"))
	npc.auto_eat_food_when_hungry = _to_bool(_get_string(row, "auto_eat_food_when_hungry", "true"))
	npc.auto_generate_food_when_hungry = _to_bool(_get_string(row, "auto_generate_food_when_hungry", "true"))
	npc.auto_generated_food_item_id = _get_string(row, "auto_generated_food_item_id", npc.auto_generated_food_item_id)
	npc.can_offer_request = _to_bool(_get_string(row, "can_offer_request", "false"))

	npc.can_trade = _to_bool(_get_string(row, "can_trade", "false"))
	npc.can_receive_order = _to_bool(_get_string(row, "can_receive_order", "false"))
	npc.extra_interact_actions = _split_list(_get_string(row, "extra_interact_actions"))

	npc.can_generate_shop_inventory = _to_bool(_get_string(row, "can_generate_shop_inventory", "false"))
	npc.shop_table_id = _normalize_loaded_shop_table_id(
		_get_string(row, "shop_table_id", npc.shop_table_id),
		"npcs.tsv npc_type_id=" + npc.npc_type_id
	)
	npc.shop_min_items = _to_int(_get_string(row, "shop_min_items"), npc.shop_min_items)
	npc.shop_max_items = _to_int(_get_string(row, "shop_max_items"), npc.shop_max_items)
	npc.shop_loot_categories = _split_loot_categories(_get_string(row, "shop_loot_categories"))

	npc.request_description = _get_string(row, "request_description", npc.request_description).replace("\\n", "\n")
	npc.request_accept_text = _get_string(row, "request_accept_text", npc.request_accept_text).replace("\\n", "\n")
	npc.request_decline_text = _get_string(row, "request_decline_text", npc.request_decline_text).replace("\\n", "\n")
	npc.random_talk_texts = _split_list(_get_string(row, "random_talk_texts"))

	npc.animation_profile = _load_resource_or_null(_get_string(row, "animation_profile_path")) as AnimationProfile
	npc.sprite_scale = Vector2(
		_to_float(_get_string(row, "sprite_scale_x"), 1.0),
		_to_float(_get_string(row, "sprite_scale_y"), 1.0)
	)

	npc.idle_right_frames = _split_texture_array(_get_string(row, "idle_right_frames"))
	npc.walk_right_frames = _split_texture_array(_get_string(row, "walk_right_frames"))
	npc.idle_left_frames = _split_texture_array(_get_string(row, "idle_left_frames"))
	npc.walk_left_frames = _split_texture_array(_get_string(row, "walk_left_frames"))
	npc.idle_down_frames = _split_texture_array(_get_string(row, "idle_down_frames"))
	npc.walk_down_frames = _split_texture_array(_get_string(row, "walk_down_frames"))
	npc.idle_up_frames = _split_texture_array(_get_string(row, "idle_up_frames"))
	npc.walk_up_frames = _split_texture_array(_get_string(row, "walk_up_frames"))

	return npc


# ============================================================
# QuestData
# ============================================================

func _load_quests() -> void:
	var rows := _load_tsv("res://data/master/quests.tsv")

	for row in rows:
		var quest := QuestData.new()

		quest.quest_id = _get_string(row, "quest_id")
		quest.title = _get_string(row, "title")
		quest.description = _get_string(row, "description")
		quest.title_template = _get_string(row, "title_template")
		quest.description_template = _get_string(row, "description_template")
		quest.objective_type = _quest_objective_type_from_text(_get_string(row, "objective_type", "DELIVER_ITEM"))

		quest.objective_item_id = _get_string(row, "objective_item_id")
		quest.objective_item_amount = _to_int(_get_string(row, "objective_item_amount"), 1)
		quest.candidate_item_ids = _split_list(_get_string(row, "candidate_item_ids"))
		quest.candidate_categories = _split_list(_get_string(row, "candidate_categories"))

		quest.amount_min = _to_int(_get_string(row, "amount_min"), 1)
		quest.amount_max = _to_int(_get_string(row, "amount_max"), quest.amount_min)
		quest.time_limit_seconds = _to_float(_get_string(row, "time_limit_seconds"), 0.0)

		quest.reward_gold = _to_int(_get_string(row, "reward_gold"), 0)
		quest.reward_bonus_rate_min = _to_float(_get_string(row, "reward_bonus_rate_min"), 1.0)
		quest.reward_bonus_rate_max = _to_float(_get_string(row, "reward_bonus_rate_max"), quest.reward_bonus_rate_min)

		quest.reward_item_ids = _split_list(_get_string(row, "reward_item_ids"))
		quest.reward_item_amounts = _split_int_list(_get_string(row, "reward_item_amounts"))

		quest.allowed_unit_role_flags = _role_flags_from_text(_get_string(row, "allowed_unit_role_flags"))
		quest.weight = _to_int(_get_string(row, "weight"), 100)
		quest.repeatable = _to_bool(_get_string(row, "repeatable", "true"))

		quest.accept_text = _get_string(row, "accept_text")
		quest.progress_text = _get_string(row, "progress_text")
		quest.ready_to_complete_text = _get_string(row, "ready_to_complete_text")
		quest.completed_text = _get_string(row, "completed_text")
		quest.failed_text = _get_string(row, "failed_text")

		if quest.quest_id == "":
			push_error("quest_id is empty")
			continue

		if quests.has(quest.quest_id):
			push_error("duplicate quest_id: " + quest.quest_id)
			continue

		quests[quest.quest_id] = quest


func _load_npc_quest_links() -> void:
	var rows := _load_optional_tsv("res://data/master/npc_quest_links.tsv")

	for row in rows:
		var npc_type_id := _get_string(row, "npc_type_id").strip_edges()
		var quest_id := _get_string(row, "quest_id").strip_edges()

		if npc_type_id == "" or quest_id == "":
			push_warning("npc_quest_links.tsv has empty npc_type_id or quest_id")
			continue

		if not has_npc(npc_type_id):
			push_warning("npc_quest_links.tsv npc_type_id not found: " + npc_type_id)

		if not has_quest(quest_id):
			push_warning("npc_quest_links.tsv quest_id not found: " + quest_id)

		var entry := {
			"npc_type_id": npc_type_id,
			"quest_id": quest_id,
			"weight": max(_to_int(_get_string(row, "weight"), 100), 0),
			"enabled": _to_bool(_get_string(row, "enabled", "true"))
		}

		npc_quest_links.append(entry)

		if not bool(entry.get("enabled", true)):
			continue

		if not npc_quest_links_by_npc.has(npc_type_id):
			npc_quest_links_by_npc[npc_type_id] = []

		var entries_value: Variant = npc_quest_links_by_npc.get(npc_type_id, [])
		if typeof(entries_value) != TYPE_ARRAY:
			npc_quest_links_by_npc[npc_type_id] = []
			entries_value = npc_quest_links_by_npc[npc_type_id]

		var entries: Array = entries_value
		entries.append(entry)


func _quest_objective_type_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"DELIVER_ITEM":
			return QuestData.ObjectiveType.DELIVER_ITEM
		"NONE", "":
			return QuestData.ObjectiveType.NONE
		_:
			push_warning("unknown quest objective_type: " + value)
			return QuestData.ObjectiveType.NONE


# 注意:
# ここは既存の UnitRole / role_flags の定義に合わせて後で調整してください。
# 現時点では、以前の想定に合わせて VILLAGER=1, MERCHANT=2, GUARD=4 としています。
func _role_flags_from_text(value: String) -> int:
	var result := 0

	for text in _split_list(value):
		match text.strip_edges().to_upper():
			"VILLAGER":
				result |= 1
			"MERCHANT":
				result |= 2
			"GUARD":
				result |= 4
			"":
				pass
			_:
				push_warning("unknown role flag: " + text)

	return result


# ============================================================
# Validate
# ============================================================

func validate_all() -> void:
	_validate_items()
	_validate_item_effects()
	_validate_quests()


func _validate_items() -> void:
	for item_id in items.keys():
		var item: ItemData = items[item_id]

		if item == null:
			push_error("item is null: " + String(item_id))
			continue

		if item.item_id == "":
			push_error("item has empty item_id")

		if item.category != "" and not has_item_category(item.category):
			_warn_unknown_item_category(item.category, "validate item_id=" + String(item_id))

		if item.icon == null and item.category != "":
			push_warning("item icon is null: " + String(item_id))


func _validate_item_effects() -> void:
	for item_id in item_effect_links.keys():
		if not items.has(item_id):
			push_error("item_effect_links item_id not found: " + String(item_id))

		for link in item_effect_links[item_id]:
			var effect_id := String(link.get("effect_id", ""))

			if not effects.has(effect_id):
				push_error("item_effect_links effect_id not found: " + effect_id)


func _validate_quests() -> void:
	for quest_id in quests.keys():
		var quest: QuestData = quests[quest_id]

		if quest == null:
			push_error("quest is null: " + String(quest_id))
			continue

		for item_id in quest.candidate_item_ids:
			if not items.has(item_id):
				push_error("quest candidate item not found: %s item=%s" % [quest_id, item_id])

		for item_id in quest.reward_item_ids:
			if not items.has(item_id):
				push_error("quest reward item not found: %s item=%s" % [quest_id, item_id])

		if quest.reward_item_amounts.size() > 0 and quest.reward_item_ids.size() != quest.reward_item_amounts.size():
			push_error("quest reward ids/amounts size mismatch: " + String(quest_id))


func _count_chest_loot_entries() -> int:
	var count := 0

	for entries_value in chest_loot_tables.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_shop_loot_entries() -> int:
	var count := 0

	for entries_value in shop_loot_tables.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_initial_inventory_entries() -> int:
	var count := 0

	for entries_value in initial_inventory_entries.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_dialogue_lines() -> int:
	var count := 0

	for entries_value in dialogue_lines_by_set.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_skill_levels() -> int:
	var count := 0

	for entries_value in skill_levels_by_skill.values():
		if typeof(entries_value) != TYPE_DICTIONARY:
			continue

		var entries: Dictionary = entries_value
		count += entries.size()

	return count


func _count_skill_effect_links() -> int:
	var count := 0

	for entries_value in skill_effect_links_by_skill.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_skill_requirements() -> int:
	var count := 0

	for entries_value in skill_requirements_by_skill.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_unit_skill_entries() -> int:
	var count := 0

	for entries_value in unit_skill_entries_by_table.values():
		if typeof(entries_value) != TYPE_ARRAY:
			continue

		var entries: Array = entries_value
		count += entries.size()

	return count


func _count_item_spawn_rule_category_multiplier_entries() -> int:
	var count := 0

	for entries_value in item_spawn_rule_category_multipliers.values():
		if typeof(entries_value) != TYPE_DICTIONARY:
			continue

		var entries: Dictionary = entries_value
		count += entries.size()

	return count


func _count_item_spawn_rule_item_override_entries() -> int:
	var count := 0

	for entries_value in item_spawn_rule_item_overrides.values():
		if typeof(entries_value) != TYPE_DICTIONARY:
			continue

		var entries: Dictionary = entries_value
		count += entries.size()

	return count


func debug_print_loaded_data() -> void:
	print("========== GameData Loaded ==========")
	print("[GameData] items: ", items.size())
	print("[GameData] effects: ", effects.size())
	print("[GameData] item_effect_links: ", item_effect_links.size())
	print("[GameData] quests: ", quests.size())
	print("[GameData] npc_quest_links: ", npc_quest_links.size())
	print("[GameData] enemies: ", enemies.size())
	print("[GameData] npcs: ", npcs.size())
	print("[GameData] enchantments: ", enchantments.size())
	print("[GameData] item_spawn_rules: ", item_spawn_rules.size())
	print("[GameData] item_spawn_rule_category_multipliers: ", _count_item_spawn_rule_category_multiplier_entries())
	print("[GameData] item_spawn_rule_item_overrides: ", _count_item_spawn_rule_item_override_entries())
	print("[GameData] dungeon_spawn_rules: ", dungeon_spawn_rules.size())
	print("[GameData] unit_spawn_rules: ", unit_spawn_rules.size())
	print("[GameData] chest_tables: ", chest_tables.size())
	print("[GameData] chest_loot_entries: ", _count_chest_loot_entries())
	print("[GameData] shop_tables: ", shop_tables.size())
	print("[GameData] shop_loot_entries: ", _count_shop_loot_entries())
	print("[GameData] initial_inventory_tables: ", initial_inventory_tables.size())
	print("[GameData] initial_inventory_entries: ", _count_initial_inventory_entries())
	print("[GameData] item_categories: ", item_categories.size())
	print("[GameData] unit_races: ", unit_races.size())
	print("[GameData] unit_factions: ", unit_factions.size())
	print("[GameData] faction_relations: ", faction_relations.size())
	print("[GameData] element_types: ", element_types.size())
	print("[GameData] damage_types: ", damage_types.size())
	print("[GameData] status_effect_types: ", status_effect_types.size())
	print("[GameData] localization_texts: ", localization_texts.size())
	print("[GameData] dialogue_sets: ", dialogue_sets.size())
	print("[GameData] dialogue_lines: ", _count_dialogue_lines())
	print("[GameData] skills: ", skills.size())
	print("[GameData] skill_levels: ", _count_skill_levels())
	print("[GameData] skill_effect_links: ", _count_skill_effect_links())
	print("[GameData] skill_requirements: ", _count_skill_requirements())
	print("[GameData] unit_skill_tables: ", unit_skill_tables.size())
	print("[GameData] unit_skill_entries: ", _count_unit_skill_entries())

	print("---------- Items ----------")
	for item_id in items.keys():
		var item: ItemData = items[item_id]

		if item == null:
			print("item: ", item_id, " is null")
			continue

		var effect_count := 0
		if "effects" in item and item.effects != null:
			effect_count = item.effects.size()

		print(
			"item: ",
			item_id,
			" name=",
			item.display_name,
			" category=",
			item.category,
			" price=",
			item.base_price,
			" can_sell=",
			item.can_sell,
			" effects=",
			effect_count
		)

	print("---------- Effects ----------")
	for effect_id in effects.keys():
		var effect: ItemEffectData = effects[effect_id]

		if effect == null:
			print("effect: ", effect_id, " is null")
			continue

		print(
			"effect: ",
			effect_id,
			" type=",
			effect.get_effect_type_name()
		)

	print("---------- Item Effect Links ----------")
	for item_id in item_effect_links.keys():
		print("links for item: ", item_id, " links=", item_effect_links[item_id])

	print("---------- NPCs ----------")
	for npc_id in npcs.keys():
		var npc: NpcData = npcs[npc_id]
		if npc == null:
			continue
		print(
			"npc: ",
			npc_id,
			" name=",
			npc.npc_name,
			" roles=",
			npc.unit_roles,
			" trade=",
			npc.can_trade,
			" request=",
			npc.can_offer_request
		)

	print("---------- Unit Spawn Rules ----------")
	for rule_id in unit_spawn_rules.keys():
		var rule: SpawnRuleData = unit_spawn_rules[rule_id]
		if rule == null:
			continue
		print(
			"unit_spawn_rule: ",
			rule_id,
			" kind=",
			rule.spawn_kind,
			" generators=",
			rule.allowed_generator_types,
			" area=",
			rule.min_area_difficulty,
			"-",
			rule.max_area_difficulty,
			" count=",
			rule.max_spawn_count
		)

	print("---------- Dungeon Spawn Rules ----------")
	for rule_id in dungeon_spawn_rules.keys():
		var rule: DungeonSpawnRuleData = dungeon_spawn_rules[rule_id]
		if rule == null:
			continue
		print(
			"dungeon_rule: ",
			rule_id,
			" kind=",
			rule.spawn_kind,
			" themes=",
			rule.allowed_generator_themes,
			" layouts=",
			rule.allowed_layout_generator_types,
			" count=",
			rule.max_spawn_count
		)

	print("---------- Enchantments ----------")
	for enchant_id in enchantments.keys():
		var enchantment: EnchantmentData = enchantments[enchant_id]
		if enchantment == null:
			continue
		print(
			"enchantment: ",
			enchant_id,
			" name=",
			enchantment.display_name,
			" stat=",
			enchantment.stat_name,
			" value=",
			enchantment.min_value,
			"-",
			enchantment.max_value
		)

	print("---------- Enemies ----------")
	for enemy_id in enemies.keys():
		var enemy: EnemyData = enemies[enemy_id]
		if enemy == null:
			continue
		print(
			"enemy: ",
			enemy_id,
			" name=",
			enemy.enemy_name,
			" difficulty=",
			enemy.base_difficulty,
			" hp=",
			enemy.max_hp,
			" atk=",
			enemy.attack,
			" tags=",
			enemy.spawn_generator_tags
		)

	print("---------- Quests ----------")
	for quest_id in quests.keys():
		var quest: QuestData = quests[quest_id]

		if quest == null:
			print("quest: ", quest_id, " is null")
			continue

		print(
			"quest: ",
			quest_id,
			" title=",
			quest.title,
			" objective_item_id=",
			quest.objective_item_id,
			" objective_amount=",
			quest.objective_item_amount,
			" candidate_items=",
			quest.candidate_item_ids,
			" candidate_categories=",
			quest.candidate_categories,
			" reward_items=",
			quest.reward_item_ids
		)

	print("---------- Item Spawn Rules ----------")
	for rule in item_spawn_rules:
		if rule == null:
			continue
		print(
			"spawn_rule: ",
			rule.rule_id,
			" map_kind=",
			rule.map_kind,
			" count=",
			rule.base_item_count_min,
			"-",
			rule.base_item_count_max,
			" category_multipliers=",
			rule.category_multipliers
		)

	print("---------- ItemDatabase TSV access ----------")
	if ItemDatabase != null:
		print("[ItemDatabase] all item ids size: ", ItemDatabase.get_all_item_ids().size())
		print("[ItemDatabase] potion name: ", ItemDatabase.get_display_name("potion"))
		print("[ItemDatabase] apple name: ", ItemDatabase.get_display_name("apple"))
		print("[ItemDatabase] potion sell price: ", ItemDatabase.get_sell_price("potion"))
		print("[ItemDatabase] consumable ids: ", ItemDatabase.get_item_ids_by_category("consumable"))
		print("[ItemDatabase] equipment ids: ", ItemDatabase.get_item_ids_by_category("equipment"))
	else:
		print("[ItemDatabase] null")

	print("=======================================")


# ============================================================
# ItemSpawnRuleData
# ============================================================

func _load_item_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/spawn_rules.tsv")

	for row in rows:
		var rule := _build_item_spawn_rule(row)

		if rule.rule_id == "":
			push_error("spawn rule_id is empty")
			continue

		if has_item_spawn_rule(rule.rule_id):
			push_error("duplicate spawn rule_id: " + rule.rule_id)
			continue

		item_spawn_rules.append(rule)

	item_spawn_rules.sort_custom(func(a: ItemSpawnRuleData, b: ItemSpawnRuleData) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		return a.priority > b.priority
	)


func _load_item_spawn_rule_category_multipliers() -> void:
	var rows := _load_optional_tsv("res://data/master/item_spawn_rule_category_multipliers.tsv")

	for row in rows:
		var rule_id := _normalize_item_spawn_rule_id(_get_string(row, "rule_id"))
		if rule_id == "":
			push_warning("item_spawn_rule_category_multipliers.tsv has empty rule_id")
			continue

		var category := _normalize_item_category_id(_get_string(row, "category"))
		var context := "item_spawn_rule_category_multipliers.tsv rule_id=" + rule_id
		if category == "":
			push_warning(context + " has empty category")
			continue

		if not has_item_category(category):
			_warn_unknown_item_category(category, context)
			continue

		var multiplier: float = max(_to_float(_get_string(row, "multiplier"), 1.0), 0.0)

		var entries_value: Variant = item_spawn_rule_category_multipliers.get(rule_id, {})
		if typeof(entries_value) != TYPE_DICTIONARY:
			entries_value = {}

		var entries: Dictionary = entries_value
		entries[category] = multiplier
		item_spawn_rule_category_multipliers[rule_id] = entries


func _load_item_spawn_rule_item_overrides() -> void:
	var rows := _load_optional_tsv("res://data/master/item_spawn_rule_item_overrides.tsv")

	for row in rows:
		var rule_id := _normalize_item_spawn_rule_id(_get_string(row, "rule_id"))
		if rule_id == "":
			push_warning("item_spawn_rule_item_overrides.tsv has empty rule_id")
			continue

		var item_id := _get_string(row, "item_id").strip_edges()
		var context := "item_spawn_rule_item_overrides.tsv rule_id=" + rule_id
		if item_id == "":
			push_warning(context + " has empty item_id")
			continue

		if not has_item(item_id):
			push_warning(context + " item_id not found: " + item_id)

		var weight: int = max(_to_int(_get_string(row, "weight"), 0), 0)

		var entries_value: Variant = item_spawn_rule_item_overrides.get(rule_id, {})
		if typeof(entries_value) != TYPE_DICTIONARY:
			entries_value = {}

		var entries: Dictionary = entries_value
		entries[item_id] = weight
		item_spawn_rule_item_overrides[rule_id] = entries


func _build_item_spawn_rule(row: Dictionary) -> ItemSpawnRuleData:
	var rule := ItemSpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.is_base_rule = _to_bool(_get_string(row, "is_base_rule", "true"))
	rule.priority = _to_int(_get_string(row, "priority"), 0)

	rule.map_kind = _get_string(row, "map_kind")
	rule.generator_theme = _get_string(row, "generator_theme")
	rule.detail_generator = _get_string(row, "detail_generator")

	rule.difficulty_min = _to_int(_get_string(row, "difficulty_min"), 0)
	rule.difficulty_max = _to_int(_get_string(row, "difficulty_max"), 9999)
	rule.floor_min = _to_int(_get_string(row, "floor_min"), 0)
	rule.floor_max = _to_int(_get_string(row, "floor_max"), 9999)
	rule.final_floor_only = _to_bool(_get_string(row, "final_floor_only", "false"))

	rule.base_item_count_min = _to_int(_get_string(row, "base_item_count_min"), 0)
	rule.base_item_count_max = _to_int(_get_string(row, "base_item_count_max"), 0)
	rule.difficulty_item_count_scale = _to_float(_get_string(row, "difficulty_item_count_scale"), 0.0)

	rule.base_rarity_target = _to_float(_get_string(row, "base_rarity_target"), 1.0)
	rule.difficulty_rarity_scale = _to_float(_get_string(row, "difficulty_rarity_scale"), 0.03)
	rule.final_floor_rarity_bonus = _to_float(_get_string(row, "final_floor_rarity_bonus"), 0.0)
	rule.rarity_step_penalty = _to_float(_get_string(row, "rarity_step_penalty"), 0.35)

	rule.blocked_categories = _split_list(_get_string(row, "blocked_categories"))
	rule.blocked_item_ids = _split_list(_get_string(row, "blocked_item_ids"))

	var category_multipliers_from_child := get_item_spawn_rule_category_multipliers(rule.rule_id)
	if category_multipliers_from_child.is_empty():
		rule.category_multipliers = _split_float_dict(_get_string(row, "category_multipliers"))
	else:
		rule.category_multipliers = category_multipliers_from_child

	var item_weight_overrides_from_child := get_item_spawn_rule_item_overrides(rule.rule_id)
	if item_weight_overrides_from_child.is_empty():
		rule.item_weight_overrides = _split_int_dict(_get_string(row, "item_weight_overrides"))
	else:
		rule.item_weight_overrides = item_weight_overrides_from_child

	return rule
