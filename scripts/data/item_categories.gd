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


static func is_valid(category: String) -> bool:
	return ALL.has(StringName(category.strip_edges().to_lower()))


static func normalize(category: String) -> String:
	var value: String = category.strip_edges().to_lower()
	if is_valid(value):
		return value
	return String(MISC)


static func get_all_as_strings() -> Array[String]:
	var result: Array[String] = []

	for value in ALL:
		result.append(String(value))

	return result
