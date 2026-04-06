extends Resource
class_name LootCategoryEntry

@export var item_type: String = "consumable"
@export var weight: int = 100
@export var min_amount: int = 1
@export var max_amount: int = 1


func get_normalized_item_type() -> String:
	return ItemCategories.normalize(item_type)
