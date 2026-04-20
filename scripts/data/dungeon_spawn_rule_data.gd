extends Resource
class_name DungeonSpawnRuleData

@export var rule_id: String = ""
@export_enum("ENEMY", "NPC") var spawn_kind: String = "ENEMY"

# ダンジョンの傾向
@export var allowed_generator_themes: Array[String] = []

# 実レイアウト側でも絞りたい時だけ使う
@export var allowed_layout_generator_types: Array[String] = []

# floor の実効難易度に対する条件
@export var min_floor_difficulty: int = -1
@export var max_floor_difficulty: int = -1

# 階数に対する条件
@export var min_floor_number: int = -1
@export var max_floor_number: int = -1

# 出現させる敵個体の難易度帯
@export var min_enemy_difficulty: int = -1
@export var max_enemy_difficulty: int = -1

@export var max_spawn_count: int = 1
@export var weight: int = 1
@export var enabled: bool = true
