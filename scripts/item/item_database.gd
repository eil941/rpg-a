extends Node
class_name ItemDatabase

const EQUIPMENT_ENCHANT_CHANCE: float = 0.1

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


static func get_entry_display_name(entry: Dictionary) -> String:
	var item_id: String = String(entry.get("item_id", ""))
	var base_name: String = get_display_name(item_id)

	if item_id == "":
		return ""

	var instance_data: Variant = entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		return base_name

	var enchantments: Variant = instance_data.get("enchantments", [])
	if not (enchantments is Array):
		return base_name

	if enchantments.is_empty():
		return base_name

	var first_data: Variant = enchantments[0]
	if typeof(first_data) != TYPE_DICTIONARY:
		return base_name

	var enchant_id: String = String(first_data.get("id", ""))
	match enchant_id:
		"atk_up_small":
			return "鋭い" + base_name
		"def_up_small":
			return "守りの" + base_name
		"hp_up_small":
			return "生命の" + base_name
		_:
			return base_name




static func _debug_enchant_log(message: String) -> void:
	if DebugSettings != null and DebugSettings.debug_enchant:
		print(message)


static func _shuffle_string_array(values: Array[String], rng: RandomNumberGenerator) -> Array[String]:
	var result: Array[String] = values.duplicate()

	for i in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = result[i]
		result[i] = result[j]
		result[j] = tmp

	return result


static func build_random_equipment_entry(item_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var entry: Dictionary = {
		"item_id": item_id,
		"amount": 1
	}

	var equipment_resource: EquipmentData = get_equipment_resource(item_id)
	if equipment_resource == null:
		_debug_enchant_log("[ENCHANT][ItemDatabase] BUILD RANDOM EQUIPMENT ENTRY = %s" % str(entry))
		return entry

	var enchant_roll: float = rng.randf()
	_debug_enchant_log("[ENCHANT][ItemDatabase] roll item_id=%s roll=%s chance=%s" % [item_id, str(enchant_roll), str(EQUIPMENT_ENCHANT_CHANCE)])
	if enchant_roll >= EQUIPMENT_ENCHANT_CHANCE:
		_debug_enchant_log("[ENCHANT][ItemDatabase] no enchant item_id=%s" % item_id)
		return entry

	var slot_name: String = equipment_resource.get_slot_name()
	var candidate_ids: Array[String] = EnchantmentDatabase.get_candidate_enchantment_ids_for_slot(slot_name)
	_debug_enchant_log("[ENCHANT][ItemDatabase] candidates item_id=%s slot=%s candidate_ids=%s" % [item_id, slot_name, str(candidate_ids)])
	if candidate_ids.is_empty():
		_debug_enchant_log("[ENCHANT][ItemDatabase] no candidates item_id=%s slot=%s" % [item_id, slot_name])
		return entry

	var requested_count: int = rng.randi_range(1, 10)
	var enchant_count: int = min(requested_count, candidate_ids.size())

	var shuffled_ids: Array[String] = _shuffle_string_array(candidate_ids, rng)
	var enchantments: Array = []

	for i in range(enchant_count):
		var enchant_id: String = shuffled_ids[i]
		var enchant_data: EnchantmentData = EnchantmentDatabase.get_enchantment(enchant_id)
		if enchant_data == null:
			continue

		var value: int = rng.randi_range(enchant_data.min_value, enchant_data.max_value)
		enchantments.append({
			"id": enchant_id,
			"value": value
		})

	if enchantments.is_empty():
		_debug_enchant_log("[ENCHANT][ItemDatabase] empty enchantments item_id=%s" % item_id)
		return entry

	entry["instance_data"] = {
		"enchantments": enchantments
	}
	_debug_enchant_log("[ENCHANT][ItemDatabase] BUILD RANDOM EQUIPMENT ENTRY = %s" % str(entry))
	return entry


static func build_equipment_entry(item_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"amount": 1
	}
