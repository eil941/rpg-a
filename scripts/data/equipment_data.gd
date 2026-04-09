extends ItemData
class_name EquipmentData

enum EquipmentSlot {
	HAND,
	HEAD,
	BODY,
	HANDS,
	WAIST,
	FEET,
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
		EquipmentSlot.ACCESSORY:
			return "accessory"
		_:
			return ""


func is_hand() -> bool:
	return slot_type == EquipmentSlot.HAND


func is_accessory() -> bool:
	return slot_type == EquipmentSlot.ACCESSORY
