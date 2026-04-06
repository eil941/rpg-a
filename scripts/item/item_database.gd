extends Node
class_name ItemDatabase

static var ITEM_RESOURCES = {
	# items
	"gold": preload("res://data/items/gold.tres"),
	"potion": preload("res://data/items/potion.tres"),
	"wood": preload("res://data/items/wood.tres"),
	"apple": preload("res://data/items/apple.tres"),

	# equipment
	"knife": preload("res://data/equipment/weapons/knife.tres"),
	"bow": preload("res://data/equipment/weapons/bow.tres"),
	"cloth_armor": preload("res://data/equipment/armor/cloth_armor.tres"),
	"power_ring": preload("res://data/equipment/accessories/power_ring.tres")
}


static func has_item(item_id: String) -> bool:
	return ITEM_RESOURCES.has(item_id)


static func exists(item_id: String) -> bool:
	return ITEM_RESOURCES.has(item_id)


static func get_item_resource(item_id: String):
	if item_id == "":
		return null
	return ITEM_RESOURCES.get(item_id, null)


static func get_item_data(item_id: String):
	return get_item_resource(item_id)


static func get_display_name(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return item_id
	return String(data.display_name)


static func get_description(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return ""
	return String(data.description)


static func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_resource(item_id)
	if data == null:
		return null
	return data.icon


static func get_max_stack(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 99
	return int(data.max_stack)


static func get_item_type(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return String(ItemCategories.MISC)

	if data is EquipmentData:
		return String(ItemCategories.EQUIPMENT)

	if data.has_method("get_item_type_name"):
		return ItemCategories.normalize(String(data.get_item_type_name()))

	return String(ItemCategories.MISC)


static func get_item_ids_by_type(item_type: String) -> Array[String]:
	var result: Array[String] = []
	var normalized_type: String = ItemCategories.normalize(item_type)

	for item_id in ITEM_RESOURCES.keys():
		if get_item_type(String(item_id)) == normalized_type:
			result.append(String(item_id))

	return result


static func get_item_ids_by_types(item_types: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var normalized_types: Array[String] = []

	for item_type in item_types:
		normalized_types.append(ItemCategories.normalize(String(item_type)))

	for item_id in ITEM_RESOURCES.keys():
		var id_text: String = String(item_id)
		var type_text: String = get_item_type(id_text)

		if normalized_types.has(type_text):
			result.append(id_text)

	return result


static func get_random_item_id_by_type(item_type: String, rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = get_item_ids_by_type(item_type)

	if candidates.is_empty():
		return ""

	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func is_usable(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	if data == null:
		return false
	return bool(data.usable)


static func is_equipment(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	return data is EquipmentData


static func get_equipment_slot(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return ""

	if data is EquipmentData:
		return data.get_slot_name()

	return ""


static func get_equipment_resource(item_id: String):
	var data = get_item_resource(item_id)
	if data is EquipmentData:
		return data
	return null


static func get_effect_type(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return "none"

	if data.has_method("get_effect_type_name"):
		return data.get_effect_type_name()

	return "none"


static func get_effect_value(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0
	return int(data.effect_value)


static func get_base_price(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0

	if "base_price" in data:
		return int(data.base_price)

	return 0


static func can_sell(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	if data == null:
		return false

	if "can_sell" in data:
		return bool(data.can_sell)

	return true
