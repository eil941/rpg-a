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

@export var override_combat_style: bool = false
@export_enum("AUTO", "MELEE", "MID", "LONG", "SUPPORTER", "HIT_AND_RUN", "DEFENSIVE")
var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = false
@export_enum("AUTO", "APPROACH", "KEEP_DISTANCE", "FLEE", "HOLD")
var move_style: int = AIMoveStyle.AUTO

@export var talk_display_name: String = ""
@export_multiline var talk_greeting_text: String = "……"
@export var talk_portrait: Texture2D

@export_flags("VILLAGER", "MERCHANT", "GUARD", "RECRUIT", "QUEST_GIVER", "ENEMY_BOSS")
var unit_roles: int = 0

@export var friendliness: int = -100
@export var can_offer_request: bool = false

# NPC互換・ショップ設定
@export var can_trade: bool = false
@export var can_receive_order: bool = false
@export var extra_interact_actions: Array[String] = []

@export var can_generate_shop_inventory: bool = false
@export var shop_min_items: int = 3
@export var shop_max_items: int = 6
@export var shop_loot_categories: Array[LootCategoryEntry] = []

@export_multiline var request_description: String = "こちらの頼みを聞くつもりか？"
@export_multiline var request_accept_text: String = "いい度胸だ。"
@export_multiline var request_decline_text: String = "賢明な判断かもしれんな。"

@export var random_talk_texts: Array[String] = [
	"……。",
	"こちらを見るな。",
	"近づきすぎるな。"
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


func get_effective_enemy_type_id() -> String:
	if enemy_type_id != "":
		return enemy_type_id
	return enemy_name


func is_shopkeeper() -> bool:
	return can_trade or can_generate_shop_inventory or has_merchant_role()


func has_merchant_role() -> bool:
	return (unit_roles & (1 << 1)) != 0
