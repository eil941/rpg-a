extends Node
class_name ItemDatabase

static var ITEM_DATA := {
	"potion": {
		"name": "Potion",
		"consumable": true,
		"effect_type": "heal_hp",
		"effect_value": 5,
		"icon_path": "res://assets/items/potion.png"
	},
	"wood": {
		"name": "Wood",
		"consumable": true,
		"effect_type": "log_only",
		"effect_value": 0,
		"icon_path": "res://assets/items/wood.png"
	},
	"apple": {
		"name": "Apple",
		"consumable": true,
		"effect_type": "heal_hp",
		"effect_value": 2,
		"icon_path": "res://assets/items/apple.png"
	}
}


static func has_item_data(item_id: String) -> bool:
	return ITEM_DATA.has(item_id)


static func get_item_data(item_id: String) -> Dictionary:
	if not ITEM_DATA.has(item_id):
		return {}
	return ITEM_DATA[item_id].duplicate(true)


static func get_item_name(item_id: String) -> String:
	var data = get_item_data(item_id)
	if data.is_empty():
		return item_id
	return String(data.get("name", item_id))


static func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_data(item_id)
	if data.is_empty():
		return null

	var icon_path := String(data.get("icon_path", ""))
	if icon_path == "":
		return null

	return load(icon_path) as Texture2D
