extends Node

var debug_free_action: bool = false
var print_tile_info: bool = false
var debug_damage_calculate: bool = false
var debug_enchant: bool = true

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

# =========================================
# デバッグ用: プレイヤー初期アイテム付与
# =========================================
# true のとき、プレイヤーにだけ下のアイテムを一度だけ配布する
# 装備欄には直接入れず、インベントリへ追加する
var debug_give_player_start_items: bool = true

# 例:
# [
#   {"item_id": "knife", "amount": 1},
#   {"item_id": "cloth_armor", "amount": 1},
#   {"item_id": "power_ring", "amount": 1},
#   {"item_id": "potion", "amount": 3}
# ]
var debug_player_start_items: Array[Dictionary] = [
	{"item_id": "knife", "amount": 1},
	{"item_id": "bow", "amount": 1},
	{"item_id": "cloth_armor", "amount": 1},
	{"item_id": "power_ring", "amount": 1},
	{"item_id": "potion", "amount": 90}
]
