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

# 固定配置用
@export var fixed_spawn_count: int = 1
@export var fixed_spawn_tiles: Array[Vector2i] = []

# ランダム抽選用
@export var random_weight: int = 1


func get_data_resource() -> Resource:
	if spawn_kind == SpawnKind.ENEMY:
		return enemy_data
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
