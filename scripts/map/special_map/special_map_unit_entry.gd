extends Resource
class_name SpecialMapUnitEntry

enum SpawnKind {
	ENEMY,
	NPC
}

@export var enabled: bool = true
@export var spawn_kind: SpawnKind = SpawnKind.NPC

@export var enemy_data: EnemyData
@export var npc_data: NpcData
@export var enemy_type_id: String = ""
@export var npc_type_id: String = ""

# 固定配置用
@export var fixed_spawn_count: int = 1
@export var fixed_spawn_tiles: Array[Vector2i] = []

# ランダム抽選用
@export var random_weight: int = 1


func get_data_resource() -> Resource:
	if spawn_kind == SpawnKind.ENEMY:
		if enemy_data == null and enemy_type_id.strip_edges() != "":
			return EnemyDatabase.get_enemy_data_by_id(enemy_type_id.strip_edges())
		return enemy_data
	if npc_data == null and npc_type_id.strip_edges() != "":
		return NpcDatabase.get_npc_data_by_id(npc_type_id.strip_edges())
	return npc_data


func get_display_name() -> String:
	var data_res: Resource = get_data_resource()
	if data_res == null:
		return "(none)"

	if spawn_kind == SpawnKind.ENEMY and data_res is EnemyData:
		return String((data_res as EnemyData).enemy_name)

	if spawn_kind == SpawnKind.NPC and data_res is NpcData:
		return String((data_res as NpcData).npc_name)

	return data_res.resource_path
