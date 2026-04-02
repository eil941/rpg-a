extends Node

var unit = null
var units_node = null

@export var first_move_hold_time: float = 0.08
@export var repeat_move_interval: float = 0.00

var held_dir: Vector2 = Vector2.ZERO
var held_time: float = 0.0
var repeat_time: float = 0.0
var is_holding_move: bool = false
var first_move_done: bool = false


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node


func _physics_process(delta: float) -> void:
	if unit == null:
		return

	if units_node == null:
		units_node = unit.units_node
		if units_node == null:
			return

	# インベントリは常にトグル可能にする
	if Input.is_action_just_pressed("inventory"):
		if is_dialog_open():
			return
		toggle_inventory_ui()
		return

	# 会話中だけは入力を止める
	if is_dialog_open():
		clear_move_hold()
		return

	if TimeManager.is_resolving_turn:
		return

	if unit.is_transitioning:
		clear_move_hold()
		return

	if not unit.is_moving and unit.repeat_timer <= 0.0:
		if Input.is_action_just_pressed("pickup_test"):
			if unit.inventory != null:
				unit.inventory.add_item("potion", 1)
				unit.notify_hud_log("potionを手に入れた")

		if Input.is_action_just_pressed("interact"):
			clear_move_hold()
			unit.try_interact_action()
			return

		if Input.is_action_just_pressed("attack"):
			clear_move_hold()
			var acted = try_attack_action()
			if acted:
				if not DebugSettings.debug_free_action:
					TimeManager.advance_time(units_node, unit.stats.speed)
					notify_hud()
					TimeManager.resolve_ai_turns(units_node)
			return

		if Input.is_action_just_pressed("wait"):
			clear_move_hold()
			unit.wait_action()
			if not DebugSettings.debug_free_action:
				TimeManager.advance_time(units_node, unit.stats.speed)
				notify_hud()
				TimeManager.resolve_ai_turns(units_node)
			return

	handle_move_input(delta)


func handle_move_input(delta: float) -> void:
	var input_dir := get_input_direction()

	if input_dir == Vector2.ZERO:
		clear_move_hold()
		return

	if not is_holding_move:
		start_hold(input_dir)
		return

	if input_dir != held_dir:
		start_hold_and_move_immediately(input_dir)
		return

	if unit.is_moving or unit.repeat_timer > 0.0:
		return

	if not first_move_done:
		held_time += delta
		if held_time >= first_move_hold_time:
			first_move_done = true
			repeat_time = 0.0
			try_move_in_direction(held_dir)
		return

	repeat_time += delta
	if repeat_time >= repeat_move_interval:
		repeat_time = 0.0
		try_move_in_direction(held_dir)


func start_hold(dir: Vector2) -> void:
	held_dir = dir
	held_time = 0.0
	repeat_time = 0.0
	is_holding_move = true
	first_move_done = false

	face_direction_only(dir)


func start_hold_and_move_immediately(dir: Vector2) -> void:
	held_dir = dir
	held_time = first_move_hold_time
	repeat_time = 0.0
	is_holding_move = true
	first_move_done = true

	face_direction_only(dir)
	try_move_in_direction(dir)


func clear_move_hold() -> void:
	held_dir = Vector2.ZERO
	held_time = 0.0
	repeat_time = 0.0
	is_holding_move = false
	first_move_done = false


func face_direction_only(dir: Vector2) -> void:
	if unit == null:
		return

	if unit.has_method("update_facing_only"):
		unit.update_facing_only(dir)
		return

	if dir == Vector2.RIGHT:
		unit.facing = unit.Facing.RIGHT
	elif dir == Vector2.LEFT:
		unit.facing = unit.Facing.LEFT
	elif dir == Vector2.DOWN:
		unit.facing = unit.Facing.DOWN
	elif dir == Vector2.UP:
		unit.facing = unit.Facing.UP

	if unit.has_method("set_idle_animation"):
		unit.set_idle_animation()


func try_move_in_direction(dir: Vector2) -> void:
	var acted = unit.try_move(dir)

	if acted:
		if not DebugSettings.debug_free_action:
			TimeManager.advance_time(units_node, unit.stats.speed)
			notify_hud()
			TimeManager.resolve_ai_turns(units_node)


func try_attack_action() -> bool:
	if unit == null:
		return false

	var target = CombatManager.get_best_attack_target(unit)
	if target == null:
		if unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃できる対象がいない")
		return false

	var acted = CombatManager.perform_attack(unit, target)
	return acted


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


func is_inventory_open() -> bool:
	var root := get_tree().current_scene
	if root == null:
		return false

	var inventory_ui = root.find_child("InventoryUI", true, false)
	if inventory_ui == null:
		return false

	return inventory_ui.visible


func is_dialog_open() -> bool:
	if not has_node("/root/DialogueManager"):
		return false

	if DialogueManager == null:
		return false

	if DialogueManager.has_method("is_dialog_open"):
		return DialogueManager.is_dialog_open()

	if "dialogue_ui" in DialogueManager and DialogueManager.dialogue_ui != null:
		if DialogueManager.dialogue_ui.has_method("is_dialog_visible"):
			return DialogueManager.dialogue_ui.is_dialog_visible()

	return false
