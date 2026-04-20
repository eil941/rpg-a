extends Resource
class_name SpawnRuleData

@export var rule_id: String = ""
@export_enum("ENEMY", "NPC") var spawn_kind: String = "ENEMY"

@export var allowed_generator_types: Array[String] = []
@export var min_area_difficulty: int = -1
@export var max_area_difficulty: int = -1

@export var min_enemy_difficulty: int = -1
@export var max_enemy_difficulty: int = -1

@export var use_hour_range: bool = false
@export_range(0, 23) var start_hour: int = 0
@export_range(0, 23) var end_hour: int = 23

@export var min_distance_from_start: int = -1
@export var max_distance_from_start: int = -1

@export var max_spawn_count: int = 1
@export var weight: int = 1
@export var enabled: bool = true
