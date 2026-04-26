extends Node
class_name ItemEffectManager


static func _notify_item_use_blocked(user, message: String) -> void:
	if user == null:
		return
	if user.has_method("consume_blocked_action_turn"):
		user.consume_blocked_action_turn(message)
		return
	if user.has_method("notify_hud_log"):
		user.notify_hud_log(message)


static func _get_resource_property_names(resource_type: int) -> Dictionary:
	match resource_type:
		ItemEffectData.ResourceType.HP:
			return {"current": "hp", "max": "max_hp"}
		ItemEffectData.ResourceType.MP:
			return {"current": "mp", "max": "max_mp"}
		ItemEffectData.ResourceType.STAMINA:
			return {"current": "stamina", "max": "max_stamina"}
		ItemEffectData.ResourceType.HUNGER:
			return {"current": "hunger", "max": "max_hunger"}
		_:
			return {}


static func _apply_resource_restore(stats, current_property: String, max_property: String, effect: ItemEffectData, amount: int) -> bool:
	if stats == null:
		return false
	if current_property == "" or max_property == "":
		return false
	if not _has_property(stats, current_property):
		return false
	if not _has_property(stats, max_property):
		return false

	var current_value_variant: Variant = stats.get(current_property)
	var max_value_variant: Variant = stats.get(max_property)
	var current_value: float = float(current_value_variant)
	var max_value: float = float(max_value_variant)
	var new_value: float = current_value

	if effect.value_mode == ItemEffectData.ValueMode.FULL:
		new_value = max_value
	elif effect.value_mode == ItemEffectData.ValueMode.PERCENT:
		new_value = min(max_value, current_value + max_value * float(effect.percent_value))
	else:
		new_value = min(max_value, current_value + float(amount))

	if typeof(current_value_variant) == TYPE_FLOAT or typeof(max_value_variant) == TYPE_FLOAT:
		stats.set(current_property, new_value)
	else:
		stats.set(current_property, int(round(new_value)))

	return true


static func _try_call_target_method(target, method_name: String, args: Array = []) -> Variant:
	if target == null:
		return null
	if not target.has_method(method_name):
		return null
	return target.callv(method_name, args)


static func apply_item_effects(user, target, item_data: ItemData, use_flag_override: int = -1) -> bool:
	if _is_item_use_blocked_by_status(user):
		return false

	if item_data == null:
		return false

	if item_data.effects.is_empty():
		return false

	var applied_any: bool = false

	print("[ITEM EFFECT] apply_item_effects item_id=", item_data.item_id, " effect_count=", item_data.effects.size())

	for effect in item_data.effects:
		if effect == null:
			continue

		print("[ITEM EFFECT] try effect_type=", effect.get_effect_type_name())
		if apply_single_effect(user, target, item_data, effect, use_flag_override):
			applied_any = true
			print("[ITEM EFFECT] success effect_type=", effect.get_effect_type_name())
		else:
			print("[ITEM EFFECT] failed effect_type=", effect.get_effect_type_name())

	if applied_any:
		_wake_sleep_target_if_needed(user, target)

	return applied_any


# 互換用:
# 旧式  apply_item_effect(target, item_data)
# 新式  apply_item_effect(user, target, item_data)
static func apply_item_effect(arg1, arg2, arg3 = null, arg4: int = -1) -> bool:
	var user = null
	var target = null
	var item_data: ItemData = null
	var use_flag_override: int = arg4

	# 旧式1:
	# apply_item_effect(owner_unit, item_id: String, target_unit = null, use_flag_override = -1)
	if arg2 is String:
		user = arg1
		target = arg3
		if target == null:
			target = user

		item_data = ItemDatabase.get_item_data(String(arg2))
		if item_data == null:
			print("[ITEM EFFECT] item_data not found item_id=", String(arg2))
			return false

		if not item_data.usable:
			print("[ITEM EFFECT] item is not usable item_id=", String(arg2))
			return false

		print("[ITEM EFFECT] old call item_id=", item_data.item_id, " target=", target.name if target != null and "name" in target else "null")
		return apply_item_effects(user, target, item_data, use_flag_override)

	# 旧式2:
	# apply_item_effect(target, item_data)
	if arg3 == null and arg2 is ItemData:
		target = arg1
		user = arg1
		item_data = arg2
	else:
		# 新式:
		# apply_item_effect(user, target, item_data)
		user = arg1
		target = arg2
		item_data = arg3

	if item_data == null:
		print("[ITEM EFFECT] item_data is null")
		return false

	print("[ITEM EFFECT] new call item_id=", item_data.item_id, " target=", target.name if target != null and "name" in target else "null")
	return apply_item_effects(user, target, item_data, use_flag_override)


static func _is_item_use_blocked_by_status(user) -> bool:
	if user == null:
		return false

	if not user.has_method("has_status_effect"):
		return false

	if user.has_status_effect(&"sleep"):
		_notify_item_use_blocked(user, "眠っていてアイテムを使えない")
		return true

	if user.has_status_effect(&"paralysis"):
		_notify_item_use_blocked(user, "麻痺していてアイテムを使えない")
		return true

	return false


static func apply_single_effect(user, target, item_data: ItemData, effect: ItemEffectData, use_flag_override: int = -1) -> bool:
	if effect == null:
		return false

	match effect.effect_type:
		ItemEffectData.EffectType.NONE:
			return false

		ItemEffectData.EffectType.RESTORE_RESOURCE:
			return _apply_restore_resource(user, target, effect)

		ItemEffectData.EffectType.CURE_STATUS:
			return _apply_cure_status(user, target, effect)

		ItemEffectData.EffectType.APPLY_STATUS:
			return _apply_status(user, target, item_data, effect)

		ItemEffectData.EffectType.APPLY_MODIFIER:
			return _apply_modifier(user, target, item_data, effect)

		ItemEffectData.EffectType.DEAL_DAMAGE:
			return _apply_deal_damage(user, target, effect)

		ItemEffectData.EffectType.GRANT_ITEM:
			return _apply_grant_item(user, target, effect)

		ItemEffectData.EffectType.GRANT_CURRENCY:
			return _apply_grant_currency(user, target, effect)

		ItemEffectData.EffectType.TELEPORT:
			return _apply_teleport(user, target, effect)

		ItemEffectData.EffectType.PERMANENT_STAT_GROWTH:
			return _apply_permanent_stat_growth(user, target, effect)

		ItemEffectData.EffectType.LEARN_SKILL:
			return _apply_learn_skill(user, target, effect)

		ItemEffectData.EffectType.UNLOCK_RECIPE:
			return _apply_unlock_recipe(user, target, effect)

		ItemEffectData.EffectType.IDENTIFY_ITEM:
			return _apply_identify_item(user, target, effect)

		ItemEffectData.EffectType.READ_DOCUMENT:
			return _apply_read_document(user, target, effect)

		ItemEffectData.EffectType.SPAWN_OBJECT:
			return _apply_spawn_object(user, target, effect)

	return false


static func _apply_restore_resource(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var stats = _get_stats_node(target)
	if stats == null:
		return false

	var amount: int = effect.get_rolled_power()
	var property_names: Dictionary = _get_resource_property_names(effect.resource_type)
	if property_names.is_empty():
		return false

	return _apply_resource_restore(
		stats,
		String(property_names.get("current", "")),
		String(property_names.get("max", "")),
		effect,
		amount
	)


static func _apply_cure_status(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.status_id == &"":
		return false

	if effect.status_id == &"sleep":
		if user != null and user.has_method("notify_hud_log"):
			user.notify_hud_log("睡眠は状態異常回復では治らない")
		return false

	if target.has_method("remove_status_effect"):
		print("[ITEM EFFECT] cure_status status_id=", String(effect.status_id))
		target.remove_status_effect(effect.status_id)
		return true

	return false


static func _apply_status(user, target, item_data: ItemData, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.status_id == &"":
		return false

	if effect.status_id == &"curse":
		return _apply_curse_status(user, target, item_data, effect)

	if not target.has_method("add_status_effect_runtime"):
		return false

	var runtime: UnitEffectRuntime = UnitEffectRuntime.new()
	runtime.source_item_id = item_data.item_id
	runtime.effect_type = ItemEffectData.EffectType.APPLY_STATUS
	runtime.status_id = effect.status_id
	runtime.status_power = max(0, int(effect.status_power))
	runtime.duration_type = effect.duration_type
	runtime.remaining_duration = effect.duration_value

	print("[ITEM EFFECT] apply_status status_id=", String(effect.status_id), " power=", runtime.status_power, " duration=", effect.duration_value)
	target.add_status_effect_runtime(runtime)
	return true


static func _apply_curse_status(user, target, item_data: ItemData, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if not target.has_method("add_status_effect_runtime"):
		return false

	var picked_indices: Array[int] = _pick_curse_status_indices(effect)
	if picked_indices.is_empty():
		print("[CURSE] no valid curse pool")
		return false

	var applied_child_count: int = 0

	for pool_index in picked_indices:
		var child_status_id: StringName = effect.get_curse_status_id_at(pool_index)
		if child_status_id == &"":
			continue

		var child_runtime: UnitEffectRuntime = UnitEffectRuntime.new()
		child_runtime.source_item_id = item_data.item_id
		child_runtime.effect_type = ItemEffectData.EffectType.APPLY_STATUS
		child_runtime.status_id = child_status_id
		child_runtime.status_power = max(0, int(effect.get_curse_status_power_for_index(pool_index)))
		child_runtime.duration_type = effect.get_curse_duration_type_for_index(pool_index)
		child_runtime.remaining_duration = effect.get_curse_duration_value_for_index(pool_index)

		print(
			"[CURSE] add status=", String(child_status_id),
			" power=", child_runtime.status_power,
			" duration_type=", child_runtime.duration_type,
			" duration=", child_runtime.remaining_duration
		)

		target.add_status_effect_runtime(child_runtime)
		applied_child_count += 1

	return applied_child_count > 0


static func _pick_curse_status_indices(effect: ItemEffectData) -> Array[int]:
	var valid_indices: Array[int] = []

	for index in range(effect.get_curse_pool_count()):
		var status_id: StringName = effect.get_curse_status_id_at(index)
		if status_id == &"":
			continue
		valid_indices.append(index)

	if valid_indices.is_empty():
		return []

	var pick_count: int = min(effect.get_curse_pick_count(), valid_indices.size())
	var picked: Array[int] = []

	while picked.size() < pick_count and not valid_indices.is_empty():
		var random_index: int = randi_range(0, valid_indices.size() - 1)
		picked.append(valid_indices[random_index])
		valid_indices.remove_at(random_index)

	return picked



static func _apply_modifier(user, target, item_data: ItemData, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.stat_name == &"":
		return false

	if not target.has_method("add_status_effect_runtime"):
		return false

	var runtime := UnitEffectRuntime.new()
	runtime.source_item_id = item_data.item_id
	runtime.effect_type = ItemEffectData.EffectType.APPLY_MODIFIER
	runtime.modifier_kind = effect.modifier_kind
	runtime.stat_name = effect.stat_name
	runtime.stat_flat = effect.stat_flat
	runtime.stat_percent = effect.stat_percent
	runtime.duration_type = effect.duration_type
	runtime.remaining_duration = effect.duration_value

	target.add_status_effect_runtime(runtime)
	return true


static func _apply_deal_damage(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var stats = _get_stats_node(target)
	if stats == null:
		return false

	if not _has_property(stats, "hp"):
		return false

	var damage_value: int = max(0, effect.get_rolled_power())
	if damage_value <= 0:
		return false

	if stats.has_method("take_damage"):
		stats.take_damage(damage_value)
	else:
		stats.hp = max(0, stats.hp - damage_value)

	print("[ITEM EFFECT] damage=", damage_value, " target_hp=", stats.hp)

	if target.has_method("notify_hud_player_status_refresh"):
		target.notify_hud_player_status_refresh()
	if target.has_method("notify_hud_effects_refresh"):
		target.notify_hud_effects_refresh()

	return true


static func _apply_grant_item(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var grant_result = _try_call_target_method(target, "grant_items_from_effect", [effect])
	if grant_result != null:
		if grant_result is bool:
			return grant_result
		return true

	if effect.grant_item_id == "":
		return false

	if target.has_method("grant_item_from_effect"):
		target.grant_item_from_effect(effect.grant_item_id, effect.grant_item_amount)
		return true

	return false


static func _apply_grant_currency(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var grant_currency_result = _try_call_target_method(target, "grant_currency_from_effect", [effect])
	if grant_currency_result != null:
		if grant_currency_result is bool:
			return bool(grant_currency_result)
		return true

	if effect.grant_currency_amount == 0:
		return false

	return false


static func _apply_teleport(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var teleport_result = _try_call_target_method(target, "apply_item_teleport_effect", [effect])
	if teleport_result != null:
		print("[ITEM EFFECT] teleport mode=", effect.get_teleport_mode_name())
		if teleport_result is bool:
			return bool(teleport_result)
		return true

	return false


static func _apply_permanent_stat_growth(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var stats = _get_stats_node(target)
	if stats == null:
		return false

	if effect.stat_name == &"":
		return false

	var stat_key: String = String(effect.stat_name)

	if not _has_property(stats, stat_key):
		return false

	var grow_value: int = effect.get_rolled_power()
	var current_value: int = int(stats.get(stat_key))
	stats.set(stat_key, current_value + grow_value)

	if stat_key == "max_hp" and _has_property(stats, "hp"):
		stats.hp = min(stats.max_hp, stats.hp + grow_value)

	return true


static func _apply_learn_skill(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.skill_id == &"":
		return false

	var result = _try_call_target_method(target, "learn_skill_from_effect", [effect.skill_id])
	if result != null:
		return true

	return false


static func _apply_unlock_recipe(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.recipe_id == &"":
		return false

	var result = _try_call_target_method(target, "unlock_recipe_from_effect", [effect.recipe_id])
	if result != null:
		return true

	return false


static func _apply_identify_item(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	var result = _try_call_target_method(target, "identify_item_from_effect", [effect.identify_all])
	if result != null:
		return true

	return false


static func _apply_read_document(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.document_text == "":
		return false

	var result = _try_call_target_method(target, "read_document_from_effect", [effect.document_text])
	if result != null:
		return true

	return false


static func _apply_spawn_object(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.spawn_object_id == &"":
		return false

	var result = _try_call_target_method(target, "spawn_object_from_effect", [effect.spawn_object_id])
	if result != null:
		return true

	return false


static func _wake_sleep_target_if_needed(user, target) -> void:
	if target == null:
		return
	if user == null:
		return
	if target == user:
		return
	if not target.has_method("has_status_effect"):
		return
	if not target.has_method("remove_status_effect"):
		return
	if not target.has_status_effect(&"sleep"):
		return

	target.remove_status_effect(&"sleep")

	if user.has_method("notify_hud_log"):
		user.notify_hud_log("%s は目を覚ました" % String(target.name))


static func _get_stats_node(target):
	if target == null:
		return null

	if target.has_node("Stats"):
		return target.get_node("Stats")

	if target.has_method("get_stats_node"):
		return target.get_stats_node()

	return null


static func _has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false

	for info in obj.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false
