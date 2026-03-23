extends Node
class_name Inventory

@export var max_slots: int = 20

var items: Array[Dictionary] = []


func _ready() -> void:
	ensure_slot_size()


func ensure_slot_size() -> void:
	while items.size() < max_slots:
		items.append(_create_empty_slot())

	if items.size() > max_slots:
		items.resize(max_slots)


func _create_empty_slot() -> Dictionary:
	return {
		"item_id": "",
		"amount": 0
	}


func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	ensure_slot_size()

	# まず同じ item_id のスロットに加算
	for i in range(items.size()):
		if String(items[i].get("item_id", "")) == item_id:
			items[i]["amount"] = int(items[i].get("amount", 0)) + amount
			return true

	# 次に空スロットへ格納
	for i in range(items.size()):
		if String(items[i].get("item_id", "")) == "":
			items[i]["item_id"] = item_id
			items[i]["amount"] = amount
			return true

	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	ensure_slot_size()

	for i in range(items.size()):
		if String(items[i].get("item_id", "")) == item_id:
			var current_amount := int(items[i].get("amount", 0))
			if current_amount < amount:
				return false

			current_amount -= amount

			if current_amount <= 0:
				items[i] = _create_empty_slot()
			else:
				items[i]["amount"] = current_amount

			return true

	return false


func get_item_amount(item_id: String) -> int:
	ensure_slot_size()

	for i in range(items.size()):
		if String(items[i].get("item_id", "")) == item_id:
			return int(items[i].get("amount", 0))

	return 0


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_amount(item_id) >= amount


func get_all_items() -> Array[Dictionary]:
	ensure_slot_size()

	var result: Array[Dictionary] = []
	for entry in items:
		result.append(entry.duplicate(true))
	return result


func get_item_data_at(index: int) -> Dictionary:
	ensure_slot_size()

	if index < 0 or index >= items.size():
		return {}

	return items[index].duplicate(true)


func clear_inventory() -> void:
	items.clear()
	ensure_slot_size()


func save_inventory_data() -> Array:
	ensure_slot_size()

	var result: Array = []
	for entry in items:
		result.append({
			"item_id": String(entry.get("item_id", "")),
			"amount": int(entry.get("amount", 0))
		})
	return result


func load_inventory_data(data: Array) -> void:
	items.clear()

	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			items.append(_create_empty_slot())
			continue

		var item_id := String(entry.get("item_id", ""))
		var amount := int(entry.get("amount", 0))

		if item_id == "" or amount <= 0:
			items.append(_create_empty_slot())
		else:
			items.append({
				"item_id": item_id,
				"amount": amount
			})

	ensure_slot_size()


func use_item_at(index: int) -> Dictionary:
	ensure_slot_size()

	if index < 0 or index >= items.size():
		return {
			"success": false,
			"item_id": "",
			"message": "範囲外"
		}

	var entry = items[index]
	var item_id := String(entry.get("item_id", ""))
	var amount := int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return {
			"success": false,
			"item_id": "",
			"message": "空スロット"
		}

	var owner_unit = get_parent()

	if not ItemEffectManager.apply_item_effect(owner_unit, item_id):
		return {
			"success": false,
			"item_id": item_id,
			"message": "使用失敗"
		}

	amount -= 1

	if amount <= 0:
		items[index] = _create_empty_slot()
	else:
		items[index]["amount"] = amount

	advance_time_after_use(owner_unit)

	return {
		"success": true,
		"item_id": item_id,
		"message": "%sを使用した" % ItemDatabase.get_item_name(item_id)
	}


func advance_time_after_use(owner_unit) -> void:
	if owner_unit == null:
		return

	var units_node = owner_unit.get("units_node")
	if units_node == null:
		return

	if owner_unit.stats == null:
		return

	TimeManager.advance_time(units_node, owner_unit.stats.speed)
	TimeManager.resolve_ai_turns(units_node)
