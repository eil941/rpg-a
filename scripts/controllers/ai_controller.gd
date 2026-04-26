extends Node

enum MoveStyle {
	AUTO,
	APPROACH,
	KEEP_DISTANCE,
	FLEE,
	HOLD
}

enum CombatStyle {
	AUTO,
	MELEE,
	MID,
	LONG,
	SUPPORTER,
	HIT_AND_RUN,
	DEFENSIVE
}

enum ActionType {
	ATTACK,
	SUPPORT,
	USE_ITEM,
	MOVE,
	WAIT
}

@export var detection_range: int = 5
@export var preferred_distance: int = 2
@export var random_idle_move_chance: float = 0.7

@export var default_move_style: int = MoveStyle.APPROACH
@export var default_combat_style: int = CombatStyle.MELEE

var unit = null
var units_node = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node
	rng.randomize()


func take_turn() -> void:
	if not can_act():
		consume_pending_action()
		return

	var context: Dictionary = build_ai_context()
	var candidates: Array[Dictionary] = build_action_candidates(context)

	sort_candidates_desc(candidates)
	_print_ai_debug(context, candidates)

	for candidate in candidates:
		if execute_candidate(candidate, context):
			consume_pending_action()
			return

	unit.wait_action()
	consume_pending_action()


func _print_ai_debug(context: Dictionary, candidates: Array[Dictionary]) -> void:
	if DebugSettings.debug_ai_turn:
		print("----- AI TURN START -----")
		print("unit: ", unit.name)
		print("target: ", context["target"].name if context["target"] != null else "null")
		print("attack_target: ", context["attack_target"].name if context["attack_target"] != null else "null")
		print("distance_to_target: ", context["distance_to_target"])
		print("move_style: ", context["move_style"])
		print("combat_style: ", context["combat_style"])

	if DebugSettings.debug_ai_candidates:
		print("----- AI CANDIDATES -----")
		print("unit: ", unit.name)
		for i in range(candidates.size()):
			print("[", i, "] ", candidates[i])


func can_act() -> bool:
	if unit == null:
		return false

	if units_node == null:
		units_node = unit.units_node
		if units_node == null:
			return false

	if not unit.has_node("Stats"):
		return false

	if unit.stats.hp <= 0:
		return false

	return true


func consume_pending_action() -> void:
	if unit == null:
		return
	if not unit.has_node("Stats"):
		return

	unit.stats.pending_actions -= 1
	if unit.stats.pending_actions < 0:
		unit.stats.pending_actions = 0


func build_ai_context() -> Dictionary:
	var nearest_hostile = Targeting.get_nearest_hostile_unit(units_node, unit, detection_range)
	var dist_to_hostile: int = -1

	if nearest_hostile != null:
		dist_to_hostile = Targeting.get_distance_between_units(unit, nearest_hostile)

	var attack_target = CombatManager.get_best_attack_target(unit)

	if DebugSettings.debug_ai_target:
		print("----- AI TARGET -----")
		print("unit: ", unit.name)
		print("target: ", nearest_hostile.name if nearest_hostile != null else "null")
		print("attack_target: ", attack_target.name if attack_target != null else "null")
		print("distance: ", dist_to_hostile)

	return {
		"self": unit,
		"target": nearest_hostile,
		"attack_target": attack_target,
		"distance_to_target": dist_to_hostile,
		"hp_rate": get_self_hp_rate(),
		"move_style": get_effective_move_style(),
		"combat_style": get_effective_combat_style()
	}


func get_self_hp_rate() -> float:
	if unit == null or unit.stats == null:
		return 1.0

	var max_hp: int = max(unit.get_total_max_hp(), 1)
	return float(unit.stats.hp) / float(max_hp)


func get_effective_move_style() -> int:
	if unit != null and unit.has_method("get_effective_move_style"):
		return unit.get_effective_move_style()
	return MoveStyle.APPROACH


func get_effective_combat_style() -> int:
	if unit != null and unit.has_method("get_effective_combat_style"):
		return unit.get_effective_combat_style()
	return CombatStyle.MELEE


func build_action_candidates(context: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []

	candidates.append_array(build_self_item_candidates(context))
	candidates.append_array(build_support_candidates(context))
	candidates.append_array(build_attack_candidates(context))
	candidates.append_array(build_move_candidates(context))
	candidates.append(make_action_candidate(ActionType.WAIT, 5, {}))

	if context["target"] == null:
		candidates.append_array(build_idle_move_candidates())

	return candidates


func build_self_item_candidates(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if context["hp_rate"] <= 0.35:
		pass

	return result


func build_support_candidates(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return result


func build_attack_candidates(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var attack_target = context["attack_target"]
	if attack_target == null:
		return result

	var move_style: int = context["move_style"]
	if move_style == MoveStyle.FLEE:
		return result

	if CombatManager.can_attack(unit, attack_target):
		var score: int = get_normal_attack_score(context, attack_target)
		result.append(
			make_action_candidate(
				ActionType.ATTACK,
				score,
				{
					"target": attack_target,
					"attack_kind": "normal"
				}
			)
		)

	return result


func get_normal_attack_score(context: Dictionary, target) -> int:
	var combat_style: int = context["combat_style"]

	match combat_style:
		CombatStyle.MELEE:
			return 100
		CombatStyle.MID:
			return 95
		CombatStyle.LONG:
			return 90
		CombatStyle.SUPPORTER:
			return 70
		CombatStyle.HIT_AND_RUN:
			return 98
		CombatStyle.DEFENSIVE:
			return 85

	return 90


func build_move_candidates(context: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var target = context["target"]
	if target == null:
		return result

	var move_style: int = context["move_style"]

	match move_style:
		MoveStyle.APPROACH:
			result.append_array(build_approach_move_candidates(context, target))
		MoveStyle.KEEP_DISTANCE:
			result.append_array(build_keep_distance_move_candidates(context, target))
		MoveStyle.FLEE:
			result.append_array(build_flee_move_candidates(context, target))
		MoveStyle.HOLD:
			pass

	return result


func build_idle_move_candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if rng.randf() > random_idle_move_chance:
		return result

	var dirs: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP
	]
	dirs.shuffle()

	var score: int = 15
	for dir in dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 1

	return result


func build_approach_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dirs: Array[Vector2] = get_candidate_steps_toward_target(target)

	var score: int = 60
	for dir in dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 5

	return result


func build_keep_distance_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var dist: int = context["distance_to_target"]

	if dist < preferred_distance:
		var away_dirs: Array[Vector2] = get_candidate_steps_away_from_target(target)
		var side_dirs: Array[Vector2] = get_side_step_candidates(target)

		var score: int = 70
		for dir in away_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
			score -= 5

		for dir in side_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
			score -= 5

	elif dist > preferred_distance:
		var toward_dirs: Array[Vector2] = get_candidate_steps_toward_target(target)
		var side_dirs2: Array[Vector2] = get_side_step_candidates(target)

		var score2: int = 55
		for dir in toward_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score2, {"direction": dir}))
			score2 -= 5

		for dir in side_dirs2:
			result.append(make_action_candidate(ActionType.MOVE, score2, {"direction": dir}))
			score2 -= 5

	return result


func build_flee_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var away_dirs: Array[Vector2] = get_candidate_steps_away_from_target(target)
	var side_dirs: Array[Vector2] = get_side_step_candidates(target)

	var score: int = 75
	for dir in away_dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 5

	for dir in side_dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 5

	return result


func make_action_candidate(action_type: int, score: int, data: Dictionary = {}) -> Dictionary:
	return {
		"type": action_type,
		"score": score,
		"data": data
	}


func sort_candidates_desc(candidates: Array[Dictionary]) -> void:
	candidates.sort_custom(func(a, b): return a["score"] > b["score"])


func execute_candidate(candidate: Dictionary, context: Dictionary) -> bool:
	var action_type: int = candidate["type"]
	var data: Dictionary = candidate["data"]

	match action_type:
		ActionType.ATTACK:
			return execute_attack_candidate(data, context)
		ActionType.SUPPORT:
			return execute_support_candidate(data, context)
		ActionType.USE_ITEM:
			return execute_item_candidate(data, context)
		ActionType.MOVE:
			return execute_move_candidate(data, context)
		ActionType.WAIT:
			unit.wait_action()
			return true

	return false


func execute_attack_candidate(data: Dictionary, context: Dictionary) -> bool:
	var target = data.get("target", null)
	if target == null:
		return false

	var attack_kind: String = data.get("attack_kind", "normal")

	match attack_kind:
		"normal":
			if CombatManager.can_attack(unit, target):
				return CombatManager.perform_attack(unit, target)

	return false


func execute_support_candidate(data: Dictionary, context: Dictionary) -> bool:
	return false


func execute_item_candidate(data: Dictionary, context: Dictionary) -> bool:
	return false


func execute_move_candidate(data: Dictionary, context: Dictionary) -> bool:
	var dir: Vector2 = data.get("direction", Vector2.ZERO)
	if dir == Vector2.ZERO:
		return false

	return unit.try_move(dir)


func get_candidate_steps_toward_target(target) -> Array[Vector2]:
	var result: Array[Vector2] = []

	if unit == null or target == null:
		return result

	var my_tile: Vector2i = unit.get_current_tile_coords()
	var target_tile: Vector2i = target.get_current_tile_coords()
	var diff: Vector2i = target_tile - my_tile

	var primary: Vector2 = Vector2.ZERO
	var secondary: Vector2 = Vector2.ZERO

	if abs(diff.x) >= abs(diff.y):
		if diff.x > 0:
			primary = Vector2.RIGHT
		elif diff.x < 0:
			primary = Vector2.LEFT

		if diff.y > 0:
			secondary = Vector2.DOWN
		elif diff.y < 0:
			secondary = Vector2.UP
	else:
		if diff.y > 0:
			primary = Vector2.DOWN
		elif diff.y < 0:
			primary = Vector2.UP

		if diff.x > 0:
			secondary = Vector2.RIGHT
		elif diff.x < 0:
			secondary = Vector2.LEFT

	if primary != Vector2.ZERO:
		result.append(primary)
	if secondary != Vector2.ZERO and secondary != primary:
		result.append(secondary)

	return result


func get_candidate_steps_away_from_target(target) -> Array[Vector2]:
	var toward_dirs: Array[Vector2] = get_candidate_steps_toward_target(target)
	var result: Array[Vector2] = []

	for dir in toward_dirs:
		result.append(-dir)

	return result


func get_side_step_candidates(target) -> Array[Vector2]:
	var result: Array[Vector2] = []

	if unit == null or target == null:
		return result

	var my_tile: Vector2i = unit.get_current_tile_coords()
	var target_tile: Vector2i = target.get_current_tile_coords()
	var diff: Vector2i = target_tile - my_tile

	if abs(diff.x) >= abs(diff.y):
		result.append(Vector2.UP)
		result.append(Vector2.DOWN)
	else:
		result.append(Vector2.LEFT)
		result.append(Vector2.RIGHT)

	return result
