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

	return _get_primary_quest(unit) != null


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
	var relation: String = get_relation_to_player(unit)
	var friendly: int = int(unit.friendliness)

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
	if action_id == "talk":
		return {
			"type": "update_text",
			"text": _pick_random_talk_text(unit)
		}

	if action_id == "trade":
		return {
			"type": "open_trade_ui",
			"text": "売買画面を開く予定です。"
		}

	if action_id == "request":
		return _build_request_detail_dialog(unit, "")

	if action_id == "request_back_to_root":
		return _build_root_dialog(unit)

	if action_id == "bye":
		return {
			"type": "close_dialog"
		}

	if action_id == "quest_accept_confirm":
		return _accept_primary_quest_and_rebuild(unit)

	if action_id == "quest_complete":
		return _complete_primary_quest_and_rebuild(unit)

	if action_id == "failed_quest_ack":
		if DialogueManager != null and DialogueManager.has_method("finish_failed_quest_dialog"):
			DialogueManager.finish_failed_quest_dialog()
		return {
			"type": "close_dialog"
		}

	if action_id == "failed_quest_detail":
		var failed_data: Dictionary = {}
		if DialogueManager != null and "current_context" in DialogueManager:
			failed_data = DialogueManager.current_context.get("failed_data", {})

		return {
			"type": "update_dialog",
			"text": build_failed_quest_dialog_text(unit, failed_data),
			"actions": [
				{"id": "failed_quest_ack", "label": "わかった"}
			]
		}

	return {
		"type": "update_text",
		"text": "%s を選択した。" % action_id
	}


static func _build_root_dialog(unit) -> Dictionary:
	return {
		"type": "update_dialog",
		"text": build_header_text(unit),
		"actions": build_actions(unit)
	}


static func _build_request_detail_dialog(unit, message_text: String) -> Dictionary:
	var quest: QuestData = _get_primary_quest(unit)
	var actions: Array = []
	var text_lines: Array[String] = []
	var player_unit = _get_current_player_unit()

	if message_text != "":
		text_lines.append(message_text)
		text_lines.append("")

	if quest == null:
		text_lines.append("現在受けられる依頼はありません。")
		actions.append({
			"id": "request_back_to_root",
			"label": "戻る"
		})
		return {
			"type": "update_dialog",
			"text": "\n".join(text_lines),
			"actions": actions
		}

	var state: String = QuestManager.get_quest_state(quest.quest_id)

	if state == "":
		text_lines.append("【%s】" % quest.title)
		text_lines.append(quest.description)
		text_lines.append("")
		text_lines.append("状態: 未受注")
		text_lines.append(_build_objective_text(quest, player_unit))

		if quest.time_limit_seconds > 0.0:
			text_lines.append("制限時間: %s" % QuestManager.format_seconds_to_limit_text(quest.time_limit_seconds))
		else:
			text_lines.append("制限時間: 無し")

		text_lines.append(_build_reward_text_from_template(quest))

		actions.append({
			"id": "quest_accept_confirm",
			"label": "受注する"
		})

	elif state == QuestManager.STATUS_ACTIVE:
		var active_data: Dictionary = QuestManager.get_active_quest_data(quest.quest_id)

		text_lines.append("【%s】" % String(active_data.get("title", quest.title)))
		text_lines.append(String(active_data.get("description", quest.description)))
		text_lines.append("")
		text_lines.append("状態: 進行中")
		text_lines.append(_build_objective_text(quest, player_unit))

		if QuestManager.has_time_limit(quest.quest_id):
			var remain: float = QuestManager.get_remaining_seconds(quest.quest_id)
			text_lines.append("残り時間: %s" % QuestManager.format_seconds_to_limit_text(remain))
		else:
			text_lines.append("残り時間: 無し")

		text_lines.append(_build_reward_text_from_active_data(active_data))

		if QuestManager.can_complete_quest(quest.quest_id, player_unit):
			actions.append({
				"id": "quest_complete",
				"label": "完了報告"
			})

	elif state == QuestManager.STATUS_COMPLETED:
		var completed_data: Dictionary = QuestManager.get_completed_quests().get(quest.quest_id, {})

		text_lines.append("【%s】" % String(completed_data.get("title", quest.title)))
		text_lines.append(String(completed_data.get("description", quest.description)))
		text_lines.append("")
		text_lines.append("状態: 完了")
		text_lines.append(quest.completed_text)
		text_lines.append(_build_completed_or_failed_objective_text(completed_data))
		text_lines.append(_build_reward_text_from_active_data(completed_data))

	elif state == QuestManager.STATUS_FAILED:
		var failed_data: Dictionary = QuestManager.get_failed_quests().get(quest.quest_id, {})

		text_lines.append("【%s】" % String(failed_data.get("title", quest.title)))
		text_lines.append(String(failed_data.get("description", quest.description)))
		text_lines.append("")
		text_lines.append("状態: 失敗")
		text_lines.append(quest.failed_text)
		text_lines.append(_build_completed_or_failed_objective_text(failed_data))
		text_lines.append(_build_reward_text_from_active_data(failed_data))

	actions.append({
		"id": "request_back_to_root",
		"label": "戻る"
	})

	return {
		"type": "update_dialog",
		"text": "\n".join(text_lines),
		"actions": actions
	}


static func _accept_primary_quest_and_rebuild(unit) -> Dictionary:
	var quest: QuestData = _get_primary_quest(unit)
	if quest == null:
		return _build_request_detail_dialog(unit, "依頼データが見つかりません。")

	var result: Dictionary = QuestManager.accept_quest(quest, unit)
	return _build_request_detail_dialog(unit, String(result.get("message", "")))


static func _complete_primary_quest_and_rebuild(unit) -> Dictionary:
	var quest: QuestData = _get_primary_quest(unit)
	var player_unit = _get_current_player_unit()

	if quest == null:
		return _build_request_detail_dialog(unit, "依頼データが見つかりません。")

	QuestManager.complete_quest(quest.quest_id, player_unit)
	return _build_root_dialog(unit)


static func _build_objective_text(quest: QuestData, player_unit) -> String:
	if quest == null:
		return "条件不明"

	var item_id: String = quest.objective_item_id
	var amount: int = quest.objective_item_amount

	var current_amount: int = 0
	if player_unit != null and player_unit.has_node("Inventory"):
		var inventory: Inventory = player_unit.get_node("Inventory") as Inventory
		if inventory != null:
			current_amount = inventory.get_total_amount_ignore_instance(item_id)

	match int(quest.objective_type):
		QuestData.ObjectiveType.DELIVER_ITEM:
			var item_name: String = _get_item_name(item_id)
			return "必要: %s x%d （所持 %d）" % [item_name, amount, current_amount]

		_:
			return "条件不明"


static func _build_completed_or_failed_objective_text(data: Dictionary) -> String:
	var item_id: String = String(data.get("objective_item_id", ""))
	var amount: int = int(data.get("objective_item_amount", 1))
	var item_name: String = _get_item_name(item_id)
	return "必要だったもの: %s x%d" % [item_name, amount]


static func _build_reward_text_from_template(quest: QuestData) -> String:
	if quest == null:
		return "報酬: 不明"

	var parts: Array[String] = []

	if quest.reward_gold > 0:
		if ItemDatabase.exists("gold"):
			parts.append("gold x%d" % quest.reward_gold)
		else:
			parts.append("%dG" % quest.reward_gold)

	var count: int = min(quest.reward_item_ids.size(), quest.reward_item_amounts.size())
	for i in range(count):
		var item_id: String = String(quest.reward_item_ids[i])
		var amount: int = int(quest.reward_item_amounts[i])
		if item_id == "" or amount <= 0:
			continue
		parts.append("%s x%d" % [_get_item_name(item_id), amount])

	if parts.is_empty():
		return "報酬: なし"

	return "報酬: " + " / ".join(parts)


static func _build_reward_text_from_active_data(data: Dictionary) -> String:
	if data.is_empty():
		return "報酬: 不明"

	var parts: Array[String] = []

	var reward_gold: int = int(data.get("reward_gold", 0))
	if reward_gold > 0:
		if ItemDatabase.exists("gold"):
			parts.append("gold x%d" % reward_gold)
		else:
			parts.append("%dG" % reward_gold)

	var reward_item_ids: Array = data.get("reward_item_ids", [])
	var reward_item_amounts: Array = data.get("reward_item_amounts", [])
	var count: int = min(reward_item_ids.size(), reward_item_amounts.size())

	for i in range(count):
		var item_id: String = String(reward_item_ids[i])
		var amount: int = int(reward_item_amounts[i])
		if item_id == "" or amount <= 0:
			continue
		parts.append("%s x%d" % [_get_item_name(item_id), amount])

	if parts.is_empty():
		return "報酬: なし"

	return "報酬: " + " / ".join(parts)


static func build_failed_quest_dialog_text(unit, failed_data: Dictionary) -> String:
	var title: String = String(failed_data.get("title", "依頼"))
	var description: String = String(failed_data.get("description", ""))
	var item_id: String = String(failed_data.get("objective_item_id", ""))
	var amount: int = int(failed_data.get("objective_item_amount", 1))
	var item_name: String = _get_item_name(item_id)

	var lines: Array[String] = []
	lines.append("【依頼失敗】")
	lines.append(title)

	if description != "":
		lines.append(description)

	if item_id != "":
		lines.append("必要だったもの: %s x%d" % [item_name, amount])

	lines.append("")
	lines.append("期限までに達成できなかったようですね。")

	return "\n".join(lines)


static func build_failed_quest_dialog_actions(unit, failed_data: Dictionary) -> Array:
	return [
		{"id": "failed_quest_ack", "label": "わかった"},
		{"id": "failed_quest_detail", "label": "詳細を見る"}
	]


static func _get_primary_quest(unit) -> QuestData:
	var quests: Array = _get_unit_quests(unit)

	for raw_quest in quests:
		var quest: QuestData = raw_quest as QuestData
		if quest == null:
			continue
		return quest

	return null


static func _get_unit_quests(unit) -> Array:
	if unit == null:
		return []

	return QuestManager.get_unit_offer_quests(unit)


static func _pick_random_talk_text(unit) -> String:
	var candidates: Array[String] = []

	if unit == null:
		return "……"

	if "random_talk_texts" in unit:
		for text in unit.random_talk_texts:
			var s: String = String(text)
			if s != "":
				candidates.append(s)

	if candidates.is_empty():
		if String(unit.talk_greeting_text) != "":
			return String(unit.talk_greeting_text)
		return "……"

	return candidates[randi() % candidates.size()]


static func _get_current_player_unit():
	if DialogueManager == null:
		return null

	if "current_player_unit" in DialogueManager:
		return DialogueManager.current_player_unit

	return null


static func _get_item_name(item_id: String) -> String:
	if item_id == "":
		return ""

	if not ItemDatabase.exists(item_id):
		return item_id

	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		return item_id

	return display_name


static func _append_unique_action(actions: Array, action_id: String, label: String) -> void:
	for action in actions:
		if String(action.get("id", "")) == action_id:
			return

	actions.append({
		"id": action_id,
		"label": label
	})
