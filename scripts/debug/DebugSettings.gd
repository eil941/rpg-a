extends Node

var debug_free_action: bool = false
var print_tile_info: bool = false
var debug_damage_calculate: bool = false

# AI 全般
var debug_ai: bool = false
var debug_ai_turn: bool = false
var debug_ai_target: bool = false
var debug_ai_candidates: bool = false
var debug_ai_attack: bool = false
var debug_ai_move: bool = false

# unit / data 適用確認
var debug_ai_style_apply: bool = false
var debug_npc_ai: bool = false
var debug_enemy_ai: bool = false

# 逃走AI確認
var debug_flee_ai: bool = false

# 必要なら対象を絞る用
# 空文字なら全対象
var debug_ai_unit_name_filter: String = ""
var debug_ai_unit_id_filter: String = ""
