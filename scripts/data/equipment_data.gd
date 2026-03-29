extends Resource
class_name EquipmentData

enum EquipmentSlot {
	WEAPON,
	ARMOR,
	ACCESSORY
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var slot_type: int = EquipmentSlot.WEAPON

@export var max_hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0

@export var attack_type_id: String = "melee"
@export var attack_min_range: int = 1
@export var attack_max_range: int = 1
