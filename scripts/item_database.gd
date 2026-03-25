extends Node
class_name ItemDatabase

static var ITEM_DATA := {
	"potion": {
		"display_name": "Potion",
		"icon": preload("res://assets/items/potion.png"),
		"max_stack": 10,
		"effect_type": "heal_hp",
		"effect_value": 20
	},
	"wood": {
		"display_name": "Wood",
		"icon": preload("res://assets/items/wood.png"),
		"max_stack": 99,
		"effect_type": "log_only",
		"effect_value": 0
	},
	"apple": {
		"display_name": "Apple",
		"icon": preload("res://assets/items/apple.png"),
		"max_stack": 20,
		"effect_type": "heal_hp",
		"effect_value": 5
	}
}


static func get_item_data(item_id: String) -> Dictionary:
	return ITEM_DATA.get(item_id, {})


static func get_display_name(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("display_name", item_id))


static func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_data(item_id)
	return data.get("icon", null)


static func get_max_stack(item_id: String) -> int:
	var data = get_item_data(item_id)
	return int(data.get("max_stack", 99))


static func get_effect_type(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("effect_type", "log_only"))


static func get_effect_value(item_id: String) -> int:
	var data = get_item_data(item_id)
	return int(data.get("effect_value", 0))
