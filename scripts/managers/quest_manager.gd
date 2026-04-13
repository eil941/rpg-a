extends Node

const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_FAILED: String = "failed"
const MAX_ACTIVE_QUESTS: int = 5


func _ensure_state_containers() -> void:
	if WorldState.quest_active_data == null:
		WorldState.quest_active_data = {}

	if WorldState.quest_completed_data == null:
		WorldState.quest_completed_data = {}

	if WorldState.quest_failed_data == null:
		WorldState.quest_failed_data = {}

	if WorldState.unit_generated_quests == null:
		WorldState.unit_generated_quests = {}


func get_active_quests() -> Dictionary:
	_ensure_state_containers()
	return WorldState.quest_active_data


func get_completed_quests() -> Dictionary:
	_ensure_state_containers()
	return WorldState.quest_completed_data


func get_failed_quests() -> Dictionary:
	_ensure_state_containers()
	return WorldState.quest_failed_data


func get_active_quest_count() -> int:
	_ensure_state_containers()
	return WorldState.quest_active_data.size()


func can_accept_more_quests() -> bool:
	return get_active_quest_count() < MAX_ACTIVE_QUESTS


func get_active_quest_list() -> Array:
	_ensure_state_containers()

	var result: Array = []

	for quest_id in WorldState.quest_active_data.keys():
		var data: Dictionary = get_active_quest_data(String(quest_id))
		if data.is_empty():
			continue
		result.append(data)

	return result


func has_active_quest(quest_id: String) -> bool:
	if quest_id == "":
		return false
	return get_active_quests().has(quest_id)


func is_completed(quest_id: String) -> bool:
	if quest_id == "":
		return false
	return get_completed_quests().has(quest_id)


func is_failed(quest_id: String) -> bool:
	if quest_id == "":
		return false
	return get_failed_quests().has(quest_id)


func get_quest_state(quest_id: String) -> String:
	if has_active_quest(quest_id):
		return STATUS_ACTIVE
	if is_completed(quest_id):
		return STATUS_COMPLETED
	if is_failed(quest_id):
		return STATUS_FAILED
	return ""


func _should_hide_quest_for_unit(quest_id: String) -> bool:
	if quest_id == "":
		return true
	if is_completed(quest_id):
		return true
	if is_failed(quest_id):
		return true
	return false


func get_unit_offer_quests(unit) -> Array:
	_ensure_state_containers()

	var result: Array = []
	if unit == null:
		return result

	if "offered_quests" in unit:
		for raw_quest in unit.offered_quests:
			var fixed_quest: QuestData = raw_quest as QuestData
			if fixed_quest == null:
				continue

			if _should_hide_quest_for_unit(fixed_quest.quest_id):
				continue

			result.append(fixed_quest)

	if "use_generated_quests" in unit and bool(unit.use_generated_quests):
		var generated: Array = get_or_create_generated_unit_quests(unit)
		for raw_generated in generated:
			var generated_quest: QuestData = raw_generated as QuestData
			if generated_quest == null:
				continue

			if _should_hide_quest_for_unit(generated_quest.quest_id):
				continue

			result.append(generated_quest)

	return result


func get_or_create_generated_unit_quests(unit) -> Array:
	_ensure_state_containers()

	var result: Array = []
	if unit == null:
		return result

	var unit_id: String = _get_unit_offer_key(unit)
	if unit_id == "":
		return result

	if WorldState.unit_generated_quests.has(unit_id):
		var saved_list_variant: Variant = WorldState.unit_generated_quests[unit_id]
		if typeof(saved_list_variant) == TYPE_ARRAY:
			var saved_list: Array = saved_list_variant
			for entry in saved_list:
				if typeof(entry) != TYPE_DICTIONARY:
					continue
				var quest: QuestData = _deserialize_quest_data(entry)
				if quest != null:
					result.append(quest)
			return result

	var generated_quests: Array = _generate_unit_quests(unit)
	var serialized_list: Array = []

	for raw_quest in generated_quests:
		var quest: QuestData = raw_quest as QuestData
		if quest == null:
			continue

		result.append(quest)
		serialized_list.append(_serialize_quest_data(quest))

	WorldState.unit_generated_quests[unit_id] = serialized_list
	return result


func refresh_generated_unit_quests(unit) -> void:
	_ensure_state_containers()

	if unit == null:
		return

	var unit_id: String = _get_unit_offer_key(unit)
	if unit_id == "":
		return

	WorldState.unit_generated_quests.erase(unit_id)


func _generate_unit_quests(unit) -> Array:
	var result: Array = []
	if unit == null:
		return result

	var min_count: int = 1
	var max_count: int = 1

	if "quest_offer_count_min" in unit:
		min_count = max(0, int(unit.quest_offer_count_min))

	if "quest_offer_count_max" in unit:
		max_count = max(min_count, int(unit.quest_offer_count_max))

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var offer_count: int = min_count
	if max_count > min_count:
		offer_count = rng.randi_range(min_count, max_count)

	if offer_count <= 0:
		return result

	var all_templates: Array = QuestDatabase.get_all_quests()
	var filtered_templates: Array = _filter_templates_for_unit(unit, all_templates)
	if filtered_templates.is_empty():
		return result

	var picked_templates: Array = _pick_weighted_templates(filtered_templates, offer_count)

	var index: int = 0
	for raw_template in picked_templates:
		var template: QuestData = raw_template as QuestData
		if template == null:
			continue

		var generated_quest: QuestData = _make_generated_quest_from_template(template, unit, index)
		if generated_quest != null:
			result.append(generated_quest)

		index += 1

	return result


func _filter_templates_for_unit(unit, templates: Array) -> Array:
	var result: Array = []

	if unit == null:
		return result

	var unit_role_flags: int = 0
	if "unit_roles" in unit:
		unit_role_flags = int(unit.unit_roles)

	for raw_template in templates:
		var template: QuestData = raw_template as QuestData
		if template == null:
			continue

		if template.quest_id == "":
			continue

		if template.allowed_unit_role_flags == 0:
			result.append(template)
			continue

		if (unit_role_flags & int(template.allowed_unit_role_flags)) != 0:
			result.append(template)

	return result


func _pick_weighted_templates(templates: Array, pick_count: int) -> Array:
	var result: Array = []
	if templates.is_empty() or pick_count <= 0:
		return result

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var remaining: Array = templates.duplicate()

	while result.size() < pick_count and not remaining.is_empty():
		var total_weight: int = 0

		for raw_template in remaining:
			var template: QuestData = raw_template as QuestData
			if template == null:
				continue
			total_weight += max(1, template.weight)

		if total_weight <= 0:
			break

		var roll: int = rng.randi_range(1, total_weight)
		var running: int = 0
		var picked_index: int = -1

		for i in range(remaining.size()):
			var template: QuestData = remaining[i] as QuestData
			if template == null:
				continue

			running += max(1, template.weight)
			if roll <= running:
				picked_index = i
				break

		if picked_index < 0:
			break

		result.append(remaining[picked_index])
		remaining.remove_at(picked_index)

	return result


func _make_generated_quest_from_template(template: QuestData, unit, index: int) -> QuestData:
	if template == null:
		return null

	var rolled_objective: Dictionary = _roll_objective_data(template)
	var rolled_item_id: String = String(rolled_objective.get("item_id", ""))
	var rolled_amount: int = int(rolled_objective.get("amount", 1))
	var rolled_category: String = String(rolled_objective.get("category", ""))

	if rolled_item_id == "" or rolled_amount <= 0:
		return null

	var rolled_reward: Dictionary = _roll_reward_data(template, rolled_item_id, rolled_amount)
	var rolled_reward_gold: int = int(rolled_reward.get("reward_gold", 0))

	var quest: QuestData = QuestData.new()
	quest.quest_id = _make_generated_quest_id(unit, template.quest_id, index)
	quest.objective_type = template.objective_type
	quest.objective_item_id = rolled_item_id
	quest.objective_item_amount = rolled_amount
	quest.candidate_item_ids = []
	quest.candidate_categories = []
	quest.amount_min = rolled_amount
	quest.amount_max = rolled_amount
	quest.time_limit_seconds = template.time_limit_seconds
	quest.reward_gold = rolled_reward_gold
	quest.random_reward_use_sell_price = false
	quest.reward_bonus_rate_min = template.reward_bonus_rate_min
	quest.reward_bonus_rate_max = template.reward_bonus_rate_max
	quest.reward_item_ids = template.reward_item_ids.duplicate()
	quest.reward_item_amounts = template.reward_item_amounts.duplicate()
	quest.allowed_unit_role_flags = template.allowed_unit_role_flags
	quest.weight = template.weight
	quest.repeatable = template.repeatable
	quest.accept_text = template.accept_text
	quest.progress_text = template.progress_text
	quest.ready_to_complete_text = template.ready_to_complete_text
	quest.completed_text = template.completed_text
	quest.failed_text = template.failed_text
	quest.title = _build_final_text(template.title_template, template.title, rolled_item_id, rolled_amount, rolled_category)
	quest.description = _build_final_text(template.description_template, template.description, rolled_item_id, rolled_amount, rolled_category)
	quest.title_template = ""
	quest.description_template = ""

	return quest


func _make_generated_quest_id(unit, template_quest_id: String, index: int) -> String:
	var unit_key: String = _get_unit_offer_key(unit)
	return "generated__%s__%s__%d" % [unit_key, template_quest_id, index]


func _get_unit_offer_key(unit) -> String:
	if unit == null:
		return ""

	if "unit_id" in unit:
		var unit_id: String = String(unit.unit_id)
		if unit_id != "":
			return unit_id

	return "instance_%s" % str(unit.get_instance_id())


func _serialize_quest_data(quest: QuestData) -> Dictionary:
	var data: Dictionary = {}

	data["quest_id"] = quest.quest_id
	data["title"] = quest.title
	data["description"] = quest.description
	data["title_template"] = quest.title_template
	data["description_template"] = quest.description_template
	data["objective_type"] = int(quest.objective_type)
	data["objective_item_id"] = quest.objective_item_id
	data["objective_item_amount"] = quest.objective_item_amount
	data["candidate_item_ids"] = quest.candidate_item_ids.duplicate()
	data["candidate_categories"] = quest.candidate_categories.duplicate()
	data["amount_min"] = quest.amount_min
	data["amount_max"] = quest.amount_max
	data["time_limit_seconds"] = quest.time_limit_seconds
	data["reward_gold"] = quest.reward_gold
	data["random_reward_use_sell_price"] = quest.random_reward_use_sell_price
	data["reward_bonus_rate_min"] = quest.reward_bonus_rate_min
	data["reward_bonus_rate_max"] = quest.reward_bonus_rate_max
	data["reward_item_ids"] = quest.reward_item_ids.duplicate()
	data["reward_item_amounts"] = quest.reward_item_amounts.duplicate()
	data["allowed_unit_role_flags"] = quest.allowed_unit_role_flags
	data["weight"] = quest.weight
	data["repeatable"] = quest.repeatable
	data["accept_text"] = quest.accept_text
	data["progress_text"] = quest.progress_text
	data["ready_to_complete_text"] = quest.ready_to_complete_text
	data["completed_text"] = quest.completed_text
	data["failed_text"] = quest.failed_text

	return data


func _deserialize_quest_data(data: Dictionary) -> QuestData:
	if data.is_empty():
		return null

	var quest: QuestData = QuestData.new()
	quest.quest_id = String(data.get("quest_id", ""))
	quest.title = String(data.get("title", ""))
	quest.description = String(data.get("description", ""))
	quest.title_template = String(data.get("title_template", ""))
	quest.description_template = String(data.get("description_template", ""))
	quest.objective_type = int(data.get("objective_type", QuestData.ObjectiveType.NONE))
	quest.objective_item_id = String(data.get("objective_item_id", ""))
	quest.objective_item_amount = int(data.get("objective_item_amount", 1))
	quest.candidate_item_ids = data.get("candidate_item_ids", []).duplicate()
	quest.candidate_categories = data.get("candidate_categories", []).duplicate()
	quest.amount_min = int(data.get("amount_min", 1))
	quest.amount_max = int(data.get("amount_max", 1))
	quest.time_limit_seconds = float(data.get("time_limit_seconds", 0.0))
	quest.reward_gold = int(data.get("reward_gold", 0))
	quest.random_reward_use_sell_price = bool(data.get("random_reward_use_sell_price", true))
	quest.reward_bonus_rate_min = float(data.get("reward_bonus_rate_min", 1.1))
	quest.reward_bonus_rate_max = float(data.get("reward_bonus_rate_max", 1.5))
	quest.reward_item_ids = data.get("reward_item_ids", []).duplicate()
	quest.reward_item_amounts = data.get("reward_item_amounts", []).duplicate()
	quest.allowed_unit_role_flags = int(data.get("allowed_unit_role_flags", 0))
	quest.weight = int(data.get("weight", 100))
	quest.repeatable = bool(data.get("repeatable", true))
	quest.accept_text = String(data.get("accept_text", "ありがとうございます。"))
	quest.progress_text = String(data.get("progress_text", "進み具合はどうでしょうか。"))
	quest.ready_to_complete_text = String(data.get("ready_to_complete_text", "条件を満たしているようですね。"))
	quest.completed_text = String(data.get("completed_text", "助かりました。"))
	quest.failed_text = String(data.get("failed_text", "もう期限を過ぎています。"))
	return quest


func can_accept_quest(quest: QuestData, giver_unit) -> bool:
	if quest == null:
		return false
	if quest.quest_id == "":
		return false
	if has_active_quest(quest.quest_id):
		return false
	if is_completed(quest.quest_id):
		return false
	if is_failed(quest.quest_id):
		return false
	if not can_accept_more_quests():
		return false
	return true


func can_show_board_quest(quest: QuestData, giver_unit) -> bool:
	if quest == null:
		return false
	if quest.quest_id == "":
		return false
	if is_completed(quest.quest_id):
		return false
	if is_failed(quest.quest_id):
		return false
	return true


func accept_quest(quest: QuestData, giver_unit) -> Dictionary:
	_ensure_state_containers()

	if not can_accept_more_quests():
		return {
			"success": false,
			"message": "受注中の依頼が上限です。"
		}

	if not can_accept_quest(quest, giver_unit):
		return {
			"success": false,
			"message": "この依頼は受けられません。"
		}

	var giver_unit_id: String = ""
	var giver_display_name: String = ""
	var giver_portrait: Texture2D = null

	if giver_unit != null:
		if "unit_id" in giver_unit:
			giver_unit_id = String(giver_unit.unit_id)
		if giver_unit.has_method("get_talk_name"):
			giver_display_name = String(giver_unit.get_talk_name())
		elif "talk_display_name" in giver_unit:
			giver_display_name = String(giver_unit.talk_display_name)
		else:
			giver_display_name = String(giver_unit.name)

		if "talk_portrait" in giver_unit:
			giver_portrait = giver_unit.talk_portrait

	var accepted_at: float = float(TimeManager.world_time_seconds)
	var deadline_at: float = -1.0

	if quest.time_limit_seconds > 0.0:
		deadline_at = accepted_at + quest.time_limit_seconds

	WorldState.quest_active_data[quest.quest_id] = {
		"quest_id": quest.quest_id,
		"title": quest.title,
		"description": quest.description,
		"giver_unit_id": giver_unit_id,
		"giver_display_name": giver_display_name,
		"giver_portrait": giver_portrait,
		"accepted_at": accepted_at,
		"deadline_at": deadline_at,
		"objective_type": int(quest.objective_type),
		"objective_item_id": quest.objective_item_id,
		"objective_item_amount": quest.objective_item_amount,
		"reward_gold": quest.reward_gold,
		"reward_item_ids": quest.reward_item_ids.duplicate(),
		"reward_item_amounts": quest.reward_item_amounts.duplicate()
	}

	var message: String = quest.accept_text
	if message == "":
		message = "依頼を受けました。"

	return {
		"success": true,
		"message": message
	}


func accept_quest_from_board(quest: QuestData, giver_unit, player_unit) -> bool:
	var result: Dictionary = accept_quest(quest, giver_unit)
	return bool(result.get("success", false))


func abandon_quest(quest_id: String) -> Dictionary:
	_ensure_state_containers()

	if quest_id == "":
		return {
			"success": false,
			"message": "依頼IDが不正です。"
		}

	if not WorldState.quest_active_data.has(quest_id):
		return {
			"success": false,
			"message": "その依頼は進行中ではありません。"
		}

	var data: Dictionary = get_active_quest_data(quest_id)
	data["failed_reason"] = "abandoned"
	data["failed_at"] = float(TimeManager.world_time_seconds)

	WorldState.quest_active_data.erase(quest_id)
	WorldState.quest_failed_data[quest_id] = data

	return {
		"success": true,
		"message": "依頼を辞退しました。"
	}


func _roll_objective_data(quest: QuestData) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var item_id: String = ""
	var category: String = ""
	var amount: int = max(1, quest.objective_item_amount)

	if quest.objective_item_id != "":
		item_id = quest.objective_item_id
	elif not quest.candidate_item_ids.is_empty():
		var valid_candidates: Array[String] = []

		for candidate in quest.candidate_item_ids:
			var candidate_id: String = String(candidate)
			if candidate_id == "":
				continue
			if not ItemDatabase.exists(candidate_id):
				continue
			if not ItemDatabase.can_sell(candidate_id):
				continue
			valid_candidates.append(candidate_id)

		if valid_candidates.is_empty():
			return {}

		item_id = valid_candidates[rng.randi_range(0, valid_candidates.size() - 1)]
	elif not quest.candidate_categories.is_empty():
		var valid_categories: Array[String] = []

		for raw_category in quest.candidate_categories:
			var category_name: String = ItemCategories.normalize(String(raw_category))
			if category_name == "":
				continue

			var category_items: Array[String] = ItemDatabase.get_item_ids_by_category(category_name)
			var sellable_items: Array[String] = []

			for candidate_id in category_items:
				if ItemDatabase.exists(candidate_id) and ItemDatabase.can_sell(candidate_id):
					sellable_items.append(candidate_id)

			if sellable_items.is_empty():
				continue

			valid_categories.append(category_name)

		if valid_categories.is_empty():
			return {}

		category = valid_categories[rng.randi_range(0, valid_categories.size() - 1)]

		var category_candidates: Array[String] = ItemDatabase.get_item_ids_by_category(category)
		var valid_item_candidates: Array[String] = []
		for candidate_id in category_candidates:
			if ItemDatabase.exists(candidate_id) and ItemDatabase.can_sell(candidate_id):
				valid_item_candidates.append(candidate_id)

		if valid_item_candidates.is_empty():
			return {}

		item_id = valid_item_candidates[rng.randi_range(0, valid_item_candidates.size() - 1)]
	else:
		return {}

	if item_id == "":
		return {}

	var max_stack: int = ItemDatabase.get_max_stack(item_id)

	if max_stack <= 1:
		amount = 1
	else:
		if quest.objective_item_id != "":
			amount = max(1, quest.objective_item_amount)
		else:
			var min_amount: int = max(1, quest.amount_min)
			var max_amount: int = max(min_amount, quest.amount_max)
			amount = rng.randi_range(min_amount, max_amount)

	return {
		"item_id": item_id,
		"amount": amount,
		"category": category
	}


func _build_final_text(template_text: String, fallback_text: String, item_id: String, amount: int, category: String) -> String:
	var base_text: String = template_text
	if base_text == "":
		base_text = fallback_text

	var item_name: String = _get_item_name(item_id)
	var category_name: String = ""
	if category != "":
		category_name = ItemDatabase.get_category_display_name(category)

	base_text = base_text.replace("{item_id}", item_id)
	base_text = base_text.replace("{item_name}", item_name)
	base_text = base_text.replace("{amount}", str(amount))
	base_text = base_text.replace("{category}", category)
	base_text = base_text.replace("{category_name}", category_name)

	return base_text


func _roll_reward_data(quest: QuestData, item_id: String, amount: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var total_reward_gold: int = max(0, quest.reward_gold)

	if quest.random_reward_use_sell_price:
		var sell_price: int = ItemDatabase.get_sell_price(item_id)
		var min_rate: float = max(0.0, quest.reward_bonus_rate_min)
		var max_rate: float = max(min_rate, quest.reward_bonus_rate_max)
		var bonus_rate: float = rng.randf_range(min_rate, max_rate)
		var variable_reward: int = int(round(float(sell_price * amount) * bonus_rate))
		total_reward_gold += max(0, variable_reward)

	return {
		"reward_gold": total_reward_gold
	}


func get_active_quest_data(quest_id: String) -> Dictionary:
	_ensure_state_containers()

	if not WorldState.quest_active_data.has(quest_id):
		return {}

	var value: Variant = WorldState.quest_active_data[quest_id]
	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return (value as Dictionary).duplicate(true)


func has_time_limit(quest_id: String) -> bool:
	var data: Dictionary = get_active_quest_data(quest_id)
	if data.is_empty():
		return false

	var deadline_at: float = float(data.get("deadline_at", -1.0))
	return deadline_at > 0.0


func is_expired(quest_id: String) -> bool:
	var data: Dictionary = get_active_quest_data(quest_id)
	if data.is_empty():
		return false

	var deadline_at: float = float(data.get("deadline_at", -1.0))
	if deadline_at <= 0.0:
		return false

	return TimeManager.world_time_seconds > deadline_at


func get_remaining_seconds(quest_id: String) -> float:
	var data: Dictionary = get_active_quest_data(quest_id)
	if data.is_empty():
		return -1.0

	var deadline_at: float = float(data.get("deadline_at", -1.0))
	if deadline_at <= 0.0:
		return -1.0

	return maxf(0.0, deadline_at - TimeManager.world_time_seconds)


func format_seconds_to_limit_text(seconds: float) -> String:
	if seconds < 0.0:
		return "無期限"

	var total_seconds: int = int(seconds)
	var days: int = total_seconds / 86400
	var remain_after_days: int = total_seconds % 86400
	var hours: int = remain_after_days / 3600
	var remain_after_hours: int = remain_after_days % 3600
	var minutes: int = remain_after_hours / 60

	if days > 0:
		return "%d日 %d時間 %d分" % [days, hours, minutes]

	if hours > 0:
		return "%d時間 %d分" % [hours, minutes]

	return "%d分" % [minutes]


func check_time_limit_failures() -> void:
	_ensure_state_containers()

	var expired_ids: Array[String] = []

	for quest_id in WorldState.quest_active_data.keys():
		var data_value: Variant = WorldState.quest_active_data.get(quest_id, {})
		if typeof(data_value) != TYPE_DICTIONARY:
			continue

		var data: Dictionary = data_value
		var deadline_at: float = float(data.get("deadline_at", -1.0))
		if deadline_at <= 0.0:
			continue

		if TimeManager.world_time_seconds > deadline_at:
			expired_ids.append(String(quest_id))

	for quest_id in expired_ids:
		fail_quest(quest_id)


func fail_quest(quest_id: String) -> void:
	_ensure_state_containers()

	if not WorldState.quest_active_data.has(quest_id):
		return

	var data: Dictionary = get_active_quest_data(quest_id)
	WorldState.quest_active_data.erase(quest_id)
	WorldState.quest_failed_data[quest_id] = data

	if DialogueManager != null and DialogueManager.has_method("queue_failed_quest_dialog"):
		DialogueManager.queue_failed_quest_dialog(data)


func can_complete_quest(quest_id: String, player_unit) -> bool:
	if quest_id == "":
		return false
	if not has_active_quest(quest_id):
		return false
	if is_expired(quest_id):
		return false

	var data: Dictionary = get_active_quest_data(quest_id)
	if data.is_empty():
		return false

	var objective_type: int = int(data.get("objective_type", 0))

	match objective_type:
		QuestData.ObjectiveType.DELIVER_ITEM:
			var item_id: String = String(data.get("objective_item_id", ""))
			var amount: int = int(data.get("objective_item_amount", 1))
			var inventory: Inventory = _get_player_inventory(player_unit)
			if inventory == null:
				return false
			return inventory.can_consume_total_amount_ignore_instance(item_id, amount)
		_:
			return false


func complete_quest(quest_id: String, player_unit) -> Dictionary:
	_ensure_state_containers()

	if not has_active_quest(quest_id):
		return {
			"success": false,
			"message": "受注中ではありません。"
		}

	if is_expired(quest_id):
		fail_quest(quest_id)
		return {
			"success": false,
			"message": "依頼は期限切れです。"
		}

	if not can_complete_quest(quest_id, player_unit):
		return {
			"success": false,
			"message": "まだ条件を満たしていません。"
		}

	var data: Dictionary = get_active_quest_data(quest_id)
	var inventory: Inventory = _get_player_inventory(player_unit)

	if inventory == null:
		return {
			"success": false,
			"message": "インベントリが見つかりません。"
		}

	var objective_type: int = int(data.get("objective_type", 0))
	if objective_type == QuestData.ObjectiveType.DELIVER_ITEM:
		var item_id: String = String(data.get("objective_item_id", ""))
		var amount: int = int(data.get("objective_item_amount", 1))
		if not inventory.consume_total_amount_ignore_instance(item_id, amount):
			return {
				"success": false,
				"message": "必要アイテムの消費に失敗しました。"
			}

	var reward_texts: Array[String] = []

	var reward_gold: int = int(data.get("reward_gold", 0))
	if reward_gold > 0:
		if ItemDatabase.exists("gold"):
			inventory.add_item("gold", reward_gold)
			reward_texts.append("gold x%d" % reward_gold)
		elif "gold" in PlayerData:
			PlayerData.gold += reward_gold
			reward_texts.append("%dG" % reward_gold)

	var reward_item_ids: Array = data.get("reward_item_ids", [])
	var reward_item_amounts: Array = data.get("reward_item_amounts", [])

	var reward_count: int = min(reward_item_ids.size(), reward_item_amounts.size())
	var i: int = 0
	while i < reward_count:
		var reward_item_id: String = String(reward_item_ids[i])
		var reward_amount: int = int(reward_item_amounts[i])

		if reward_item_id != "" and reward_amount > 0:
			inventory.add_item(reward_item_id, reward_amount)
			reward_texts.append("%s x%d" % [_get_item_name(reward_item_id), reward_amount])

		i += 1

	if player_unit != null and player_unit.has_method("notify_inventory_refresh"):
		player_unit.notify_inventory_refresh()

	WorldState.quest_active_data.erase(quest_id)
	WorldState.quest_completed_data[quest_id] = data

	var reward_message: String = "報酬を受け取りました。"
	if not reward_texts.is_empty():
		reward_message = "報酬: " + " / ".join(reward_texts)

	return {
		"success": true,
		"message": reward_message
	}


func complete_quest_from_board(quest_id: String, giver_unit, player_unit) -> bool:
	var result: Dictionary = complete_quest(quest_id, player_unit)
	return bool(result.get("success", false))


func _get_player_inventory(player_unit) -> Inventory:
	if player_unit == null:
		return null

	if player_unit.has_node("Inventory"):
		return player_unit.get_node("Inventory") as Inventory

	return null


func _get_item_name(item_id: String) -> String:
	if item_id == "":
		return ""

	if not ItemDatabase.exists(item_id):
		return item_id

	var display_name: String = ItemDatabase.get_display_name(item_id)
	if display_name == "":
		return item_id

	return display_name


func get_board_quests(linked_unit_ids: Array[String], player_unit) -> Array:
	var result: Array = []
	var target_units: Array = []

	if linked_unit_ids.is_empty():
		var units = get_tree().get_nodes_in_group("units")
		for unit in units:
			if unit == null:
				continue
			target_units.append(unit)
	else:
		for raw_unit_id in linked_unit_ids:
			var unit_id: String = String(raw_unit_id)
			if unit_id == "":
				continue

			var giver_unit = _find_unit_by_id(unit_id)
			if giver_unit == null:
				continue

			target_units.append(giver_unit)

	for giver_unit in target_units:
		if giver_unit == null:
			continue

		if "is_player_unit" in giver_unit and bool(giver_unit.is_player_unit):
			continue

		var quests: Array = get_unit_offer_quests(giver_unit)
		if quests.is_empty():
			continue

		for raw_quest in quests:
			var quest: QuestData = raw_quest as QuestData
			if quest == null:
				continue

			if not can_show_board_quest(quest, giver_unit):
				continue

			var state: String = get_quest_state(quest.quest_id)
			var can_accept_flag: bool = can_accept_quest(quest, giver_unit)
			var can_complete_flag: bool = false

			if state == STATUS_ACTIVE:
				can_complete_flag = can_complete_quest(quest.quest_id, player_unit)

			var state_text: String = _build_board_state_text(quest.quest_id, giver_unit, player_unit)

			result.append({
				"giver_unit": giver_unit,
				"giver_unit_id": String(giver_unit.get("unit_id")),
				"giver_name": _get_unit_display_name(giver_unit),
				"giver_portrait": _get_unit_portrait(giver_unit),
				"quest": quest,
				"quest_title": quest.title,
				"detail_text": _build_board_detail_text(quest, player_unit),
				"progress_text": _build_board_progress_text(quest, player_unit),
				"reward_text": _build_board_reward_text(quest),
				"remaining_time_text": _build_board_time_limit_text(quest),
				"state_text": state_text,
				"can_accept": can_accept_flag,
				"can_complete": can_complete_flag
			})

	return result


func _find_unit_by_id(unit_id: String):
	if unit_id == "":
		return null

	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if "unit_id" in unit and String(unit.unit_id) == unit_id:
			return unit

	return null


func _get_unit_display_name(unit) -> String:
	if unit == null:
		return ""

	if unit.has_method("get_talk_name"):
		return String(unit.get_talk_name())

	if "talk_display_name" in unit and String(unit.talk_display_name) != "":
		return String(unit.talk_display_name)

	return String(unit.name)


func _get_unit_portrait(unit):
	if unit == null:
		return null

	if "talk_portrait" in unit:
		return unit.talk_portrait

	return null


func _build_board_detail_text(quest: QuestData, player_unit) -> String:
	if quest == null:
		return ""

	return String(quest.description)


func _build_board_progress_text(quest: QuestData, player_unit) -> String:
	if quest == null:
		return ""

	var item_id: String = String(quest.objective_item_id)
	var amount: int = int(quest.objective_item_amount)
	var current_amount: int = 0

	if player_unit != null and player_unit.has_node("Inventory"):
		var inv = player_unit.get_node("Inventory")
		if inv != null and inv.has_method("get_total_amount_ignore_instance"):
			current_amount = int(inv.get_total_amount_ignore_instance(item_id))

	var item_name: String = _get_item_name(item_id)

	return "必要: %s x%d    所持: %d / %d" % [item_name, amount, current_amount, amount]


func _build_board_reward_text(quest: QuestData) -> String:
	if quest == null:
		return ""

	var parts: Array[String] = []

	if int(quest.reward_gold) > 0:
		parts.append("%dG" % int(quest.reward_gold))

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


func _build_board_time_limit_text(quest: QuestData) -> String:
	if quest == null:
		return ""

	if float(quest.time_limit_seconds) <= 0.0:
		return "制限時間: なし"

	return "制限時間: %s" % format_seconds_to_limit_text(float(quest.time_limit_seconds))


func _build_board_state_text(quest_id: String, giver_unit, player_unit) -> String:
	var state: String = get_quest_state(quest_id)

	if state == STATUS_COMPLETED:
		return "完了済み"

	if state == STATUS_FAILED:
		return "失敗"

	if state == STATUS_ACTIVE:
		if can_complete_quest(quest_id, player_unit):
			return "報告可能"
		return "進行中"

	var quest: QuestData = null
	var quests: Array = get_unit_offer_quests(giver_unit)
	for raw_quest in quests:
		var q: QuestData = raw_quest as QuestData
		if q != null and q.quest_id == quest_id:
			quest = q
			break

	if quest != null:
		if not can_accept_more_quests():
			return "未受注（上限）"

		if can_accept_quest(quest, giver_unit):
			return "未受注"

	return ""
