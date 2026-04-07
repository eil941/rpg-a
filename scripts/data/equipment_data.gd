extends ItemData
class_name EquipmentData

enum EquipmentSlot {
	WEAPON = 0,
	ARMOR = 1,
	ACCESSORY = 2,
	HAND = 3,
	HEAD = 4,
	BODY = 5,
	HANDS = 6,
	WAIST = 7,
	FEET = 8
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

@export var slot_type: EquipmentSlot = EquipmentSlot.HAND

@export var max_hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0

@export_enum("melee", "shot", "magic", "heal")
var attack_type_id: String = "melee"

@export var attack_min_range: int = 1
@export var attack_max_range: int = 1

@export var combat_style: AICombatStyle = AICombatStyle.AUTO
@export var move_style: AIMoveStyle = AIMoveStyle.AUTO


func get_slot_name() -> String:
	match slot_type:
		EquipmentSlot.WEAPON:
			return "hand"
		EquipmentSlot.ARMOR:
			return "body"
		EquipmentSlot.ACCESSORY:
			return "accessory"
		EquipmentSlot.HAND:
			return "hand"
		EquipmentSlot.HEAD:
			return "head"
		EquipmentSlot.BODY:
			return "body"
		EquipmentSlot.HANDS:
			return "hands"
		EquipmentSlot.WAIST:
			return "waist"
		EquipmentSlot.FEET:
			return "feet"
		_:
			return ""


func is_weapon() -> bool:
	return slot_type == EquipmentSlot.WEAPON or slot_type == EquipmentSlot.HAND


func is_armor() -> bool:
	return (
		slot_type == EquipmentSlot.ARMOR
		or slot_type == EquipmentSlot.HEAD
		or slot_type == EquipmentSlot.BODY
		or slot_type == EquipmentSlot.HANDS
		or slot_type == EquipmentSlot.WAIST
		or slot_type == EquipmentSlot.FEET
	)


func is_accessory() -> bool:
	return slot_type == EquipmentSlot.ACCESSORY
