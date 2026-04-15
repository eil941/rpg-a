extends Node
class_name NpcDatabase

static func get_all_npc_data() -> Array[NpcData]:
	return [
		preload("res://data/test/NPC/new_sabo.tres"),
		preload("res://data/test/NPC/npc_1.tres")
	]


static func get_npc_data_by_id(npc_type_id: String) -> NpcData:
	var all_data: Array[NpcData] = get_all_npc_data()

	for data in all_data:
		if data == null:
			continue
		if data.npc_type_id == npc_type_id:
			return data

	return null


static func has_npc(npc_type_id: String) -> bool:
	return get_npc_data_by_id(npc_type_id) != null
