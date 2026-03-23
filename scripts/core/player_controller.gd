extends Node

var unit = null
var units_node = null


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node


func _physics_process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory_ui()
		return
	
	if unit == null:
		return

	if units_node == null:
		units_node = unit.units_node
		if units_node == null:
			return

	if TimeManager.is_resolving_turn:
		return

	if unit.is_transitioning:
		return
		
	if Input.is_action_just_pressed("inventory"):
		print("open inventory")
		toggle_inventory_ui()
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

		if not unit.debug_free_action:
			TimeManager.advance_time(units_node, unit.stats.speed)
			notify_hud()
			TimeManager.resolve_ai_turns(units_node)

		return

	var input_dir := get_input_direction()
	if input_dir != Vector2.ZERO:
		var acted = unit.try_move(input_dir)

		if acted:
			if not unit.debug_free_action:
				TimeManager.advance_time(units_node, unit.stats.speed)
				notify_hud()
				TimeManager.resolve_ai_turns(units_node)


func notify_hud() -> void:
	var node: Node = unit

	while node != null:
		if node.has_method("refresh_hud"):
			node.refresh_hud()
			return
		node = node.get_parent()


func get_input_direction() -> Vector2:
	if Input.is_action_pressed("RIGHT"):
		return Vector2.RIGHT
	elif Input.is_action_pressed("LEFT"):
		return Vector2.LEFT
	elif Input.is_action_pressed("DOWN"):
		return Vector2.DOWN
	elif Input.is_action_pressed("UP"):
		return Vector2.UP

	return Vector2.ZERO

func toggle_inventory_ui() -> void:
	var node: Node = unit

	while node != null:
		if node.has_method("toggle_inventory_ui"):
			node.toggle_inventory_ui()
			return
		node = node.get_parent()
