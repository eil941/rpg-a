extends Node
class_name ItemDatabase

static var ITEM_DATA = {
	"potion": {
		"display_name": "Potion",
		"description": "HPを20回復する。",
		"icon": preload("res://assets/items/potion.png"),
		"max_stack": 10,
		"item_type": "consumable",
		"usable": true,
		"effect_type": "heal_hp",
		"effect_value": 20
	},
	"wood": {
		"display_name": "Wood",
		"description": "クラフトなどに使う素材。",
		"icon": preload("res://assets/items/wood.png"),
		"max_stack": 99,
		"item_type": "material",
		"usable": false,
		"effect_type": "log_only",
		"effect_value": 0
	},
	"apple": {
		"display_name": "Apple",
		"description": "HPを5回復する。",
		"icon": preload("res://assets/items/apple.png"),
		"max_stack": 20,
		"item_type": "consumable",
		"usable": true,
		"effect_type": "heal_hp",
		"effect_value": 5
	}

	# 装備品はこういう形で追加
	# "bronze_sword": {
	# 	"display_name": "Bronze Sword",
	# 	"description": "基本的な剣。",
	# 	"icon": preload("res://assets/items/bronze_sword.png"),
	# 	"max_stack": 1,
	# 	"item_type": "equipment",
	# 	"usable": false,
	# 	"equipment_slot": "weapon",
	# 	"equipment_resource": preload("res://data/equipment/bronze_sword.tres")
	# }
}


static func get_item_data(item_id: String) -> Dictionary:
	return ITEM_DATA.get(item_id, {})


static func get_display_name(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("display_name", item_id))


static func get_description(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("description", ""))


static func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_data(item_id)
	return data.get("icon", null)


static func get_max_stack(item_id: String) -> int:
	var data = get_item_data(item_id)
	return int(data.get("max_stack", 99))


static func get_item_type(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("item_type", "misc"))


static func is_usable(item_id: String) -> bool:
	var data = get_item_data(item_id)
	return bool(data.get("usable", false))


static func is_equipment(item_id: String) -> bool:
	return get_item_type(item_id) == "equipment"


static func get_equipment_slot(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("equipment_slot", ""))


static func get_equipment_resource(item_id: String):
	var data = get_item_data(item_id)
	return data.get("equipment_resource", null)


static func get_effect_type(item_id: String) -> String:
	var data = get_item_data(item_id)
	return String(data.get("effect_type", "log_only"))


static func get_effect_value(item_id: String) -> int:
	var data = get_item_data(item_id)
	return int(data.get("effect_value", 0))
