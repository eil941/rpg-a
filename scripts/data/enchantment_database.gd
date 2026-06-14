extends Node
class_name EnchantmentDatabase


static func get_enchantment(enchant_id: String) -> EnchantmentData:
	if enchant_id == "":
		return null

	if GameData == null:
		return null

	if GameData.has_method("get_enchantment"):
		return GameData.get_enchantment(enchant_id)

	return null


static func has_enchantment(enchant_id: String) -> bool:
	if enchant_id == "":
		return false

	if GameData == null:
		return false

	if GameData.has_method("has_enchantment"):
		return GameData.has_enchantment(enchant_id)

	return get_enchantment(enchant_id) != null


static func get_all_enchantments() -> Array[EnchantmentData]:
	var result: Array[EnchantmentData] = []

	if GameData == null:
		return result

	if not GameData.has_method("get_all_enchantments"):
		return result

	for raw_enchantment in GameData.get_all_enchantments():
		var enchantment: EnchantmentData = raw_enchantment as EnchantmentData
		if enchantment == null:
			continue
		result.append(enchantment)

	return result


static func get_candidate_enchantment_ids_for_slot(slot_name: String) -> Array[String]:
	var result: Array[String] = []

	for enchant_data in get_all_enchantments():
		if enchant_data == null:
			continue

		if enchant_data.allows_slot_name(slot_name):
			result.append(enchant_data.enchant_id)

	return result
