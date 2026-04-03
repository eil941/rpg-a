extends RefCounted
class_name UnitInteractionLogic


static func has_role(unit, role_flag: int) -> bool:
	if unit == null:
		return false
	return (int(unit.unit_roles) & role_flag) != 0


static func get_relation_to_player(unit) -> String:
	var player_unit = _get_current_player_unit()

	if unit == null:
		return "NEUTRAL"

	if player_unit == null:
		return "NEUTRAL"

	if unit == player_unit:
		return "SELF"

	if FactionManager.are_units_hostile(unit, player_unit):
		return "HOSTILE"

	if FactionManager.are_units_friendly(unit, player_unit):
		return "ALLY"

	if FactionManager.are_units_neutral(unit, player_unit):
		return "NEUTRAL"

	return "NEUTRAL"


static func can_offer_request_to_player(unit) -> bool:
	var player_unit = _get_current_player_unit()
	if unit == null or player_unit == null:
		return false

	if FactionManager.are_units_hostile(unit, player_unit):
		return false

	if bool(unit.can_offer_request):
		return true

	if has_role(unit, unit.UnitRole.QUEST_GIVER):
		return true

	return false


static func can_trade_with_player(unit) -> bool:
	var player_unit = _get_current_player_unit()
	if unit == null or player_unit == null:
		return false

	if FactionManager.are_units_hostile(unit, player_unit):
		return false

	if has_role(unit, unit.UnitRole.MERCHANT):
		return true

	if "can_trade" in unit and bool(unit.can_trade):
		return true

	return false


static func build_header_text(unit) -> String:
	var relation := get_relation_to_player(unit)
	var friendly := int(unit.friendliness)

	if relation == "HOSTILE":
		if friendly <= -70:
			return "……強い敵意を感じる。"
		return "警戒されている。"

	if has_role(unit, unit.UnitRole.ENEMY_BOSS):
		return "ここまで来たか。"

	if can_trade_with_player(unit):
		if friendly >= 50:
			return "いらっしゃい。今日は何を見る？"
		return "品物を見るかい？"

	if can_offer_request_to_player(unit):
		if friendly >= 50:
			return "ちょうどよかった。頼みたいことがある。"
		return "少し頼みたいことがある。"

	if has_role(unit, unit.UnitRole.GUARD):
		return "異常なし。"

	if has_role(unit, unit.UnitRole.VILLAGER):
		return "こんにちは。"

	if String(unit.talk_greeting_text) != "":
		return String(unit.talk_greeting_text)

	return "……"


static func build_actions(unit) -> Array:
	var actions: Array = []

	actions.append({
		"id": "talk",
		"label": "話をする"
	})

	if can_trade_with_player(unit):
		_append_unique_action(actions, "trade", "売買したい")

	if can_offer_request_to_player(unit):
		_append_unique_action(actions, "request", "依頼について")

	_append_unique_action(actions, "bye", "さようなら")
	return actions


static func handle_action(unit, action_id: String) -> Dictionary:
	match action_id:
		"talk":
			return {
				"type": "update_text",
				"text": _pick_random_talk_text(unit)
			}

		"trade":
			return {
				"type": "open_trade_ui",
				"text": "売買画面を開く予定です。"
			}

		"request":
			return {
				"type": "update_dialog",
				"text": _get_request_description(unit),
				"actions": [
					{"id": "request_accept", "label": "受ける"},
					{"id": "request_decline", "label": "受けない"}
				]
			}

		"request_accept":
			return {
				"type": "return_to_root",
				"text": _get_request_accept_text(unit)
			}

		"request_decline":
			return {
				"type": "return_to_root",
				"text": _get_request_decline_text(unit)
			}

		"bye":
			return {
				"type": "close_dialog"
			}

		_:
			return {
				"type": "update_text",
				"text": "%s を選択した。" % action_id
			}


static func _pick_random_talk_text(unit) -> String:
	var candidates: Array[String] = []

	if unit == null:
		return "……"

	if "random_talk_texts" in unit:
		for text in unit.random_talk_texts:
			var s := String(text)
			if s != "":
				candidates.append(s)

	if candidates.is_empty():
		if String(unit.talk_greeting_text) != "":
			return String(unit.talk_greeting_text)
		return "……"

	return candidates[randi() % candidates.size()]


static func _get_request_description(unit) -> String:
	if unit == null:
		return "依頼内容はまだありません。"

	if "request_description" in unit:
		var desc := String(unit.request_description)
		if desc != "":
			return desc

	return "依頼システムはまだ未実装です。"


static func _get_request_accept_text(unit) -> String:
	if unit != null and "request_accept_text" in unit:
		var text := String(unit.request_accept_text)
		if text != "":
			return text

	return "ありがとうございます。"


static func _get_request_decline_text(unit) -> String:
	if unit != null and "request_decline_text" in unit:
		var text := String(unit.request_decline_text)
		if text != "":
			return text

	return "また今度おねがいします。"


static func _get_current_player_unit():
	if DialogueManager == null:
		return null

	if "current_player_unit" in DialogueManager:
		return DialogueManager.current_player_unit

	return null


static func _append_unique_action(actions: Array, action_id: String, label: String) -> void:
	for action in actions:
		if String(action.get("id", "")) == action_id:
			return

	actions.append({
		"id": action_id,
		"label": label
	})
