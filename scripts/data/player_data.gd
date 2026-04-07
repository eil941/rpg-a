extends Node

var max_hp: int = 20
var hp: int = 2000
var attack: int = 1
var defense: int = 2
var speed: float = 120.0

var extended_stats_data: Dictionary = {}
var skills_data: Dictionary = {}

var current_map_id: String = ""
var current_tile: Vector2i = Vector2i.ZERO

var last_map_id: String = ""
var last_tile: Vector2i = Vector2i.ZERO

var map_positions: Dictionary = {}

var inventory_data: Array = []

var equipment_data: Dictionary = {
	"right_hand": "",
	"left_hand": "",
	"head": "",
	"body": "",
	"hands": "",
	"waist": "",
	"feet": "",
	"accessory_1": "",
	"accessory_2": "",
	"accessory_3": "",
	"accessory_4": ""
}

var debug_start_items_applied: bool = false
