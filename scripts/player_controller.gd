extends Node

var unit = null
var units_node = null

func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = get_tree().current_scene.get_node_or_null("Units")

func _physics_process(_delta: float) -> void:
	if unit == null:
		return

	if TimeManager.is_resolving_turn:
		return

	if unit.is_transitioning:
		return

	if unit.is_moving:
		return

	if unit.repeat_timer > 0.0:
		return

	if Input.is_action_just_pressed("interact"):
		unit.try_interact_transition()
		if unit.is_transitioning:
			return

	if Input.is_action_just_pressed("wait"):
		unit.wait_action()
		if units_node != null:
			TimeManager.advance_time(units_node, unit.stats.speed)
		return

	var input_dir := get_input_direction()
	if input_dir != Vector2.ZERO:
		var was_moving = unit.is_moving
		unit.try_move(input_dir)

		if not was_moving and unit.is_moving:
			if units_node != null:
				TimeManager.advance_time(units_node, unit.stats.speed)

func get_input_direction() -> Vector2:
	if Input.is_action_pressed("ui_right"):
		return Vector2.RIGHT
	elif Input.is_action_pressed("ui_left"):
		return Vector2.LEFT
	elif Input.is_action_pressed("ui_down"):
		return Vector2.DOWN
	elif Input.is_action_pressed("ui_up"):
		return Vector2.UP

	return Vector2.ZERO
