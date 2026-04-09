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


func resize_inventory(new_max_slots: int) -> void:
	if new_max_slots <= 0:
		return

	if new_max_slots == max_slots and items.size() == max_slots:
		return

	var old_items: Array[Dictionary] = get_all_items()
	max_slots = new_max_slots

	items.clear()
	for i in range(max_slots):
		items.append(_make_empty_slot())

	for i in range(min(old_items.size(), max_slots)):
		items[i] = _normalize_entry(old_items[i])


func _make_empty_slot() -> Dictionary:
	return {
		"item_id": "",
		"amount": 0
	}


func _normalize_entry(entry: Dictionary) -> Dictionary:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return _make_empty_slot()

	var result: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}

	if entry.has("instance_data"):
		var instance_data: Variant = entry.get("instance_data", {})
		if typeof(instance_data) == TYPE_DICTIONARY and not instance_data.is_empty():
			result["instance_data"] = (instance_data as Dictionary).duplicate(true)

	return result


func _has_instance_data(entry: Dictionary) -> bool:
	if not entry.has("instance_data"):
		return false

	var instance_data: Variant = entry.get("instance_data", null)
	return typeof(instance_data) == TYPE_DICTIONARY and not (instance_data as Dictionary).is_empty()


func _is_equipment_entry(entry: Dictionary) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return false

	var equipment_resource = ItemDatabase.get_equipment_resource(item_id)
	return equipment_resource != null


func _can_stack_entry(entry: Dictionary) -> bool:
	if _has_instance_data(entry):
		return false

	if _is_equipment_entry(entry):
		return false

	return true


func is_same_item_instance(a: Dictionary, b: Dictionary) -> bool:
	var a_normalized: Dictionary = _normalize_entry(a)
	var b_normalized: Dictionary = _normalize_entry(b)

	if String(a_normalized.get("item_id", "")) != String(b_normalized.get("item_id", "")):
		return false

	var a_has_instance: bool = _has_instance_data(a_normalized)
	var b_has_instance: bool = _has_instance_data(b_normalized)

	if a_has_instance != b_has_instance:
		return false

	if not a_has_instance and not b_has_instance:
		return true

	var a_instance: Dictionary = a_normalized.get("instance_data", {})
	var b_instance: Dictionary = b_normalized.get("instance_data", {})
	return a_instance == b_instance


func is_valid_index(index: int) -> bool:
	return index >= 0 and index < items.size()


func is_slot_empty(index: int) -> bool:
	if not is_valid_index(index):
		return true

	var entry: Dictionary = items[index]
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	return item_id == "" or amount <= 0


func get_item_data_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {}

	return items[index].duplicate(true)


func set_item_data_at(index: int, entry: Dictionary) -> bool:
	if not is_valid_index(index):
		return false

	items[index] = _normalize_entry(entry)
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

	var entry: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}
	return add_item_entry(entry)


func add_item_entry(entry: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_entry(entry)
	var item_id: String = String(normalized.get("item_id", ""))
	var amount: int = int(normalized.get("amount", 0))

	if item_id == "" or amount <= 0:
		return false

	if not _can_stack_entry(normalized):
		if amount == 1:
			var empty_index: int = find_first_empty_slot()
			if empty_index < 0:
				return false
			items[empty_index] = normalized.duplicate(true)
			return true

		var remaining_non_stack: int = amount
		while remaining_non_stack > 0:
			var empty_slot_index: int = find_first_empty_slot()
			if empty_slot_index < 0:
				return false

			var single_entry: Dictionary = normalized.duplicate(true)
			single_entry["amount"] = 1
			items[empty_slot_index] = single_entry
			remaining_non_stack -= 1

		return true

	var max_stack: int = ItemDatabase.get_max_stack(item_id)
	var remaining: int = amount

	for i in range(items.size()):
		var existing: Dictionary = items[i]
		if not is_same_item_instance(existing, normalized):
			continue

		var current_amount: int = int(existing.get("amount", 0))
		if current_amount >= max_stack:
			continue

		var addable: int = min(max_stack - current_amount, remaining)
		existing["amount"] = current_amount + addable
		items[i] = existing
		remaining -= addable

		if remaining <= 0:
			return true

	for i in range(items.size()):
		if not is_slot_empty(i):
			continue

		var addable: int = min(max_stack, remaining)
		var new_entry: Dictionary = normalized.duplicate(true)
		new_entry["amount"] = addable
		items[i] = new_entry
		remaining -= addable

		if remaining <= 0:
			return true

	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	var remaining: int = amount

	for i in range(items.size()):
		var entry: Dictionary = items[i]
		if String(entry.get("item_id", "")) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = int(entry.get("amount", 0))
		if current_amount <= 0:
			continue

		var removable: int = min(current_amount, remaining)
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


func remove_item_entry(target_entry: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_entry(target_entry)
	if String(normalized.get("item_id", "")) == "":
		return false

	for i in range(items.size()):
		if is_same_item_instance(items[i], normalized):
			var current_amount: int = int(items[i].get("amount", 0))
			if current_amount <= 1:
				items[i] = _make_empty_slot()
			else:
				var entry: Dictionary = items[i].duplicate(true)
				entry["amount"] = current_amount - 1
				items[i] = entry
			return true

	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_amount(item_id) >= amount


func has_item_entry(target_entry: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_entry(target_entry)
	for entry in items:
		if is_same_item_instance(entry, normalized):
			return true
	return false


func get_item_amount(item_id: String) -> int:
	var total: int = 0

	for entry in items:
		if String(entry.get("item_id", "")) == item_id and not _has_instance_data(entry):
			total += int(entry.get("amount", 0))

	return total


func get_total_amount(item_id: String) -> int:
	var total: int = 0

	for entry in items:
		if String(entry.get("item_id", "")) == item_id:
			total += int(entry.get("amount", 0))

	return total


func can_consume_item_amount(item_id: String, amount: int) -> bool:
	if item_id == "":
		return false

	if amount <= 0:
		return true

	return get_item_amount(item_id) >= amount


func consume_item_amount(item_id: String, amount: int) -> bool:
	if item_id == "":
		return false

	if amount <= 0:
		return true

	if not can_consume_item_amount(item_id, amount):
		return false

	var remaining: int = amount

	for i in range(items.size()):
		if remaining <= 0:
			break

		var entry: Dictionary = items[i]
		if String(entry.get("item_id", "")) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = int(entry.get("amount", 0))
		if current_amount <= 0:
			continue

		if current_amount <= remaining:
			remaining -= current_amount
			items[i] = _make_empty_slot()
		else:
			entry["amount"] = current_amount - remaining
			items[i] = entry
			remaining = 0
			break

	return remaining <= 0


func force_add_item_amount(item_id: String, amount: int) -> bool:
	if item_id == "":
		return false

	if amount <= 0:
		return true

	return add_item(item_id, amount)


func can_add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	var entry: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}
	return can_add_item_entry(entry)


func can_add_item_entry(entry: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_entry(entry)
	var item_id: String = String(normalized.get("item_id", ""))
	var amount: int = int(normalized.get("amount", 0))

	if item_id == "" or amount <= 0:
		return false

	if not _can_stack_entry(normalized):
		var empty_slots: int = 0
		for i in range(items.size()):
			if is_slot_empty(i):
				empty_slots += 1
		return empty_slots >= amount

	var max_stack: int = ItemDatabase.get_max_stack(item_id)
	var capacity: int = 0

	for existing in items:
		var existing_id: String = String(existing.get("item_id", ""))
		var existing_amount: int = int(existing.get("amount", 0))

		if is_same_item_instance(existing, normalized):
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
	var result: Array = []

	for entry in items:
		result.append(_normalize_entry(entry))

	return result


func load_inventory_data(data: Array) -> void:
	initialize_empty_slots()

	for i in range(min(data.size(), max_slots)):
		var entry = data[i]

		if typeof(entry) != TYPE_DICTIONARY:
			continue

		items[i] = _normalize_entry(entry)


func use_item_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {
			"success": false,
			"item_id": "",
			"message": "範囲外"
		}

	var entry: Dictionary = items[index]
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))

	if item_id == "" or amount <= 0:
		return {
			"success": false,
			"item_id": "",
			"message": "空スロット"
		}

	if _has_instance_data(entry):
		return {
			"success": false,
			"item_id": item_id,
			"message": "個体装備はここでは使用できない"
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
