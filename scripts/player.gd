extends CharacterBody2D

@export var tile_size: int = 32
@export var move_speed: float = 220.0
@export var repeat_delay: float = 0.0

var is_moving: bool = false
var target_position: Vector2
var repeat_timer: float = 0.0
var is_transitioning: bool = false

@onready var tile_map = get_parent().get_node("TileMap")
@onready var stats = $Stats


func _ready() -> void:
	global_position = global_position.snapped(Vector2(tile_size, tile_size))
	target_position = global_position
	
	
	print("HP: ", stats.hp, "/", stats.max_hp)
	print("ATK: ", stats.attack, " DEF: ", stats.defense)

func _physics_process(delta: float) -> void:
	if is_transitioning:
		return

	if is_moving:
		global_position = global_position.move_toward(target_position, move_speed * delta)

		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			is_moving = false
			repeat_timer = repeat_delay
		return

	if repeat_timer > 0.0:
		repeat_timer -= delta
		return

	if Input.is_action_just_pressed("interact"):
		try_interact_transition()
		if is_transitioning:
			return

	var input_dir := get_input_direction()
	if input_dir != Vector2.ZERO:
		try_move(input_dir)

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

func get_tile_data_at_coords(coords: Vector2i):
	return tile_map.get_cell_tile_data(0, coords)

func try_move(dir: Vector2) -> void:
	var next_pos = global_position + dir * tile_size
	var next_tile = tile_map.local_to_map(tile_map.to_local(next_pos))

	var space_state = get_world_2d().direct_space_state

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = Transform2D(0, next_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query)

	if result.is_empty():
		target_position = next_pos
		is_moving = true
		return

	var tile_data = get_tile_data_at_coords(next_tile)
	if tile_data == null:
		return

	var wall_transfer = tile_data.get_custom_data("scene_transfer")
	if wall_transfer != null and wall_transfer == true:
		var next_scene = String(tile_data.get_custom_data("enter_scene"))
		var spawn_x = int(tile_data.get_custom_data("spawn_x"))
		var spawn_y = int(tile_data.get_custom_data("spawn_y"))

		if next_scene != "":
			is_transitioning = true
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)
			get_tree().change_scene_to_file(next_scene)

func get_current_tile_coords() -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(global_position))

func get_current_tile_data():
	var coords = get_current_tile_coords()
	return tile_map.get_cell_tile_data(0, coords)

func try_interact_transition() -> void:
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
