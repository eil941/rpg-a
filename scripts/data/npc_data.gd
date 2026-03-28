extends Resource
class_name NpcData

@export var npc_name: String = "no_name"
@export var npc_type_id: String = "no_id"
@export var max_hp: int = 20
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 120.0

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []
