extends RefCounted
class_name UnitEffectRuntime

var source_item_id: String = ""
var source_unit_id: String = ""

var effect_type: int = ItemEffectData.EffectType.NONE

var status_id: StringName = &""
var status_power: int = 0

var modifier_kind: int = ItemEffectData.ModifierKind.BUFF
var stat_name: StringName = &""
var stat_flat: int = 0
var stat_percent: float = 0.0

var duration_type: int = ItemEffectData.DurationType.NONE
var remaining_duration: float = 0.0

var tick_interval_seconds: float = 0.0
var tick_accumulator_seconds: float = 0.0

var extra_data: Dictionary = {}


func is_status_effect() -> bool:
	return effect_type == ItemEffectData.EffectType.APPLY_STATUS


func is_modifier_effect() -> bool:
	return effect_type == ItemEffectData.EffectType.APPLY_MODIFIER


func has_duration() -> bool:
	return duration_type != ItemEffectData.DurationType.NONE and remaining_duration > 0.0


func is_expired() -> bool:
	if duration_type == ItemEffectData.DurationType.NONE:
		return false
	return remaining_duration <= 0.0


func matches_status(status_name: StringName) -> bool:
	if status_id == &"":
		return false
	return status_id == status_name


func matches_modifier(target_modifier_kind: int, target_stat_name: StringName) -> bool:
	if not is_modifier_effect():
		return false
	if modifier_kind != target_modifier_kind:
		return false
	return stat_name == target_stat_name


func advance_time(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return

	var effective_elapsed: float = elapsed_seconds

	if duration_type == ItemEffectData.DurationType.TIME:
		effective_elapsed = min(elapsed_seconds, max(0.0, remaining_duration))
		remaining_duration -= effective_elapsed

	if tick_interval_seconds > 0.0:
		tick_accumulator_seconds += effective_elapsed


func consume_turn(turn_count: int = 1) -> void:
	if turn_count <= 0:
		return

	if duration_type == ItemEffectData.DurationType.TURN:
		remaining_duration -= float(turn_count)


func consume_action(action_count: int = 1) -> void:
	if action_count <= 0:
		return

	if duration_type == ItemEffectData.DurationType.ACTION:
		remaining_duration -= float(action_count)


func can_consume_tick() -> bool:
	if tick_interval_seconds <= 0.0:
		return false
	return tick_accumulator_seconds >= tick_interval_seconds


func consume_one_tick() -> void:
	if tick_interval_seconds <= 0.0:
		return

	tick_accumulator_seconds -= tick_interval_seconds
	if tick_accumulator_seconds < 0.0:
		tick_accumulator_seconds = 0.0


func get_remaining_turns_text() -> String:
	if duration_type != ItemEffectData.DurationType.TURN:
		return ""

	return str(max(0, int(ceil(remaining_duration)))) + " turns"


func get_remaining_time_text() -> String:
	if duration_type != ItemEffectData.DurationType.TIME:
		return ""

	return str(max(0, int(ceil(remaining_duration)))) + " sec"


func duplicate_runtime() -> UnitEffectRuntime:
	var copy := UnitEffectRuntime.new()

	copy.source_item_id = source_item_id
	copy.source_unit_id = source_unit_id

	copy.effect_type = effect_type

	copy.status_id = status_id
	copy.status_power = status_power

	copy.modifier_kind = modifier_kind
	copy.stat_name = stat_name
	copy.stat_flat = stat_flat
	copy.stat_percent = stat_percent

	copy.duration_type = duration_type
	copy.remaining_duration = remaining_duration

	copy.tick_interval_seconds = tick_interval_seconds
	copy.tick_accumulator_seconds = tick_accumulator_seconds

	copy.extra_data = extra_data.duplicate(true)

	return copy


func to_debug_dictionary() -> Dictionary:
	return {
		"source_item_id": source_item_id,
		"source_unit_id": source_unit_id,
		"effect_type": effect_type,
		"status_id": String(status_id),
		"status_power": status_power,
		"modifier_kind": modifier_kind,
		"stat_name": String(stat_name),
		"stat_flat": stat_flat,
		"stat_percent": stat_percent,
		"duration_type": duration_type,
		"remaining_duration": remaining_duration,
		"tick_interval_seconds": tick_interval_seconds,
		"tick_accumulator_seconds": tick_accumulator_seconds,
		"extra_data": extra_data
	}
