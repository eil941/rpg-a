extends Node
class_name Inventory

@export var max_slots: int = 20

var items: Array[Dictionary] = []


func _ready() -> void:
	initialize_empty_slots()


func initialize_empty_slots() -> void:
	items.clear()

	for i in range(max_slots):
		items.append(_make_empty_slot())


func _make_empty_slot() -> Dictionary:
	return {
		"item_id": "",
		"amount": 0
	}


func is_valid_index(index: int) -> bool:
	return index >= 0 and index < items.size()


func is_slot_empty(index: int) -> bool:
	if not is_valid_index(index):
		return true

	var entry = items[index]
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))
	return item_id == "" or amount <= 0


func get_item_data_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {}

	return items[index].duplicate(true)


func set_item_data_at(index: int, entry: Dictionary) -> bool:
	if not is_valid_index(index):
		return false

	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		items[index] = _make_empty_slot()
		return true

	items[index] = {
		"item_id": item_id,
		"amount": amount
	}
	return true


func clear_slot(index: int) -> bool:
	if not is_valid_index(index):
		return false

	items[index] = _make_empty_slot()
	return true


func find_first_empty_slot() -> int:
	for i in range(items.size()):
		if is_slot_empty(i):
			return i
	return -1


func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	var max_stack = ItemDatabase.get_max_stack(item_id)
	var remaining = amount

	for i in range(items.size()):
		var entry = items[i]
		if String(entry.get("item_id", "")) != item_id:
			continue

		var current_amount = int(entry.get("amount", 0))
		if current_amount >= max_stack:
			continue

		var addable = min(max_stack - current_amount, remaining)
		entry["amount"] = current_amount + addable
		items[i] = entry
		remaining -= addable

		if remaining <= 0:
			return true

	for i in range(items.size()):
		var entry = items[i]
		var existing_id = String(entry.get("item_id", ""))
		var existing_amount = int(entry.get("amount", 0))

		if existing_id != "" or existing_amount > 0:
			continue

		var addable = min(max_stack, remaining)
		items[i] = {
			"item_id": item_id,
			"amount": addable
		}
		remaining -= addable

		if remaining <= 0:
			return true

	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	var remaining = amount

	for i in range(items.size()):
		var entry = items[i]
		if String(entry.get("item_id", "")) != item_id:
			continue

		var current_amount = int(entry.get("amount", 0))
		if current_amount <= 0:
			continue

		var removable = min(current_amount, remaining)
		current_amount -= removable
		remaining -= removable

		if current_amount <= 0:
			items[i] = _make_empty_slot()
		else:
			entry["amount"] = current_amount
			items[i] = entry

		if remaining <= 0:
			return true

	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_amount(item_id) >= amount


func get_item_amount(item_id: String) -> int:
	var total = 0

	for entry in items:
		if String(entry.get("item_id", "")) == item_id:
			total += int(entry.get("amount", 0))

	return total


func can_add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	var max_stack = ItemDatabase.get_max_stack(item_id)
	var capacity = 0

	for entry in items:
		var existing_id = String(entry.get("item_id", ""))
		var existing_amount = int(entry.get("amount", 0))

		if existing_id == item_id:
			capacity += max(0, max_stack - existing_amount)
		elif existing_id == "" or existing_amount <= 0:
			capacity += max_stack

	return capacity >= amount


func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in items:
		result.append(entry.duplicate(true))

	return result


func clear_inventory() -> void:
	initialize_empty_slots()


func save_inventory_data() -> Array:
	var result = []

	for entry in items:
		var item_id = String(entry.get("item_id", ""))
		var amount = int(entry.get("amount", 0))

		result.append({
			"item_id": item_id,
			"amount": amount
		})

	return result


func load_inventory_data(data: Array) -> void:
	initialize_empty_slots()

	for i in range(min(data.size(), max_slots)):
		var entry = data[i]

		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var item_id = String(entry.get("item_id", ""))
		var amount = int(entry.get("amount", 0))

		if item_id == "" or amount <= 0:
			items[i] = _make_empty_slot()
		else:
			items[i] = {
				"item_id": item_id,
				"amount": amount
			}


func use_item_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {
			"success": false,
			"item_id": "",
			"message": "範囲外"
		}

	var entry = items[index]
	var item_id = String(entry.get("item_id", ""))
	var amount = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return {
			"success": false,
			"item_id": "",
			"message": "空スロット"
		}

	if not ItemDatabase.is_usable(item_id):
		return {
			"success": false,
			"item_id": item_id,
			"message": "このアイテムは使用できない"
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
		items[index] = _make_empty_slot()
	else:
		entry["amount"] = amount
		items[index] = entry

	return {
		"success": true,
		"item_id": item_id,
		"message": "%sを使用した" % ItemDatabase.get_display_name(item_id)
	}
