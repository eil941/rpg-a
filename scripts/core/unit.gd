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

@onready var inventory: Inventory = $Inventory

var is_moving: bool = false
var target_position: Vector2
var repeat_timer: float = 0.0
var is_transitioning: bool = false

var enemy_data_to_apply: EnemyData = null
var npc_data_to_apply: NpcData = null

var map_root: Node = null
var ground_layer: TileMapLayer = null
var wall_layer: TileMapLayer = null
var event_layer: TileMapLayer = null
var units_node: Node = null

@onready var stats = $Stats
@onready var controller = $Controller
@onready var targeting = Targeting
@onready var combat_manager = CombatManager


func _ready() -> void:
	print("UNIT READY name=", name)
	print("UNIT scene_file_path=", scene_file_path)
	print("UNIT has Inventory =", has_node("Inventory"))
	print("UNIT children = ", get_children().map(func(c): return c.name))
	
	resolve_map_references()

	if ground_layer == null:
		push_error("Unit: ground_layer の取得に失敗")
		return

	sync_map_id_from_scene()

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
		if not PlayerData.map_positions.has(map_id):
			global_position = ground_layer.to_global(ground_layer.map_to_local(GlobalPlayerSpawn.next_tile))
			target_position = global_position
		GlobalPlayerSpawn.has_next_tile = false

	is_transitioning = false
	is_moving = false
	repeat_timer = 0.0
	target_position = global_position

	if is_player_unit:
		print("READY map_id =", map_id)
		print("READY has_next_tile =", GlobalPlayerSpawn.has_next_tile)
		print("READY next_tile =", GlobalPlayerSpawn.next_tile)
		print("READY saved_positions =", PlayerData.map_positions)
		print("READY units_node =", units_node)
		print("READY map_root =", map_root)
		print("READY controller =", controller)

	TimeManager.is_resolving_turn = false
	
	if is_player_unit and inventory != null:
		if PlayerData.inventory_data.is_empty():
			inventory.add_item("potion", 6)
			inventory.add_item("wood", 5)
			inventory.add_item("apple", 2)


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
				TimeManager.notify_unit_move_finished(units_node)

			if is_player_unit:
				if try_auto_use_dungeon_stairs_on_touch():
					return
			return 

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

	var next_tile_data = get_tile_data_at_coords(next_tile)
	if next_tile_data != null:
		var next_scene_transfer = next_tile_data.get_custom_data("scene_transfer")
		if not can_trigger_scene_transition and next_scene_transfer == true:
			return false

	var target_unit = targeting.get_unit_on_tile(units_node, next_tile, self)

	if target_unit != null:
		if combat_manager.try_bump_attack(self, target_unit):
			return true
		return false

	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = Transform2D(0, next_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query)
	if not result.is_empty():
		print("TRY MOVE collision_result=", result)

	if result.is_empty():
		if instant_move:
			global_position = next_pos
			target_position = next_pos
			is_moving = false

			if units_node != null:
				TimeManager.notify_unit_move_finished(units_node)

			# 触れた瞬間に階段移動
			if is_player_unit:
				if try_auto_use_dungeon_stairs_on_touch():
					return true
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

		var spawn_x_data = tile_data.get_custom_data("spawn_x")
		var spawn_y_data = tile_data.get_custom_data("spawn_y")

		var current_tile = get_current_tile_coords()

		if next_scene != "":
			# ダンジョン遷移は先に専用処理
			if next_scene == "res://scenes/dungeon_main.tscn":
				var dungeon_id = ""

				if map_root != null and map_root.has_method("get_dungeon_id_at_cell"):
					dungeon_id = map_root.get_dungeon_id_at_cell(next_tile)

				print("DUNGEON TRANSFER next_tile = ", next_tile)
				print("DUNGEON TRANSFER dungeon_id = ", dungeon_id)

				if dungeon_id == "":
					push_error("Dungeon transfer failed: dungeon_id is empty")
					return false

				GlobalDungeon.current_dungeon_id = dungeon_id
				GlobalDungeon.current_floor = 1
				GlobalDungeon.return_field_map_id = map_id
				GlobalDungeon.return_field_cell = next_tile

				if is_player_unit:
					PlayerData.last_map_id = map_id
					PlayerData.last_tile = current_tile

				if map_root != null and map_root.has_method("save_all_units"):
					map_root.save_all_units()

				is_transitioning = true
				GlobalPlayerSpawn.has_next_tile = false
				notify_hud_log(next_scene + "へ移動")
				request_map_change(next_scene)
				return true

			# それ以外は従来の詳細マップ遷移
			if spawn_x_data == null or spawn_y_data == null:
				return false

			var spawn_x = int(spawn_x_data)
			var spawn_y = int(spawn_y_data)

			var field_tile = current_tile
			var detail_map_key = "field_%d_%d" % [field_tile.x, field_tile.y]

			var generator_type = tile_data.get_custom_data("detail_generator")
			if generator_type == null:
				generator_type = "plain"

			var return_to_field_map: bool = next_scene == "res://scenes/field_map.tscn"

			if return_to_field_map:
				spawn_x = GlobalDetailMap.from_field_tile.x
				spawn_y = GlobalDetailMap.from_field_tile.y
			else:
				GlobalDetailMap.current_detail_map_key = detail_map_key
				GlobalDetailMap.current_generator_type = String(generator_type)
				GlobalDetailMap.from_field_tile = field_tile

				if not WorldState.field_detail_map_data.has(detail_map_key):
					WorldState.field_detail_map_data[detail_map_key] = create_detail_map_config(
						String(generator_type),
						field_tile
					)

				print("DETAIL MAP KEY =", detail_map_key)
				print("DETAIL GENERATOR =", generator_type)

			if is_player_unit:
				PlayerData.last_map_id = map_id
				PlayerData.last_tile = current_tile

			if map_root != null and map_root.has_method("save_all_units"):
				map_root.save_all_units()

			is_transitioning = true
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)
			notify_hud_log(next_scene + "へ移動")
			request_map_change(next_scene)
			return true

	return false

func try_interact_transition() -> void:
	if not can_trigger_scene_transition:
		return

	# 先にダンジョン階段処理を試す
	# ここで処理できたら、その後の TileData 読み取りには進まない
	if map_root != null and map_root.has_method("try_use_dungeon_stairs_from_player_position"):
		if map_root.try_use_dungeon_stairs_from_player_position():
			print("STAIRS TRANSITION HANDLED")
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

	var current_tile = get_current_tile_coords()

	# ダンジョン遷移は先に専用処理
	if next_scene == "res://scenes/dungeon_main.tscn":
		var dungeon_id = ""

		if map_root != null and map_root.has_method("get_dungeon_id_at_cell"):
			dungeon_id = map_root.get_dungeon_id_at_cell(current_tile)

		print("INTERACT DUNGEON TRANSFER current_tile = ", current_tile)
		print("INTERACT DUNGEON TRANSFER dungeon_id = ", dungeon_id)

		if dungeon_id == "":
			push_error("Dungeon interact transfer failed: dungeon_id is empty")
			return

		GlobalDungeon.current_dungeon_id = dungeon_id
		GlobalDungeon.current_floor = 1
		GlobalDungeon.return_field_map_id = map_id
		GlobalDungeon.return_field_cell = current_tile
		GlobalDungeon.pending_spawn_stair_type = "RETURN"

		if is_player_unit:
			PlayerData.last_map_id = map_id
			PlayerData.last_tile = current_tile

		if map_root != null and map_root.has_method("save_all_units"):
			map_root.save_all_units()

		is_transitioning = true
		GlobalPlayerSpawn.has_next_tile = false
		notify_hud_log(next_scene + "へ移動")
		request_map_change(next_scene)
		return

	var spawn_x_data = tile_data.get_custom_data("spawn_x")
	var spawn_y_data = tile_data.get_custom_data("spawn_y")

	if spawn_x_data == null or spawn_y_data == null:
		push_error("spawn_x or spawn_y is missing on event tile")
		return

	var spawn_x = int(spawn_x_data)
	var spawn_y = int(spawn_y_data)

	var field_tile = current_tile
	var detail_map_key = "field_%d_%d" % [field_tile.x, field_tile.y]

	var generator_type = tile_data.get_custom_data("detail_generator")
	if generator_type == null:
		generator_type = "plain"

	var return_to_field_map: bool = next_scene == "res://scenes/field_map.tscn"

	if return_to_field_map:
		spawn_x = GlobalDetailMap.from_field_tile.x
		spawn_y = GlobalDetailMap.from_field_tile.y
	else:
		GlobalDetailMap.current_detail_map_key = detail_map_key
		GlobalDetailMap.current_generator_type = String(generator_type)
		GlobalDetailMap.from_field_tile = field_tile

		if not WorldState.field_detail_map_data.has(detail_map_key):
			WorldState.field_detail_map_data[detail_map_key] = create_detail_map_config(
				String(generator_type),
				field_tile
			)

		print("DETAIL MAP KEY =", detail_map_key)
		print("DETAIL GENERATOR =", generator_type)

	if is_player_unit:
		PlayerData.last_map_id = map_id
		PlayerData.last_tile = current_tile

	if map_root != null and map_root.has_method("save_all_units"):
		map_root.save_all_units()

	print("INTERACT TRANSFER next_scene=", next_scene)
	print("INTERACT TRANSFER spawn_x=", spawn_x, " spawn_y=", spawn_y)
	print("INTERACT TRANSFER set next_tile=", Vector2i(spawn_x, spawn_y))

	is_transitioning = true
	GlobalPlayerSpawn.has_next_tile = true
	GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)

	notify_hud_log(next_scene + "へ移動")
	request_map_change(next_scene)

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
		"tile_y": get_current_tile_coords().y,
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
		
		PlayerData.inventory_data = inventory.save_inventory_data()
		
		print("PLAYER SAVE map_id=", map_id)
		print("PLAYER SAVE global_position=", global_position)
		print("PLAYER SAVE local position=", position)
		print("PLAYER SAVE current_tile=", get_current_tile_coords())

		if map_id != "":
			PlayerData.map_positions[map_id] = get_current_tile_coords()
			print("PLAYER SAVE map_positions=", PlayerData.map_positions)
		else:
			print("PLAYER SAVE FAILED: map_id is empty")

		return

	if unit_id != "":
		var data = get_stats_data()
		data["is_dead"] = stats.hp <= 0
		WorldState.unit_states[unit_id] = data
		print("SAVE unit_id=", unit_id, " hp=", stats.hp)


func load_persistent_stats() -> void:
	if is_player_unit:
		print("PLAYER LOAD map_id=", map_id)
		print("PLAYER LOAD map_positions=", PlayerData.map_positions)

		stats.max_hp = PlayerData.max_hp
		stats.hp = PlayerData.hp
		stats.attack = PlayerData.attack
		stats.defense = PlayerData.defense
		stats.speed = PlayerData.speed
		
		if inventory != null:
			inventory.load_inventory_data(PlayerData.inventory_data)
		
		if map_id != "" and PlayerData.map_positions.has(map_id):
			var saved_tile: Vector2i = PlayerData.map_positions[map_id]
			print("PLAYER RESTORE tile=", saved_tile)
			global_position = ground_layer.to_global(ground_layer.map_to_local(saved_tile))
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


func sync_map_id_from_scene() -> void:
	if map_root != null:
		var scene_map_id = map_root.get("map_id")
		if scene_map_id != null and String(scene_map_id) != "":
			map_id = String(scene_map_id)
			return

	if GlobalDetailMap.current_detail_map_key != "":
		map_id = GlobalDetailMap.current_detail_map_key


func create_detail_map_config(generator_type: String, field_tile: Vector2i) -> Dictionary:
	generator_type = generator_type.strip_edges().replace("\"", "").to_upper()

	print("CONFIG generator_type normalized = ", generator_type)

	var config = {
		"generator_type": String(generator_type),
		"field_x": field_tile.x,
		"field_y": field_tile.y,
		"enemy_spawn_count": 5,
		"npc_spawn_count": 3,
		"enemy_type_ids": ["bat", "slime"],
		"npc_type_ids": ["villager"]
	}

	match generator_type:
		"GRASS":
			config["enemy_spawn_count"] = 5
			config["npc_spawn_count"] = 3
			config["enemy_type_ids"] = ["bat", "slime"]
			config["npc_type_ids"] = ["sabo"]

		"FOREST":
			config["enemy_spawn_count"] = 8
			config["npc_spawn_count"] = 1
			config["enemy_type_ids"] = ["bat", "orc"]
			config["npc_type_ids"] = ["npc-1"]

		"SAND":
			config["enemy_spawn_count"] = 4
			config["npc_spawn_count"] = 0
			config["enemy_type_ids"] = ["slime"]
			config["npc_type_ids"] = []

		"SEA":
			config["enemy_spawn_count"] = 6
			config["npc_spawn_count"] = 0
			config["enemy_type_ids"] = ["bat"]
			config["npc_type_ids"] = []

		"BEACH":
			config["enemy_spawn_count"] = 3
			config["npc_spawn_count"] = 2
			config["enemy_type_ids"] = ["slime"]
			config["npc_type_ids"] = ["sabo"]

	print("CONFIG result = ", config)
	return config


func resolve_map_references() -> void:
	var node: Node = self

	while node != null:
		if node.has_node("GroundLayer") and node.has_node("WallLayer") and node.has_node("EventLayer"):
			map_root = node
			break
		node = node.get_parent()

	if map_root == null:
		push_error("Unit: map_root が見つかりません")
		return

	ground_layer = map_root.get_node("GroundLayer") as TileMapLayer
	wall_layer = map_root.get_node("WallLayer") as TileMapLayer
	event_layer = map_root.get_node("EventLayer") as TileMapLayer
	units_node = map_root.get_node_or_null("Units")


func request_map_change(next_scene: String) -> bool:
	var node: Node = self

	while node != null:
		print("REQUEST MAP CHECK:", node.name, " script=", node.get_script())
		if node.has_method("load_map_by_path"):
			print("REQUEST MAP FOUND:", node.name, " next_scene=", next_scene)
			node.load_map_by_path(next_scene)
			print("REQUEST MAP CALLED")
			return true
		node = node.get_parent()

	push_error("Unit: load_map_by_path を持つ親が見つかりません")
	return false


func notify_hud_log(text: String) -> void:
	var node: Node = self

	while node != null:
		if node.has_method("add_hud_log"):
			node.add_hud_log(text)
			return
		node = node.get_parent()


func notify_hud_player_status_refresh() -> void:
	var node: Node = self

	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()
			return
		node = node.get_parent()

func try_auto_use_dungeon_stairs_on_touch() -> bool:
	if map_root == null:
		return false

	if not map_root.has_method("try_use_dungeon_stairs_from_player_position"):
		return false

	return map_root.try_use_dungeon_stairs_from_player_position()


func reset_after_map_transition() -> void:
	is_transitioning = false
	is_moving = false
	repeat_timer = 0.0
	velocity = Vector2.ZERO
	target_position = global_position

	if has_node("Controller"):
		var c = $Controller
		if c != null and c.has_method("reset_input_state"):
			c.reset_input_state()

	TimeManager.is_resolving_turn = false
	
