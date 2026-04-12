extends Node

var unit_states: Dictionary = {}

var map_enemy_spawns: Dictionary = {}
var map_npc_spawns: Dictionary = {}

var map_tile_data: Dictionary = {}
var dungeon_map_data: Dictionary = {}

var field_detail_map_data: Dictionary = {}

var field_dungeon_entrances: Dictionary = {}
var dungeon_data: Dictionary = {}
var dungeon_floor_data: Dictionary = {}

var field_special_places: Dictionary = {}

var map_item_pickups: Dictionary = {}
var map_chests: Dictionary = {}

# =========================
# Quest
# =========================
var quest_active_data: Dictionary = {}
var quest_completed_data: Dictionary = {}
var quest_failed_data: Dictionary = {}

# unitごとの提示依頼キャッシュ
# unit_id -> Array[Dictionary]
var unit_generated_quests: Dictionary = {}



func clear_enemy_spawns() -> void:
	map_enemy_spawns.clear()
	unit_states.clear()
