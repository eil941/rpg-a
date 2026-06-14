extends Node

var items: Dictionary = {}
var effects: Dictionary = {}
var quests: Dictionary = {}
var enemies: Dictionary = {}
var npcs: Dictionary = {}
var enchantments: Dictionary = {}
var dungeon_spawn_rules: Dictionary = {}
var unit_spawn_rules: Dictionary = {}

var item_effect_links: Dictionary = {}

var item_spawn_rules: Array[ItemSpawnRuleData] = []


func _ready() -> void:
	load_all()
	validate_all()


func load_all() -> void:
	items.clear()
	effects.clear()
	quests.clear()
	enemies.clear()
	npcs.clear()
	enchantments.clear()
	item_effect_links.clear()
	item_spawn_rules.clear()
	dungeon_spawn_rules.clear()
	unit_spawn_rules.clear()

	_load_items()
	_load_equipment()
	_load_item_effects()
	_load_item_effect_links()
	_apply_item_effect_links()
	_load_enchantments()
	_load_dungeon_spawn_rules()
	_load_unit_spawn_rules()
	_load_enemies()
	_load_npcs()
	_load_quests()
	_load_item_spawn_rules()


	# 確認したいときだけ有効化
	# debug_print_loaded_data()

func get_item(item_id: String):
	return items.get(item_id)


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func get_all_items() -> Array:
	return items.values()


func get_all_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []

	for quest in quests.values():
		result.append(quest)

	return result


func get_quest(quest_id: String) -> QuestData:
	return quests.get(quest_id, null) as QuestData


func has_quest(quest_id: String) -> bool:
	return quests.has(quest_id)


func get_enemy(enemy_type_id: String) -> EnemyData:
	return enemies.get(enemy_type_id, null) as EnemyData


func has_enemy(enemy_type_id: String) -> bool:
	return enemies.has(enemy_type_id)


func get_all_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	for enemy in enemies.values():
		var enemy_data := enemy as EnemyData
		if enemy_data == null:
			continue
		result.append(enemy_data)

	return result


func get_npc(npc_type_id: String) -> NpcData:
	return npcs.get(npc_type_id, null) as NpcData


func has_npc(npc_type_id: String) -> bool:
	return npcs.has(npc_type_id)


func get_all_npcs() -> Array[NpcData]:
	var result: Array[NpcData] = []

	for npc in npcs.values():
		var npc_data := npc as NpcData
		if npc_data == null:
			continue
		result.append(npc_data)

	return result


func get_enchantment(enchant_id: String) -> EnchantmentData:
	return enchantments.get(enchant_id, null) as EnchantmentData


func has_enchantment(enchant_id: String) -> bool:
	return enchantments.has(enchant_id)


func get_all_enchantments() -> Array[EnchantmentData]:
	var result: Array[EnchantmentData] = []

	for enchantment in enchantments.values():
		var enchantment_data := enchantment as EnchantmentData
		if enchantment_data == null:
			continue
		result.append(enchantment_data)

	return result


func get_unit_spawn_rule(rule_id: String) -> SpawnRuleData:
	return unit_spawn_rules.get(rule_id, null) as SpawnRuleData


func has_unit_spawn_rule(rule_id: String) -> bool:
	return unit_spawn_rules.has(rule_id)


func get_all_unit_spawn_rules() -> Array[SpawnRuleData]:
	var result: Array[SpawnRuleData] = []

	for rule in unit_spawn_rules.values():
		var rule_data := rule as SpawnRuleData
		if rule_data == null:
			continue
		result.append(rule_data)

	return result


func get_dungeon_spawn_rule(rule_id: String) -> DungeonSpawnRuleData:
	return dungeon_spawn_rules.get(rule_id, null) as DungeonSpawnRuleData


func has_dungeon_spawn_rule(rule_id: String) -> bool:
	return dungeon_spawn_rules.has(rule_id)


func get_all_dungeon_spawn_rules() -> Array[DungeonSpawnRuleData]:
	var result: Array[DungeonSpawnRuleData] = []

	for rule in dungeon_spawn_rules.values():
		var rule_data := rule as DungeonSpawnRuleData
		if rule_data == null:
			continue
		result.append(rule_data)

	return result


func get_all_item_spawn_rules() -> Array[ItemSpawnRuleData]:
	return item_spawn_rules.duplicate()


func get_item_spawn_rule(rule_id: String) -> ItemSpawnRuleData:
	for rule in item_spawn_rules:
		if rule == null:
			continue
		if rule.rule_id == rule_id:
			return rule

	return null


func has_item_spawn_rule(rule_id: String) -> bool:
	return get_item_spawn_rule(rule_id) != null


# ============================================================
# TSV読み込み
# ============================================================

func _load_tsv(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("TSV not found: " + path)
		return []

	if file.eof_reached():
		return []

	var header_line := file.get_line()
	var headers := header_line.split("\t", true)

	var rows: Array[Dictionary] = []

	while not file.eof_reached():
		var line := file.get_line()

		if line.strip_edges() == "":
			continue

		if line.begins_with("#"):
			continue

		var cols := line.split("\t", true)
		var row := {}

		for i in range(headers.size()):
			var key := String(headers[i]).strip_edges()
			var value := ""

			if i < cols.size():
				value = String(cols[i])

			row[key] = value

		rows.append(row)

	return rows

# ============================================================
# 型変換
# ============================================================

func _get_string(row: Dictionary, key: String, default_value: String = "") -> String:
	return String(row.get(key, default_value))


func _to_bool(value: String) -> bool:
	var text := value.strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"


func _to_int(value: String, default_value: int = 0) -> int:
	if value.strip_edges() == "":
		return default_value

	return int(value)


func _to_float(value: String, default_value: float = 0.0) -> float:
	if value.strip_edges() == "":
		return default_value

	return float(value)


func _split_list(value: String) -> Array[String]:
	var result: Array[String] = []
	value = value.strip_edges()

	if value == "":
		return result

	for part in value.split("|", false):
		var text := String(part).strip_edges()

		if text != "":
			result.append(text)

	return result


func _split_int_list(value: String) -> Array[int]:
	var result: Array[int] = []

	for text in _split_list(value):
		result.append(int(text))

	return result


func _split_float_dict(value: String) -> Dictionary:
	var result: Dictionary = {}
	value = value.strip_edges()

	if value == "":
		return result

	for entry in value.split("|", false):
		var entry_text := String(entry).strip_edges()
		if entry_text == "":
			continue

		var parts := entry_text.split("=", true)
		if parts.size() < 2:
			continue

		var key := String(parts[0]).strip_edges()
		var number_text := String(parts[1]).strip_edges()
		if key == "":
			continue

		result[key] = _to_float(number_text, 0.0)

	return result


func _split_int_dict(value: String) -> Dictionary:
	var result: Dictionary = {}
	value = value.strip_edges()

	if value == "":
		return result

	for entry in value.split("|", false):
		var entry_text := String(entry).strip_edges()
		if entry_text == "":
			continue

		var parts := entry_text.split("=", true)
		if parts.size() < 2:
			continue

		var key := String(parts[0]).strip_edges()
		var number_text := String(parts[1]).strip_edges()
		if key == "":
			continue

		result[key] = _to_int(number_text, 0)

	return result


func _load_resource_or_null(path: String):
	path = path.strip_edges()

	if path == "":
		return null

	var resource = load(path)
	if resource == null:
		push_warning("resource load failed: " + path)

	return resource


func _split_texture_array(value: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []

	for path in _split_list(value):
		var texture := _load_resource_or_null(path) as Texture2D
		if texture == null:
			continue
		result.append(texture)

	return result


func _split_initial_inventory_entries(value: String) -> Array[InitialInventoryEntry]:
	var result: Array[InitialInventoryEntry] = []
	value = value.strip_edges()

	if value == "":
		return result

	for entry_text in value.split(";", false):
		var text := String(entry_text).strip_edges()
		if text == "":
			continue

		var parts := text.split(",", true)
		if parts.size() < 1:
			continue

		var entry := InitialInventoryEntry.new()
		entry.item_id = String(parts[0]).strip_edges()

		if parts.size() >= 2:
			entry.amount_min = _to_int(String(parts[1]), 1)
		if parts.size() >= 3:
			entry.amount_max = _to_int(String(parts[2]), entry.amount_min)
		if parts.size() >= 4:
			entry.chance = _to_float(String(parts[3]), 1.0)
		if parts.size() >= 5:
			entry.roll_equipment_enchantments = _to_bool(String(parts[4]))

		if entry.item_id != "":
			result.append(entry)

	return result


func _split_loot_categories(value: String) -> Array[LootCategoryEntry]:
	var result: Array[LootCategoryEntry] = []
	value = value.strip_edges()

	if value == "":
		return result

	for entry_text in value.split(";", false):
		var text := String(entry_text).strip_edges()
		if text == "":
			continue

		var parts := text.split(",", true)
		if parts.size() < 1:
			continue

		var entry := LootCategoryEntry.new()
		entry.item_type = String(parts[0]).strip_edges()

		if parts.size() >= 2:
			entry.weight = _to_int(String(parts[1]), 100)
		if parts.size() >= 3:
			entry.min_amount = _to_int(String(parts[2]), 1)
		if parts.size() >= 4:
			entry.max_amount = _to_int(String(parts[3]), entry.min_amount)

		if entry.item_type != "":
			result.append(entry)

	return result


# ============================================================
# ItemData
# ============================================================

func _load_items() -> void:
	var rows := _load_tsv("res://data/master/items.tsv")

	for row in rows:
		var item := ItemData.new()

		item.item_id = _get_string(row, "item_id")
		item.display_name = _get_string(row, "display_name")
		item.description = _get_string(row, "description")
		item.category = _get_string(row, "category")
		item.max_stack = _to_int(_get_string(row, "max_stack"), 99)
		item.usable = _to_bool(_get_string(row, "usable", "false"))
		item.base_price = _to_int(_get_string(row, "base_price"), 0)
		item.can_sell = _to_bool(_get_string(row, "can_sell", "true"))
		item.rarity = _to_int(_get_string(row, "rarity"), 1)
		item.spawn_weight = _to_int(_get_string(row, "spawn_weight"), 100)
		item.use_flags = _to_int(_get_string(row, "use_flags"), 0)
		item.target_flags = _to_int(_get_string(row, "target_flags"), 0)

		var icon_path := _get_string(row, "icon_path").strip_edges()
		if icon_path != "":
			item.icon = load(icon_path)

		_register_item(item)


func _register_item(item: ItemData) -> void:
	if item == null:
		return

	if item.item_id == "":
		push_error("item_id is empty")
		return

	if items.has(item.item_id):
		push_error("duplicate item_id: " + item.item_id)
		return

	items[item.item_id] = item


# ============================================================
# EquipmentData
# ============================================================

func _load_equipment() -> void:
	var rows := _load_tsv("res://data/master/equipment.tsv")

	for row in rows:
		var item_id := _get_string(row, "item_id").strip_edges()

		if item_id == "":
			push_error("equipment item_id is empty")
			continue

		var base_item: ItemData = items.get(item_id)

		if base_item == null:
			push_error("equipment item_id not found in items.tsv: " + item_id)
			continue

		var equip := EquipmentData.new()
		_copy_item_fields(base_item, equip)

		equip.slot_type = _equipment_slot_from_text(_get_string(row, "slot_type", "HAND"))
		equip.max_hp_bonus = _to_int(_get_string(row, "max_hp_bonus"), 0)
		equip.attack_bonus = _to_int(_get_string(row, "attack_bonus"), 0)
		equip.defense_bonus = _to_int(_get_string(row, "defense_bonus"), 0)
		equip.speed_bonus = _to_int(_get_string(row, "speed_bonus"), 0)
		equip.attack_type_id = _get_string(row, "attack_type_id", "melee")
		equip.attack_min_range = _to_int(_get_string(row, "attack_min_range"), 1)
		equip.attack_max_range = _to_int(_get_string(row, "attack_max_range"), 1)
		equip.combat_style = _combat_style_from_text(_get_string(row, "combat_style", "AUTO"))
		equip.move_style = _move_style_from_text(_get_string(row, "move_style", "AUTO"))

		items[item_id] = equip


func _copy_item_fields(src: ItemData, dst: ItemData) -> void:
	dst.item_id = src.item_id
	dst.display_name = src.display_name
	dst.description = src.description
	dst.icon = src.icon
	dst.category = src.category
	dst.max_stack = src.max_stack
	dst.usable = src.usable
	dst.base_price = src.base_price
	dst.can_sell = src.can_sell
	dst.rarity = src.rarity
	dst.spawn_weight = src.spawn_weight
	dst.use_flags = src.use_flags
	dst.target_flags = src.target_flags
	dst.effects = src.effects


func _equipment_slot_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"HAND":
			return EquipmentData.EquipmentSlot.HAND
		"HEAD":
			return EquipmentData.EquipmentSlot.HEAD
		"BODY":
			return EquipmentData.EquipmentSlot.BODY
		"HANDS":
			return EquipmentData.EquipmentSlot.HANDS
		"WAIST":
			return EquipmentData.EquipmentSlot.WAIST
		"FEET":
			return EquipmentData.EquipmentSlot.FEET
		"ACCESSORY":
			return EquipmentData.EquipmentSlot.ACCESSORY
		_:
			return EquipmentData.EquipmentSlot.HAND


func _combat_style_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"MELEE":
			return EquipmentData.AICombatStyle.MELEE
		"MID":
			return EquipmentData.AICombatStyle.MID
		"LONG":
			return EquipmentData.AICombatStyle.LONG
		"SUPPORTER":
			return EquipmentData.AICombatStyle.SUPPORTER
		"HIT_AND_RUN":
			return EquipmentData.AICombatStyle.HIT_AND_RUN
		"DEFENSIVE":
			return EquipmentData.AICombatStyle.DEFENSIVE
		_:
			return EquipmentData.AICombatStyle.AUTO


func _move_style_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"APPROACH":
			return EquipmentData.AIMoveStyle.APPROACH
		"KEEP_DISTANCE":
			return EquipmentData.AIMoveStyle.KEEP_DISTANCE
		"FLEE":
			return EquipmentData.AIMoveStyle.FLEE
		"HOLD":
			return EquipmentData.AIMoveStyle.HOLD
		_:
			return EquipmentData.AIMoveStyle.AUTO


# ============================================================
# ItemEffectData
# ============================================================

func _load_item_effects() -> void:
	var rows := _load_tsv("res://data/master/item_effects.tsv")

	for row in rows:
		var effect_id := _get_string(row, "effect_id").strip_edges()

		if effect_id == "":
			push_error("effect_id is empty")
			continue

		if effects.has(effect_id):
			push_error("duplicate effect_id: " + effect_id)
			continue

		var effect := _build_item_effect(row)
		effects[effect_id] = effect


func _build_item_effect(row: Dictionary) -> ItemEffectData:
	var effect := ItemEffectData.new()
	var effect_type := _get_string(row, "effect_type").strip_edges()

	match effect_type:
		"restore_resource":
			effect.effect_type = ItemEffectData.EffectType.RESTORE_RESOURCE
			effect.resource_type = _resource_type_from_text(_get_string(row, "resource_type", "hp"))
			effect.value_mode = _value_mode_from_text(_get_string(row, "value_mode", "flat"))
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)
			effect.percent_value = _to_float(_get_string(row, "percent_value"), 0.0)

		"cure_status":
			effect.effect_type = ItemEffectData.EffectType.CURE_STATUS
			effect.status_id = StringName(_get_string(row, "status_id"))

		"apply_status":
			effect.effect_type = ItemEffectData.EffectType.APPLY_STATUS
			effect.status_id = StringName(_get_string(row, "status_id"))
			effect.status_power = _to_int(_get_string(row, "status_power"), 0)
			effect.duration_type = _duration_type_from_text(_get_string(row, "duration_type", "none"))
			effect.duration_value = _to_float(_get_string(row, "duration_value"), 0.0)

		"apply_modifier":
			effect.effect_type = ItemEffectData.EffectType.APPLY_MODIFIER
			effect.modifier_kind = _modifier_kind_from_text(_get_string(row, "modifier_kind", "buff"))
			effect.stat_name = StringName(_get_string(row, "stat_name"))
			effect.stat_flat = _to_int(_get_string(row, "stat_flat"), 0)
			effect.stat_percent = _to_float(_get_string(row, "stat_percent"), 0.0)
			effect.duration_type = _duration_type_from_text(_get_string(row, "duration_type", "none"))
			effect.duration_value = _to_float(_get_string(row, "duration_value"), 0.0)

		"deal_damage":
			effect.effect_type = ItemEffectData.EffectType.DEAL_DAMAGE
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)

		"grant_item":
			effect.effect_type = ItemEffectData.EffectType.GRANT_ITEM
			effect.grant_item_id = _get_string(row, "grant_item_id")
			effect.grant_item_amount = _to_int(_get_string(row, "grant_item_amount"), 1)

		"grant_currency":
			effect.effect_type = ItemEffectData.EffectType.GRANT_CURRENCY
			effect.grant_currency_amount = _to_int(_get_string(row, "grant_currency_amount"), 0)

		"teleport":
			effect.effect_type = ItemEffectData.EffectType.TELEPORT
			effect.teleport_mode = _teleport_mode_from_text(_get_string(row, "teleport_mode", "random"))
			effect.teleport_min_range = _to_int(_get_string(row, "teleport_min_range"), 0)
			effect.teleport_max_range = _to_int(_get_string(row, "teleport_max_range"), 999)
			effect.warp_point_id = StringName(_get_string(row, "warp_point_id"))

		"permanent_stat_growth":
			effect.effect_type = ItemEffectData.EffectType.PERMANENT_STAT_GROWTH
			effect.stat_name = StringName(_get_string(row, "stat_name"))
			effect.power_min = _to_int(_get_string(row, "power_min"), 0)
			effect.power_max = _to_int(_get_string(row, "power_max"), effect.power_min)

		"learn_skill":
			effect.effect_type = ItemEffectData.EffectType.LEARN_SKILL
			effect.skill_id = StringName(_get_string(row, "skill_id"))

		"unlock_recipe":
			effect.effect_type = ItemEffectData.EffectType.UNLOCK_RECIPE
			effect.recipe_id = StringName(_get_string(row, "recipe_id"))

		"identify_item":
			effect.effect_type = ItemEffectData.EffectType.IDENTIFY_ITEM
			effect.identify_all = _to_bool(_get_string(row, "identify_all", "false"))

		"read_document":
			effect.effect_type = ItemEffectData.EffectType.READ_DOCUMENT
			effect.document_text = _get_string(row, "document_text")

		"spawn_object":
			effect.effect_type = ItemEffectData.EffectType.SPAWN_OBJECT
			effect.spawn_object_id = StringName(_get_string(row, "spawn_object_id"))

		"none", "":
			effect.effect_type = ItemEffectData.EffectType.NONE

		_:
			push_error("unknown effect_type: " + effect_type)
			effect.effect_type = ItemEffectData.EffectType.NONE

	var curse_random_status_count_text := _get_string(row, "curse_random_status_count")
	if curse_random_status_count_text.strip_edges() != "":
		effect.curse_random_status_count = _to_int(curse_random_status_count_text, effect.curse_random_status_count)

	var curse_status_pool_text := _get_string(row, "curse_status_pool")
	if curse_status_pool_text.strip_edges() != "":
		var pool: Array[StringName] = []
		for status_text in _split_list(curse_status_pool_text):
			pool.append(StringName(status_text))
		effect.curse_status_pool = pool

	var curse_status_power_overrides_text := _get_string(row, "curse_status_power_overrides")
	if curse_status_power_overrides_text.strip_edges() != "":
		effect.curse_status_power_overrides = _split_int_list(curse_status_power_overrides_text)

	var curse_duration_type_overrides_text := _get_string(row, "curse_duration_type_overrides")
	if curse_duration_type_overrides_text.strip_edges() != "":
		var duration_types: Array[int] = []
		for duration_type_text in _split_list(curse_duration_type_overrides_text):
			duration_types.append(_duration_type_from_text(duration_type_text))
		effect.curse_duration_type_overrides = duration_types

	var curse_duration_value_overrides_text := _get_string(row, "curse_duration_value_overrides")
	if curse_duration_value_overrides_text.strip_edges() != "":
		var duration_values: Array[float] = []
		for duration_value_text in _split_list(curse_duration_value_overrides_text):
			duration_values.append(_to_float(duration_value_text, 0.0))
		effect.curse_duration_value_overrides = duration_values


	return effect


func _resource_type_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"hp":
			return ItemEffectData.ResourceType.HP
		"mp":
			return ItemEffectData.ResourceType.MP
		"stamina":
			return ItemEffectData.ResourceType.STAMINA
		"hunger":
			return ItemEffectData.ResourceType.HUNGER
		_:
			return ItemEffectData.ResourceType.HP


func _value_mode_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"flat":
			return ItemEffectData.ValueMode.FLAT
		"percent":
			return ItemEffectData.ValueMode.PERCENT
		"full":
			return ItemEffectData.ValueMode.FULL
		_:
			return ItemEffectData.ValueMode.FLAT


func _duration_type_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"time":
			return ItemEffectData.DurationType.TIME
		"turn":
			return ItemEffectData.DurationType.TURN
		"action":
			return ItemEffectData.DurationType.ACTION
		"none", "":
			return ItemEffectData.DurationType.NONE
		_:
			return ItemEffectData.DurationType.NONE


func _modifier_kind_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"buff":
			return ItemEffectData.ModifierKind.BUFF
		"debuff":
			return ItemEffectData.ModifierKind.DEBUFF
		_:
			return ItemEffectData.ModifierKind.BUFF


func _teleport_mode_from_text(value: String) -> int:
	match value.strip_edges().to_lower():
		"random":
			return ItemEffectData.TeleportMode.RANDOM
		"point":
			return ItemEffectData.TeleportMode.POINT
		"home":
			return ItemEffectData.TeleportMode.HOME
		"dungeon_exit":
			return ItemEffectData.TeleportMode.DUNGEON_EXIT
		_:
			return ItemEffectData.TeleportMode.RANDOM


# ============================================================
# ItemEffectLink
# ============================================================

func _load_item_effect_links() -> void:
	var rows := _load_tsv("res://data/master/item_effect_links.tsv")

	for row in rows:
		var item_id := _get_string(row, "item_id").strip_edges()
		var effect_id := _get_string(row, "effect_id").strip_edges()
		var order := _to_int(_get_string(row, "order"), 0)

		if item_id == "" or effect_id == "":
			push_error("item_effect_links has empty item_id or effect_id")
			continue

		if not item_effect_links.has(item_id):
			item_effect_links[item_id] = []

		item_effect_links[item_id].append({
			"effect_id": effect_id,
			"order": order
		})


func _apply_item_effect_links() -> void:
	for item_id in item_effect_links.keys():
		var item: ItemData = items.get(item_id)

		if item == null:
			push_error("effect link item not found: " + String(item_id))
			continue

		var links: Array = item_effect_links[item_id]
		links.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))

		item.effects.clear()

		for link in links:
			var effect_id := String(link["effect_id"])
			var effect: ItemEffectData = effects.get(effect_id)

			if effect == null:
				push_error("effect not found: " + effect_id)
				continue

			item.effects.append(effect)






# ============================================================
# SpawnRuleData
# ============================================================

func _load_unit_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/unit_spawn_rules.tsv")

	for row in rows:
		var rule := _build_unit_spawn_rule_data(row)

		if rule.rule_id == "":
			push_error("unit spawn rule_id is empty")
			continue

		if unit_spawn_rules.has(rule.rule_id):
			push_error("duplicate unit spawn rule_id: " + rule.rule_id)
			continue

		unit_spawn_rules[rule.rule_id] = rule


func _build_unit_spawn_rule_data(row: Dictionary) -> SpawnRuleData:
	var rule := SpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.spawn_kind = _get_string(row, "spawn_kind", rule.spawn_kind).strip_edges().replace("\"", "").to_upper()
	rule.allowed_generator_types = _split_upper_list(_get_string(row, "allowed_generator_types"))
	rule.min_area_difficulty = _to_int(_get_string(row, "min_area_difficulty"), rule.min_area_difficulty)
	rule.max_area_difficulty = _to_int(_get_string(row, "max_area_difficulty"), rule.max_area_difficulty)
	rule.min_enemy_difficulty = _to_int(_get_string(row, "min_enemy_difficulty"), rule.min_enemy_difficulty)
	rule.max_enemy_difficulty = _to_int(_get_string(row, "max_enemy_difficulty"), rule.max_enemy_difficulty)
	rule.use_hour_range = _to_bool(_get_string(row, "use_hour_range", "false"))
	rule.start_hour = _to_int(_get_string(row, "start_hour"), rule.start_hour)
	rule.end_hour = _to_int(_get_string(row, "end_hour"), rule.end_hour)
	rule.min_distance_from_start = _to_int(_get_string(row, "min_distance_from_start"), rule.min_distance_from_start)
	rule.max_distance_from_start = _to_int(_get_string(row, "max_distance_from_start"), rule.max_distance_from_start)
	rule.max_spawn_count = _to_int(_get_string(row, "max_spawn_count"), rule.max_spawn_count)
	rule.weight = _to_int(_get_string(row, "weight"), rule.weight)
	rule.enabled = _to_bool(_get_string(row, "enabled", "true"))

	return rule


# ============================================================
# DungeonSpawnRuleData
# ============================================================

func _load_dungeon_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/dungeon_spawn_rules.tsv")

	for row in rows:
		var rule := _build_dungeon_spawn_rule_data(row)

		if rule.rule_id == "":
			push_error("rule_id is empty")
			continue

		if dungeon_spawn_rules.has(rule.rule_id):
			push_error("duplicate dungeon spawn rule_id: " + rule.rule_id)
			continue

		dungeon_spawn_rules[rule.rule_id] = rule


func _build_dungeon_spawn_rule_data(row: Dictionary) -> DungeonSpawnRuleData:
	var rule := DungeonSpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.spawn_kind = _get_string(row, "spawn_kind", rule.spawn_kind).strip_edges().replace("\"", "").to_upper()
	rule.allowed_generator_themes = _split_upper_list(_get_string(row, "allowed_generator_themes"))
	rule.allowed_layout_generator_types = _split_upper_list(_get_string(row, "allowed_layout_generator_types"))
	rule.min_floor_difficulty = _to_int(_get_string(row, "min_floor_difficulty"), rule.min_floor_difficulty)
	rule.max_floor_difficulty = _to_int(_get_string(row, "max_floor_difficulty"), rule.max_floor_difficulty)
	rule.min_floor_number = _to_int(_get_string(row, "min_floor_number"), rule.min_floor_number)
	rule.max_floor_number = _to_int(_get_string(row, "max_floor_number"), rule.max_floor_number)
	rule.min_enemy_difficulty = _to_int(_get_string(row, "min_enemy_difficulty"), rule.min_enemy_difficulty)
	rule.max_enemy_difficulty = _to_int(_get_string(row, "max_enemy_difficulty"), rule.max_enemy_difficulty)
	rule.max_spawn_count = _to_int(_get_string(row, "max_spawn_count"), rule.max_spawn_count)
	rule.weight = _to_int(_get_string(row, "weight"), rule.weight)
	rule.enabled = _to_bool(_get_string(row, "enabled", "true"))

	return rule


func _split_upper_list(value: String) -> Array[String]:
	var result: Array[String] = []
	value = value.strip_edges()

	if value == "":
		return result

	for part in value.split("|", false):
		var text := String(part).strip_edges().replace("\"", "").to_upper()
		if text == "":
			continue
		result.append(text)

	return result


# ============================================================
# EnchantmentData
# ============================================================

func _load_enchantments() -> void:
	var rows := _load_tsv("res://data/master/enchantments.tsv")

	for row in rows:
		var enchantment := _build_enchantment_data(row)

		if enchantment.enchant_id == "":
			push_error("enchant_id is empty")
			continue

		if enchantments.has(enchantment.enchant_id):
			push_error("duplicate enchant_id: " + enchantment.enchant_id)
			continue

		enchantments[enchantment.enchant_id] = enchantment


func _build_enchantment_data(row: Dictionary) -> EnchantmentData:
	var enchantment := EnchantmentData.new()

	enchantment.enchant_id = _get_string(row, "enchant_id")
	enchantment.display_name = _get_string(row, "display_name", enchantment.display_name)
	enchantment.description = _get_string(row, "description", enchantment.description).replace("\\n", "\n")
	enchantment.effect_type = _to_int(_get_string(row, "effect_type"), int(enchantment.effect_type))
	enchantment.stat_name = _get_string(row, "stat_name", enchantment.stat_name)
	enchantment.min_value = _to_int(_get_string(row, "min_value"), enchantment.min_value)
	enchantment.max_value = _to_int(_get_string(row, "max_value"), enchantment.max_value)
	enchantment.weight = _to_int(_get_string(row, "weight"), enchantment.weight)
	enchantment.allowed_slot_flags = _to_int(_get_string(row, "allowed_slot_flags"), enchantment.allowed_slot_flags)
	enchantment.price_bonus_at_min_value = _to_int(_get_string(row, "price_bonus_at_min_value"), enchantment.price_bonus_at_min_value)
	enchantment.price_bonus_at_max_value = _to_int(_get_string(row, "price_bonus_at_max_value"), enchantment.price_bonus_at_max_value)

	return enchantment


# ============================================================
# EnemyData
# ============================================================

func _load_enemies() -> void:
	var rows := _load_tsv("res://data/master/enemies.tsv")

	for row in rows:
		var enemy := _build_enemy_data(row)

		if enemy.enemy_type_id == "":
			push_error("enemy_type_id is empty")
			continue

		if enemies.has(enemy.enemy_type_id):
			push_error("duplicate enemy_type_id: " + enemy.enemy_type_id)
			continue

		enemies[enemy.enemy_type_id] = enemy


func _build_enemy_data(row: Dictionary) -> EnemyData:
	var enemy := EnemyData.new()

	enemy.enemy_type_id = _get_string(row, "enemy_type_id")
	enemy.enemy_name = _get_string(row, "enemy_name", enemy.enemy_name)

	enemy.base_difficulty = _to_int(_get_string(row, "base_difficulty"), enemy.base_difficulty)
	enemy.spawn_generator_tags = _split_list(_get_string(row, "spawn_generator_tags"))
	enemy.habitat_tags = _split_list(_get_string(row, "habitat_tags"))
	enemy.rarity = _to_int(_get_string(row, "rarity"), enemy.rarity)
	enemy.can_be_quest_target = _to_bool(_get_string(row, "can_be_quest_target", "true"))
	enemy.quest_rank = _to_int(_get_string(row, "quest_rank"), enemy.quest_rank)
	enemy.is_nocturnal = _to_bool(_get_string(row, "is_nocturnal", "false"))

	enemy.faction = _get_string(row, "faction", enemy.faction)

	enemy.max_hp = _to_int(_get_string(row, "max_hp"), enemy.max_hp)
	enemy.attack = _to_int(_get_string(row, "attack"), enemy.attack)
	enemy.defense = _to_int(_get_string(row, "defense"), enemy.defense)
	enemy.speed = _to_float(_get_string(row, "speed"), enemy.speed)

	enemy.accuracy = _to_float(_get_string(row, "accuracy"), enemy.accuracy)
	enemy.evasion = _to_float(_get_string(row, "evasion"), enemy.evasion)
	enemy.crit_rate = _to_float(_get_string(row, "crit_rate"), enemy.crit_rate)
	enemy.crit_damage = _to_float(_get_string(row, "crit_damage"), enemy.crit_damage)
	enemy.luck = _to_int(_get_string(row, "luck"), enemy.luck)

	enemy.element = _get_string(row, "element", enemy.element)
	enemy.element_resistances = _split_float_dict(_get_string(row, "element_resistances"))

	enemy.strength = _to_int(_get_string(row, "strength"), enemy.strength)
	enemy.vitality = _to_int(_get_string(row, "vitality"), enemy.vitality)
	enemy.agility = _to_int(_get_string(row, "agility"), enemy.agility)
	enemy.dexterity = _to_int(_get_string(row, "dexterity"), enemy.dexterity)
	enemy.intelligence = _to_int(_get_string(row, "intelligence"), enemy.intelligence)
	enemy.spirit = _to_int(_get_string(row, "spirit"), enemy.spirit)
	enemy.sense = _to_int(_get_string(row, "sense"), enemy.sense)
	enemy.charm = _to_int(_get_string(row, "charm"), enemy.charm)

	enemy.gathering = _to_int(_get_string(row, "gathering"), enemy.gathering)
	enemy.investigation = _to_int(_get_string(row, "investigation"), enemy.investigation)
	enemy.stealth = _to_int(_get_string(row, "stealth"), enemy.stealth)
	enemy.trap_disarm = _to_int(_get_string(row, "trap_disarm"), enemy.trap_disarm)
	enemy.fishing = _to_int(_get_string(row, "fishing"), enemy.fishing)
	enemy.appraisal = _to_int(_get_string(row, "appraisal"), enemy.appraisal)
	enemy.cooking = _to_int(_get_string(row, "cooking"), enemy.cooking)
	enemy.repair = _to_int(_get_string(row, "repair"), enemy.repair)
	enemy.smithing = _to_int(_get_string(row, "smithing"), enemy.smithing)
	enemy.alchemy = _to_int(_get_string(row, "alchemy"), enemy.alchemy)
	enemy.negotiation = _to_int(_get_string(row, "negotiation"), enemy.negotiation)
	enemy.speech = _to_int(_get_string(row, "speech"), enemy.speech)
	enemy.medical = _to_int(_get_string(row, "medical"), enemy.medical)

	enemy.equipped_weapon = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_weapon"))
	enemy.equipped_armor = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_armor"))
	enemy.equipped_accessory = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory"))

	enemy.equipped_right_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_right_hand"))
	enemy.equipped_left_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_left_hand"))
	enemy.equipped_head = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_head"))
	enemy.equipped_body = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_body"))
	enemy.equipped_hands = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_hands"))
	enemy.equipped_waist = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_waist"))
	enemy.equipped_feet = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_feet"))
	enemy.equipped_accessory_1 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_1"))
	enemy.equipped_accessory_2 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_2"))
	enemy.equipped_accessory_3 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_3"))
	enemy.equipped_accessory_4 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_4"))

	enemy.initial_inventory_items = _split_initial_inventory_entries(_get_string(row, "initial_inventory_items"))
	enemy.drop_inventory_on_death = _to_bool(_get_string(row, "drop_inventory_on_death", "true"))
	enemy.drop_equipped_items_on_death = _to_bool(_get_string(row, "drop_equipped_items_on_death", "true"))
	enemy.death_inventory_drop_radius = _to_int(_get_string(row, "death_inventory_drop_radius"), enemy.death_inventory_drop_radius)
	enemy.attacked_by_player_behavior = _load_resource_or_null(_get_string(row, "attacked_by_player_behavior_path")) as AttackedBehaviorData

	enemy.override_combat_style = _to_bool(_get_string(row, "override_combat_style", "false"))
	enemy.combat_style = _to_int(_get_string(row, "combat_style"), enemy.combat_style)
	enemy.override_move_style = _to_bool(_get_string(row, "override_move_style", "false"))
	enemy.move_style = _to_int(_get_string(row, "move_style"), enemy.move_style)

	enemy.talk_display_name = _get_string(row, "talk_display_name", enemy.talk_display_name)
	enemy.talk_greeting_text = _get_string(row, "talk_greeting_text", enemy.talk_greeting_text).replace("\\n", "\n")
	enemy.talk_portrait = _load_resource_or_null(_get_string(row, "talk_portrait_path")) as Texture2D
	enemy.unit_roles = _to_int(_get_string(row, "unit_roles"), enemy.unit_roles)
	enemy.friendliness = _to_int(_get_string(row, "friendliness"), enemy.friendliness)

	enemy.disable_hunger_decay = _to_bool(_get_string(row, "disable_hunger_decay", "true"))
	enemy.auto_eat_food_when_hungry = _to_bool(_get_string(row, "auto_eat_food_when_hungry", "false"))
	enemy.auto_generate_food_when_hungry = _to_bool(_get_string(row, "auto_generate_food_when_hungry", "false"))
	enemy.auto_generated_food_item_id = _get_string(row, "auto_generated_food_item_id", enemy.auto_generated_food_item_id)
	enemy.can_offer_request = _to_bool(_get_string(row, "can_offer_request", "false"))

	enemy.can_trade = _to_bool(_get_string(row, "can_trade", "false"))
	enemy.can_receive_order = _to_bool(_get_string(row, "can_receive_order", "false"))
	enemy.extra_interact_actions = _split_list(_get_string(row, "extra_interact_actions"))
	enemy.can_generate_shop_inventory = _to_bool(_get_string(row, "can_generate_shop_inventory", "false"))
	enemy.shop_min_items = _to_int(_get_string(row, "shop_min_items"), enemy.shop_min_items)
	enemy.shop_max_items = _to_int(_get_string(row, "shop_max_items"), enemy.shop_max_items)

	enemy.request_description = _get_string(row, "request_description", enemy.request_description).replace("\\n", "\n")
	enemy.request_accept_text = _get_string(row, "request_accept_text", enemy.request_accept_text).replace("\\n", "\n")
	enemy.request_decline_text = _get_string(row, "request_decline_text", enemy.request_decline_text).replace("\\n", "\n")
	enemy.random_talk_texts = _split_list(_get_string(row, "random_talk_texts"))

	enemy.animation_profile = _load_resource_or_null(_get_string(row, "animation_profile_path")) as AnimationProfile
	enemy.sprite_scale = Vector2(
		_to_float(_get_string(row, "sprite_scale_x"), 1.0),
		_to_float(_get_string(row, "sprite_scale_y"), 1.0)
	)

	enemy.idle_right_frames = _split_texture_array(_get_string(row, "idle_right_frames"))
	enemy.walk_right_frames = _split_texture_array(_get_string(row, "walk_right_frames"))
	enemy.idle_left_frames = _split_texture_array(_get_string(row, "idle_left_frames"))
	enemy.walk_left_frames = _split_texture_array(_get_string(row, "walk_left_frames"))
	enemy.idle_down_frames = _split_texture_array(_get_string(row, "idle_down_frames"))
	enemy.walk_down_frames = _split_texture_array(_get_string(row, "walk_down_frames"))
	enemy.idle_up_frames = _split_texture_array(_get_string(row, "idle_up_frames"))
	enemy.walk_up_frames = _split_texture_array(_get_string(row, "walk_up_frames"))

	return enemy



# ============================================================
# NpcData
# ============================================================

func _load_npcs() -> void:
	var rows := _load_tsv("res://data/master/npcs.tsv")

	for row in rows:
		var npc := _build_npc_data(row)

		if npc.npc_type_id == "":
			push_error("npc_type_id is empty")
			continue

		if npcs.has(npc.npc_type_id):
			push_error("duplicate npc_type_id: " + npc.npc_type_id)
			continue

		npcs[npc.npc_type_id] = npc


func _build_npc_data(row: Dictionary) -> NpcData:
	var npc := NpcData.new()

	npc.npc_name = _get_string(row, "npc_name", npc.npc_name)
	npc.npc_type_id = _get_string(row, "npc_type_id")
	npc.faction = _get_string(row, "faction", npc.faction)

	npc.base_difficulty = _to_int(_get_string(row, "base_difficulty"), npc.base_difficulty)
	npc.spawn_generator_tags = _split_list(_get_string(row, "spawn_generator_tags"))
	npc.rarity = _to_int(_get_string(row, "rarity"), npc.rarity)
	npc.is_nocturnal = _to_bool(_get_string(row, "is_nocturnal", "false"))

	npc.max_hp = _to_int(_get_string(row, "max_hp"), npc.max_hp)
	npc.attack = _to_int(_get_string(row, "attack"), npc.attack)
	npc.defense = _to_int(_get_string(row, "defense"), npc.defense)
	npc.speed = _to_float(_get_string(row, "speed"), npc.speed)

	npc.accuracy = _to_float(_get_string(row, "accuracy"), npc.accuracy)
	npc.evasion = _to_float(_get_string(row, "evasion"), npc.evasion)
	npc.crit_rate = _to_float(_get_string(row, "crit_rate"), npc.crit_rate)
	npc.crit_damage = _to_float(_get_string(row, "crit_damage"), npc.crit_damage)
	npc.luck = _to_int(_get_string(row, "luck"), npc.luck)

	npc.element = _get_string(row, "element", npc.element)
	npc.element_resistances = _split_float_dict(_get_string(row, "element_resistances"))

	npc.strength = _to_int(_get_string(row, "strength"), npc.strength)
	npc.vitality = _to_int(_get_string(row, "vitality"), npc.vitality)
	npc.agility = _to_int(_get_string(row, "agility"), npc.agility)
	npc.dexterity = _to_int(_get_string(row, "dexterity"), npc.dexterity)
	npc.intelligence = _to_int(_get_string(row, "intelligence"), npc.intelligence)
	npc.spirit = _to_int(_get_string(row, "spirit"), npc.spirit)
	npc.sense = _to_int(_get_string(row, "sense"), npc.sense)
	npc.charm = _to_int(_get_string(row, "charm"), npc.charm)

	npc.gathering = _to_int(_get_string(row, "gathering"), npc.gathering)
	npc.investigation = _to_int(_get_string(row, "investigation"), npc.investigation)
	npc.stealth = _to_int(_get_string(row, "stealth"), npc.stealth)
	npc.trap_disarm = _to_int(_get_string(row, "trap_disarm"), npc.trap_disarm)
	npc.fishing = _to_int(_get_string(row, "fishing"), npc.fishing)
	npc.appraisal = _to_int(_get_string(row, "appraisal"), npc.appraisal)
	npc.cooking = _to_int(_get_string(row, "cooking"), npc.cooking)
	npc.repair = _to_int(_get_string(row, "repair"), npc.repair)
	npc.smithing = _to_int(_get_string(row, "smithing"), npc.smithing)
	npc.alchemy = _to_int(_get_string(row, "alchemy"), npc.alchemy)
	npc.negotiation = _to_int(_get_string(row, "negotiation"), npc.negotiation)
	npc.speech = _to_int(_get_string(row, "speech"), npc.speech)
	npc.medical = _to_int(_get_string(row, "medical"), npc.medical)

	npc.equipped_weapon = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_weapon"))
	npc.equipped_armor = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_armor"))
	npc.equipped_accessory = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory"))
	npc.equipped_right_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_right_hand"))
	npc.equipped_left_hand = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_left_hand"))
	npc.equipped_head = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_head"))
	npc.equipped_body = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_body"))
	npc.equipped_hands = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_hands"))
	npc.equipped_waist = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_waist"))
	npc.equipped_feet = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_feet"))
	npc.equipped_accessory_1 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_1"))
	npc.equipped_accessory_2 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_2"))
	npc.equipped_accessory_3 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_3"))
	npc.equipped_accessory_4 = ItemDatabase.get_equipment_resource(_get_string(row, "equipped_accessory_4"))

	npc.initial_inventory_items = _split_initial_inventory_entries(_get_string(row, "initial_inventory_items"))
	npc.drop_inventory_on_death = _to_bool(_get_string(row, "drop_inventory_on_death", "true"))
	npc.drop_equipped_items_on_death = _to_bool(_get_string(row, "drop_equipped_items_on_death", "true"))
	npc.death_inventory_drop_radius = _to_int(_get_string(row, "death_inventory_drop_radius"), npc.death_inventory_drop_radius)
	npc.attacked_by_player_behavior = _load_resource_or_null(_get_string(row, "attacked_by_player_behavior_path")) as AttackedBehaviorData

	npc.override_combat_style = _to_bool(_get_string(row, "override_combat_style", "false"))
	npc.combat_style = _to_int(_get_string(row, "combat_style"), npc.combat_style)
	npc.override_move_style = _to_bool(_get_string(row, "override_move_style", "true"))
	npc.move_style = _to_int(_get_string(row, "move_style"), npc.move_style)

	npc.talk_display_name = _get_string(row, "talk_display_name", npc.talk_display_name)
	npc.talk_greeting_text = _get_string(row, "talk_greeting_text", npc.talk_greeting_text).replace("\\n", "\n")
	npc.talk_portrait = _load_resource_or_null(_get_string(row, "talk_portrait_path")) as Texture2D
	npc.unit_roles = _to_int(_get_string(row, "unit_roles"), npc.unit_roles)
	npc.friendliness = _to_int(_get_string(row, "friendliness"), npc.friendliness)

	npc.disable_hunger_decay = _to_bool(_get_string(row, "disable_hunger_decay", "false"))
	npc.auto_eat_food_when_hungry = _to_bool(_get_string(row, "auto_eat_food_when_hungry", "true"))
	npc.auto_generate_food_when_hungry = _to_bool(_get_string(row, "auto_generate_food_when_hungry", "true"))
	npc.auto_generated_food_item_id = _get_string(row, "auto_generated_food_item_id", npc.auto_generated_food_item_id)
	npc.can_offer_request = _to_bool(_get_string(row, "can_offer_request", "false"))

	npc.can_trade = _to_bool(_get_string(row, "can_trade", "false"))
	npc.can_receive_order = _to_bool(_get_string(row, "can_receive_order", "false"))
	npc.extra_interact_actions = _split_list(_get_string(row, "extra_interact_actions"))

	npc.can_generate_shop_inventory = _to_bool(_get_string(row, "can_generate_shop_inventory", "false"))
	npc.shop_min_items = _to_int(_get_string(row, "shop_min_items"), npc.shop_min_items)
	npc.shop_max_items = _to_int(_get_string(row, "shop_max_items"), npc.shop_max_items)
	npc.shop_loot_categories = _split_loot_categories(_get_string(row, "shop_loot_categories"))

	npc.request_description = _get_string(row, "request_description", npc.request_description).replace("\\n", "\n")
	npc.request_accept_text = _get_string(row, "request_accept_text", npc.request_accept_text).replace("\\n", "\n")
	npc.request_decline_text = _get_string(row, "request_decline_text", npc.request_decline_text).replace("\\n", "\n")
	npc.random_talk_texts = _split_list(_get_string(row, "random_talk_texts"))

	npc.animation_profile = _load_resource_or_null(_get_string(row, "animation_profile_path")) as AnimationProfile
	npc.sprite_scale = Vector2(
		_to_float(_get_string(row, "sprite_scale_x"), 1.0),
		_to_float(_get_string(row, "sprite_scale_y"), 1.0)
	)

	npc.idle_right_frames = _split_texture_array(_get_string(row, "idle_right_frames"))
	npc.walk_right_frames = _split_texture_array(_get_string(row, "walk_right_frames"))
	npc.idle_left_frames = _split_texture_array(_get_string(row, "idle_left_frames"))
	npc.walk_left_frames = _split_texture_array(_get_string(row, "walk_left_frames"))
	npc.idle_down_frames = _split_texture_array(_get_string(row, "idle_down_frames"))
	npc.walk_down_frames = _split_texture_array(_get_string(row, "walk_down_frames"))
	npc.idle_up_frames = _split_texture_array(_get_string(row, "idle_up_frames"))
	npc.walk_up_frames = _split_texture_array(_get_string(row, "walk_up_frames"))

	return npc


# ============================================================
# QuestData
# ============================================================

func _load_quests() -> void:
	var rows := _load_tsv("res://data/master/quests.tsv")

	for row in rows:
		var quest := QuestData.new()

		quest.quest_id = _get_string(row, "quest_id")
		quest.title = _get_string(row, "title")
		quest.description = _get_string(row, "description")
		quest.title_template = _get_string(row, "title_template")
		quest.description_template = _get_string(row, "description_template")
		quest.objective_type = _quest_objective_type_from_text(_get_string(row, "objective_type", "DELIVER_ITEM"))

		quest.objective_item_id = _get_string(row, "objective_item_id")
		quest.objective_item_amount = _to_int(_get_string(row, "objective_item_amount"), 1)
		quest.candidate_item_ids = _split_list(_get_string(row, "candidate_item_ids"))
		quest.candidate_categories = _split_list(_get_string(row, "candidate_categories"))

		quest.amount_min = _to_int(_get_string(row, "amount_min"), 1)
		quest.amount_max = _to_int(_get_string(row, "amount_max"), quest.amount_min)
		quest.time_limit_seconds = _to_float(_get_string(row, "time_limit_seconds"), 0.0)

		quest.reward_gold = _to_int(_get_string(row, "reward_gold"), 0)
		quest.reward_bonus_rate_min = _to_float(_get_string(row, "reward_bonus_rate_min"), 1.0)
		quest.reward_bonus_rate_max = _to_float(_get_string(row, "reward_bonus_rate_max"), quest.reward_bonus_rate_min)

		quest.reward_item_ids = _split_list(_get_string(row, "reward_item_ids"))
		quest.reward_item_amounts = _split_int_list(_get_string(row, "reward_item_amounts"))

		quest.allowed_unit_role_flags = _role_flags_from_text(_get_string(row, "allowed_unit_role_flags"))
		quest.weight = _to_int(_get_string(row, "weight"), 100)
		quest.repeatable = _to_bool(_get_string(row, "repeatable", "true"))

		quest.accept_text = _get_string(row, "accept_text")
		quest.progress_text = _get_string(row, "progress_text")
		quest.ready_to_complete_text = _get_string(row, "ready_to_complete_text")
		quest.completed_text = _get_string(row, "completed_text")
		quest.failed_text = _get_string(row, "failed_text")

		if quest.quest_id == "":
			push_error("quest_id is empty")
			continue

		if quests.has(quest.quest_id):
			push_error("duplicate quest_id: " + quest.quest_id)
			continue

		quests[quest.quest_id] = quest


func _quest_objective_type_from_text(value: String) -> int:
	match value.strip_edges().to_upper():
		"DELIVER_ITEM":
			return QuestData.ObjectiveType.DELIVER_ITEM
		"NONE", "":
			return QuestData.ObjectiveType.NONE
		_:
			push_warning("unknown quest objective_type: " + value)
			return QuestData.ObjectiveType.NONE


# 注意:
# ここは既存の UnitRole / role_flags の定義に合わせて後で調整してください。
# 現時点では、以前の想定に合わせて VILLAGER=1, MERCHANT=2, GUARD=4 としています。
func _role_flags_from_text(value: String) -> int:
	var result := 0

	for text in _split_list(value):
		match text.strip_edges().to_upper():
			"VILLAGER":
				result |= 1
			"MERCHANT":
				result |= 2
			"GUARD":
				result |= 4
			"":
				pass
			_:
				push_warning("unknown role flag: " + text)

	return result


# ============================================================
# Validate
# ============================================================

func validate_all() -> void:
	_validate_items()
	_validate_item_effects()
	_validate_quests()


func _validate_items() -> void:
	for item_id in items.keys():
		var item: ItemData = items[item_id]

		if item == null:
			push_error("item is null: " + String(item_id))
			continue

		if item.item_id == "":
			push_error("item has empty item_id")

		if item.icon == null and item.category != "":
			push_warning("item icon is null: " + String(item_id))


func _validate_item_effects() -> void:
	for item_id in item_effect_links.keys():
		if not items.has(item_id):
			push_error("item_effect_links item_id not found: " + String(item_id))

		for link in item_effect_links[item_id]:
			var effect_id := String(link.get("effect_id", ""))

			if not effects.has(effect_id):
				push_error("item_effect_links effect_id not found: " + effect_id)


func _validate_quests() -> void:
	for quest_id in quests.keys():
		var quest: QuestData = quests[quest_id]

		if quest == null:
			push_error("quest is null: " + String(quest_id))
			continue

		for item_id in quest.candidate_item_ids:
			if not items.has(item_id):
				push_error("quest candidate item not found: %s item=%s" % [quest_id, item_id])

		for item_id in quest.reward_item_ids:
			if not items.has(item_id):
				push_error("quest reward item not found: %s item=%s" % [quest_id, item_id])

		if quest.reward_item_amounts.size() > 0 and quest.reward_item_ids.size() != quest.reward_item_amounts.size():
			push_error("quest reward ids/amounts size mismatch: " + String(quest_id))
			
func debug_print_loaded_data() -> void:
	print("========== GameData Loaded ==========")
	print("[GameData] items: ", items.size())
	print("[GameData] effects: ", effects.size())
	print("[GameData] item_effect_links: ", item_effect_links.size())
	print("[GameData] quests: ", quests.size())
	print("[GameData] enemies: ", enemies.size())
	print("[GameData] npcs: ", npcs.size())
	print("[GameData] enchantments: ", enchantments.size())
	print("[GameData] item_spawn_rules: ", item_spawn_rules.size())
	print("[GameData] dungeon_spawn_rules: ", dungeon_spawn_rules.size())
	print("[GameData] unit_spawn_rules: ", unit_spawn_rules.size())

	print("---------- Items ----------")
	for item_id in items.keys():
		var item: ItemData = items[item_id]

		if item == null:
			print("item: ", item_id, " is null")
			continue

		var effect_count := 0
		if "effects" in item and item.effects != null:
			effect_count = item.effects.size()

		print(
			"item: ",
			item_id,
			" name=",
			item.display_name,
			" category=",
			item.category,
			" price=",
			item.base_price,
			" can_sell=",
			item.can_sell,
			" effects=",
			effect_count
		)

	print("---------- Effects ----------")
	for effect_id in effects.keys():
		var effect: ItemEffectData = effects[effect_id]

		if effect == null:
			print("effect: ", effect_id, " is null")
			continue

		print(
			"effect: ",
			effect_id,
			" type=",
			effect.get_effect_type_name()
		)

	print("---------- Item Effect Links ----------")
	for item_id in item_effect_links.keys():
		print("links for item: ", item_id, " links=", item_effect_links[item_id])

	print("---------- NPCs ----------")
	for npc_id in npcs.keys():
		var npc: NpcData = npcs[npc_id]
		if npc == null:
			continue
		print(
			"npc: ",
			npc_id,
			" name=",
			npc.npc_name,
			" roles=",
			npc.unit_roles,
			" trade=",
			npc.can_trade,
			" request=",
			npc.can_offer_request
		)

	print("---------- Unit Spawn Rules ----------")
	for rule_id in unit_spawn_rules.keys():
		var rule: SpawnRuleData = unit_spawn_rules[rule_id]
		if rule == null:
			continue
		print(
			"unit_spawn_rule: ",
			rule_id,
			" kind=",
			rule.spawn_kind,
			" generators=",
			rule.allowed_generator_types,
			" area=",
			rule.min_area_difficulty,
			"-",
			rule.max_area_difficulty,
			" count=",
			rule.max_spawn_count
		)

	print("---------- Dungeon Spawn Rules ----------")
	for rule_id in dungeon_spawn_rules.keys():
		var rule: DungeonSpawnRuleData = dungeon_spawn_rules[rule_id]
		if rule == null:
			continue
		print(
			"dungeon_rule: ",
			rule_id,
			" kind=",
			rule.spawn_kind,
			" themes=",
			rule.allowed_generator_themes,
			" layouts=",
			rule.allowed_layout_generator_types,
			" count=",
			rule.max_spawn_count
		)

	print("---------- Enchantments ----------")
	for enchant_id in enchantments.keys():
		var enchantment: EnchantmentData = enchantments[enchant_id]
		if enchantment == null:
			continue
		print(
			"enchantment: ",
			enchant_id,
			" name=",
			enchantment.display_name,
			" stat=",
			enchantment.stat_name,
			" value=",
			enchantment.min_value,
			"-",
			enchantment.max_value
		)

	print("---------- Enemies ----------")
	for enemy_id in enemies.keys():
		var enemy: EnemyData = enemies[enemy_id]
		if enemy == null:
			continue
		print(
			"enemy: ",
			enemy_id,
			" name=",
			enemy.enemy_name,
			" difficulty=",
			enemy.base_difficulty,
			" hp=",
			enemy.max_hp,
			" atk=",
			enemy.attack,
			" tags=",
			enemy.spawn_generator_tags
		)

	print("---------- Quests ----------")
	for quest_id in quests.keys():
		var quest: QuestData = quests[quest_id]

		if quest == null:
			print("quest: ", quest_id, " is null")
			continue

		print(
			"quest: ",
			quest_id,
			" title=",
			quest.title,
			" objective_item_id=",
			quest.objective_item_id,
			" objective_amount=",
			quest.objective_item_amount,
			" candidate_items=",
			quest.candidate_item_ids,
			" candidate_categories=",
			quest.candidate_categories,
			" reward_items=",
			quest.reward_item_ids
		)

	print("---------- Item Spawn Rules ----------")
	for rule in item_spawn_rules:
		if rule == null:
			continue
		print(
			"spawn_rule: ",
			rule.rule_id,
			" map_kind=",
			rule.map_kind,
			" count=",
			rule.base_item_count_min,
			"-",
			rule.base_item_count_max,
			" category_multipliers=",
			rule.category_multipliers
		)

	print("---------- ItemDatabase TSV access ----------")
	if ItemDatabase != null:
		print("[ItemDatabase] all item ids size: ", ItemDatabase.get_all_item_ids().size())
		print("[ItemDatabase] potion name: ", ItemDatabase.get_display_name("potion"))
		print("[ItemDatabase] apple name: ", ItemDatabase.get_display_name("apple"))
		print("[ItemDatabase] potion sell price: ", ItemDatabase.get_sell_price("potion"))
		print("[ItemDatabase] consumable ids: ", ItemDatabase.get_item_ids_by_category("consumable"))
		print("[ItemDatabase] equipment ids: ", ItemDatabase.get_item_ids_by_category("equipment"))
	else:
		print("[ItemDatabase] null")

	print("=======================================")


# ============================================================
# ItemSpawnRuleData
# ============================================================

func _load_item_spawn_rules() -> void:
	var rows := _load_tsv("res://data/master/spawn_rules.tsv")

	for row in rows:
		var rule := _build_item_spawn_rule(row)

		if rule.rule_id == "":
			push_error("spawn rule_id is empty")
			continue

		if has_item_spawn_rule(rule.rule_id):
			push_error("duplicate spawn rule_id: " + rule.rule_id)
			continue

		item_spawn_rules.append(rule)

	item_spawn_rules.sort_custom(func(a: ItemSpawnRuleData, b: ItemSpawnRuleData) -> bool:
		if a == null:
			return false
		if b == null:
			return true
		return a.priority > b.priority
	)


func _build_item_spawn_rule(row: Dictionary) -> ItemSpawnRuleData:
	var rule := ItemSpawnRuleData.new()

	rule.rule_id = _get_string(row, "rule_id")
	rule.is_base_rule = _to_bool(_get_string(row, "is_base_rule", "true"))
	rule.priority = _to_int(_get_string(row, "priority"), 0)

	rule.map_kind = _get_string(row, "map_kind")
	rule.generator_theme = _get_string(row, "generator_theme")
	rule.detail_generator = _get_string(row, "detail_generator")

	rule.difficulty_min = _to_int(_get_string(row, "difficulty_min"), 0)
	rule.difficulty_max = _to_int(_get_string(row, "difficulty_max"), 9999)
	rule.floor_min = _to_int(_get_string(row, "floor_min"), 0)
	rule.floor_max = _to_int(_get_string(row, "floor_max"), 9999)
	rule.final_floor_only = _to_bool(_get_string(row, "final_floor_only", "false"))

	rule.base_item_count_min = _to_int(_get_string(row, "base_item_count_min"), 0)
	rule.base_item_count_max = _to_int(_get_string(row, "base_item_count_max"), 0)
	rule.difficulty_item_count_scale = _to_float(_get_string(row, "difficulty_item_count_scale"), 0.0)

	rule.base_rarity_target = _to_float(_get_string(row, "base_rarity_target"), 1.0)
	rule.difficulty_rarity_scale = _to_float(_get_string(row, "difficulty_rarity_scale"), 0.03)
	rule.final_floor_rarity_bonus = _to_float(_get_string(row, "final_floor_rarity_bonus"), 0.0)
	rule.rarity_step_penalty = _to_float(_get_string(row, "rarity_step_penalty"), 0.35)

	rule.blocked_categories = _split_list(_get_string(row, "blocked_categories"))
	rule.blocked_item_ids = _split_list(_get_string(row, "blocked_item_ids"))
	rule.category_multipliers = _split_float_dict(_get_string(row, "category_multipliers"))
	rule.item_weight_overrides = _split_int_dict(_get_string(row, "item_weight_overrides"))

	return rule
