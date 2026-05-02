extends Resource
class_name DungeonTileVisualConfig

# Dungeon visual config.
# Each generator_theme can define:
# - field: tile shown on the field map for the dungeon entrance / dungeon marker
# - down: tile used inside dungeon to go to the next/lower floor
# - up: tile used inside dungeon to return to the previous/upper floor
# - floor: dungeon floor tile
# - wall: dungeon wall tile

const THEME_NATURAL: String = "NATURAL"
const THEME_FORTIFIED: String = "FORTIFIED"
const THEME_RUINED: String = "RUINED"
const THEME_ARTIFICIAL: String = "ARTIFICIAL"
const THEME_CHAOTIC: String = "CHAOTIC"

const KIND_FIELD: String = "FIELD"
const KIND_DOWN: String = "DOWN"
const KIND_UP: String = "UP"
const KIND_FLOOR: String = "FLOOR"
const KIND_WALL: String = "WALL"

# =========================
# NATURAL
# =========================
@export_group("NATURAL Field")
@export var natural_field_source_id: int = 0
@export var natural_field_atlas_coords: Vector2i = Vector2i(0, 0)
@export var natural_field_alternative_tile: int = 0

@export_group("NATURAL Dungeon")
@export var natural_down_source_id: int = 6
@export var natural_down_atlas_coords: Vector2i = Vector2i(0, 0)
@export var natural_down_alternative_tile: int = 0
@export var natural_up_source_id: int = 3
@export var natural_up_atlas_coords: Vector2i = Vector2i(0, 0)
@export var natural_up_alternative_tile: int = 0
@export var natural_floor_source_id: int = 29
@export var natural_floor_atlas_coords: Vector2i = Vector2i(1, 4)
@export var natural_floor_alternative_tile: int = 0
@export var natural_wall_source_id: int = 5
@export var natural_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var natural_wall_alternative_tile: int = 0

# =========================
# FORTIFIED
# =========================
@export_group("FORTIFIED Field")
@export var fortified_field_source_id: int = 0
@export var fortified_field_atlas_coords: Vector2i = Vector2i(0, 0)
@export var fortified_field_alternative_tile: int = 0

@export_group("FORTIFIED Dungeon")
@export var fortified_down_source_id: int = 6
@export var fortified_down_atlas_coords: Vector2i = Vector2i(0, 0)
@export var fortified_down_alternative_tile: int = 0
@export var fortified_up_source_id: int = 3
@export var fortified_up_atlas_coords: Vector2i = Vector2i(0, 0)
@export var fortified_up_alternative_tile: int = 0
@export var fortified_floor_source_id: int = 29
@export var fortified_floor_atlas_coords: Vector2i = Vector2i(1, 4)
@export var fortified_floor_alternative_tile: int = 0
@export var fortified_wall_source_id: int = 5
@export var fortified_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var fortified_wall_alternative_tile: int = 0

# =========================
# RUINED
# =========================
@export_group("RUINED Field")
@export var ruined_field_source_id: int = 0
@export var ruined_field_atlas_coords: Vector2i = Vector2i(0, 0)
@export var ruined_field_alternative_tile: int = 0

@export_group("RUINED Dungeon")
@export var ruined_down_source_id: int = 6
@export var ruined_down_atlas_coords: Vector2i = Vector2i(0, 0)
@export var ruined_down_alternative_tile: int = 0
@export var ruined_up_source_id: int = 3
@export var ruined_up_atlas_coords: Vector2i = Vector2i(0, 0)
@export var ruined_up_alternative_tile: int = 0
@export var ruined_floor_source_id: int = 29
@export var ruined_floor_atlas_coords: Vector2i = Vector2i(1, 4)
@export var ruined_floor_alternative_tile: int = 0
@export var ruined_wall_source_id: int = 5
@export var ruined_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var ruined_wall_alternative_tile: int = 0

# =========================
# ARTIFICIAL
# =========================
@export_group("ARTIFICIAL Field")
@export var artificial_field_source_id: int = 0
@export var artificial_field_atlas_coords: Vector2i = Vector2i(0, 0)
@export var artificial_field_alternative_tile: int = 0

@export_group("ARTIFICIAL Dungeon")
@export var artificial_down_source_id: int = 6
@export var artificial_down_atlas_coords: Vector2i = Vector2i(0, 0)
@export var artificial_down_alternative_tile: int = 0
@export var artificial_up_source_id: int = 3
@export var artificial_up_atlas_coords: Vector2i = Vector2i(0, 0)
@export var artificial_up_alternative_tile: int = 0
@export var artificial_floor_source_id: int = 29
@export var artificial_floor_atlas_coords: Vector2i = Vector2i(1, 4)
@export var artificial_floor_alternative_tile: int = 0
@export var artificial_wall_source_id: int = 5
@export var artificial_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var artificial_wall_alternative_tile: int = 0

# =========================
# CHAOTIC
# =========================
@export_group("CHAOTIC Field")
@export var chaotic_field_source_id: int = 0
@export var chaotic_field_atlas_coords: Vector2i = Vector2i(0, 0)
@export var chaotic_field_alternative_tile: int = 0

@export_group("CHAOTIC Dungeon")
@export var chaotic_down_source_id: int = 6
@export var chaotic_down_atlas_coords: Vector2i = Vector2i(0, 0)
@export var chaotic_down_alternative_tile: int = 0
@export var chaotic_up_source_id: int = 3
@export var chaotic_up_atlas_coords: Vector2i = Vector2i(0, 0)
@export var chaotic_up_alternative_tile: int = 0
@export var chaotic_floor_source_id: int = 29
@export var chaotic_floor_atlas_coords: Vector2i = Vector2i(1, 4)
@export var chaotic_floor_alternative_tile: int = 0
@export var chaotic_wall_source_id: int = 5
@export var chaotic_wall_atlas_coords: Vector2i = Vector2i(0, 0)
@export var chaotic_wall_alternative_tile: int = 0


func get_tile(generator_theme: String, kind: String) -> Dictionary:
	var theme: String = _normalize_theme(generator_theme)
	var normalized_kind: String = String(kind).strip_edges().replace("\"", "").to_upper()

	match theme:
		THEME_NATURAL:
			return _get_natural_tile(normalized_kind)
		THEME_FORTIFIED:
			return _get_fortified_tile(normalized_kind)
		THEME_RUINED:
			return _get_ruined_tile(normalized_kind)
		THEME_ARTIFICIAL:
			return _get_artificial_tile(normalized_kind)
		THEME_CHAOTIC:
			return _get_chaotic_tile(normalized_kind)

	return _get_natural_tile(normalized_kind)


func _normalize_theme(generator_theme: String) -> String:
	var theme: String = String(generator_theme).strip_edges().replace("\"", "").to_upper()

	match theme:
		THEME_NATURAL, THEME_FORTIFIED, THEME_RUINED, THEME_ARTIFICIAL, THEME_CHAOTIC:
			return theme

	return THEME_NATURAL


func _make_tile(source_id: int, atlas_coords: Vector2i, alternative_tile: int) -> Dictionary:
	return {
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile": alternative_tile
	}


func _get_natural_tile(kind: String) -> Dictionary:
	match kind:
		KIND_FIELD:
			return _make_tile(natural_field_source_id, natural_field_atlas_coords, natural_field_alternative_tile)
		KIND_DOWN:
			return _make_tile(natural_down_source_id, natural_down_atlas_coords, natural_down_alternative_tile)
		KIND_UP:
			return _make_tile(natural_up_source_id, natural_up_atlas_coords, natural_up_alternative_tile)
		KIND_FLOOR:
			return _make_tile(natural_floor_source_id, natural_floor_atlas_coords, natural_floor_alternative_tile)
		KIND_WALL:
			return _make_tile(natural_wall_source_id, natural_wall_atlas_coords, natural_wall_alternative_tile)

	return _make_tile(natural_floor_source_id, natural_floor_atlas_coords, natural_floor_alternative_tile)


func _get_fortified_tile(kind: String) -> Dictionary:
	match kind:
		KIND_FIELD:
			return _make_tile(fortified_field_source_id, fortified_field_atlas_coords, fortified_field_alternative_tile)
		KIND_DOWN:
			return _make_tile(fortified_down_source_id, fortified_down_atlas_coords, fortified_down_alternative_tile)
		KIND_UP:
			return _make_tile(fortified_up_source_id, fortified_up_atlas_coords, fortified_up_alternative_tile)
		KIND_FLOOR:
			return _make_tile(fortified_floor_source_id, fortified_floor_atlas_coords, fortified_floor_alternative_tile)
		KIND_WALL:
			return _make_tile(fortified_wall_source_id, fortified_wall_atlas_coords, fortified_wall_alternative_tile)

	return _make_tile(fortified_floor_source_id, fortified_floor_atlas_coords, fortified_floor_alternative_tile)


func _get_ruined_tile(kind: String) -> Dictionary:
	match kind:
		KIND_FIELD:
			return _make_tile(ruined_field_source_id, ruined_field_atlas_coords, ruined_field_alternative_tile)
		KIND_DOWN:
			return _make_tile(ruined_down_source_id, ruined_down_atlas_coords, ruined_down_alternative_tile)
		KIND_UP:
			return _make_tile(ruined_up_source_id, ruined_up_atlas_coords, ruined_up_alternative_tile)
		KIND_FLOOR:
			return _make_tile(ruined_floor_source_id, ruined_floor_atlas_coords, ruined_floor_alternative_tile)
		KIND_WALL:
			return _make_tile(ruined_wall_source_id, ruined_wall_atlas_coords, ruined_wall_alternative_tile)

	return _make_tile(ruined_floor_source_id, ruined_floor_atlas_coords, ruined_floor_alternative_tile)


func _get_artificial_tile(kind: String) -> Dictionary:
	match kind:
		KIND_FIELD:
			return _make_tile(artificial_field_source_id, artificial_field_atlas_coords, artificial_field_alternative_tile)
		KIND_DOWN:
			return _make_tile(artificial_down_source_id, artificial_down_atlas_coords, artificial_down_alternative_tile)
		KIND_UP:
			return _make_tile(artificial_up_source_id, artificial_up_atlas_coords, artificial_up_alternative_tile)
		KIND_FLOOR:
			return _make_tile(artificial_floor_source_id, artificial_floor_atlas_coords, artificial_floor_alternative_tile)
		KIND_WALL:
			return _make_tile(artificial_wall_source_id, artificial_wall_atlas_coords, artificial_wall_alternative_tile)

	return _make_tile(artificial_floor_source_id, artificial_floor_atlas_coords, artificial_floor_alternative_tile)


func _get_chaotic_tile(kind: String) -> Dictionary:
	match kind:
		KIND_FIELD:
			return _make_tile(chaotic_field_source_id, chaotic_field_atlas_coords, chaotic_field_alternative_tile)
		KIND_DOWN:
			return _make_tile(chaotic_down_source_id, chaotic_down_atlas_coords, chaotic_down_alternative_tile)
		KIND_UP:
			return _make_tile(chaotic_up_source_id, chaotic_up_atlas_coords, chaotic_up_alternative_tile)
		KIND_FLOOR:
			return _make_tile(chaotic_floor_source_id, chaotic_floor_atlas_coords, chaotic_floor_alternative_tile)
		KIND_WALL:
			return _make_tile(chaotic_wall_source_id, chaotic_wall_atlas_coords, chaotic_wall_alternative_tile)

	return _make_tile(chaotic_floor_source_id, chaotic_floor_atlas_coords, chaotic_floor_alternative_tile)
