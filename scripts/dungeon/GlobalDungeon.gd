extends Node

var current_dungeon_id: String = ""
var current_floor: int = 1

# 旧互換用。必要なら参照できるように残す
var current_generator_type: String = ""

# ダンジョン全体の傾向
# 例: NATURAL, FORTIFIED, RUINED, ARTIFICIAL, CHAOTIC
var current_generator_theme: String = ""

# その階で実際に使われる内部レイアウト生成タイプ
# 例: ROOM, CAVE, RUINS, CROSS, ARENA, LINEAR, RINGS, MAZE
var current_layout_generator_type: String = ""

var return_field_map_id: String = ""
var return_field_cell: Vector2i = Vector2i.ZERO

# "RETURN" なら上に戻る階段。実際のタイルは DungeonTileVisualConfig 側で決める。
# "NEXT" なら下に進む階段。実際のタイルは DungeonTileVisualConfig 側で決める。
var pending_spawn_stair_type: String = "RETURN"
