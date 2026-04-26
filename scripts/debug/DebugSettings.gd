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
	#{"item_id": "knife", "amount": 1},
	#{"item_id": "bow", "amount": 1},
	#{"item_id": "cloth_armor", "amount": 1},
	#{"item_id": "power_ring", "amount": 1},
	#{"item_id": "potion", "amount": 90},
	#{"item_id": "healing_potion","amount":10 },
	#{"item_id": "mushroom_bad","amount":10 },
	#{"item_id": "paralysis_cure_potion","amount":10 },
	#{"item_id": "potion_of_strength","amount":10 },
	{"item_id": "teleport_stone","amount":10 },
	#{"item_id": "poison_cure_potion","amount":10 },
	
	# phase1 items
	#{"item_id": "fire_bottle", "amount": 10},
	#{"item_id": "frost_bottle", "amount": 10},
	#{"item_id": "sleep_orb", "amount": 10},
	#{"item_id": "confusion_mushroom", "amount": 10},
	#{"item_id": "softening_powder", "amount": 10},
	#{"item_id": "slow_slime", "amount": 10},
	#{"item_id": "blur_powder", "amount": 10},
	#{"item_id": "snare_smoke", "amount": 10},
	#{"item_id": "calm_breaker", "amount": 10},
	#{"item_id": "blast_stone", "amount": 10},
	#{"item_id": "guard_tonic", "amount": 10},
	#{"item_id": "swift_tonic", "amount": 10},
	#{"item_id": "focus_tonic", "amount": 10},
	#{"item_id": "dodge_tonic", "amount": 10},
	#{"item_id": "crit_oil", "amount": 10},
	#{"item_id": "life_seed", "amount": 10},
	
	#{"item_id":"supply_bag","amount":10},
	#{"item_id":"small_gold_pouch","amount":10},
	
	#{"item_id":"hallucination_powder","amount":10},
	#{"item_id":"blind_sand","amount":10},
	#{"item_id":"curse_orb","amount":10},
	{"item_id":"bread","amount":10},
	{"item_id":"apple","amount":10},
	{"item_id":"meat_skewer","amount":10},
	{"item_id":"travel_ration","amount":10},
	
]

var debug_item_spawn: bool = true
