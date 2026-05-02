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


const FLOOR_SOURCE_ID: int = 1
const WALL_SOURCE_ID: int = 0
const HIGHROCK_SOURCE_ID: int = 5

const FLOOR_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const WALL_ATLAS_COORDS: Vector2i = Vector2i(0, 0)
const HIGHROCK_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

@export var dungeon_entrance_count: int = 300

const SPECIAL_PLACE_TILE_MAP: Dictionary = {
	"start_1": {"source_id": 14, "atlas_coords": Vector2i(0, 0)},

	"town_1": {"source_id": 15, "atlas_coords": Vector2i(1, 0)},
	"town_2": {"source_id": 16, "atlas_coords": Vector2i(2, 0)},

	"village_1": {"source_id": 17, "atlas_coords": Vector2i(0, 1)},
	"village_2": {"source_id": 18, "atlas_coords": Vector2i(1, 1)},
	"village_3": {"source_id": 19, "atlas_coords": Vector2i(2, 1)},
	"village_4": {"source_id": 20, "atlas_coords": Vector2i(3, 1)},
	"village_5": {"source_id": 21, "atlas_coords": Vector2i(4, 1)},

	"castle_1": {"source_id": 22, "atlas_coords": Vector2i(0, 2)},
	"castle_2": {"source_id": 23, "atlas_coords": Vector2i(1, 2)},

	"unique_dungeon_1": {"source_id": 24, "atlas_coords": Vector2i(0, 3)},
	"unique_dungeon_2": {"source_id": 25, "atlas_coords": Vector2i(1, 3)},
	"unique_dungeon_3": {"source_id": 26, "atlas_coords": Vector2i(2, 3)},
	"unique_dungeon_4": {"source_id": 27, "atlas_coords": Vector2i(3, 3)},

	"special_map_1": {"source_id": 28, "atlas_coords": Vector2i(0, 4)},
	"special_map_2": {"source_id": 29, "atlas_coords": Vector2i(1, 4)},
	"special_map_3": {"source_id": 30, "atlas_coords": Vector2i(2, 4)}
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

		dungeon_entrance_generator = FieldDungeonEntranceGenerator.new(MAP_WIDTH, MAP_HEIGHT)
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

	print("FIELDMAP READY END")



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

	if not place.has("enter_scene"):
		print("[DEBUG][FiledMap] place has no enter_scene -> return false")
		return false

	var enter_scene: String = str(place.get("enter_scene", ""))
	print("[DEBUG][FiledMap] enter_scene = ", enter_scene)

	if enter_scene == "":
		print("[DEBUG][FiledMap] enter_scene is empty -> return false")
		return false

	var place_difficulty: int = get_special_place_difficulty_at_cell(current_cell)
	var generator_type: String = _get_special_place_generator_type(place)
	var detail_map_key: String = _build_detail_map_key(current_cell)

	print("[DEBUG][FiledMap] detail_map_key = ", detail_map_key)
	print("[DEBUG][FiledMap] generator_type = ", generator_type)
	print("[DEBUG][FiledMap] place_difficulty = ", place_difficulty)

	GlobalDetailMap.current_detail_map_key = detail_map_key
	GlobalDetailMap.current_generator_type = generator_type
	GlobalDetailMap.from_field_tile = current_cell
	GlobalDetailMap.current_area_difficulty = place_difficulty

	print("[DEBUG][FiledMap] GlobalDetailMap.current_detail_map_key = ", GlobalDetailMap.current_detail_map_key)
	print("[DEBUG][FiledMap] GlobalDetailMap.current_generator_type = ", GlobalDetailMap.current_generator_type)
	print("[DEBUG][FiledMap] GlobalDetailMap.from_field_tile = ", GlobalDetailMap.from_field_tile)
	print("[DEBUG][FiledMap] GlobalDetailMap.current_area_difficulty = ", GlobalDetailMap.current_area_difficulty)

	get_tree().change_scene_to_file(enter_scene)
	return true


func apply_special_places_to_event_layer(places: Array) -> void:
	for place in places:
		var cell: Vector2i = Vector2i(place["x"], place["y"])
		var place_id: String = place["place_id"]

		if not SPECIAL_PLACE_TILE_MAP.has(place_id):
			continue

		var tile_info: Dictionary = SPECIAL_PLACE_TILE_MAP[place_id]
		var source_id: int = tile_info["source_id"]
		var atlas_coords: Vector2i = tile_info["atlas_coords"]

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
