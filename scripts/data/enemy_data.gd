extends Resource
class_name EnemyData

enum AICombatStyle {
	AUTO,
	MELEE,
	MID,
	LONG,
	SUPPORTER,
	HIT_AND_RUN,
	DEFENSIVE
}

enum AIMoveStyle {
	AUTO,
	APPROACH,
	KEEP_DISTANCE,
	FLEE,
	HOLD
}

@export var enemy_type_id: String = "Enemy"
@export var enemy_name: String = "no_id"

@export_enum("PLAYER", "NPC", "ENEMY")
var faction: String = "ENEMY"

@export var max_hp: int = 10
@export var attack: int = 1
@export var defense: int = 0
@export var speed: float = 120.0

@export var equipped_weapon: EquipmentData
@export var equipped_armor: EquipmentData
@export var equipped_accessory: EquipmentData

# 敵個体ごとのAI override
# false / AUTO の場合は武器依存
# 武器も未指定なら最終的に近接型
@export var override_combat_style: bool = false
@export_enum("AUTO", "MELEE", "MID", "LONG", "SUPPORTER", "HIT_AND_RUN", "DEFENSIVE")
var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = false
@export_enum("AUTO", "APPROACH", "KEEP_DISTANCE", "FLEE", "HOLD")
var move_style: int = AIMoveStyle.AUTO

@export var animation_profile: AnimationProfile

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []
