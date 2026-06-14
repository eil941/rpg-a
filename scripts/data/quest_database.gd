extends Node
class_name QuestDatabase


static func get_all_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []

	if GameData == null:
		return result

	if GameData.has_method("get_all_quests"):
		for raw_quest in GameData.get_all_quests():
			var quest: QuestData = raw_quest as QuestData
			if quest == null:
				continue
			result.append(quest)
		return result

	if "quests" in GameData:
		for quest_id in GameData.quests.keys():
			var quest: QuestData = GameData.quests[quest_id] as QuestData
			if quest == null:
				continue
			result.append(quest)

	return result


static func get_quest(quest_id: String) -> QuestData:
	if quest_id == "":
		return null

	if GameData == null:
		return null

	if GameData.has_method("get_quest"):
		return GameData.get_quest(quest_id) as QuestData

	if "quests" in GameData:
		return GameData.quests.get(quest_id, null) as QuestData

	return null


static func has_quest(quest_id: String) -> bool:
	return get_quest(quest_id) != null
