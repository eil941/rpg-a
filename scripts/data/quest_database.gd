extends Node
class_name QuestDatabase

static var QUEST_TEMPLATES: Array[QuestData] = [
	preload("res://data/quest/quest_villager_food_delivery.tres"),
	preload("res://data/quest/quest_villager_material_delivery.tres"),
	preload("res://data/quest/quest_merchant_consumable_delivery.tres"),
	preload("res://data/quest/quest_guard_equipment_delivery.tres"),
	preload("res://data/quest/quest_fixed_apple_delivery.tres")
]


static func get_all_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []

	for raw_quest in QUEST_TEMPLATES:
		var quest: QuestData = raw_quest as QuestData
		if quest == null:
			continue
		result.append(quest)

	return result
