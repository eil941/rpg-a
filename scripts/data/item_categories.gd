extends RefCounted
class_name ItemCategories

const CONSUMABLE: StringName = &"consumable"
const MATERIAL: StringName = &"material"
const EQUIPMENT: StringName = &"equipment"
const MISC: StringName = &"misc"

const ALL: Array[StringName] = [
	CONSUMABLE,
	MATERIAL,
	EQUIPMENT,
	MISC
]


static func _has_loaded_game_data_categories() -> bool:
	if GameData == null:
		return false

	if not GameData.has_method("get_all_item_categories"):
		return false

	return not GameData.get_all_item_categories().is_empty()


static func is_valid(category: String) -> bool:
	var value: String = category.strip_edges().to_lower()
	if value == "":
		return false

	if _has_loaded_game_data_categories():
		return GameData.has_item_category(value)

	return ALL.has(StringName(value))


static func normalize(category: String) -> String:
	var value: String = category.strip_edges().to_lower()
	if value == "":
		return String(MISC)

	if _has_loaded_game_data_categories():
		if GameData.has_item_category(value):
			return value
		if GameData.has_method("get_item_category"):
			GameData.get_item_category(value)
		return String(MISC)

	if ALL.has(StringName(value)):
		return value

	return String(MISC)


static func get_all_as_strings() -> Array[String]:
	var result: Array[String] = []

	if _has_loaded_game_data_categories():
		for category in GameData.get_all_item_categories():
			if typeof(category) != TYPE_DICTIONARY:
				continue

			var category_id := String(category.get("category_id", "")).strip_edges()
			if category_id != "":
				result.append(category_id)

		return result

	for value in ALL:
		result.append(String(value))

	return result


static func get_category_data(category: String) -> Dictionary:
	var normalized := normalize(category)

	if _has_loaded_game_data_categories():
		return GameData.get_item_category(normalized)

	return {}
