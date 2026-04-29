extends Node
class_name Inventory


# =========================
# Slot layout / slot count
# =========================
# スロット総数の本体は slot_columns × slot_rows。
# InventoryUI 側でスロット総数を決めない。
#
# 例:
# プレイヤー: 9列 × 4段 = 36
# 商人:       9列 × 3段 = 27
# 小さい箱:   5列 × 3段 = 15
#
# max_slots は旧互換・キャッシュ用として残す。
# 直接編集する本命は slot_columns / slot_rows。

@export var slot_columns: int = 9
@export var slot_rows: int = 4

# 旧互換用。
# 現在は slot_columns * slot_rows に同期される。
@export var max_slots: int = 36

# ホットバーも Inventory が持つ独立した収納領域。
# 通常インベントリ items の先頭を表示するのではなく、
# hotbar_items 自体にアイテムを収納する。
@export var hotbar_slot_count: int = 9

var items: Array[Dictionary] = []
var hotbar_items: Array[Dictionary] = []


func _ready() -> void:
	initialize_empty_slots()


func get_slot_columns() -> int:
	return max(1, slot_columns)


func get_slot_rows() -> int:
	ensure_slot_count()
	return max(1, slot_rows)


func get_slot_count() -> int:
	ensure_slot_count()
	return max_slots


func set_slot_grid_size(new_columns: int, new_rows: int, keep_items: bool = true) -> void:
	new_columns = max(1, new_columns)
	new_rows = max(1, new_rows)

	var old_items: Array[Dictionary] = []
	if keep_items:
		old_items = get_all_items()

	slot_columns = new_columns
	slot_rows = new_rows
	_sync_max_slots_from_grid()

	items.clear()
	for i in range(max_slots):
		items.append(_make_empty_slot())

	if keep_items:
		for i in range(min(old_items.size(), max_slots)):
			items[i] = _normalize_entry(old_items[i])


func initialize_empty_slots() -> void:
	_sync_max_slots_from_grid()

	items.clear()
	for i in range(max_slots):
		items.append(_make_empty_slot())

	hotbar_items.clear()
	ensure_hotbar_slot_count()


func ensure_slot_count() -> void:
	_sync_max_slots_from_grid()
	ensure_hotbar_slot_count()

	# items の方が長い場合は、絶対に切り捨てない。
	# ここで切ると、下段のアイテム消失が起きる。
	if items.size() > max_slots:
		_expand_grid_to_fit_count(items.size())

	while items.size() < max_slots:
		items.append(_make_empty_slot())


func _sync_max_slots_from_grid() -> void:
	slot_columns = max(1, slot_columns)
	slot_rows = max(1, slot_rows)
	max_slots = slot_columns * slot_rows


func _expand_grid_to_fit_count(required_count: int) -> void:
	required_count = max(1, required_count)
	slot_columns = max(1, slot_columns)

	var required_rows: int = int(ceil(float(required_count) / float(slot_columns)))
	slot_rows = max(slot_rows, required_rows)
	_sync_max_slots_from_grid()


func _get_last_non_empty_slot_index(source_items: Array[Dictionary]) -> int:
	for i in range(source_items.size() - 1, -1, -1):
		var entry: Dictionary = _normalize_entry(source_items[i])
		if not _is_entry_empty(entry):
			return i

	return -1


# 旧コード互換用。
# new_max_slots を直接指定された場合も、現在の列数を維持して rows を自動調整する。
# ただし、入りきらない非空スロットがある場合は切り捨てず、必要な分だけ広げる。
func resize_inventory(new_max_slots: int) -> void:
	if new_max_slots <= 0:
		return

	var old_items: Array[Dictionary] = get_all_items()
	var last_non_empty_index: int = _get_last_non_empty_slot_index(old_items)
	var required_count: int = max(new_max_slots, last_non_empty_index + 1)

	slot_columns = max(1, slot_columns)
	slot_rows = max(1, int(ceil(float(required_count) / float(slot_columns))))
	_sync_max_slots_from_grid()

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
		if typeof(instance_data) == TYPE_DICTIONARY and not (instance_data as Dictionary).is_empty():
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


func _get_entry_item_id(entry: Dictionary) -> String:
	return String(entry.get("item_id", ""))


func _get_entry_amount(entry: Dictionary) -> int:
	return int(entry.get("amount", 0))


func _is_entry_empty(entry: Dictionary) -> bool:
	return _get_entry_item_id(entry) == "" or _get_entry_amount(entry) <= 0


func _count_empty_slots() -> int:
	ensure_slot_count()

	var empty_slots: int = 0

	for i in range(items.size()):
		if is_slot_empty(i):
			empty_slots += 1

	return empty_slots


func is_same_item_instance(a: Dictionary, b: Dictionary) -> bool:
	var a_normalized: Dictionary = _normalize_entry(a)
	var b_normalized: Dictionary = _normalize_entry(b)

	if _get_entry_item_id(a_normalized) != _get_entry_item_id(b_normalized):
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
	ensure_slot_count()
	return index >= 0 and index < items.size()


func is_slot_empty(index: int) -> bool:
	if not is_valid_index(index):
		return true

	var entry: Dictionary = items[index]
	return _is_entry_empty(entry)


func get_item_data_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {}

	return items[index].duplicate(true)


func set_item_data_at(index: int, entry: Dictionary) -> bool:
	if not is_valid_index(index):
		return false

	items[index] = _normalize_entry(entry)
	return true


# =========================
# Hotbar slots
# =========================

func get_hotbar_slot_count() -> int:
	ensure_hotbar_slot_count()
	return hotbar_items.size()


func set_hotbar_slot_count(new_count: int, keep_items: bool = true) -> void:
	new_count = max(0, new_count)

	var old_items: Array[Dictionary] = []
	if keep_items:
		old_items = get_all_hotbar_items()

	hotbar_slot_count = new_count
	hotbar_items.clear()

	for i in range(hotbar_slot_count):
		hotbar_items.append(_make_empty_slot())

	if keep_items:
		for i in range(min(old_items.size(), hotbar_items.size())):
			hotbar_items[i] = _normalize_entry(old_items[i])


func ensure_hotbar_slot_count() -> void:
	hotbar_slot_count = max(0, hotbar_slot_count)

	while hotbar_items.size() < hotbar_slot_count:
		hotbar_items.append(_make_empty_slot())

	# hotbar_items の方が長い場合は切り捨てない。
	# 保存データ互換や一時的な設定ミスでアイテムが消えるのを防ぐ。
	if hotbar_items.size() > hotbar_slot_count:
		hotbar_slot_count = hotbar_items.size()


func is_valid_hotbar_index(index: int) -> bool:
	ensure_hotbar_slot_count()
	return index >= 0 and index < hotbar_items.size()


func is_hotbar_slot_empty(index: int) -> bool:
	if not is_valid_hotbar_index(index):
		return true

	return _is_entry_empty(hotbar_items[index])


func get_hotbar_item_data_at(index: int) -> Dictionary:
	if not is_valid_hotbar_index(index):
		return {}

	return hotbar_items[index].duplicate(true)


func set_hotbar_item_data_at(index: int, entry: Dictionary) -> bool:
	if not is_valid_hotbar_index(index):
		return false

	hotbar_items[index] = _normalize_entry(entry)
	return true


func clear_hotbar_slot(index: int) -> bool:
	if not is_valid_hotbar_index(index):
		return false

	hotbar_items[index] = _make_empty_slot()
	return true


func find_first_empty_hotbar_slot() -> int:
	ensure_hotbar_slot_count()

	for i in range(hotbar_items.size()):
		if is_hotbar_slot_empty(i):
			return i

	return -1


func get_all_hotbar_items() -> Array[Dictionary]:
	ensure_hotbar_slot_count()

	var result: Array[Dictionary] = []

	for entry in hotbar_items:
		result.append(entry.duplicate(true))

	return result


func use_hotbar_item_at(index: int) -> Dictionary:
	if not is_valid_hotbar_index(index):
		return {
			"success": false,
			"item_id": "",
			"message": "範囲外"
		}

	var entry: Dictionary = hotbar_items[index]
	var item_id: String = _get_entry_item_id(entry)
	var amount: int = _get_entry_amount(entry)

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
		hotbar_items[index] = _make_empty_slot()
	else:
		entry["amount"] = amount
		hotbar_items[index] = entry

	return {
		"success": true,
		"item_id": item_id,
		"message": "%sを使用した" % ItemDatabase.get_display_name(item_id)
	}

func clear_slot(index: int) -> bool:
	if not is_valid_index(index):
		return false

	items[index] = _make_empty_slot()
	return true


func find_first_empty_slot() -> int:
	ensure_slot_count()

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
	ensure_slot_count()

	var normalized: Dictionary = _normalize_entry(entry)
	var item_id: String = _get_entry_item_id(normalized)
	var amount: int = _get_entry_amount(normalized)

	if item_id == "" or amount <= 0:
		return false

	if not _can_stack_entry(normalized):
		return _add_non_stackable_entry(normalized, amount)

	return _add_stackable_entry(normalized, item_id, amount)


func _add_non_stackable_entry(normalized: Dictionary, amount: int) -> bool:
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


func _add_stackable_entry(normalized: Dictionary, item_id: String, amount: int) -> bool:
	var max_stack: int = ItemDatabase.get_max_stack(item_id)
	var remaining: int = amount

	for i in range(items.size()):
		var existing: Dictionary = items[i]
		if not is_same_item_instance(existing, normalized):
			continue

		var current_amount: int = _get_entry_amount(existing)
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

	ensure_slot_count()
	ensure_hotbar_slot_count()

	var remaining: int = amount

	for i in range(items.size()):
		var entry: Dictionary = items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = _get_entry_amount(entry)
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

	for i in range(hotbar_items.size()):
		var entry: Dictionary = hotbar_items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = _get_entry_amount(entry)
		if current_amount <= 0:
			continue

		var removable: int = min(current_amount, remaining)
		current_amount -= removable
		remaining -= removable

		if current_amount <= 0:
			hotbar_items[i] = _make_empty_slot()
		else:
			entry["amount"] = current_amount
			hotbar_items[i] = entry

		if remaining <= 0:
			return true

	return false

func remove_item_entry(target_entry: Dictionary) -> bool:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var normalized: Dictionary = _normalize_entry(target_entry)
	if _get_entry_item_id(normalized) == "":
		return false

	for i in range(items.size()):
		if is_same_item_instance(items[i], normalized):
			var current_amount: int = _get_entry_amount(items[i])
			if current_amount <= 1:
				items[i] = _make_empty_slot()
			else:
				var entry: Dictionary = items[i].duplicate(true)
				entry["amount"] = current_amount - 1
				items[i] = entry
			return true

	for i in range(hotbar_items.size()):
		if is_same_item_instance(hotbar_items[i], normalized):
			var current_amount: int = _get_entry_amount(hotbar_items[i])
			if current_amount <= 1:
				hotbar_items[i] = _make_empty_slot()
			else:
				var entry: Dictionary = hotbar_items[i].duplicate(true)
				entry["amount"] = current_amount - 1
				hotbar_items[i] = entry
			return true

	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_item_amount(item_id) >= amount


func has_item_entry(target_entry: Dictionary) -> bool:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var normalized: Dictionary = _normalize_entry(target_entry)

	for entry in items:
		if is_same_item_instance(entry, normalized):
			return true

	for entry in hotbar_items:
		if is_same_item_instance(entry, normalized):
			return true

	return false

func get_item_amount(item_id: String) -> int:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var total: int = 0

	for entry in items:
		if _get_entry_item_id(entry) == item_id and not _has_instance_data(entry):
			total += _get_entry_amount(entry)

	for entry in hotbar_items:
		if _get_entry_item_id(entry) == item_id and not _has_instance_data(entry):
			total += _get_entry_amount(entry)

	return total

func get_total_amount(item_id: String) -> int:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var total: int = 0

	for entry in items:
		if _get_entry_item_id(entry) == item_id:
			total += _get_entry_amount(entry)

	for entry in hotbar_items:
		if _get_entry_item_id(entry) == item_id:
			total += _get_entry_amount(entry)

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

	ensure_slot_count()
	ensure_hotbar_slot_count()

	var remaining: int = amount

	for i in range(items.size()):
		if remaining <= 0:
			break

		var entry: Dictionary = items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = _get_entry_amount(entry)
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

	for i in range(hotbar_items.size()):
		if remaining <= 0:
			break

		var entry: Dictionary = hotbar_items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		if _has_instance_data(entry):
			continue

		var current_amount: int = _get_entry_amount(entry)
		if current_amount <= 0:
			continue

		if current_amount <= remaining:
			remaining -= current_amount
			hotbar_items[i] = _make_empty_slot()
		else:
			entry["amount"] = current_amount - remaining
			hotbar_items[i] = entry
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
	ensure_slot_count()

	var normalized: Dictionary = _normalize_entry(entry)
	var item_id: String = _get_entry_item_id(normalized)
	var amount: int = _get_entry_amount(normalized)

	if item_id == "" or amount <= 0:
		return false

	if not _can_stack_entry(normalized):
		return _count_empty_slots() >= amount

	var max_stack: int = ItemDatabase.get_max_stack(item_id)
	var capacity: int = 0

	for existing in items:
		var existing_id: String = _get_entry_item_id(existing)
		var existing_amount: int = _get_entry_amount(existing)

		if is_same_item_instance(existing, normalized):
			capacity += max(0, max_stack - existing_amount)
		elif existing_id == "" or existing_amount <= 0:
			capacity += max_stack

	return capacity >= amount


func get_all_items() -> Array[Dictionary]:
	ensure_slot_count()

	var result: Array[Dictionary] = []

	for entry in items:
		result.append(entry.duplicate(true))

	return result


func clear_inventory() -> void:
	initialize_empty_slots()


# 旧セーブ経路互換用。
# 既存の Unit.gd / PlayerData 側が Array を前提にしているため、ここでは通常インベントリだけを Array で返す。
# ホットバー込みで保存したい場合は save_inventory_full_data() を使う。
func save_inventory_data() -> Array:
	ensure_slot_count()

	var result: Array = []

	for entry in items:
		result.append(_normalize_entry(entry))

	return result


# 新形式。通常インベントリ + ホットバー + グリッド情報をまとめて保存する。
# PlayerData 側を Dictionary/Variant 対応にした後はこちらを使う。
func save_inventory_full_data() -> Dictionary:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var bag_result: Array = []

	for entry in items:
		bag_result.append(_normalize_entry(entry))

	var hotbar_result: Array = []

	for entry in hotbar_items:
		hotbar_result.append(_normalize_entry(entry))

	return {
		"version": 2,
		"slot_columns": slot_columns,
		"slot_rows": slot_rows,
		"max_slots": max_slots,
		"hotbar_slot_count": hotbar_slot_count,
		"items": bag_result,
		"hotbar_items": hotbar_result
	}


func load_inventory_data(data: Variant) -> void:
	# 旧形式互換: Array = 通常インベントリだけ。
	if typeof(data) == TYPE_ARRAY:
		var old_items: Array = data as Array
		if old_items.size() > 0:
			_expand_grid_to_fit_count(old_items.size())

		items.clear()
		for i in range(max_slots):
			items.append(_make_empty_slot())

		for i in range(min(old_items.size(), items.size())):
			var entry: Variant = old_items[i]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			items[i] = _normalize_entry(entry)

		hotbar_items.clear()
		ensure_hotbar_slot_count()
		return

	if typeof(data) != TYPE_DICTIONARY:
		initialize_empty_slots()
		return

	var dict: Dictionary = data as Dictionary

	if dict.has("slot_columns"):
		slot_columns = max(1, int(dict.get("slot_columns", slot_columns)))

	if dict.has("slot_rows"):
		slot_rows = max(1, int(dict.get("slot_rows", slot_rows)))

	if dict.has("hotbar_slot_count"):
		hotbar_slot_count = max(0, int(dict.get("hotbar_slot_count", hotbar_slot_count)))

	_sync_max_slots_from_grid()

	var bag_items: Array = []
	if dict.has("items") and typeof(dict.get("items")) == TYPE_ARRAY:
		bag_items = dict.get("items") as Array

	if bag_items.size() > 0:
		_expand_grid_to_fit_count(bag_items.size())

	items.clear()
	for i in range(max_slots):
		items.append(_make_empty_slot())

	for i in range(min(bag_items.size(), items.size())):
		var entry: Variant = bag_items[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		items[i] = _normalize_entry(entry)

	var loaded_hotbar_items: Array = []
	if dict.has("hotbar_items") and typeof(dict.get("hotbar_items")) == TYPE_ARRAY:
		loaded_hotbar_items = dict.get("hotbar_items") as Array
		if loaded_hotbar_items.size() > hotbar_slot_count:
			hotbar_slot_count = loaded_hotbar_items.size()

	hotbar_items.clear()
	ensure_hotbar_slot_count()

	for i in range(min(loaded_hotbar_items.size(), hotbar_items.size())):
		var entry: Variant = loaded_hotbar_items[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		hotbar_items[i] = _normalize_entry(entry)

func use_item_at(index: int) -> Dictionary:
	if not is_valid_index(index):
		return {
			"success": false,
			"item_id": "",
			"message": "範囲外"
		}

	var entry: Dictionary = items[index]
	var item_id: String = _get_entry_item_id(entry)
	var amount: int = _get_entry_amount(entry)

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


func get_total_amount_ignore_instance(item_id: String) -> int:
	ensure_slot_count()
	ensure_hotbar_slot_count()

	var total: int = 0

	for entry in items:
		if _get_entry_item_id(entry) == item_id:
			total += _get_entry_amount(entry)

	for entry in hotbar_items:
		if _get_entry_item_id(entry) == item_id:
			total += _get_entry_amount(entry)

	return total

func can_consume_total_amount_ignore_instance(item_id: String, amount: int) -> bool:
	if item_id == "":
		return false

	if amount <= 0:
		return true

	return get_total_amount_ignore_instance(item_id) >= amount


func consume_total_amount_ignore_instance(item_id: String, amount: int) -> bool:
	if item_id == "":
		return false

	if amount <= 0:
		return true

	if not can_consume_total_amount_ignore_instance(item_id, amount):
		return false

	ensure_slot_count()
	ensure_hotbar_slot_count()

	var remaining: int = amount

	for i in range(items.size()):
		if remaining <= 0:
			break

		var entry: Dictionary = items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		var current_amount: int = _get_entry_amount(entry)
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

	for i in range(hotbar_items.size()):
		if remaining <= 0:
			break

		var entry: Dictionary = hotbar_items[i]
		if _get_entry_item_id(entry) != item_id:
			continue

		var current_amount: int = _get_entry_amount(entry)
		if current_amount <= 0:
			continue

		if current_amount <= remaining:
			remaining -= current_amount
			hotbar_items[i] = _make_empty_slot()
		else:
			entry["amount"] = current_amount - remaining
			hotbar_items[i] = entry
			remaining = 0
			break

	return remaining <= 0
