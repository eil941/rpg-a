extends Resource
class_name EquipmentData

enum EquipmentSlot {
	WEAPON,
	ARMOR,
	ACCESSORY
}

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

@export var item_id: String = ""
@export var display_name: String = ""
@export var slot_type: int = EquipmentSlot.WEAPON

@export var max_hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0

# 攻撃情報
@export var attack_type_id: String = "melee"
@export var attack_min_range: int = 1
@export var attack_max_range: int = 1

# AI傾向
# AUTO の場合は unit 側設定へ委譲
# unit 側も未指定なら最終的に近接型へ
@export var combat_style: int = AICombatStyle.AUTO
@export var move_style: int = AIMoveStyle.AUTO
