extends Node
class_name EnemyDatabase

static func get_all_enemy_data() -> Array[EnemyData]:
	return [
		preload("res://data/test/bat_data.tres"),
		preload("res://data/test/orc_data.tres"),
		preload("res://data/test/slime_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat1_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat2_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat3_data.tres"),
		preload("res://data/unit/unit_data/enemy/bat4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/block1_data.tres"),
		preload("res://data/unit/unit_data/enemy/block2_data.tres"),
		preload("res://data/unit/unit_data/enemy/block3_data.tres"),
		preload("res://data/unit/unit_data/enemy/block4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/carrot1_data.tres"),
		preload("res://data/unit/unit_data/enemy/carrot2_data.tres"),
		preload("res://data/unit/unit_data/enemy/carrot3_data.tres"),
		preload("res://data/unit/unit_data/enemy/carrot4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/drop1_data.tres"),
		preload("res://data/unit/unit_data/enemy/drop2_data.tres"),
		preload("res://data/unit/unit_data/enemy/drop3_data.tres"),
		preload("res://data/unit/unit_data/enemy/drop4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/ghost1_data.tres"),
		preload("res://data/unit/unit_data/enemy/ghost2_data.tres"),
		preload("res://data/unit/unit_data/enemy/ghost3_data.tres"),
		preload("res://data/unit/unit_data/enemy/ghost4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/madhand1_data.tres"),
		preload("res://data/unit/unit_data/enemy/madhand2_data.tres"),
		preload("res://data/unit/unit_data/enemy/madhand3_data.tres"),
		preload("res://data/unit/unit_data/enemy/madhand4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/slime1_data.tres"),
		preload("res://data/unit/unit_data/enemy/slime2_data.tres"),
		preload("res://data/unit/unit_data/enemy/slime3_data.tres"),
		preload("res://data/unit/unit_data/enemy/slime4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/soul1_data.tres"),
		preload("res://data/unit/unit_data/enemy/soul2_data.tres"),
		preload("res://data/unit/unit_data/enemy/soul3_data.tres"),
		preload("res://data/unit/unit_data/enemy/soul4_data.tres"),
		
		preload("res://data/unit/unit_data/enemy/stump1_data.tres"),
		preload("res://data/unit/unit_data/enemy/stump2_data.tres"),
		preload("res://data/unit/unit_data/enemy/stump3_data.tres"),
		preload("res://data/unit/unit_data/enemy/stump4_data.tres")
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
