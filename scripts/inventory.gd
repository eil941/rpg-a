extends Node
class_name Inventory

@export var max_slots: int = 20

var items: Array[Dictionary] = []
# 例:
# [
#   {"item_id": "potion", "amount": 3},
#   {"item_id": "wood", "amount": 5}
# ]


func add_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	for entry in items:
		if entry.get("item_id", "") == item_id:
			entry["amount"] += amount
			return true

	if items.size() >= max_slots:
		return false

	items.append({
		"item_id": item_id,
		"amount": amount
	})
	return true


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false

	for i in range(items.size()):
		var entry = items[i]
		if entry.get("item_id", "") == item_id:
			var current_amount: int = int(entry.get("amount", 0))

			if current_amount < amount:
				return false

			current_amount -= amount

			if current_amount <= 0:
				items.remove_at(i)
			else:
				entry["amount"] = current_amount
				items[i] = entry

			return true

	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_amount(item_id) >= amount


func get_item_amount(item_id: String) -> int:
	for entry in items:
		if entry.get("item_id", "") == item_id:
			return int(entry.get("amount", 0))
	return 0


func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in items:
		result.append(entry.duplicate(true))

	return result


func clear_inventory() -> void:
	items.clear()


func save_inventory_data() -> Array:
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
			continue

		var item_id := String(entry.get("item_id", ""))
		var amount := int(entry.get("amount", 0))

		if item_id == "" or amount <= 0:
			continue

		items.append({
			"item_id": item_id,
			"amount": amount
		})
