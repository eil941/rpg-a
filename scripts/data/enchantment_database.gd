extends Node
class_name EnchantmentDatabase

const ENCHANT_RESOURCES: Dictionary = {
	"atk_up_small": preload("res://data/enchantments/atk_up_small.tres"),
	"def_up_small": preload("res://data/enchantments/def_up_small.tres"),
	"hp_up_small": preload("res://data/enchantments/hp_up_small.tres"),
}


static func get_enchantment(enchant_id: String) -> EnchantmentData:
	if ENCHANT_RESOURCES.has(enchant_id):
		return ENCHANT_RESOURCES[enchant_id]
	return null


static func get_candidate_enchantment_ids_for_slot(slot_name: String) -> Array[String]:
	var result: Array[String] = []

	for enchant_id_variant in ENCHANT_RESOURCES.keys():
		var enchant_id: String = String(enchant_id_variant)
		var enchant_data: EnchantmentData = ENCHANT_RESOURCES[enchant_id]
		if enchant_data == null:
			continue

		if enchant_data.allows_slot_name(slot_name):
			result.append(enchant_id)

	return result
