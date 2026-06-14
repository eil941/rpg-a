extends Node
class_name EnemyDatabase


static func get_all_enemy_data() -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	if GameData == null:
		return result

	if not GameData.has_method("get_all_enemies"):
		return result

	for raw_enemy in GameData.get_all_enemies():
		var enemy: EnemyData = raw_enemy as EnemyData
		if enemy == null:
			continue
		result.append(enemy)

	return result


static func get_enemy_data_by_id(enemy_type_id: String) -> EnemyData:
	if enemy_type_id == "":
		return null

	if GameData == null:
		return null

	if GameData.has_method("get_enemy"):
		return GameData.get_enemy(enemy_type_id)

	return null


static func get_enemy(enemy_type_id: String) -> EnemyData:
	return get_enemy_data_by_id(enemy_type_id)


static func exists(enemy_type_id: String) -> bool:
	return has_enemy(enemy_type_id)


static func has_enemy(enemy_type_id: String) -> bool:
	if enemy_type_id == "":
		return false

	if GameData == null:
		return false

	if GameData.has_method("has_enemy"):
		return GameData.has_enemy(enemy_type_id)

	return get_enemy_data_by_id(enemy_type_id) != null
