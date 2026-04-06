extends Resource
class_name LootCategoryEntry

@export_enum("consumable", "material", "equipment", "misc") var item_type: String = "consumable"
@export var weight: int = 100
@export var min_amount: int = 1
@export var max_amount: int = 1
