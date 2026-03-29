extends Resource
class_name AnimationProfile

@export var sprite_sheet: Texture2D

# true のときは columns / rows から自動計算
@export var use_grid_size: bool = true

# 何列・何行あるか
@export var frame_columns: int = 4
@export var frame_rows: int = 4

# use_grid_size = false のときだけ手動サイズを使う
@export var frame_width: int = 32
@export var frame_height: int = 32

@export var auto_bottom_align: bool = true
@export var base_tile_height: int = 32
@export var profile_offset: Vector2 = Vector2.ZERO

@export var idle_right_indices: Array[int] = []
@export var walk_right_indices: Array[int] = []

@export var idle_left_indices: Array[int] = []
@export var walk_left_indices: Array[int] = []

@export var idle_down_indices: Array[int] = []
@export var walk_down_indices: Array[int] = []

@export var idle_up_indices: Array[int] = []
@export var walk_up_indices: Array[int] = []


func get_frame_width() -> int:
	if sprite_sheet == null:
		return frame_width

	if use_grid_size and frame_columns > 0:
		return int(sprite_sheet.get_width() / frame_columns)

	return frame_width


func get_frame_height() -> int:
	if sprite_sheet == null:
		return frame_height

	if use_grid_size and frame_rows > 0:
		return int(sprite_sheet.get_height() / frame_rows)

	return frame_height
