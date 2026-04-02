extends Node

var max_hp: int = 20
var hp: int = 2000
var attack: int = 1
var defense: int = 2
var speed: float = 120.0

var current_map_id: String = ""
var current_tile: Vector2i = Vector2i.ZERO

var last_map_id: String = ""
var last_tile: Vector2i = Vector2i.ZERO

var map_positions: Dictionary = {}

var inventory_data: Array = []

var equipment_data: Dictionary = {
	"weapon": "",
	"armor": "",
	"accessory": ""
}

# デバッグ用初期アイテムをすでに配ったか
# シーン移動のたびに増殖しないように使う
var debug_start_items_applied: bool = false
