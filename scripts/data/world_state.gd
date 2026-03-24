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

func clear_enemy_spawns() -> void:
	map_enemy_spawns.clear()
	unit_states.clear()
