extends Node

enum MoveBehavior {
	APPROACH_MELEE,
	KEEP_DISTANCE,
	FLEE
}

@export var move_behavior: int = MoveBehavior.APPROACH_MELEE
@export var detection_range: int = 5
@export var preferred_distance: int = 2
@export var random_move_chance: float = 0.7

var unit = null
var units_node = null
var rng := RandomNumberGenerator.new()


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node
	rng.randomize()


func take_turn() -> void:
	if unit == null:
		return

	if units_node == null:
		units_node = unit.units_node
		if units_node == null:
			consume_pending_action()
			return

	if not unit.has_node("Stats"):
		consume_pending_action()
		return

	if unit.stats.hp <= 0:
		consume_pending_action()
		return

	var target = Targeting.get_nearest_hostile_unit(units_node, unit, detection_range)

	if target == null:
		#do_idle_behavior()
		#ターゲットが近くにいない時は停止
		unit.wait_action()
		consume_pending_action()
		return

	if CombatManager.can_attack(unit, target):
		face_target(target)
		CombatManager.perform_attack(unit, target)
		consume_pending_action()
		return

	match move_behavior:
		MoveBehavior.APPROACH_MELEE:
			do_approach_melee(target)
		MoveBehavior.KEEP_DISTANCE:
			do_keep_distance(target)
		MoveBehavior.FLEE:
			do_flee(target)

	consume_pending_action()


func consume_pending_action() -> void:
	if unit == null:
		return
	if not unit.has_node("Stats"):
		return

	unit.stats.pending_actions -= 1
	if unit.stats.pending_actions < 0:
		unit.stats.pending_actions = 0


func do_idle_behavior() -> void:
	if unit == null:
		return

	if rng.randf() > random_move_chance:
		unit.wait_action()
		return

	var directions = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP
	]
	directions.shuffle()

	for dir in directions:
		if unit.try_move(dir):
			return

	unit.wait_action()


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


func get_step_toward_target(target) -> Vector2:
	if unit == null or target == null:
		return Vector2.ZERO

	var my_tile = unit.get_current_tile_coords()
	var target_tile = target.get_current_tile_coords()
	var diff = target_tile - my_tile

	if abs(diff.x) > abs(diff.y):
		return Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	elif diff.y != 0:
		return Vector2.DOWN if diff.y > 0 else Vector2.UP

	return Vector2.ZERO


func get_step_away_from_target(target) -> Vector2:
	var toward = get_step_toward_target(target)

	if toward == Vector2.RIGHT:
		return Vector2.LEFT
	elif toward == Vector2.LEFT:
		return Vector2.RIGHT
	elif toward == Vector2.DOWN:
		return Vector2.UP
	elif toward == Vector2.UP:
		return Vector2.DOWN

	return Vector2.ZERO


func do_approach_melee(target) -> void:
	var dir = get_step_toward_target(target)

	if dir == Vector2.ZERO:
		unit.wait_action()
		return

	if not unit.try_move(dir):
		unit.wait_action()


func do_keep_distance(target) -> void:
	var dist = Targeting.get_distance_between_units(unit, target)

	if dist <= preferred_distance:
		var dir = get_step_away_from_target(target)
		if dir != Vector2.ZERO and unit.try_move(dir):
			return

	var dir2 = get_step_toward_target(target)
	if dir2 != Vector2.ZERO and unit.try_move(dir2):
		return

	unit.wait_action()


func do_flee(target) -> void:
	var dir = get_step_away_from_target(target)

	if dir == Vector2.ZERO:
		unit.wait_action()
		return

	if not unit.try_move(dir):
		unit.wait_action()
