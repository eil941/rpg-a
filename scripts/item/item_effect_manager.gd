extends Node
class_name ItemEffectManager


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

		if not bool(item_data.usable):
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
		if user.has_method("consume_blocked_action_turn"):
			user.consume_blocked_action_turn("眠っていてアイテムを使えない")
		elif user.has_method("notify_hud_log"):
			user.notify_hud_log("眠っていてアイテムを使えない")
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

	match effect.resource_type:
		ItemEffectData.ResourceType.HP:
			if not _has_property(stats, "hp") or not _has_property(stats, "max_hp"):
				return false

			if effect.value_mode == ItemEffectData.ValueMode.FULL:
				stats.hp = stats.max_hp
			elif effect.value_mode == ItemEffectData.ValueMode.PERCENT:
				var restore_hp: int = int(round(float(stats.max_hp) * effect.percent_value))
				stats.hp = min(stats.max_hp, stats.hp + restore_hp)
			else:
				stats.hp = min(stats.max_hp, stats.hp + amount)
			return true

		ItemEffectData.ResourceType.MP:
			if not _has_property(stats, "mp") or not _has_property(stats, "max_mp"):
				return false

			if effect.value_mode == ItemEffectData.ValueMode.FULL:
				stats.mp = stats.max_mp
			elif effect.value_mode == ItemEffectData.ValueMode.PERCENT:
				var restore_mp: int = int(round(float(stats.max_mp) * effect.percent_value))
				stats.mp = min(stats.max_mp, stats.mp + restore_mp)
			else:
				stats.mp = min(stats.max_mp, stats.mp + amount)
			return true

		ItemEffectData.ResourceType.STAMINA:
			if not _has_property(stats, "stamina") or not _has_property(stats, "max_stamina"):
				return false

			if effect.value_mode == ItemEffectData.ValueMode.FULL:
				stats.stamina = stats.max_stamina
			elif effect.value_mode == ItemEffectData.ValueMode.PERCENT:
				var restore_stamina: int = int(round(float(stats.max_stamina) * effect.percent_value))
				stats.stamina = min(stats.max_stamina, stats.stamina + restore_stamina)
			else:
				stats.stamina = min(stats.max_stamina, stats.stamina + amount)
			return true

		ItemEffectData.ResourceType.HUNGER:
			if not _has_property(stats, "hunger") or not _has_property(stats, "max_hunger"):
				return false

			if effect.value_mode == ItemEffectData.ValueMode.FULL:
				stats.hunger = stats.max_hunger
			elif effect.value_mode == ItemEffectData.ValueMode.PERCENT:
				var restore_hunger: int = int(round(float(stats.max_hunger) * effect.percent_value))
				stats.hunger = min(stats.max_hunger, stats.hunger + restore_hunger)
			else:
				stats.hunger = min(stats.max_hunger, stats.hunger + amount)
			return true

	return false


static func _apply_cure_status(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.status_id == &"":
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

	if effect.grant_item_id == "":
		return false

	if target.has_method("grant_item_from_effect"):
		target.grant_item_from_effect(effect.grant_item_id, effect.grant_item_amount)
		return true

	return false


static func _apply_grant_currency(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.grant_currency_amount == 0:
		return false

	if target.has_method("grant_currency_from_effect"):
		target.grant_currency_from_effect(effect.grant_currency_amount)
		return true

	return false


static func _apply_teleport(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if target.has_method("apply_item_teleport_effect"):
		print("[ITEM EFFECT] teleport mode=", effect.get_teleport_mode_name())
		target.apply_item_teleport_effect(effect)
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

	if target.has_method("learn_skill_from_effect"):
		target.learn_skill_from_effect(effect.skill_id)
		return true

	return false


static func _apply_unlock_recipe(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.recipe_id == &"":
		return false

	if target.has_method("unlock_recipe_from_effect"):
		target.unlock_recipe_from_effect(effect.recipe_id)
		return true

	return false


static func _apply_identify_item(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if target.has_method("identify_item_from_effect"):
		target.identify_item_from_effect(effect.identify_all)
		return true

	return false


static func _apply_read_document(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.document_text == "":
		return false

	if target.has_method("read_document_from_effect"):
		target.read_document_from_effect(effect.document_text)
		return true

	return false


static func _apply_spawn_object(user, target, effect: ItemEffectData) -> bool:
	if target == null:
		return false

	if effect.spawn_object_id == &"":
		return false

	if target.has_method("spawn_object_from_effect"):
		target.spawn_object_from_effect(effect.spawn_object_id)
		return true

	return false


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
