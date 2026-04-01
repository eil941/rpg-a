extends Node

enum ActionType {
	ATTACK,
	SUPPORT,
	USE_ITEM,
	MOVE,
	WAIT
}

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

@export var detection_range: int = 5
@export var preferred_distance: int = 2
@export var random_idle_move_chance: float = 0.7

# 暫定設定
@export var default_move_style: int = MoveStyle.APPROACH
@export var default_combat_style: int = CombatStyle.MELEE

var unit = null
var units_node = null
var rng := RandomNumberGenerator.new()


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node
	rng.randomize()


func take_turn() -> void:
	if not can_act():
		if DebugSettings.debug_ai_turn:
			print("----- AI TURN SKIP -----")
			print("unit: ", unit.name if unit != null else "null")
			print("reason: can_act() == false")
		consume_pending_action()
		return

	var context = build_ai_context()
	var candidates = build_action_candidates(context)

	sort_candidates_desc(candidates)

	if DebugSettings.debug_ai_turn:
		print("----- AI TURN START -----")
		print("unit: ", unit.name)
		print("unit_id: ", unit.unit_id)
		print("target: ", context["target"].name if context["target"] != null else "null")
		print("distance_to_target: ", context["distance_to_target"])
		print("hp_rate: ", context["hp_rate"])
		print("move_style: ", context["move_style"])
		print("combat_style: ", context["combat_style"])

		if unit.has_method("get_effective_move_style"):
			print("effective_move_style: ", unit.get_effective_move_style())
		if unit.has_method("get_effective_combat_style"):
			print("effective_combat_style: ", unit.get_effective_combat_style())

	if DebugSettings.debug_ai_candidates:
		print("----- AI CANDIDATES -----")
		print("unit: ", unit.name)
		for i in range(candidates.size()):
			print("[", i, "] ", candidates[i])

	for candidate in candidates:
		if execute_candidate(candidate, context):
			consume_pending_action()
			return

	if DebugSettings.debug_ai_turn:
		print("----- AI FALLBACK WAIT -----")
		print("unit: ", unit.name)

	unit.wait_action()
	consume_pending_action()


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
	var dist_to_hostile := -1

	if nearest_hostile != null:
		dist_to_hostile = Targeting.get_distance_between_units(unit, nearest_hostile)

	if DebugSettings.debug_ai_target:
		print("----- AI TARGET -----")
		print("unit: ", unit.name)
		print("target: ", nearest_hostile.name if nearest_hostile != null else "null")
		print("distance: ", dist_to_hostile)

	return {
		"self": unit,
		"target": nearest_hostile,
		"distance_to_target": dist_to_hostile,
		"hp_rate": get_self_hp_rate(),
		"move_style": get_effective_move_style(),
		"combat_style": get_effective_combat_style()
	}


func get_self_hp_rate() -> float:
	if unit == null or unit.stats == null:
		return 1.0

	var max_hp = max(unit.get_total_max_hp(), 1)
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

	var target = context["target"]

	candidates.append_array(build_self_item_candidates(context))
	candidates.append_array(build_support_candidates(context))
	candidates.append_array(build_attack_candidates(context))
	candidates.append_array(build_move_candidates(context))
	candidates.append(make_action_candidate(ActionType.WAIT, 5, {}))

	if target == null:
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

	var target = context["target"]
	if target == null:
		return result

	var move_style = context["move_style"]

	if DebugSettings.debug_ai_attack:
		print("----- BUILD ATTACK CANDIDATES -----")
		print("unit: ", unit.name)
		print("move_style: ", move_style)
		print("target: ", target.name)

	# FLEE の時は攻撃候補を作らない
	if move_style == MoveStyle.FLEE:
		if DebugSettings.debug_flee_ai:
			print("----- FLEE ATTACK BLOCK -----")
			print("unit: ", unit.name)
			print("reason: move_style == FLEE")
		return result

	if CombatManager.can_attack(unit, target):
		var score = get_normal_attack_score(context, target)
		result.append(
			make_action_candidate(
				ActionType.ATTACK,
				score,
				{
					"target": target,
					"attack_kind": "normal"
				}
			)
		)

		if DebugSettings.debug_ai_attack:
			print("add attack candidate")
			print("unit: ", unit.name)
			print("target: ", target.name)
			print("score: ", score)
	else:
		if DebugSettings.debug_ai_attack:
			print("cannot attack")
			print("unit: ", unit.name)
			print("target: ", target.name)

	return result


func get_normal_attack_score(context: Dictionary, target) -> int:
	var combat_style = context["combat_style"]

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

	var move_style = context["move_style"]

	if DebugSettings.debug_ai_move:
		print("----- BUILD MOVE CANDIDATES -----")
		print("unit: ", unit.name)
		print("move_style: ", move_style)
		print("target: ", target.name)
		print("distance_to_target: ", context["distance_to_target"])

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

	var score := 15
	for dir in dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 1

	return result


func build_approach_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dirs = get_candidate_steps_toward_target(target)

	if DebugSettings.debug_ai_move:
		print("APPROACH dirs: ", dirs)

	var score := 60
	for dir in dirs:
		result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
		score -= 5

	return result


func build_keep_distance_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var dist = context["distance_to_target"]

	if dist < preferred_distance:
		var away_dirs = get_candidate_steps_away_from_target(target)
		var side_dirs = get_side_step_candidates(target)

		if DebugSettings.debug_ai_move:
			print("KEEP_DISTANCE near")
			print("away_dirs: ", away_dirs)
			print("side_dirs: ", side_dirs)

		var score := 70
		for dir in away_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
			score -= 5

		for dir in side_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score, {"direction": dir}))
			score -= 5

	elif dist > preferred_distance:
		var toward_dirs = get_candidate_steps_toward_target(target)
		var side_dirs2 = get_side_step_candidates(target)

		if DebugSettings.debug_ai_move:
			print("KEEP_DISTANCE far")
			print("toward_dirs: ", toward_dirs)
			print("side_dirs: ", side_dirs2)

		var score2 := 55
		for dir in toward_dirs:
			result.append(make_action_candidate(ActionType.MOVE, score2, {"direction": dir}))
			score2 -= 5

		for dir in side_dirs2:
			result.append(make_action_candidate(ActionType.MOVE, score2, {"direction": dir}))
			score2 -= 5

	return result


func build_flee_move_candidates(context: Dictionary, target) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var away_dirs = get_candidate_steps_away_from_target(target)
	var side_dirs = get_side_step_candidates(target)

	if DebugSettings.debug_flee_ai or DebugSettings.debug_ai_move:
		print("----- FLEE MOVE CANDIDATES -----")
		print("unit: ", unit.name)
		print("target: ", target.name)
		print("away_dirs: ", away_dirs)
		print("side_dirs: ", side_dirs)
		print("distance_to_target: ", context["distance_to_target"])

	var score := 75
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
	var action_type = candidate["type"]
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
			if DebugSettings.debug_ai_turn:
				print("execute wait")
				print("unit: ", unit.name)
			unit.wait_action()
			return true

	return false


func execute_attack_candidate(data: Dictionary, context: Dictionary) -> bool:
	var target = data.get("target", null)
	if target == null:
		return false

	var attack_kind = data.get("attack_kind", "normal")

	if DebugSettings.debug_ai_attack:
		print("----- EXECUTE ATTACK -----")
		print("unit: ", unit.name)
		print("attack_kind: ", attack_kind)
		print("target: ", target.name)

	match attack_kind:
		"normal":
			if CombatManager.can_attack(unit, target):
				face_target(target)
				CombatManager.perform_attack(unit, target)
				return true

	return false


func execute_support_candidate(data: Dictionary, context: Dictionary) -> bool:
	return false


func execute_item_candidate(data: Dictionary, context: Dictionary) -> bool:
	return false


func execute_move_candidate(data: Dictionary, context: Dictionary) -> bool:
	var dir: Vector2 = data.get("direction", Vector2.ZERO)
	if dir == Vector2.ZERO:
		return false

	if DebugSettings.debug_ai_move:
		print("----- EXECUTE MOVE -----")
		print("unit: ", unit.name)
		print("dir: ", dir)

	return unit.try_move(dir)


func face_target(target) -> void:
	if unit == null or target == null:
		return

	var my_tile = unit.get_current_tile_coords()
	var target_tile = target.get_current_tile_coords()
	var diff = target_tile - my_tile

	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			unit.update_facing_only(Vector2.RIGHT)
		elif diff.x < 0:
			unit.update_facing_only(Vector2.LEFT)
	else:
		if diff.y > 0:
			unit.update_facing_only(Vector2.DOWN)
		elif diff.y < 0:
			unit.update_facing_only(Vector2.UP)


func get_candidate_steps_toward_target(target) -> Array[Vector2]:
	var result: Array[Vector2] = []

	if unit == null or target == null:
		return result

	var my_tile = unit.get_current_tile_coords()
	var target_tile = target.get_current_tile_coords()
	var diff = target_tile - my_tile

	var primary := Vector2.ZERO
	var secondary := Vector2.ZERO

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
	var toward_dirs = get_candidate_steps_toward_target(target)
	var result: Array[Vector2] = []

	for dir in toward_dirs:
		result.append(-dir)

	return result


func get_side_step_candidates(target) -> Array[Vector2]:
	var result: Array[Vector2] = []

	if unit == null or target == null:
		return result

	var my_tile = unit.get_current_tile_coords()
	var target_tile = target.get_current_tile_coords()
	var diff = target_tile - my_tile

	if abs(diff.x) >= abs(diff.y):
		result.append(Vector2.UP)
		result.append(Vector2.DOWN)
	else:
		result.append(Vector2.LEFT)
		result.append(Vector2.RIGHT)

	return result
