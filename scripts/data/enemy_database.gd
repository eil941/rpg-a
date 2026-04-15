extends Node
class_name EnemyDatabase

static func get_all_enemy_data() -> Array[EnemyData]:
	return [
		preload("res://data/test/bat_data.tres"),
		preload("res://data/test/orc_data.tres"),
		preload("res://data/test/slime_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat1_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat2_data.tres")
	]


static func get_enemy_data_by_id(enemy_type_id: String) -> EnemyData:
	var all_data: Array[EnemyData] = get_all_enemy_data()

	for data in all_data:
		if data == null:
			continue
		if data.enemy_type_id == enemy_type_id:
			return data

	return null


static func has_enemy(enemy_type_id: String) -> bool:
	return get_enemy_data_by_id(enemy_type_id) != null
