extends Node

var current_dungeon_id = ""
var current_floor = 1
var current_generator_type = ""

var return_field_map_id = ""
var return_field_cell = Vector2i.ZERO

# "RETURN" なら戻る階段(source_id=3)
# "NEXT" なら進む階段(source_id=6)
var pending_spawn_stair_type = "RETURN"
