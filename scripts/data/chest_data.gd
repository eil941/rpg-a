extends Resource
class_name ChestData

enum SpecialFunctionFlag {
	SPECIAL_TRAP = 1 << 0,
	SPECIAL_LOCKED = 1 << 1,
	SPECIAL_MIMIC = 1 << 2,
	SPECIAL_HEAL = 1 << 3,
	SPECIAL_RESTOCK = 1 << 4
}

@export var chest_type_id: String = "wooden"
@export var chest_name: String = "Chest"

@export var closed_texture: Texture2D
@export var opened_texture: Texture2D

@export var slot_count: int = 12

@export var can_put_items: bool = true
@export var can_take_items: bool = true

@export var allowed_item_types: Array[String] = []
@export var denied_item_types: Array[String] = []

@export var is_shared_storage: bool = false
@export var is_one_time_loot: bool = false

@export_flags("trap", "locked", "mimic", "heal", "restock") var special_function_flags: int = 0

@export var loot_min_items: int = 1
@export var loot_max_items: int = 3
@export var loot_categories: Array[LootCategoryEntry] = []

@export var ui_panel_min_size: Vector2 = Vector2(320, 240)
@export var ui_slot_size: Vector2 = Vector2(48, 48)
@export var ui_slot_columns: int = 5
@export var ui_background: Texture2D


func has_allowed_item_type(item_type: String) -> bool:
	if allowed_item_types.is_empty():
		return true

	var normalized_type: String = ItemCategories.normalize(item_type)

	for value in allowed_item_types:
		if ItemCategories.normalize(String(value)) == normalized_type:
			return true

	return false


func has_denied_item_type(item_type: String) -> bool:
	var normalized_type: String = ItemCategories.normalize(item_type)

	for value in denied_item_types:
		if ItemCategories.normalize(String(value)) == normalized_type:
			return true

	return false


func has_special_function_flag(flag: int) -> bool:
	return (special_function_flags & flag) != 0
