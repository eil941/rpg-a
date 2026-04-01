extends Node

const RELATION_FRIENDLY := 1
const RELATION_NEUTRAL := 0
const RELATION_HOSTILE := -1

const FACTION_PLAYER := "PLAYER"
const FACTION_NPC := "NPC"
const FACTION_ENEMY := "ENEMY"

var faction_relations := {
	FACTION_PLAYER: {
		FACTION_PLAYER: RELATION_FRIENDLY,
		FACTION_NPC: RELATION_FRIENDLY,
		FACTION_ENEMY: RELATION_HOSTILE,
	},
	FACTION_NPC: {
		FACTION_PLAYER: RELATION_FRIENDLY,
		FACTION_NPC: RELATION_FRIENDLY,
		FACTION_ENEMY: RELATION_HOSTILE,
	},
	FACTION_ENEMY: {
		FACTION_PLAYER: RELATION_HOSTILE,
		FACTION_NPC: RELATION_HOSTILE,
		FACTION_ENEMY: RELATION_FRIENDLY,
	},
}


func normalize_faction_name(faction_name: String) -> String:
	return faction_name.strip_edges().to_upper()


func has_faction(faction_name: String) -> bool:
	var normalized = normalize_faction_name(faction_name)
	return faction_relations.has(normalized)


func get_relation(faction_a: String, faction_b: String) -> int:
	var a = normalize_faction_name(faction_a)
	var b = normalize_faction_name(faction_b)

	if not faction_relations.has(a):
		return RELATION_NEUTRAL

	var row = faction_relations[a]
	if not row.has(b):
		return RELATION_NEUTRAL

	return row[b]


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
