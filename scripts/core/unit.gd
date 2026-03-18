extends CharacterBody2D

@export var tile_size: int = 32
@export var move_speed: float = 220.0
@export var repeat_delay: float = 0.0

@export var start_tile: Vector2i = Vector2i(1, 1)
@export var can_trigger_scene_transition: bool = false

@export var can_bump_attack: bool = false
@export var is_enemy: bool = false

@export var receives_time_turns: bool = true
@export var instant_move: bool = true

@export var unit_id: String = ""
@export var is_player_unit: bool = false
@export var map_id: String = ""
@export var debug_free_action: bool = false

var is_moving: bool = false
var target_position: Vector2
var repeat_timer: float = 0.0
var is_transitioning: bool = false

var enemy_data_to_apply: EnemyData = null
var npc_data_to_apply: NpcData = null

@onready var ground_layer: TileMapLayer = get_tree().current_scene.get_node("GroundLayer")
@onready var wall_layer: TileMapLayer = get_tree().current_scene.get_node("WallLayer")
@onready var event_layer: TileMapLayer = get_tree().current_scene.get_node("EventLayer")

@onready var stats = $Stats
@onready var controller = $Controller
@onready var units_node = get_tree().current_scene.get_node_or_null("Units")
@onready var targeting = Targeting
@onready var combat_manager = CombatManager

func _ready() -> void:
	global_position = ground_layer.to_global(ground_layer.map_to_local(start_tile))
	target_position = global_position

	if controller != null and controller.has_method("setup"):
		controller.setup(self)

	if enemy_data_to_apply != null:
		apply_enemy_data(enemy_data_to_apply)

	if npc_data_to_apply != null:
		apply_npc_data(npc_data_to_apply)

	load_persistent_stats()

	if is_player_unit and GlobalPlayerSpawn.has_next_tile:
		global_position = ground_layer.to_global(ground_layer.map_to_local(GlobalPlayerSpawn.next_tile))
		target_position = global_position
		GlobalPlayerSpawn.has_next_tile = false

	print("HP: ", stats.hp, "/", stats.max_hp)
	print("ATK: ", stats.attack, " DEF: ", stats.defense)
	print("SPD: ", stats.speed)

	TimeManager.is_resolving_turn = false

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
	return event_layer.get_cell_tile_data(coords)

func get_current_tile_coords() -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(global_position))

func get_current_tile_data():
	var coords = get_current_tile_coords()
	return event_layer.get_cell_tile_data(coords)

func get_occupied_tile_coords() -> Vector2i:
	if is_moving:
		return ground_layer.local_to_map(ground_layer.to_local(target_position))
	return get_current_tile_coords()

func try_move(dir: Vector2) -> bool:
	var next_pos = global_position + dir * tile_size
	var next_tile = ground_layer.local_to_map(ground_layer.to_local(next_pos))

	var target_unit = targeting.get_unit_on_tile(units_node, next_tile, self)
	if target_unit != null:
		if combat_manager.try_bump_attack(self, target_unit):
			return true
		return false

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

		return true

	var tile_data = get_tile_data_at_coords(next_tile)
	if tile_data == null:
		return false

	var scene_transfer = tile_data.get_custom_data("scene_transfer")
	if can_trigger_scene_transition and scene_transfer != null and scene_transfer == true:
		var next_scene = String(tile_data.get_custom_data("enter_scene"))
		var spawn_x = int(tile_data.get_custom_data("spawn_x"))
		var spawn_y = int(tile_data.get_custom_data("spawn_y"))

		if next_scene != "":
			if is_player_unit:
				PlayerData.last_map_id = map_id
				PlayerData.last_tile = get_current_tile_coords()

			var current_scene = get_tree().current_scene
			if current_scene != null and current_scene.has_method("save_all_units"):
				current_scene.save_all_units()

			is_transitioning = true
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)
			get_tree().change_scene_to_file(next_scene)
			return true

	return false

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

	if is_player_unit:
		PlayerData.last_map_id = map_id
		PlayerData.last_tile = get_current_tile_coords()

	var current_scene = get_tree().current_scene
	if current_scene != null and current_scene.has_method("save_all_units"):
		current_scene.save_all_units()

	is_transitioning = true
	GlobalPlayerSpawn.has_next_tile = true
	GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)

	get_tree().change_scene_to_file(next_scene)

func wait_action() -> void:
	is_moving = false
	repeat_timer = repeat_delay

func get_hp_status_text() -> String:
	return "%s HP: %d/%d" % [name, stats.hp, stats.max_hp]

func get_stats_data() -> Dictionary:
	return {
		"hp": stats.hp,
		"max_hp": stats.max_hp,
		"attack": stats.attack,
		"defense": stats.defense,
		"speed": stats.speed,
		"tile_x": get_current_tile_coords().x,
		"tile_y": get_current_tile_coords().y
	}

func apply_stats_data(data: Dictionary) -> void:
	if data.has("max_hp"):
		stats.max_hp = data["max_hp"]
	if data.has("hp"):
		stats.hp = data["hp"]
	if data.has("attack"):
		stats.attack = data["attack"]
	if data.has("defense"):
		stats.defense = data["defense"]
	if data.has("speed"):
		stats.speed = data["speed"]
	if data.has("tile_x") and data.has("tile_y"):
		var saved_tile = Vector2i(data["tile_x"], data["tile_y"])
		global_position = ground_layer.to_global(ground_layer.map_to_local(saved_tile))
		target_position = global_position

func save_persistent_stats() -> void:
	print("SAVE unit_id=", unit_id, " hp=", stats.hp)

	if is_player_unit:
		PlayerData.max_hp = stats.max_hp
		PlayerData.hp = stats.hp
		PlayerData.attack = stats.attack
		PlayerData.defense = stats.defense
		PlayerData.speed = stats.speed
		PlayerData.current_tile = get_current_tile_coords()
		PlayerData.current_map_id = map_id
		return

	if unit_id != "":
		var data = get_stats_data()
		data["is_dead"] = stats.hp <= 0
		WorldState.unit_states[unit_id] = data
		print("SAVE unit_id=", unit_id, " hp=", stats.hp)

func load_persistent_stats() -> void:
	if is_player_unit:
		stats.max_hp = PlayerData.max_hp
		stats.hp = PlayerData.hp
		stats.attack = PlayerData.attack
		stats.defense = PlayerData.defense
		stats.speed = PlayerData.speed

		if map_id != "" and PlayerData.current_map_id != "" and PlayerData.current_map_id == map_id:
			global_position = ground_layer.to_global(ground_layer.map_to_local(PlayerData.current_tile))
			target_position = global_position

		return

	if unit_id != "" and WorldState.unit_states.has(unit_id):
		print("LOAD unit_id=", unit_id, " hp=", WorldState.unit_states[unit_id]["hp"])
		apply_stats_data(WorldState.unit_states[unit_id])

func apply_enemy_data(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		return

	name = enemy_data.enemy_name

	stats.max_hp = enemy_data.max_hp
	stats.hp = enemy_data.max_hp
	stats.attack = enemy_data.attack
	stats.defense = enemy_data.defense
	stats.speed = enemy_data.speed

	if has_node("Sprite2D"):
		$Sprite2D.texture = enemy_data.sprite_texture

func handle_death() -> void:
	if is_player_unit:
		print("プレイヤー死亡")
		return

	if unit_id != "":
		var data = get_stats_data()
		data["is_dead"] = true
		WorldState.unit_states[unit_id] = data

	queue_free()

func apply_npc_data(npc_data: NpcData) -> void:
	if npc_data == null:
		return

	name = npc_data.npc_name

	stats.max_hp = npc_data.max_hp
	stats.hp = npc_data.max_hp
	stats.attack = npc_data.attack
	stats.defense = npc_data.defense
	stats.speed = npc_data.speed

	if has_node("Sprite2D"):
		$Sprite2D.texture = npc_data.sprite_texture
