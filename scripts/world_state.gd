extends Node

var unit_states: Dictionary = {}

var map_enemy_spawns: Dictionary = {}
var map_npc_spawns: Dictionary = {}

func clear_enemy_spawns() -> void:
	map_enemy_spawns.clear()
	unit_states.clear()
