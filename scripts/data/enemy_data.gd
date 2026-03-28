extends Resource
class_name EnemyData

@export var enemy_type_id: String = "Enemy"
@export var enemy_name: String = "no_id"
@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 0
@export var speed: float = 120.0

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []
