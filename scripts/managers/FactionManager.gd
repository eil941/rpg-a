extends Node

const RELATION_FRIENDLY := 1
const RELATION_NEUTRAL := 0
const RELATION_HOSTILE := -1

const FACTION_PLAYER := "PLAYER"
const FACTION_NPC := "NPC"
const FACTION_ENEMY := "ENEMY"
const FACTION_NEUTRAL := "NEUTRAL"

const RELATION_TEXT_FRIENDLY := "FRIENDLY"
const RELATION_TEXT_NEUTRAL := "NEUTRAL"
const RELATION_TEXT_HOSTILE := "HOSTILE"

var faction_relations := {
	FACTION_PLAYER: {
		FACTION_PLAYER: RELATION_FRIENDLY,
		FACTION_NPC: RELATION_FRIENDLY,
		FACTION_ENEMY: RELATION_HOSTILE,
		FACTION_NEUTRAL: RELATION_NEUTRAL,
	},
	FACTION_NPC: {
		FACTION_PLAYER: RELATION_FRIENDLY,
		FACTION_NPC: RELATION_FRIENDLY,
		FACTION_ENEMY: RELATION_HOSTILE,
		FACTION_NEUTRAL: RELATION_NEUTRAL,
	},
	FACTION_ENEMY: {
		FACTION_PLAYER: RELATION_HOSTILE,
		FACTION_NPC: RELATION_HOSTILE,
		FACTION_ENEMY: RELATION_FRIENDLY,
		FACTION_NEUTRAL: RELATION_NEUTRAL,
	},
	FACTION_NEUTRAL: {
		FACTION_PLAYER: RELATION_NEUTRAL,
		FACTION_NPC: RELATION_NEUTRAL,
		FACTION_ENEMY: RELATION_NEUTRAL,
		FACTION_NEUTRAL: RELATION_FRIENDLY,
	},
}

var _warned_unknown_factions: Dictionary = {}
var _warned_missing_relations: Dictionary = {}


func normalize_faction_name(faction_name: String) -> String:
	return faction_name.strip_edges().to_upper()


func has_faction(faction_name: String) -> bool:
	var normalized := normalize_faction_name(faction_name)
	if _can_use_game_data_relations():
		return bool(GameData.has_unit_faction(normalized))

	return faction_relations.has(normalized)


func get_relation(faction_a: String, faction_b: String) -> int:
	var a := normalize_faction_name(faction_a)
	var b := normalize_faction_name(faction_b)

	if _can_use_game_data_relations():
		return _relation_from_text(String(GameData.get_faction_relation(a, b)))

	return _get_fallback_relation(a, b)


func _get_fallback_relation(faction_a: String, faction_b: String) -> int:
	if not faction_relations.has(faction_a):
		_warn_unknown_faction(faction_a)
		return RELATION_NEUTRAL

	if not faction_relations.has(faction_b):
		_warn_unknown_faction(faction_b)
		return RELATION_NEUTRAL

	var row_value: Variant = faction_relations[faction_a]
	if typeof(row_value) != TYPE_DICTIONARY:
		_warn_missing_relation(faction_a, faction_b)
		return RELATION_NEUTRAL

	var row: Dictionary = row_value
	if not row.has(faction_b):
		_warn_missing_relation(faction_a, faction_b)
		return RELATION_NEUTRAL

	return int(row[faction_b])


func _can_use_game_data_relations() -> bool:
	if GameData == null:
		return false

	if not GameData.has_method("get_faction_relation"):
		return false

	if not GameData.has_method("has_unit_faction"):
		return false

	if not GameData.has_method("get_all_unit_factions"):
		return false

	var factions_value: Variant = GameData.get_all_unit_factions()
	if typeof(factions_value) != TYPE_ARRAY:
		return false

	var factions: Array = factions_value
	return not factions.is_empty()


func _relation_from_text(relation: String) -> int:
	match relation.strip_edges().to_upper():
		RELATION_TEXT_FRIENDLY:
			return RELATION_FRIENDLY
		RELATION_TEXT_HOSTILE:
			return RELATION_HOSTILE
		RELATION_TEXT_NEUTRAL, "":
			return RELATION_NEUTRAL
		_:
			push_warning("unknown relation text: " + relation + " -> " + RELATION_TEXT_NEUTRAL)
			return RELATION_NEUTRAL


func _warn_unknown_faction(faction_name: String) -> void:
	var normalized := normalize_faction_name(faction_name)
	if normalized == "":
		normalized = "<empty>"

	if _warned_unknown_factions.has(normalized):
		return

	_warned_unknown_factions[normalized] = true
	push_warning("unknown faction: " + faction_name + " -> " + FACTION_NEUTRAL)


func _warn_missing_relation(faction_a: String, faction_b: String) -> void:
	var key := faction_a + "->" + faction_b
	if _warned_missing_relations.has(key):
		return

	_warned_missing_relations[key] = true
	push_warning("missing faction relation: " + key + " -> " + RELATION_TEXT_NEUTRAL)


func is_hostile(faction_a: String, faction_b: String) -> bool:
	return get_relation(faction_a, faction_b) == RELATION_HOSTILE


func is_friendly(faction_a: String, faction_b: String) -> bool:
	return get_relation(faction_a, faction_b) == RELATION_FRIENDLY


func is_neutral(faction_a: String, faction_b: String) -> bool:
	return get_relation(faction_a, faction_b) == RELATION_NEUTRAL


func are_units_hostile(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	return is_hostile(String(unit_a.faction), String(unit_b.faction))


func are_units_friendly(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	return is_friendly(String(unit_a.faction), String(unit_b.faction))


func are_units_neutral(unit_a, unit_b) -> bool:
	if unit_a == null or unit_b == null:
		return false
	return is_neutral(String(unit_a.faction), String(unit_b.faction))


func set_relation(faction_a: String, faction_b: String, relation: int, bidirectional: bool = true) -> void:
	var a = normalize_faction_name(faction_a)
	var b = normalize_faction_name(faction_b)

	if not faction_relations.has(a):
		faction_relations[a] = {}
	if not faction_relations.has(b):
		faction_relations[b] = {}

	faction_relations[a][b] = relation

	if bidirectional:
		faction_relations[b][a] = relation


func add_faction(faction_name: String, default_relation_to_others: int = RELATION_NEUTRAL) -> void:
	var new_faction = normalize_faction_name(faction_name)

	if faction_relations.has(new_faction):
		return

	faction_relations[new_faction] = {}
	faction_relations[new_faction][new_faction] = RELATION_FRIENDLY

	for existing_faction in faction_relations.keys():
		if existing_faction == new_faction:
			continue

		faction_relations[new_faction][existing_faction] = default_relation_to_others
		faction_relations[existing_faction][new_faction] = default_relation_to_others
