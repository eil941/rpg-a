extends Node
class_name Skills

# Canonical skill component.
# Fixed legacy skills remain as exported fields; TSV-backed skills live in
# dynamic_skills and are accessed through the same public Skills API.

const LEGACY_SKILL_IDS: Array[String] = [
	"gathering",
	"investigation",
	"stealth",
	"trap_disarm",
	"fishing",
	"appraisal",
	"cooking",
	"repair",
	"smithing",
	"alchemy",
	"negotiation",
	"speech",
	"medical"
]

@export var gathering: int = 0
@export var investigation: int = 0
@export var stealth: int = 0
@export var trap_disarm: int = 0
@export var fishing: int = 0
@export var appraisal: int = 0
@export var cooking: int = 0
@export var repair: int = 0
@export var smithing: int = 0
@export var alchemy: int = 0
@export var negotiation: int = 0
@export var speech: int = 0
@export var medical: int = 0

var learned_skills: Dictionary = {
	"gathering": false,
	"investigation": false,
	"stealth": false,
	"trap_disarm": false,
	"fishing": false,
	"appraisal": false,
	"cooking": false,
	"repair": false,
	"smithing": false,
	"alchemy": false,
	"negotiation": false,
	"speech": false,
	"medical": false
}

@export var skill_growth_threshold: int = 40

var skill_growth_points: Dictionary = {
	"gathering": 0,
	"investigation": 0,
	"stealth": 0,
	"trap_disarm": 0,
	"fishing": 0,
	"appraisal": 0,
	"cooking": 0,
	"repair": 0,
	"smithing": 0,
	"alchemy": 0,
	"negotiation": 0,
	"speech": 0,
	"medical": 0
}

var dynamic_skills: Dictionary = {}


func is_skill_learned(skill_name: String) -> bool:
	var skill_id: String = _normalize_skill_id(skill_name)
	if skill_id == "":
		return false

	if _is_legacy_skill_id(skill_id):
		return bool(learned_skills.get(skill_id, false))

	var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
	if entry.is_empty():
		return false

	return bool(entry.get("learned", false))


func learn_skill(skill_name: String, initial_level: int = 1) -> bool:
	var skill_id: String = _normalize_skill_id(skill_name)
	if skill_id == "":
		return false

	if _is_legacy_skill_id(skill_id):
		var was_learned: bool = bool(learned_skills.get(skill_id, false))
		learned_skills[skill_id] = true

		var normalized_level: int = maxi(1, initial_level)
		if get_skill_value(skill_id) < normalized_level:
			set_skill_value(skill_id, normalized_level)

		return not was_learned

	if not _game_data_has_skill(skill_id):
		push_warning("unknown skill: %s" % skill_id)
		return false

	var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
	var was_learned_dynamic: bool = bool(entry.get("learned", false))
	var current_value: int = int(entry.get("value", 0))
	var current_growth: int = int(entry.get("growth", 0))
	var max_level: int = _get_skill_max_level(skill_id)
	var normalized_dynamic_level: int = clampi(maxi(maxi(initial_level, current_value), 1), 1, max_level)

	if normalized_dynamic_level >= max_level:
		current_growth = 0

	_set_dynamic_skill_entry(skill_id, true, normalized_dynamic_level, current_growth)
	return not was_learned_dynamic or current_value != normalized_dynamic_level


func forget_skill(skill_name: String) -> void:
	var skill_id: String = _normalize_skill_id(skill_name)
	if skill_id == "":
		return

	if _is_legacy_skill_id(skill_id):
		learned_skills[skill_id] = false
		set_skill_value(skill_id, 0)
		skill_growth_points[skill_id] = 0
		return

	if dynamic_skills.has(skill_id):
		dynamic_skills.erase(skill_id)


func gain_skill_growth(skill_name: String, amount: int = 1) -> void:
	var skill_id: String = _normalize_skill_id(skill_name)
	if skill_id == "":
		return

	if amount <= 0:
		return

	if _is_legacy_skill_id(skill_id):
		if not is_skill_learned(skill_id):
			return

		skill_growth_points[skill_id] = int(skill_growth_points.get(skill_id, 0)) + amount
		apply_skill_growth(skill_id)
		return

	if not _game_data_has_skill(skill_id):
		push_warning("unknown skill: %s" % skill_id)
		return

	if not is_skill_learned(skill_id):
		return

	var old_value: int = get_skill_value(skill_id)
	var old_growth: int = get_skill_growth_point(skill_id)
	var value: int = old_value
	var growth: int = old_growth + amount
	var max_level: int = _get_skill_max_level(skill_id)
	var level_ups: int = 0

	while value < max_level:
		var growth_to_next: int = _get_dynamic_growth_to_next(skill_id, value)
		if growth_to_next <= 0:
			growth = 0
			break

		if growth < growth_to_next:
			break

		growth -= growth_to_next
		value += 1
		level_ups += 1

	if value >= max_level:
		value = max_level
		growth = 0

	_set_dynamic_skill_entry(skill_id, true, value, growth)

	if level_ups > 0:
		on_skill_increased(skill_id, level_ups)

	_log_dynamic_skill_growth_if_needed(skill_id, old_value, old_growth, value, growth, level_ups)


func apply_skill_growth(skill_name: String) -> void:
	var skill_id: String = _normalize_skill_id(skill_name)
	if not _is_legacy_skill_id(skill_id):
		return

	if not is_skill_learned(skill_id):
		return

	while int(skill_growth_points.get(skill_id, 0)) >= skill_growth_threshold:
		skill_growth_points[skill_id] = int(skill_growth_points.get(skill_id, 0)) - skill_growth_threshold
		increase_skill(skill_id, 1)


func increase_skill(skill_name: String, amount: int = 1) -> void:
	var skill_id: String = _normalize_skill_id(skill_name)
	if skill_id == "":
		return

	if amount <= 0:
		return

	if not is_skill_learned(skill_id):
		return

	if _is_legacy_skill_id(skill_id):
		var current_value: int = get_skill_value(skill_id)
		set_skill_value(skill_id, current_value + amount)
		on_skill_increased(skill_id, amount)
		return

	if not _game_data_has_skill(skill_id):
		return

	var max_level: int = _get_skill_max_level(skill_id)
	var old_value: int = get_skill_value(skill_id)
	var old_growth: int = get_skill_growth_point(skill_id)
	var new_value: int = clampi(old_value + amount, 0, max_level)
	var new_growth: int = old_growth
	if new_value >= max_level:
		new_growth = 0

	_set_dynamic_skill_entry(skill_id, true, new_value, new_growth)
	on_skill_increased(skill_id, new_value - old_value)


func on_skill_increased(skill_name: String, amount: int) -> void:
	print(skill_name, " increased by ", amount)


func get_skill_value(skill_name: String) -> int:
	var skill_id: String = _normalize_skill_id(skill_name)

	match skill_id:
		"gathering":
			return gathering
		"investigation":
			return investigation
		"stealth":
			return stealth
		"trap_disarm":
			return trap_disarm
		"fishing":
			return fishing
		"appraisal":
			return appraisal
		"cooking":
			return cooking
		"repair":
			return repair
		"smithing":
			return smithing
		"alchemy":
			return alchemy
		"negotiation":
			return negotiation
		"speech":
			return speech
		"medical":
			return medical

	var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
	if not entry.is_empty():
		return int(entry.get("value", 0))

	if _game_data_has_skill(skill_id):
		return 0

	if skill_id != "":
		push_warning("unknown skill: %s" % skill_id)
	return 0


func set_skill_value(skill_name: String, value: int) -> void:
	var skill_id: String = _normalize_skill_id(skill_name)
	var normalized_value: int = maxi(value, 0)

	match skill_id:
		"gathering":
			gathering = normalized_value
			return
		"investigation":
			investigation = normalized_value
			return
		"stealth":
			stealth = normalized_value
			return
		"trap_disarm":
			trap_disarm = normalized_value
			return
		"fishing":
			fishing = normalized_value
			return
		"appraisal":
			appraisal = normalized_value
			return
		"cooking":
			cooking = normalized_value
			return
		"repair":
			repair = normalized_value
			return
		"smithing":
			smithing = normalized_value
			return
		"alchemy":
			alchemy = normalized_value
			return
		"negotiation":
			negotiation = normalized_value
			return
		"speech":
			speech = normalized_value
			return
		"medical":
			medical = normalized_value
			return

	if not _game_data_has_skill(skill_id):
		if skill_id != "":
			push_warning("unknown skill: %s" % skill_id)
		return

	var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
	var max_level: int = _get_skill_max_level(skill_id)
	var new_value: int = clampi(normalized_value, 0, max_level)
	var new_growth: int = int(entry.get("growth", 0))
	var learned: bool = bool(entry.get("learned", false))

	if new_value <= 0:
		dynamic_skills.erase(skill_id)
		return

	if new_value >= max_level:
		new_growth = 0

	_set_dynamic_skill_entry(skill_id, learned or new_value > 0, new_value, new_growth)


func get_skill_growth_point(skill_name: String) -> int:
	var skill_id: String = _normalize_skill_id(skill_name)

	if _is_legacy_skill_id(skill_id):
		return int(skill_growth_points.get(skill_id, 0))

	var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
	if not entry.is_empty():
		return int(entry.get("growth", 0))

	if _game_data_has_skill(skill_id):
		return 0

	if skill_id != "":
		push_warning("unknown skill: %s" % skill_id)
	return 0


func get_dynamic_skill_display_rows(locale: String = "ja") -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for skill_id_value in dynamic_skills.keys():
		var skill_id: String = String(skill_id_value).strip_edges()
		if skill_id == "":
			continue

		var entry: Dictionary = _get_dynamic_skill_entry(skill_id)
		if entry.is_empty():
			continue

		result.append({
			"skill_id": skill_id,
			"display_name": _get_skill_display_name(skill_id, locale),
			"learned": bool(entry.get("learned", false)),
			"value": int(entry.get("value", 0)),
			"growth": int(entry.get("growth", 0)),
			"growth_to_next": _get_dynamic_growth_to_next(skill_id, int(entry.get("value", 0)))
		})

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("skill_id", "")) < String(b.get("skill_id", ""))
	)

	return result


func get_skill_display_rows(locale: String = "ja") -> Array[Dictionary]:
	var rows: Array[Dictionary] = [
		{"skill_id": "gathering", "display_name": "採取", "value": gathering, "sort_order": 10},
		{"skill_id": "investigation", "display_name": "調査", "value": investigation, "sort_order": 20},
		{"skill_id": "stealth", "display_name": "隠密", "value": stealth, "sort_order": 30},
		{"skill_id": "trap_disarm", "display_name": "罠解除", "value": trap_disarm, "sort_order": 40},
		{"skill_id": "fishing", "display_name": "釣り", "value": fishing, "sort_order": 50},
		{"skill_id": "appraisal", "display_name": "鑑定", "value": appraisal, "sort_order": 60},
		{"skill_id": "cooking", "display_name": "料理", "value": cooking, "sort_order": 70},
		{"skill_id": "repair", "display_name": "修理", "value": repair, "sort_order": 80},
		{"skill_id": "smithing", "display_name": "鍛冶", "value": smithing, "sort_order": 90},
		{"skill_id": "alchemy", "display_name": "錬金", "value": alchemy, "sort_order": 100},
		{"skill_id": "negotiation", "display_name": "交渉", "value": negotiation, "sort_order": 110},
		{"skill_id": "speech", "display_name": "話術", "value": speech, "sort_order": 120},
		{"skill_id": "medical", "display_name": "医療", "value": medical, "sort_order": 130}
	]

	var dynamic_sort_order: int = 1000
	var dynamic_rows: Array[Dictionary] = get_dynamic_skill_display_rows(locale)
	for row in dynamic_rows:
		var skill_id: String = String(row.get("skill_id", "")).strip_edges()
		var display_name: String = String(row.get("display_name", skill_id)).strip_edges()
		if display_name == "":
			display_name = skill_id

		rows.append({
			"skill_id": skill_id,
			"display_name": display_name,
			"value": int(row.get("value", 0)),
			"sort_order": dynamic_sort_order
		})
		dynamic_sort_order += 10

	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)

	return rows


func apply_initial_skills_from_table(skill_table_id: String) -> void:
	dynamic_skills.clear()

	var normalized_id: String = skill_table_id.strip_edges()
	if normalized_id == "":
		return

	if GameData == null:
		return

	if not GameData.has_method("build_initial_dynamic_skills"):
		return

	var dynamic_value: Variant = GameData.build_initial_dynamic_skills(normalized_id)
	if typeof(dynamic_value) != TYPE_DICTIONARY:
		return

	var initial_dynamic_skills: Dictionary = dynamic_value
	_apply_dynamic_skills_data(initial_dynamic_skills)

	if DebugSettings != null and bool(DebugSettings.debug_dynamic_skill_apply) and not dynamic_skills.is_empty():
		print("[DynamicSkills] owner=", get_parent().name, " skill_table_id=", normalized_id, " skills=", dynamic_skills)


func apply_legacy_skill_state_data(legacy_skill_state: Dictionary) -> void:
	for key_value in legacy_skill_state.keys():
		var raw_entry: Variant = legacy_skill_state.get(key_value, {})
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = raw_entry
		var skill_id: String = String(entry.get("skill_id", String(key_value))).strip_edges()
		if skill_id == "":
			continue

		var learned: bool = bool(entry.get("learned", false))
		var value: int = int(entry.get("value", entry.get("level", 0)))
		var growth: int = int(entry.get("growth", entry.get("exp", 0)))

		if learned or value > 0 or growth > 0:
			_set_dynamic_skill_entry(skill_id, learned, value, growth)


func get_skills_data() -> Dictionary:
	return {
		"gathering": gathering,
		"investigation": investigation,
		"stealth": stealth,
		"trap_disarm": trap_disarm,
		"fishing": fishing,
		"appraisal": appraisal,
		"cooking": cooking,
		"repair": repair,
		"smithing": smithing,
		"alchemy": alchemy,
		"negotiation": negotiation,
		"speech": speech,
		"medical": medical,
		"learned_skills": learned_skills.duplicate(true),
		"skill_growth_threshold": skill_growth_threshold,
		"skill_growth_points": skill_growth_points.duplicate(true),
		"dynamic_skills": dynamic_skills.duplicate(true)
	}


func apply_skills_data(data: Dictionary) -> void:
	if data.has("gathering"):
		gathering = int(data["gathering"])
	if data.has("investigation"):
		investigation = int(data["investigation"])
	if data.has("stealth"):
		stealth = int(data["stealth"])
	if data.has("trap_disarm"):
		trap_disarm = int(data["trap_disarm"])
	if data.has("fishing"):
		fishing = int(data["fishing"])
	if data.has("appraisal"):
		appraisal = int(data["appraisal"])
	if data.has("cooking"):
		cooking = int(data["cooking"])
	if data.has("repair"):
		repair = int(data["repair"])
	if data.has("smithing"):
		smithing = int(data["smithing"])
	if data.has("alchemy"):
		alchemy = int(data["alchemy"])
	if data.has("negotiation"):
		negotiation = int(data["negotiation"])
	if data.has("speech"):
		speech = int(data["speech"])
	if data.has("medical"):
		medical = int(data["medical"])

	if data.has("learned_skills"):
		var learned_value: Variant = data.get("learned_skills", {})
		if typeof(learned_value) == TYPE_DICTIONARY:
			learned_skills = (learned_value as Dictionary).duplicate(true)

	if data.has("skill_growth_threshold"):
		skill_growth_threshold = int(data["skill_growth_threshold"])

	if data.has("skill_growth_points"):
		var growth_value: Variant = data.get("skill_growth_points", {})
		if typeof(growth_value) == TYPE_DICTIONARY:
			skill_growth_points = (growth_value as Dictionary).duplicate(true)

	dynamic_skills.clear()

	if data.has("dynamic_skills"):
		var dynamic_value: Variant = data.get("dynamic_skills", {})
		if typeof(dynamic_value) == TYPE_DICTIONARY:
			_apply_dynamic_skills_data(dynamic_value)

	if data.has("skill_state"):
		var skill_state_value: Variant = data.get("skill_state", {})
		if typeof(skill_state_value) == TYPE_DICTIONARY:
			var legacy_skill_state: Dictionary = skill_state_value
			apply_legacy_skill_state_data(legacy_skill_state)


func _apply_dynamic_skills_data(dynamic_value: Dictionary) -> void:
	for key_value in dynamic_value.keys():
		var raw_entry: Variant = dynamic_value.get(key_value, {})
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = raw_entry
		var skill_id: String = String(entry.get("skill_id", String(key_value))).strip_edges()
		if skill_id == "":
			continue

		var learned: bool = bool(entry.get("learned", false))
		var value: int = int(entry.get("value", 0))
		var growth: int = int(entry.get("growth", 0))
		_set_dynamic_skill_entry(skill_id, learned, value, growth)


func _set_dynamic_skill_entry(skill_id: String, learned: bool, value: int, growth: int) -> void:
	var normalized_id: String = _normalize_skill_id(skill_id)
	if normalized_id == "":
		return

	if not _game_data_has_skill(normalized_id):
		return

	var max_level: int = _get_skill_max_level(normalized_id)
	var normalized_value: int = clampi(maxi(value, 0), 0, max_level)
	var normalized_growth: int = maxi(growth, 0)
	var normalized_learned: bool = learned

	if normalized_value <= 0:
		normalized_learned = false
	elif normalized_value >= max_level:
		normalized_growth = 0

	dynamic_skills[normalized_id] = {
		"skill_id": normalized_id,
		"learned": normalized_learned,
		"value": normalized_value,
		"growth": normalized_growth
	}


func _get_dynamic_skill_entry(skill_id: String) -> Dictionary:
	var normalized_id: String = _normalize_skill_id(skill_id)
	if normalized_id == "":
		return {}

	var entry_value: Variant = dynamic_skills.get(normalized_id, {})
	if typeof(entry_value) != TYPE_DICTIONARY:
		return {}

	var entry: Dictionary = entry_value
	return entry


func _normalize_skill_id(skill_id: String) -> String:
	return skill_id.strip_edges()


func _is_legacy_skill_id(skill_id: String) -> bool:
	return LEGACY_SKILL_IDS.has(skill_id)


func _game_data_has_skill(skill_id: String) -> bool:
	if GameData == null:
		return false

	if not GameData.has_method("has_skill"):
		return false

	return bool(GameData.has_skill(skill_id))


func _get_skill_max_level(skill_id: String) -> int:
	if GameData == null:
		return 1

	if not GameData.has_method("get_skill"):
		return 1

	var skill_value: Variant = GameData.get_skill(skill_id)
	if typeof(skill_value) != TYPE_DICTIONARY:
		return 1

	var skill: Dictionary = skill_value
	return maxi(1, int(skill.get("max_level", 1)))


func _get_dynamic_growth_to_next(skill_id: String, value: int) -> int:
	if GameData == null:
		return 0

	if not GameData.has_method("get_skill_exp_to_next"):
		return 0

	if value <= 0:
		return 0

	return int(GameData.get_skill_exp_to_next(skill_id, value))


func _get_skill_display_name(skill_id: String, locale: String = "ja") -> String:
	if GameData == null:
		return skill_id

	if not GameData.has_method("get_skill"):
		return skill_id

	var skill_value: Variant = GameData.get_skill(skill_id)
	if typeof(skill_value) != TYPE_DICTIONARY:
		return skill_id

	var skill: Dictionary = skill_value
	var display_name_key: String = String(skill.get("display_name_key", "")).strip_edges()
	if display_name_key == "":
		return skill_id

	if not GameData.has_method("get_localized_text"):
		return skill_id

	return String(GameData.get_localized_text(display_name_key, locale, skill_id))


func _log_dynamic_skill_growth_if_needed(
	skill_id: String,
	old_value: int,
	old_growth: int,
	new_value: int,
	new_growth: int,
	level_ups: int
) -> void:
	if DebugSettings == null:
		return

	if not bool(DebugSettings.debug_skill_exp):
		return

	if old_value == new_value and old_growth == new_growth:
		return

	print(
		"[SkillExp] owner=", get_parent().name,
		" skill_id=", skill_id,
		" old=value", old_value, " growth", old_growth,
		" new=value", new_value, " growth", new_growth,
		" level_ups=", level_ups
	)
