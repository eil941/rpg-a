extends Node2D

@onready var player = $Units/Unit

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var event_layer: TileMapLayer = $EventLayer
@onready var units_node: Node = $Units

@export var MAP_WIDTH: int = 200
@export var MAP_HEIGHT: int = 200
@export var map_id: String = ""
@export var world_seed: int = 123456

@export var min_area_difficulty: int = 1
@export var max_area_difficulty: int = 5

@export_group("Tile Visual Settings")
@export var ground_tile_set_override: TileSet
@export var wall_tile_set_override: TileSet
@export var event_tile_set_override: TileSet
@export var field_tile_visual_config: MapTileVisualConfig
@export var force_regenerate_map_tiles_on_ready: bool = false

@export_group("Dungeon Entrance Settings")
@export var dungeon_tile_visual_config: DungeonTileVisualConfig
@export_range(0, 1000, 1) var dungeon_entrance_count: int = 300
@export var natural_dungeon_weight: int = 40
@export var fortified_dungeon_weight: int = 15
@export var ruined_dungeon_weight: int = 25
@export var artificial_dungeon_weight: int = 10
@export var chaotic_dungeon_weight: int = 10
@export var min_dungeon_floor_count: int = 3
@export var max_dungeon_floor_count: int = 6
@export var min_dungeon_difficulty: int = 1
@export var max_dungeon_difficulty: int = 100


const FLOOR_SOURCE_ID: int = 1
const WALL_SOURCE_ID: int = 0
const HIGHROCK_SOURCE_ID: int = 5

const FLOOR_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const WALL_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const HIGHROCK_ATLAS_COORDS: Vector2i = Vector2i(0, 0)


const SPECIAL_PLACE_TILE_MAP: Dictionary = {
	"special_map_1": {"source_id": 11, "atlas_coords": Vector2i(1, 0)},
}

var map_generator: PlainMapGenerator
var dungeon_entrance_generator: FieldDungeonEntranceGenerator
var special_place_generator: FieldSpecialPlaceGenerator


func _ready() -> void:
	print("FIELDMAP READY START")

	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("FiledMap: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	_apply_tile_set_overrides()

	player.map_id = map_id

	if not WorldState.field_dungeon_entrances.has(map_id):
		WorldState.field_dungeon_entrances[map_id] = []

	if not WorldState.field_special_places.has(map_id):
		WorldState.field_special_places[map_id] = []

	if force_regenerate_map_tiles_on_ready and map_id != "":
		WorldState.map_tile_data.erase(map_id)

	if WorldState.map_tile_data.has(map_id):
		load_map_tiles()
		_redraw_dungeon_entrances_from_state()
	else:
		map_generator = PlainMapGenerator.new(
			MAP_WIDTH,
			MAP_HEIGHT,
			FLOOR_SOURCE_ID,
			WALL_SOURCE_ID,
			FLOOR_ATLAS_COORDS,
			WALL_ATLAS_COORDS,
			world_seed,
			field_tile_visual_config
		)
		map_generator.generate_map(ground_layer, wall_layer, event_layer)

		dungeon_entrance_generator = FieldDungeonEntranceGenerator.new(
			MAP_WIDTH,
			MAP_HEIGHT,
			dungeon_tile_visual_config,
			_build_dungeon_theme_weights(),
			min_dungeon_floor_count,
			max_dungeon_floor_count,
			min_dungeon_difficulty,
			max_dungeon_difficulty
		)
		var entrances: Array = dungeon_entrance_generator.generate_map(
			map_id,
			ground_layer,
			wall_layer,
			event_layer,
			dungeon_entrance_count
		)
		WorldState.field_dungeon_entrances[map_id] = entrances

		special_place_generator = FieldSpecialPlaceGenerator.new(
			MAP_WIDTH,
			MAP_HEIGHT,
			map_generator.biome_result,
			map_generator.terrain_result,
			world_seed + 1000
		)

		var special_places: Array = special_place_generator.generate_all_places()
		special_places = assign_difficulty_to_special_places(special_places)
		WorldState.field_special_places[map_id] = special_places

		print("[DEBUG][FiledMap] generated special_places = ", special_places)

		apply_special_places_to_event_layer(special_places)

		save_map_tiles()

	_ensure_special_place_difficulties()

	if WorldState.field_special_places.has(map_id):
		print("[DEBUG][FiledMap] final field_special_places[map_id] = ", WorldState.field_special_places[map_id])
		apply_special_places_to_event_layer(WorldState.field_special_places[map_id])

	_resolve_pending_unique_map_return_if_needed()

	print("FIELDMAP READY END")



func _non_negative_weight(value: int) -> int:
	if value < 0:
		return 0
	return value


func _build_dungeon_theme_weights() -> Dictionary:
	return {
		"NATURAL": _non_negative_weight(natural_dungeon_weight),
		"FORTIFIED": _non_negative_weight(fortified_dungeon_weight),
		"RUINED": _non_negative_weight(ruined_dungeon_weight),
		"ARTIFICIAL": _non_negative_weight(artificial_dungeon_weight),
		"CHAOTIC": _non_negative_weight(chaotic_dungeon_weight)
	}


func _get_dungeon_field_visual(generator_theme: String) -> Dictionary:
	var fallback: Dictionary = {
		"source_id": 4,
		"atlas_coords": Vector2i(0, 0),
		"alternative_tile": 0
	}

	if dungeon_tile_visual_config == null:
		return fallback

	if not dungeon_tile_visual_config.has_method("get_tile"):
		return fallback

	var theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()
	var visual: Dictionary = dungeon_tile_visual_config.get_tile(theme, "FIELD")
	return visual


func _redraw_dungeon_entrances_from_state() -> void:
	if not WorldState.field_dungeon_entrances.has(map_id):
		return

	var entrances: Array = WorldState.field_dungeon_entrances[map_id]

	for entrance in entrances:
		var cell: Vector2i = Vector2i(int(entrance.get("x", 0)), int(entrance.get("y", 0)))
		var dungeon_id: String = String(entrance.get("dungeon_id", ""))
		var generator_theme: String = String(entrance.get("generator_theme", "NATURAL"))

		if dungeon_id != "" and WorldState.dungeon_data.has(dungeon_id):
			var dungeon_info: Dictionary = WorldState.dungeon_data[dungeon_id]
			generator_theme = String(dungeon_info.get("generator_theme", generator_theme))

		var visual: Dictionary = _get_dungeon_field_visual(generator_theme)
		var source_id: int = int(visual.get("source_id", 4))
		var atlas_coords: Vector2i = visual.get("atlas_coords", Vector2i(0, 0))
		var alternative_tile: int = int(visual.get("alternative_tile", 0))

		event_layer.set_cell(cell, source_id, atlas_coords, alternative_tile)


func _apply_tile_set_overrides() -> void:
	if ground_tile_set_override != null:
		ground_layer.tile_set = ground_tile_set_override
	if wall_tile_set_override != null:
		wall_layer.tile_set = wall_tile_set_override
	if event_tile_set_override != null:
		event_layer.tile_set = event_tile_set_override


func _roll_area_difficulty() -> int:
	if max_area_difficulty < min_area_difficulty:
		return min_area_difficulty
	return randi_range(min_area_difficulty, max_area_difficulty)


func _is_safe_special_place(place_id: String) -> bool:
	return place_id.begins_with("start_") \
		or place_id.begins_with("town_") \
		or place_id.begins_with("village_") \
		or place_id.begins_with("castle_")


func assign_difficulty_to_special_places(places: Array) -> Array:
	var result: Array = []

	for place in places:
		var entry: Dictionary = place.duplicate(true)
		var place_id: String = str(entry.get("place_id", ""))

		if not entry.has("difficulty"):
			if _is_safe_special_place(place_id):
				entry["difficulty"] = 0
			else:
				entry["difficulty"] = _roll_area_difficulty()

		print("[DEBUG][FiledMap] assign difficulty place_id=", place_id, " difficulty=", entry.get("difficulty", -999))

		result.append(entry)

	return result


func _ensure_special_place_difficulties() -> void:
	if not WorldState.field_special_places.has(map_id):
		print("[DEBUG][FiledMap] no field_special_places for map_id=", map_id)
		return

	var original_places: Array = WorldState.field_special_places[map_id]
	print("[DEBUG][FiledMap] original field_special_places before ensure = ", original_places)

	var updated_places: Array = assign_difficulty_to_special_places(original_places)
	WorldState.field_special_places[map_id] = updated_places

	print("[DEBUG][FiledMap] updated field_special_places after ensure = ", WorldState.field_special_places[map_id])


func _build_detail_map_key(cell: Vector2i) -> String:
	return "field_%d_%d" % [cell.x, cell.y]


func _build_unique_detail_map_key(unique_map_id: String, cell: Vector2i) -> String:
	if WorldState.has_method("make_unique_detail_map_id"):
		return WorldState.make_unique_detail_map_id(unique_map_id, cell)

	var safe_id: String = unique_map_id.strip_edges().to_lower()
	safe_id = safe_id.replace(" ", "_")
	safe_id = safe_id.replace("-", "_")
	safe_id = safe_id.replace("/", "_")
	if safe_id == "":
		safe_id = "unknown"

	return "unique_%s_field_%d_%d" % [safe_id, cell.x, cell.y]


func _request_map_change(scene_path: String) -> bool:
	var node: Node = self

	while node != null:
		if node.has_method("load_map_by_path"):
			node.load_map_by_path(scene_path)
			return true
		node = node.get_parent()

	var error: Error = get_tree().change_scene_to_file(scene_path)
	return error == OK


func _resolve_pending_unique_map_return_if_needed() -> void:
	if not ("pending_resolve_return_from_unique_map" in GlobalDetailMap):
		return

	if not GlobalDetailMap.pending_resolve_return_from_unique_map:
		return

	print("[DEBUG][FiledMap] resolve pending unique map return")	
	print("[DEBUG][FiledMap] pending unique_map_id = ", GlobalDetailMap.pending_return_unique_map_id)
	print("[DEBUG][FiledMap] pending scene_path = ", GlobalDetailMap.pending_return_unique_scene_path)

	var place: Dictionary = _find_special_place_for_pending_unique_map_return()
	if place.is_empty():
		push_warning("[FiledMap] pending unique map return を解決できませんでした")
		return

	var return_cell: Vector2i = Vector2i(
		int(place.get("x", 0)),
		int(place.get("y", 0))
	)

	GlobalDetailMap.from_field_tile = return_cell
	if GlobalDetailMap.has_method("clear_pending_unique_map_return"):
		GlobalDetailMap.clear_pending_unique_map_return()

	_place_player_on_field_tile(return_cell)

	print("[DEBUG][FiledMap] resolved unique map return tile = ", return_cell)


func _find_special_place_for_pending_unique_map_return() -> Dictionary:
	if not WorldState.field_special_places.has(map_id):
		return {}

	var pending_unique_map_id: String = String(GlobalDetailMap.pending_return_unique_map_id).strip_edges()
	var pending_scene_path: String = String(GlobalDetailMap.pending_return_unique_scene_path).strip_edges()
	var places: Array = WorldState.field_special_places[map_id]

	# 1. unique_map_id 優先。
	for raw_place in places:
		if typeof(raw_place) != TYPE_DICTIONARY:
			continue

		var place: Dictionary = raw_place
		var place_unique_map_id: String = String(place.get("unique_map_id", "")).strip_edges()
		if place_unique_map_id == "":
			place_unique_map_id = String(place.get("place_id", "")).strip_edges()

		if pending_unique_map_id != "" and place_unique_map_id == pending_unique_map_id:
			return place

	# 2. TileSet custom data の enter_scene で逆引き。
	for raw_place in places:
		if typeof(raw_place) != TYPE_DICTIONARY:
			continue

		var place: Dictionary = raw_place
		var cell: Vector2i = Vector2i(
			int(place.get("x", 0)),
			int(place.get("y", 0))
		)

		var enter_scene_from_tile: String = _get_event_tile_enter_scene_at_cell(cell)
		if pending_scene_path != "" and enter_scene_from_tile == pending_scene_path:
			return place

		# 互換用。基本はTileSet custom dataを使う。
		var enter_scene_from_place: String = String(place.get("enter_scene", "")).strip_edges()
		if pending_scene_path != "" and enter_scene_from_place == pending_scene_path:
			return place

		var scene_path_from_place: String = String(place.get("scene_path", "")).strip_edges()
		if pending_scene_path != "" and scene_path_from_place == pending_scene_path:
			return place

	return {}


func _get_event_tile_enter_scene_at_cell(cell: Vector2i) -> String:
	var tile_data: TileData = event_layer.get_cell_tile_data(cell)
	if tile_data == null:
		return ""

	var raw_enter_scene: Variant = tile_data.get_custom_data("enter_scene")
	if raw_enter_scene == null:
		return ""

	return String(raw_enter_scene).strip_edges()


func _get_event_tile_spawn_tile_at_cell(cell: Vector2i, fallback: Vector2i) -> Vector2i:
	var tile_data: TileData = event_layer.get_cell_tile_data(cell)
	if tile_data == null:
		return fallback

	var spawn_x_data: Variant = tile_data.get_custom_data("spawn_x")
	var spawn_y_data: Variant = tile_data.get_custom_data("spawn_y")

	if spawn_x_data == null or spawn_y_data == null:
		return fallback

	return Vector2i(int(spawn_x_data), int(spawn_y_data))


func _place_player_on_field_tile(cell: Vector2i) -> void:
	if player == null:
		return

	var target_pos: Vector2 = ground_layer.to_global(
		ground_layer.map_to_local(cell)
	)

	player.global_position = target_pos
	player.target_position = target_pos
	player.start_tile = cell
	player.is_moving = false
	player.is_transitioning = false

	PlayerData.map_positions[map_id] = cell
	GlobalPlayerSpawn.has_next_tile = false
	GlobalPlayerSpawn.next_tile = cell

	print("[DEBUG][FiledMap] player placed on field tile = ", cell)


func _get_special_place_generator_type(place: Dictionary) -> String:
	var generator_type: String = str(place.get("detail_generator", ""))
	if generator_type == "":
		generator_type = str(place.get("generator_type", ""))
	return generator_type.strip_edges().replace("\"", "").to_upper()


func generate_map() -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell: Vector2i = Vector2i(x, y)

			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				wall_layer.set_cell(cell, HIGHROCK_SOURCE_ID, HIGHROCK_ATLAS_COORDS, 0)


func get_dungeon_id_at_cell(cell: Vector2i) -> String:
	if not WorldState.field_dungeon_entrances.has(map_id):
		return ""

	for entrance in WorldState.field_dungeon_entrances[map_id]:
		if entrance["x"] == cell.x and entrance["y"] == cell.y:
			return entrance["dungeon_id"]

	return ""


func get_special_place_at_cell(cell: Vector2i) -> Dictionary:
	if not WorldState.field_special_places.has(map_id):
		print("[DEBUG][FiledMap] get_special_place_at_cell: no field_special_places for map_id=", map_id)
		return {}

	for place in WorldState.field_special_places[map_id]:
		if place["x"] == cell.x and place["y"] == cell.y:
			print("[DEBUG][FiledMap] get_special_place_at_cell hit: ", place)
			return place

	print("[DEBUG][FiledMap] get_special_place_at_cell miss at cell=", cell)
	return {}


func get_special_place_difficulty_at_cell(cell: Vector2i) -> int:
	if not WorldState.field_special_places.has(map_id):
		print("[DEBUG][FiledMap] get_special_place_difficulty_at_cell: no field_special_places for map_id=", map_id)
		return 0

	for place in WorldState.field_special_places[map_id]:
		if place["x"] == cell.x and place["y"] == cell.y:
			var difficulty: int = int(place.get("difficulty", 0))
			print("[DEBUG][FiledMap] get_special_place_difficulty_at_cell hit cell=", cell, " difficulty=", difficulty, " place=", place)
			return difficulty

	print("[DEBUG][FiledMap] get_special_place_difficulty_at_cell miss at cell=", cell)
	return 0


func try_enter_dungeon_from_player_position() -> bool:
	var current_cell: Vector2i = ground_layer.local_to_map(
		ground_layer.to_local(player.global_position)
	)

	var dungeon_id: String = get_dungeon_id_at_cell(current_cell)
	if dungeon_id == "":
		return false

	print("[DEBUG][FiledMap] enter dungeon current_cell=", current_cell, " dungeon_id=", dungeon_id)

	GlobalDungeon.current_dungeon_id = dungeon_id
	GlobalDungeon.current_floor = 1
	GlobalDungeon.return_field_map_id = map_id
	GlobalDungeon.return_field_cell = current_cell
	GlobalDungeon.pending_spawn_stair_type = "RETURN"

	get_tree().change_scene_to_file("res://scenes/dungeon_main.tscn")
	return true


func try_enter_special_place_from_player_position() -> bool:
	print("[DEBUG][FiledMap] try_enter_special_place_from_player_position called")

	var current_cell: Vector2i = ground_layer.local_to_map(
		ground_layer.to_local(player.global_position)
	)

	print("[DEBUG][FiledMap] current_cell = ", current_cell)

	var place: Dictionary = get_special_place_at_cell(current_cell)
	print("[DEBUG][FiledMap] place = ", place)

	if place.is_empty():
		print("[DEBUG][FiledMap] place is empty -> return false")
		return false

	var tile_data: TileData = event_layer.get_cell_tile_data(current_cell)
	if tile_data == null:
		print("[DEBUG][FiledMap] tile_data is null -> return false")
		return false

	var can_enter_data: Variant = tile_data.get_custom_data("can_enter")
	if not (can_enter_data is bool and bool(can_enter_data)):
		print("[DEBUG][FiledMap] can_enter is false -> return false")
		return false

	# 移動先はTileSet custom dataを最優先する。
	# FieldMap側は unique_map_id だけを持ち、二重設定を避ける。
	var enter_scene: String = _get_event_tile_enter_scene_at_cell(current_cell)
	if enter_scene == "":
		# 互換用。基本はTileSet custom dataを使う。
		enter_scene = String(place.get("enter_scene", "")).strip_edges()
	if enter_scene == "":
		enter_scene = String(place.get("scene_path", "")).strip_edges()

	print("[DEBUG][FiledMap] enter_scene = ", enter_scene)

	if enter_scene == "":
		print("[DEBUG][FiledMap] enter_scene is empty -> return false")
		return false

	var entry_spawn_tile: Vector2i = _get_event_tile_spawn_tile_at_cell(current_cell, Vector2i(5, 8))

	var unique_map_id: String = String(place.get("unique_map_id", "")).strip_edges()
	if unique_map_id == "":
		unique_map_id = String(place.get("place_id", "")).strip_edges()
	if unique_map_id == "":
		unique_map_id = "unknown_unique_map"

	var place_for_instance: Dictionary = place.duplicate(true)
	place_for_instance["unique_map_id"] = unique_map_id
	place_for_instance["enter_scene"] = enter_scene
	place_for_instance["scene_path"] = enter_scene
	place_for_instance["entry_spawn_tile"] = entry_spawn_tile
	place_for_instance["return_spawn_tile"] = current_cell
	place_for_instance["return_scene_path"] = "res://scenes/field_map.tscn"

	var instance: Dictionary = {}
	if WorldState.has_method("ensure_unique_map_instance"):
		instance = WorldState.ensure_unique_map_instance(map_id, current_cell, place_for_instance)
	else:
		instance = {
			"instance_id": "field_%d_%d_%s" % [current_cell.x, current_cell.y, unique_map_id],
			"unique_map_id": unique_map_id,
			"scene_path": enter_scene,
			"enter_scene": enter_scene,
			"map_id": _build_unique_detail_map_key(unique_map_id, current_cell),
			"return_field_map_id": map_id,
			"return_scene_path": "res://scenes/field_map.tscn",
			"return_field_tile": current_cell,
			"return_spawn_tile": current_cell,
			"entry_spawn_tile": entry_spawn_tile,
			"area_difficulty": int(place.get("difficulty", 0)),
			"place_type": String(place.get("type", "")),
			"place_id": String(place.get("place_id", ""))
		}

	if instance.is_empty():
		print("[DEBUG][FiledMap] unique map instance is empty -> return false")
		return false

	var detail_map_key: String = String(instance.get("map_id", "")).strip_edges()
	if detail_map_key == "":
		detail_map_key = _build_unique_detail_map_key(unique_map_id, current_cell)

	var place_difficulty: int = int(instance.get("area_difficulty", get_special_place_difficulty_at_cell(current_cell)))

	var generator_type: String = _get_special_place_generator_type(place)
	if generator_type == "":
		generator_type = "SPECIAL"

	print("[DEBUG][FiledMap] unique instance = ", instance)
	print("[DEBUG][FiledMap] detail_map_key = ", detail_map_key)
	print("[DEBUG][FiledMap] generator_type = ", generator_type)
	print("[DEBUG][FiledMap] place_difficulty = ", place_difficulty)
	print("[DEBUG][FiledMap] entry_spawn_tile = ", entry_spawn_tile)

	GlobalDetailMap.current_detail_map_key = detail_map_key
	GlobalDetailMap.current_generator_type = generator_type
	GlobalDetailMap.from_field_tile = current_cell
	GlobalDetailMap.current_area_difficulty = place_difficulty

	GlobalDetailMap.current_unique_map_instance_id = String(instance.get("instance_id", ""))
	GlobalDetailMap.current_unique_map_id = String(instance.get("unique_map_id", ""))
	GlobalDetailMap.current_return_scene_path = String(instance.get("return_scene_path", "res://scenes/field_map.tscn"))
	GlobalDetailMap.current_return_field_map_id = String(instance.get("return_field_map_id", map_id))

	if not WorldState.field_detail_map_data.has(detail_map_key):
		WorldState.field_detail_map_data[detail_map_key] = {
			"generator_type": generator_type,
			"area_difficulty": place_difficulty,
			"is_unique_map_instance": true,
			"unique_map_instance_id": String(instance.get("instance_id", "")),
			"unique_map_id": String(instance.get("unique_map_id", "")),
			"return_field_tile": current_cell
		}

	if player != null:
		PlayerData.last_map_id = map_id
		PlayerData.last_tile = current_cell
		player.is_transitioning = true

	save_all_units()

	GlobalPlayerSpawn.has_next_tile = true
	GlobalPlayerSpawn.next_tile = entry_spawn_tile

	print("[DEBUG][FiledMap] GlobalDetailMap.current_detail_map_key = ", GlobalDetailMap.current_detail_map_key)
	print("[DEBUG][FiledMap] GlobalDetailMap.from_field_tile = ", GlobalDetailMap.from_field_tile)
	print("[DEBUG][FiledMap] GlobalPlayerSpawn.next_tile = ", GlobalPlayerSpawn.next_tile)

	return _request_map_change(enter_scene)


func apply_special_places_to_event_layer(places: Array) -> void:
	for raw_place in places:
		if typeof(raw_place) != TYPE_DICTIONARY:
			continue

		var place: Dictionary = raw_place
		if not place.has("x") or not place.has("y"):
			continue

		var cell: Vector2i = Vector2i(int(place["x"]), int(place["y"]))
		var place_id: String = String(place.get("place_id", ""))

		if not SPECIAL_PLACE_TILE_MAP.has(place_id):
			print("[DEBUG][FiledMap] no visual tile for special place place_id=", place_id)
			continue

		var tile_info: Dictionary = SPECIAL_PLACE_TILE_MAP[place_id]
		var source_id: int = int(tile_info["source_id"])
		var atlas_coords: Vector2i = tile_info["atlas_coords"]

		# このタイルの移動先は、置かれたTileSet custom dataのenter_sceneを読む。
		# ここでは見た目タイルを置くだけ。
		event_layer.set_cell(cell, source_id, atlas_coords, 0)


func save_all_units() -> void:
	if not has_node("Units"):
		return

	for unit in $Units.get_children():
		if unit.has_method("save_persistent_stats"):
			unit.save_persistent_stats()


func save_layer_data(layer: TileMapLayer) -> Array:
	var result: Array = []
	var used_cells: Array = layer.get_used_cells()

	for cell in used_cells:
		var source_id: int = layer.get_cell_source_id(cell)
		if source_id == -1:
			continue

		var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
		var alternative: int = layer.get_cell_alternative_tile(cell)

		result.append({
			"x": cell.x,
			"y": cell.y,
			"source_id": source_id,
			"atlas_x": atlas_coords.x,
			"atlas_y": atlas_coords.y,
			"alternative": alternative
		})

	return result


func load_layer_data(layer: TileMapLayer, data: Array) -> void:
	layer.clear()

	for cell_data in data:
		var cell: Vector2i = Vector2i(cell_data["x"], cell_data["y"])
		var source_id: int = cell_data["source_id"]
		var atlas_coords: Vector2i = Vector2i(cell_data["atlas_x"], cell_data["atlas_y"])
		var alternative: int = cell_data["alternative"]

		layer.set_cell(cell, source_id, atlas_coords, alternative)


func save_map_tiles() -> void:
	WorldState.map_tile_data[map_id] = {
		"ground": save_layer_data(ground_layer),
		"wall": save_layer_data(wall_layer),
		"event": save_layer_data(event_layer)
	}


func load_map_tiles() -> void:
	if not WorldState.map_tile_data.has(map_id):
		return

	var data: Dictionary = WorldState.map_tile_data[map_id]

	load_layer_data(ground_layer, data.get("ground", []))
	load_layer_data(wall_layer, data.get("wall", []))
	load_layer_data(event_layer, data.get("event", []))
