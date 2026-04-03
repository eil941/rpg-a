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

@export var override_combat_style: bool = false
@export_enum("AUTO", "MELEE", "MID", "LONG", "SUPPORTER", "HIT_AND_RUN", "DEFENSIVE")
var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = true
@export_enum("AUTO", "APPROACH", "KEEP_DISTANCE", "FLEE", "HOLD")
var move_style: int = AIMoveStyle.FLEE

@export var talk_display_name: String = ""
@export_multiline var talk_greeting_text: String = "こんにちは。"
@export var talk_portrait: Texture2D

@export_flags("VILLAGER", "MERCHANT", "GUARD", "RECRUIT", "QUEST_GIVER", "ENEMY_BOSS")
var unit_roles: int = 0

@export var friendliness: int = 0
@export var can_offer_request: bool = false

# 既存互換
@export var can_trade: bool = false
@export var can_receive_order: bool = false
@export var extra_interact_actions: Array[String] = []

@export_multiline var request_description: String = "薬草を3個集めてきてほしい。"
@export_multiline var request_accept_text: String = "助かる。よろしく頼む。"
@export_multiline var request_decline_text: String = "そうか……また気が向いたら頼む。"

@export var random_talk_texts: Array[String] = [
	"今日は静かですね。",
	"この辺りは夜になると危ないですよ。",
	"最近、森の様子がおかしいんです。"
]

@export var animation_profile: AnimationProfile

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []


func get_effective_npc_type_id() -> String:
	if npc_type_id != "":
		return npc_type_id
	return npc_name
