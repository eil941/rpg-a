extends Node
class_name ItemEffectManager

static func apply_item_effect(owner_unit, item_id: String) -> bool:
	var data := ItemDatabase.get_item_data(item_id)

	if data.is_empty():
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sを使用した" % item_id)
		return true

	if not bool(data.get("usable", false)):
		if owner_unit != null and owner_unit.has_method("notify_hud_log"):
			owner_unit.notify_hud_log("%sは使用できない" % ItemDatabase.get_display_name(item_id))
		return false

	var item_name := String(data.get("display_name", item_id))
	var effect_type := String(data.get("effect_type", "log_only"))
	var effect_value := int(data.get("effect_value", 0))

	match effect_type:
		"heal_hp":
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

		"log_only":
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true

		_:
			if owner_unit != null and owner_unit.has_method("notify_hud_log"):
				owner_unit.notify_hud_log("%sを使用した" % item_name)
			return true
