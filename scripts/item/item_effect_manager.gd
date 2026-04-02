extends Node
class_name ItemEffectManager

static func apply_item_effect(owner_unit, item_id: String) -> bool:
	var data = ItemDatabase.get_item_data(item_id)

	if data == null:
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sを使用した" % item_id)
		return true

	if not bool(data.usable):
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sは使用できない" % ItemDatabase.get_display_name(item_id))
		return false

	var item_name = String(data.display_name)
	var effect_type = int(data.effect_type)
	var effect_value = int(data.effect_value)

	match effect_type:
		ItemData.ItemEffectType.HEAL_HP:
			if owner_unit != null and owner_unit.stats != null:
				var max_hp = owner_unit.stats.max_hp
				if owner_unit.has_method("get_total_max_hp"):
					max_hp = owner_unit.get_total_max_hp()

				owner_unit.stats.hp = min(max_hp, owner_unit.stats.hp + effect_value)

			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)

			if owner_unit != null and owner_unit.has_method("notify_hud_player_status_refresh"):
				owner_unit.notify_hud_player_status_refresh()

			return true

		ItemData.ItemEffectType.LOG_ONLY:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true

		ItemData.ItemEffectType.NONE:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true

		_:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true
