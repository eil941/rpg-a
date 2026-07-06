extends Node

#HP上限値
var max_hp: int = 2000
#現在のHP
var hp: int = 2000
var attack: int = 10
var defense: int = 200
var speed: float = 120.0

var extended_stats_data: Dictionary = {}
var skills_data: Dictionary = {}
var skill_state_data: Dictionary = {}

var current_map_id: String = ""
var current_tile: Vector2i = Vector2i.ZERO

var last_map_id: String = ""
var last_tile: Vector2i = Vector2i.ZERO

var map_positions: Dictionary = {}

# Inventory.save_inventory_full_data() は Dictionary を返す。
# 旧データ互換の Array も Inventory.load_inventory_data() 側で読めるため、Variantで保持する。
var inventory_data: Variant = []

var equipment_data: Dictionary = {
	"right_hand": {},
	"left_hand": {},
	"head": {},
	"body": {},
	"hands": {},
	"waist": {},
	"feet": {},
	"accessory_1": {},
	"accessory_2": {},
	"accessory_3": {},
	"accessory_4": {}
}

var effect_runtimes_data: Array = []
var last_effect_update_time: float = 0.0

var debug_start_items_applied: bool = false
var held_inventory_entry: Dictionary = {}
var held_inventory_source_area: String = ""
var held_inventory_source_index: int = -1
var held_inventory_source_slot_name: String = ""
var held_inventory_previous_ui_mode: String = ""

func reset_for_new_game() -> void:
	max_hp = 2000
	hp = 2000
	attack = 10
	defense = 200
	speed = 120.0

	extended_stats_data.clear()
	skills_data.clear()
	skill_state_data.clear()

	current_map_id = ""
	current_tile = Vector2i.ZERO
	last_map_id = ""
	last_tile = Vector2i.ZERO
	map_positions.clear()

	inventory_data = []

	equipment_data = {
		"right_hand": {},
		"left_hand": {},
		"head": {},
		"body": {},
		"hands": {},
		"waist": {},
		"feet": {},
		"accessory_1": {},
		"accessory_2": {},
		"accessory_3": {},
		"accessory_4": {}
	}

	effect_runtimes_data.clear()
	last_effect_update_time = 0.0
	debug_start_items_applied = false
	clear_held_inventory_state()


func set_held_inventory_state(entry: Dictionary, source_area: String, source_index: int, source_slot_name: String, previous_ui_mode: String = "") -> void:
	held_inventory_entry = entry.duplicate(true)
	held_inventory_source_area = source_area
	held_inventory_source_index = source_index
	held_inventory_source_slot_name = source_slot_name
	held_inventory_previous_ui_mode = previous_ui_mode


func clear_held_inventory_state() -> void:
	held_inventory_entry = {}
	held_inventory_source_area = ""
	held_inventory_source_index = -1
	held_inventory_source_slot_name = ""
	held_inventory_previous_ui_mode = ""
