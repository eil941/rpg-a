extends Resource
class_name NpcData

# right_hand / left_hand は装備欄です。
# 装備アイテム側のカテゴリは equipment_data.gd 側で hand に統一します。

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

@export_range(0.0, 1.0, 0.01) var accuracy: float = 0.95
@export_range(0.0, 1.0, 0.01) var evasion: float = 0.05
@export_range(0.0, 1.0, 0.01) var crit_rate: float = 0.05
@export var crit_damage: float = 1.5
@export var luck: int = 0

@export var element: String = "neutral"
@export var element_resistances: Dictionary = {
	"neutral": 1.0
}

@export var strength: int = 10
@export var vitality: int = 10
@export var agility: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10
@export var spirit: int = 10
@export var sense: int = 10
@export var charm: int = 10

@export var gathering: int = 0
@export var investigation: int = 0
@export var stealth: int = 0
@export var trap_disarm: int = 0
@export var fishing: int = 0
@export var appraisal: int = 0
@export var cooking: int = 0
@export var repair: int = 0
@export var smithing: int = 0
@export var alchemy: int = 0
@export var negotiation: int = 0
@export var speech: int = 0
@export var medical: int = 0

@export var equipped_weapon: EquipmentData
@export var equipped_armor: EquipmentData
@export var equipped_accessory: EquipmentData

@export var equipped_right_hand: EquipmentData
@export var equipped_left_hand: EquipmentData
@export var equipped_head: EquipmentData
@export var equipped_body: EquipmentData
@export var equipped_hands: EquipmentData
@export var equipped_waist: EquipmentData
@export var equipped_feet: EquipmentData
@export var equipped_accessory_1: EquipmentData
@export var equipped_accessory_2: EquipmentData
@export var equipped_accessory_3: EquipmentData
@export var equipped_accessory_4: EquipmentData

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

@export var can_trade: bool = false
@export var can_receive_order: bool = false
@export var extra_interact_actions: Array[String] = []

@export var can_generate_shop_inventory: bool = false
@export var shop_min_items: int = 3
@export var shop_max_items: int = 6
@export var shop_loot_categories: Array[LootCategoryEntry] = []

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


func is_shopkeeper() -> bool:
	return can_trade or can_generate_shop_inventory or has_merchant_role()


func has_merchant_role() -> bool:
	return (unit_roles & (1 << 1)) != 0


func get_equipment_save_data() -> Dictionary:
	return {
		"right_hand": _get_preferred_equipment_id(equipped_right_hand, equipped_weapon),
		"left_hand": _get_preferred_equipment_id(equipped_left_hand, null),
		"head": _get_preferred_equipment_id(equipped_head, null),
		"body": _get_preferred_equipment_id(equipped_body, equipped_armor),
		"hands": _get_preferred_equipment_id(equipped_hands, null),
		"waist": _get_preferred_equipment_id(equipped_waist, null),
		"feet": _get_preferred_equipment_id(equipped_feet, null),
		"accessory_1": _get_preferred_equipment_id(equipped_accessory_1, equipped_accessory),
		"accessory_2": _get_preferred_equipment_id(equipped_accessory_2, null),
		"accessory_3": _get_preferred_equipment_id(equipped_accessory_3, null),
		"accessory_4": _get_preferred_equipment_id(equipped_accessory_4, null)
	}


func _get_preferred_equipment_id(primary: EquipmentData, fallback: EquipmentData) -> String:
	if primary != null and String(primary.item_id) != "":
		return String(primary.item_id)
	if fallback != null and String(fallback.item_id) != "":
		return String(fallback.item_id)
	return ""
