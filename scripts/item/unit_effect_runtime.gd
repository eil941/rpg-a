extends Node
class_name UnitEffectRuntime

const META_STATUS_KEY: StringName = &"runtime_status_effects"
const META_BUFF_KEY: StringName = &"runtime_buffs"
const META_BASE_MULTIPLIERS_KEY: StringName = &"runtime_base_multipliers"

const STATUS_POISON: StringName = &"poison"
const STATUS_PARALYSIS: StringName = &"paralysis"
const STATUS_BURN: StringName = &"burn"
const STATUS_SLEEP: StringName = &"sleep"
const STATUS_FREEZE: StringName = &"freeze"

const STAT_ATTACK: StringName = &"attack"
const STAT_DEFENSE: StringName = &"defense"
const STAT_SPEED: StringName = &"speed"
const STAT_ACCURACY: StringName = &"accuracy"
const STAT_EVASION: StringName = &"evasion"
const STAT_CRIT_RATE: StringName = &"crit_rate"


static func ensure_runtime_state(unit) -> void:
	if unit == null:
		return

	if not unit.has_meta(META_STATUS_KEY):
		unit.set_meta(META_STATUS_KEY, [])

	if not unit.has_meta(META_BUFF_KEY):
		unit.set_meta(META_BUFF_KEY, [])

	if not unit.has_meta(META_BASE_MULTIPLIERS_KEY):
		var base_multipliers: Dictionary = {
			"attack_multiplier": 1.0,
			"defense_multiplier": 1.0,
			"accuracy_multiplier": 1.0,
			"evasion_multiplier": 1.0,
			"crit_rate_multiplier": 1.0,
			"speed_multiplier": 1.0
		}

		var stats = unit.get("stats")
		if stats != null:
			base_multipliers["attack_multiplier"] = float(stats.attack_multiplier)
			base_multipliers["defense_multiplier"] = float(stats.defense_multiplier)
			base_multipliers["accuracy_multiplier"] = float(stats.accuracy_multiplier)
			base_multipliers["evasion_multiplier"] = float(stats.evasion_multiplier)
			base_multipliers["crit_rate_multiplier"] = float(stats.crit_rate_multiplier)
			base_multipliers["speed_multiplier"] = float(stats.speed_multiplier)

		unit.set_meta(META_BASE_MULTIPLIERS_KEY, base_multipliers)


static func has_status(unit, status_id: StringName) -> bool:
	if unit == null:
		return false

	ensure_runtime_state(unit)

	var statuses: Array = unit.get_meta(META_STATUS_KEY, [])
	for entry_variant in statuses:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		if StringName(entry.get("status_id", &"")) == status_id:
			return true

	return false


static func apply_status(unit, status_id: StringName, duration_seconds: float, status_power: int) -> bool:
	if unit == null:
		return false
	if status_id == &"":
		return false

	if duration_seconds <= 0.0:
		duration_seconds = 1.0

	ensure_runtime_state(unit)

	var statuses: Array = unit.get_meta(META_STATUS_KEY, [])
	var updated: bool = false

	for i in range(statuses.size()):
		var entry_variant = statuses[i]
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		if StringName(entry.get("status_id", &"")) != status_id:
			continue

		var old_time: float = float(entry.get("remaining_time_seconds", 0.0))
		var old_power: int = int(entry.get("power", 0))

		entry["remaining_time_seconds"] = max(old_time, duration_seconds)
		entry["power"] = max(old_power, status_power)
		statuses[i] = entry
		updated = true
		break

	if not updated:
		statuses.append({
			"status_id": status_id,
			"remaining_time_seconds": duration_seconds,
			"power": status_power
		})

	unit.set_meta(META_STATUS_KEY, statuses)
	_recompute_runtime_multipliers(unit)
	return true


static func cure_status(unit, status_id: StringName) -> bool:
	if unit == null:
		return false

	ensure_runtime_state(unit)

	var statuses: Array = unit.get_meta(META_STATUS_KEY, [])
	var result: Array = []
	var removed: bool = false

	for entry_variant in statuses:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		if StringName(entry.get("status_id", &"")) == status_id:
			removed = true
			continue

		result.append(entry)

	unit.set_meta(META_STATUS_KEY, result)
	_recompute_runtime_multipliers(unit)
	return removed


static func apply_buff(unit, stat_name: StringName, duration_seconds: float, stat_flat: int, stat_percent: float) -> bool:
	if unit == null:
		return false
	if stat_name == &"":
		return false

	if duration_seconds <= 0.0:
		duration_seconds = 1.0

	ensure_runtime_state(unit)

	var buffs: Array = unit.get_meta(META_BUFF_KEY, [])
	buffs.append({
		"stat_name": stat_name,
		"remaining_time_seconds": duration_seconds,
		"flat": stat_flat,
		"percent": stat_percent
	})

	unit.set_meta(META_BUFF_KEY, buffs)
	_recompute_runtime_multipliers(unit)
	return true


static func tick_effects(unit, elapsed_seconds: float) -> void:
	if unit == null:
		return
	if elapsed_seconds <= 0.0:
		return

	var stats = unit.get("stats")
	if stats == null:
		return

	ensure_runtime_state(unit)

	var old_statuses: Array = unit.get_meta(META_STATUS_KEY, [])
	var new_statuses: Array = []

	for entry_variant in old_statuses:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		var status_id: StringName = StringName(entry.get("status_id", &""))
		var remaining_time_seconds: float = float(entry.get("remaining_time_seconds", 0.0))
		var power: int = int(entry.get("power", 0))

		if remaining_time_seconds <= 0.0:
			continue

		match status_id:
			STATUS_POISON:
				var poison_damage: int = max(1, power)
				stats.hp = max(0, stats.hp - poison_damage)

			STATUS_BURN:
				var burn_damage: int = max(1, power)
				stats.hp = max(0, stats.hp - burn_damage)

			_:
				pass

		remaining_time_seconds -= elapsed_seconds

		if remaining_time_seconds > 0.0:
			entry["remaining_time_seconds"] = remaining_time_seconds
			new_statuses.append(entry)

	unit.set_meta(META_STATUS_KEY, new_statuses)

	var old_buffs: Array = unit.get_meta(META_BUFF_KEY, [])
	var new_buffs: Array = []

	for buff_variant in old_buffs:
		if typeof(buff_variant) != TYPE_DICTIONARY:
			continue

		var buff: Dictionary = buff_variant
		var remaining_time_seconds: float = float(buff.get("remaining_time_seconds", 0.0))

		if remaining_time_seconds <= 0.0:
			continue

		remaining_time_seconds -= elapsed_seconds

		if remaining_time_seconds > 0.0:
			buff["remaining_time_seconds"] = remaining_time_seconds
			new_buffs.append(buff)

	unit.set_meta(META_BUFF_KEY, new_buffs)

	_recompute_runtime_multipliers(unit)

	if unit.has_method("notify_hud_player_status_refresh"):
		unit.notify_hud_player_status_refresh()


static func get_status_entries(unit) -> Array:
	if unit == null:
		return []

	ensure_runtime_state(unit)
	return unit.get_meta(META_STATUS_KEY, []).duplicate(true)


static func get_buff_entries(unit) -> Array:
	if unit == null:
		return []

	ensure_runtime_state(unit)
	return unit.get_meta(META_BUFF_KEY, []).duplicate(true)


static func get_remaining_time_text(seconds: float) -> String:
	if seconds <= 0.0:
		return "0秒"

	var total_seconds: int = int(ceil(seconds))

	if total_seconds < 60:
		return "%d秒" % total_seconds

	if total_seconds < 3600:
		var minutes: int = int(ceil(float(total_seconds) / 60.0))
		return "%d分" % minutes

	if total_seconds < 86400:
		var hours: int = int(ceil(float(total_seconds) / 3600.0))
		return "%d時間" % hours

	var days: int = int(ceil(float(total_seconds) / 86400.0))
	return "%d日" % days


static func get_remaining_turn_text(seconds: float, player_speed: float) -> String:
	if seconds <= 0.0:
		return "約0ターン"

	if player_speed <= 0.0:
		return ""

	var seconds_per_turn: float = 86400.0 / player_speed
	if seconds_per_turn <= 0.0:
		return ""

	var estimated_turns: int = int(ceil(seconds / seconds_per_turn))
	return "約%dターン" % estimated_turns


static func get_remaining_display_text(seconds: float, player_speed: float) -> String:
	var time_text: String = get_remaining_time_text(seconds)
	var turn_text: String = get_remaining_turn_text(seconds, player_speed)

	if turn_text == "":
		return time_text

	if seconds >= 6.0 * 3600.0:
		return time_text

	return "%s（%s）" % [time_text, turn_text]


static func _recompute_runtime_multipliers(unit) -> void:
	if unit == null:
		return

	var stats = unit.get("stats")
	if stats == null:
		return

	ensure_runtime_state(unit)

	var base_multipliers: Dictionary = unit.get_meta(META_BASE_MULTIPLIERS_KEY, {})

	stats.attack_multiplier = float(base_multipliers.get("attack_multiplier", 1.0))
	stats.defense_multiplier = float(base_multipliers.get("defense_multiplier", 1.0))
	stats.accuracy_multiplier = float(base_multipliers.get("accuracy_multiplier", 1.0))
	stats.evasion_multiplier = float(base_multipliers.get("evasion_multiplier", 1.0))
	stats.crit_rate_multiplier = float(base_multipliers.get("crit_rate_multiplier", 1.0))
	stats.speed_multiplier = float(base_multipliers.get("speed_multiplier", 1.0))

	var buffs: Array = unit.get_meta(META_BUFF_KEY, [])

	var attack_bonus_percent: float = 0.0
	var defense_bonus_percent: float = 0.0
	var speed_bonus_percent: float = 0.0
	var accuracy_bonus_percent: float = 0.0
	var evasion_bonus_percent: float = 0.0
	var crit_rate_bonus_percent: float = 0.0

	for buff_variant in buffs:
		if typeof(buff_variant) != TYPE_DICTIONARY:
			continue

		var buff: Dictionary = buff_variant
		if float(buff.get("remaining_time_seconds", 0.0)) <= 0.0:
			continue

		var stat_name: StringName = StringName(buff.get("stat_name", &""))
		var stat_flat: int = int(buff.get("flat", 0))
		var stat_percent: float = float(buff.get("percent", 0.0))

		match stat_name:
			STAT_ATTACK:
				var attack_base: int = max(1, int(stats.attack))
				attack_bonus_percent += stat_percent + (float(stat_flat) / float(attack_base))

			STAT_DEFENSE:
				var defense_base: int = max(1, int(stats.defense))
				defense_bonus_percent += stat_percent + (float(stat_flat) / float(defense_base))

			STAT_SPEED:
				var speed_base: float = max(0.01, float(stats.speed))
				speed_bonus_percent += stat_percent + (float(stat_flat) / speed_base)

			STAT_ACCURACY:
				accuracy_bonus_percent += stat_percent

			STAT_EVASION:
				evasion_bonus_percent += stat_percent

			STAT_CRIT_RATE:
				crit_rate_bonus_percent += stat_percent

			_:
				pass

	var statuses: Array = unit.get_meta(META_STATUS_KEY, [])

	for status_variant in statuses:
		if typeof(status_variant) != TYPE_DICTIONARY:
			continue

		var status_entry: Dictionary = status_variant
		var status_id: StringName = StringName(status_entry.get("status_id", &""))

		match status_id:
			STATUS_PARALYSIS:
				speed_bonus_percent -= 0.50

			STATUS_FREEZE:
				speed_bonus_percent -= 0.90

			STATUS_SLEEP:
				speed_bonus_percent -= 0.90

			_:
				pass

	stats.attack_multiplier *= max(0.0, 1.0 + attack_bonus_percent)
	stats.defense_multiplier *= max(0.0, 1.0 + defense_bonus_percent)
	stats.speed_multiplier *= max(0.0, 1.0 + speed_bonus_percent)
	stats.accuracy_multiplier *= max(0.0, 1.0 + accuracy_bonus_percent)
	stats.evasion_multiplier *= max(0.0, 1.0 + evasion_bonus_percent)
	stats.crit_rate_multiplier *= max(0.0, 1.0 + crit_rate_bonus_percent)
