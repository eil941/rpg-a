extends Node

var unit = null
var units_node = null

func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = get_tree().current_scene.get_node_or_null("Units")

func _physics_process(_delta: float) -> void:
	if unit == null:
		return

	if unit.is_transitioning:
		return

	if unit.is_moving:
		return

	if unit.repeat_timer > 0.0:
		return

	if unit.stats.pending_actions <= 0:
		if units_node != null:
			TimeManager.update_turn_state(units_node)
		return

	unit.stats.pending_actions -= 1

	var choice = choose_direction_by_time()


	if choice == Vector2.ZERO:
		unit.wait_action()
		if units_node != null:
			TimeManager.update_turn_state(units_node)
		return

	unit.try_move(choice)

	if not unit.is_moving:
		if units_node != null:
			TimeManager.update_turn_state(units_node)

func choose_direction_by_time() -> Vector2:
	var all_dirs = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP,
		Vector2.ZERO
	]

	var time_of_day = TimeManager.get_time_of_day()

	if randf() < 0.7:
		match time_of_day:
			"朝":
				return Vector2.DOWN
			"昼":
				return Vector2.LEFT
			"夕":
				return Vector2.UP
			"夜":
				return Vector2.RIGHT

	all_dirs.shuffle()
	return all_dirs[0]
