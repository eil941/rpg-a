extends CharacterBody2D

@export var tile_size: int = 32
@export var move_speed: float = 220.0
@export var repeat_delay: float = 0.0

var is_moving: bool = false
var target_position: Vector2
var repeat_timer: float = 0.0
var is_transitioning: bool = false

@onready var tile_map = get_tree().current_scene.get_node("TileMap")

@onready var stats = $Stats
@onready var controller = $Controller

@export var start_tile: Vector2i = Vector2i(1, 1)
@export var use_start_tile: bool = false
@export var can_trigger_scene_transition: bool = false

@onready var units_node = get_tree().current_scene.get_node("Units")
@export var receives_time_turns: bool = true

@export var instant_move: bool = true



func _ready() -> void:
	if use_start_tile:
		global_position = tile_map.to_global(tile_map.map_to_local(start_tile))
	else:
		var current_tile = tile_map.local_to_map(tile_map.to_local(global_position))
		global_position = tile_map.to_global(tile_map.map_to_local(current_tile))

	target_position = global_position


	print("HP: ", stats.hp, "/", stats.max_hp)
	print("ATK: ", stats.attack, " DEF: ", stats.defense)
	print("SPD: ", stats.speed)

	if controller != null and controller.has_method("setup"):
		controller.setup(self)

func _physics_process(delta: float) -> void:
	if is_transitioning:
		return

	if is_moving:
		global_position = global_position.move_toward(target_position, move_speed * delta)

		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			is_moving = false
			repeat_timer = repeat_delay

			if units_node != null:
				TimeManager.update_turn_state(units_node)
		return

	if repeat_timer > 0.0:
		repeat_timer -= delta
		return

func on_time_advanced(elapsed_seconds: float) -> void:
	if not receives_time_turns:
		return

	stats.action_progress_seconds += elapsed_seconds

	if stats.speed <= 0.0:
		return

	var action_cost_seconds = 86400.0 / stats.speed

	while stats.action_progress_seconds >= action_cost_seconds:
		stats.action_progress_seconds -= action_cost_seconds
		stats.pending_actions += 1

func get_tile_data_at_coords(coords: Vector2i):
	return tile_map.get_cell_tile_data(0, coords)

func get_current_tile_coords() -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(global_position))

func get_current_tile_data():
	var coords = get_current_tile_coords()
	return tile_map.get_cell_tile_data(0, coords)

func get_occupied_tile_coords() -> Vector2i:
	if is_moving:
		return tile_map.local_to_map(tile_map.to_local(target_position))
	return get_current_tile_coords()

func is_unit_on_tile(tile: Vector2i) -> bool:
	if units_node == null:
		return false

	for other in units_node.get_children():
		if other == null:
			continue
		if other == self:
			continue
		if not other.has_method("get_occupied_tile_coords"):
			continue

		if other.get_occupied_tile_coords() == tile:
			return true

	return false

func try_move(dir: Vector2) -> void:
	var next_pos = global_position + dir * tile_size
	var next_tile = tile_map.local_to_map(tile_map.to_local(next_pos))

	if is_unit_on_tile(next_tile):
		return

	var space_state = get_world_2d().direct_space_state

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = Transform2D(0, next_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query)

	if result.is_empty():
		if instant_move:
			global_position = next_pos
			target_position = next_pos
			is_moving = false

			if units_node != null:
				TimeManager.update_turn_state(units_node)
		else:
			target_position = next_pos
			is_moving = true
		return

	var tile_data = get_tile_data_at_coords(next_tile)
	if tile_data == null:
		return

	var scene_transfer = tile_data.get_custom_data("scene_transfer")
	if can_trigger_scene_transition and scene_transfer != null and scene_transfer == true:
		var next_scene = String(tile_data.get_custom_data("enter_scene"))
		var spawn_x = int(tile_data.get_custom_data("spawn_x"))
		var spawn_y = int(tile_data.get_custom_data("spawn_y"))

		if next_scene != "":
			is_transitioning = true
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)
			get_tree().change_scene_to_file(next_scene)

func try_interact_transition() -> void:
	if not can_trigger_scene_transition:
		return

	var tile_data = get_current_tile_data()

	if tile_data == null:
		return

	var can_enter = tile_data.get_custom_data("can_enter")
	if can_enter == null or can_enter == false:
		return

	var next_scene = String(tile_data.get_custom_data("enter_scene"))
	if next_scene == "":
		return

	var spawn_x = int(tile_data.get_custom_data("spawn_x"))
	var spawn_y = int(tile_data.get_custom_data("spawn_y"))

	is_transitioning = true
	GlobalPlayerSpawn.has_next_tile = true
	GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)

	get_tree().change_scene_to_file(next_scene)

func wait_action() -> void:
	is_moving = false
	repeat_timer = repeat_delay
