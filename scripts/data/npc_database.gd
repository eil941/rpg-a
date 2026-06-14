extends Node
class_name NpcDatabase


static func get_all_npc_data() -> Array[NpcData]:
	var result: Array[NpcData] = []

	if GameData == null:
		return result

	if not GameData.has_method("get_all_npcs"):
		return result

	for raw_npc in GameData.get_all_npcs():
		var npc: NpcData = raw_npc as NpcData
		if npc == null:
			continue
		result.append(npc)

	return result


static func get_npc_data_by_id(npc_type_id: String) -> NpcData:
	if npc_type_id == "":
		return null

	if GameData == null:
		return null

	if GameData.has_method("get_npc"):
		return GameData.get_npc(npc_type_id)

	return null


static func get_npc(npc_type_id: String) -> NpcData:
	return get_npc_data_by_id(npc_type_id)


static func has_npc(npc_type_id: String) -> bool:
	if npc_type_id == "":
		return false

	if GameData == null:
		return false

	if GameData.has_method("has_npc"):
		return GameData.has_npc(npc_type_id)

	return get_npc_data_by_id(npc_type_id) != null


static func exists(npc_type_id: String) -> bool:
	return has_npc(npc_type_id)
