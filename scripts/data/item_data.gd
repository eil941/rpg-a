extends Resource
class_name ItemData

enum ItemCategory {
	CONSUMABLE,
	MATERIAL,
	EQUIPMENT,
	MISC
}

enum ItemEffectType {
	NONE,
	HEAL_HP,
	LOG_ONLY
}

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var category: ItemCategory = ItemCategory.MISC
@export var max_stack: int = 99
@export var usable: bool = false

@export var effect_type: ItemEffectType = ItemEffectType.NONE
@export var effect_value: int = 0

@export var base_price: int = 0
@export var can_sell: bool = true


func get_item_type_name() -> String:
	match category:
		ItemCategory.CONSUMABLE:
			return "consumable"
		ItemCategory.MATERIAL:
			return "material"
		ItemCategory.EQUIPMENT:
			return "equipment"
		ItemCategory.MISC:
			return "misc"
		_:
			return "misc"


func get_effect_type_name() -> String:
	match effect_type:
		ItemEffectType.NONE:
			return "none"
		ItemEffectType.HEAL_HP:
			return "heal_hp"
		ItemEffectType.LOG_ONLY:
			return "log_only"
		_:
			return "none"
