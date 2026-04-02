extends Resource
class_name NpcData

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

@export var npc_name: String = "no_name"
@export var npc_type_id: String = "no_id"

@export_enum("PLAYER", "NPC", "ENEMY")
var faction: String = "NPC"

@export var max_hp: int = 20
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 120.0

@export var equipped_weapon: EquipmentData
@export var equipped_armor: EquipmentData
@export var equipped_accessory: EquipmentData

# NPC個体ごとのAI override
# NPC はデフォルトで逃走移動
@export var override_combat_style: bool = false
@export_enum("AUTO", "MELEE", "MID", "LONG", "SUPPORTER", "HIT_AND_RUN", "DEFENSIVE")
var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = true
@export_enum("AUTO", "APPROACH", "KEEP_DISTANCE", "FLEE", "HOLD")
var move_style: int = AIMoveStyle.FLEE

@export var talk_display_name: String = ""
@export_multiline var talk_greeting_text: String = "こんにちは。"
@export var talk_portrait: Texture2D
@export var can_trade: bool = false
@export var can_receive_order: bool = false
@export var extra_interact_actions: Array[String] = []

@export var animation_profile: AnimationProfile

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []
