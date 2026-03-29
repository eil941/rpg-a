extends Node

var unit = null
var units_node = null


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node


func _physics_process(_delta: float) -> void:
	pass


func take_turn() -> void:
	if unit == null:
		return

	if units_node == null:
		units_node = unit.units_node
		if units_node == null:
			return

	if unit.is_transitioning:
		return

	if unit.is_moving:
		return

	if unit.repeat_timer > 0.0:
		return

	if units_node != null:
		for other in units_node.get_children():
			if other == null:
				continue
			if other.is_player_unit and other.is_moving:
				return

	if unit.stats.pending_actions <= 0:
		return

	unit.stats.pending_actions -= 1

	var choice = choose_direction_by_time()

	if choice == Vector2.ZERO:
		unit.wait_action()
		return

	unit.try_move(choice)


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
