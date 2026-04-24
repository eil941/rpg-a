extends Node
class_name ItemDatabase

const EQUIPMENT_ENCHANT_CHANCE: float = 0.1

static var ITEM_RESOURCES = {
	# items
	"gold": preload("res://data/items/gold.tres"),
	"potion": preload("res://data/items/potion.tres"),
	"wood": preload("res://data/items/wood.tres"),
	"apple": preload("res://data/items/apple.tres"),
	
	"healing_potion": preload("res://data/items/healing_potion.tres"),
	"mushroom_bad": preload("res://data/items/mushroom_bad.tres"),
	"paralysis_cure_potion": preload("res://data/items/paralysis_cure_potion.tres"),
	"potion_of_strength": preload("res://data/items/potion_of_strength.tres"),
	"teleport_stone": preload("res://data/items/teleport_stone.tres"),
	"poison_cure_potion": preload("res://data/items/poison_cure_potion.tres"),

	# phase1 items
	"fire_bottle": preload("res://data/items/phase1/fire_bottle.tres"),
	"frost_bottle": preload("res://data/items/phase1/frost_bottle.tres"),
	"sleep_orb": preload("res://data/items/phase1/sleep_orb.tres"),
	"confusion_mushroom": preload("res://data/items/phase1/confusion_mushroom.tres"),
	"softening_powder": preload("res://data/items/phase1/softening_powder.tres"),
	"slow_slime": preload("res://data/items/phase1/slow_slime.tres"),
	"blur_powder": preload("res://data/items/phase1/blur_powder.tres"),
	"snare_smoke": preload("res://data/items/phase1/snare_smoke.tres"),
	"calm_breaker": preload("res://data/items/phase1/calm_breaker.tres"),
	"blast_stone": preload("res://data/items/phase1/blast_stone.tres"),
	"guard_tonic": preload("res://data/items/phase1/guard_tonic.tres"),
	"swift_tonic": preload("res://data/items/phase1/swift_tonic.tres"),
	"focus_tonic": preload("res://data/items/phase1/focus_tonic.tres"),
	"dodge_tonic": preload("res://data/items/phase1/dodge_tonic.tres"),
	"crit_oil": preload("res://data/items/phase1/crit_oil.tres"),
	"life_seed": preload("res://data/items/phase1/life_seed.tres"),
	
	# phase2 items
	"small_gold_pouch":preload("res://data/items/phase2/small_gold_pouch.tres"),
	"supply_bag":preload("res://data/items/phase2/supply_bag.tres"),
	
	# phase3 items
	"blind_sand": preload("res://data/items/phase3/blind_sand.tres"),
	"hallucination_powder": preload("res://data/items/phase3/hallucination_powder.tres"),
	"curse_orb":preload("res://data/items/phase3/curse_orb.tres"),

	# equipment
	"knife": preload("res://data/equipment/weapons/knife.tres"),
	"bow": preload("res://data/equipment/weapons/bow.tres"),
	"cloth_armor": preload("res://data/equipment/armor/cloth_armor.tres"),
	"power_ring": preload("res://data/equipment/accessories/power_ring.tres")
}


static func has_item(item_id: String) -> bool:
	return ITEM_RESOURCES.has(item_id)


static func exists(item_id: String) -> bool:
	return ITEM_RESOURCES.has(item_id)


static func get_item_resource(item_id: String):
	if item_id == "":
		return null
	return ITEM_RESOURCES.get(item_id, null)


static func get_item_data(item_id: String):
	return get_item_resource(item_id)


static func get_display_name(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return item_id
	return String(data.display_name)


static func get_description(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return ""
	return String(data.description)


static func get_item_icon(item_id: String) -> Texture2D:
	var data = get_item_resource(item_id)
	if data == null:
		return null
	return data.icon


static func get_max_stack(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 99
	return int(data.max_stack)


static func get_item_type(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return String(ItemCategories.MISC)

	if data is EquipmentData:
		return String(ItemCategories.EQUIPMENT)

	if data.has_method("get_item_type_name"):
		return ItemCategories.normalize(String(data.get_item_type_name()))

	return String(ItemCategories.MISC)


static func get_item_ids_by_type(item_type: String) -> Array[String]:
	var result: Array[String] = []
	var normalized_type: String = ItemCategories.normalize(item_type)

	for item_id in ITEM_RESOURCES.keys():
		if get_item_type(String(item_id)) == normalized_type:
			result.append(String(item_id))

	return result


static func get_item_ids_by_types(item_types: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var normalized_types: Array[String] = []

	for item_type in item_types:
		normalized_types.append(ItemCategories.normalize(String(item_type)))

	for item_id in ITEM_RESOURCES.keys():
		var id_text: String = String(item_id)
		var type_text: String = get_item_type(id_text)

		if normalized_types.has(type_text):
			result.append(id_text)

	return result


static func get_item_ids_by_category(category: String) -> Array[String]:
	return get_item_ids_by_type(category)


static func get_item_ids_by_categories(categories: Array[String]) -> Array[String]:
	return get_item_ids_by_types(categories)


static func get_random_item_id_by_type(item_type: String, rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = get_item_ids_by_type(item_type)

	if candidates.is_empty():
		return ""

	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func get_random_item_id_by_category(category: String, rng: RandomNumberGenerator) -> String:
	return get_random_item_id_by_type(category, rng)


static func get_category_display_name(category: String) -> String:
	var normalized: String = ItemCategories.normalize(category)

	match normalized:
		String(ItemCategories.CONSUMABLE):
			return "消耗品"
		String(ItemCategories.MATERIAL):
			return "素材"
		String(ItemCategories.EQUIPMENT):
			return "装備品"
		String(ItemCategories.MISC):
			return "その他"
		_:
			return normalized


static func is_usable(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	if data == null:
		return false
	return bool(data.usable)


static func is_equipment(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	return data is EquipmentData


static func get_equipment_slot(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return ""

	if data is EquipmentData:
		return data.get_slot_name()

	return ""


static func get_equipment_resource(item_id: String):
	var data = get_item_resource(item_id)
	if data is EquipmentData:
		return data
	return null


static func get_effect_type(item_id: String) -> String:
	var data = get_item_resource(item_id)
	if data == null:
		return "none"

	if "effects" in data and data.effects is Array and data.effects.size() > 0:
		var effect: ItemEffectData = data.effects[0]
		if effect != null:
			return effect.get_effect_type_name()

	return "none"


static func get_effect_value(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0

	if "effects" in data and data.effects is Array and data.effects.size() > 0:
		var effect: ItemEffectData = data.effects[0]
		if effect == null:
			return 0

		if effect.value_mode == ItemEffectData.ValueMode.PERCENT:
			return int(round(effect.percent_value * 100.0))

		if effect.power_min == effect.power_max:
			return int(effect.power_min)

		return int(effect.power_min)

	return 0


static func get_effect_summary_lines(item_id: String) -> Array[String]:
	var data = get_item_resource(item_id)
	var result: Array[String] = []

	if data == null:
		return result

	if not ("effects" in data):
		return result

	var effects = data.effects
	if effects == null:
		return result

	for effect in effects:
		if effect == null:
			continue

		match effect.effect_type:
			ItemEffectData.EffectType.RESTORE_RESOURCE:
				result.append(_build_restore_resource_text(effect))

			ItemEffectData.EffectType.CURE_STATUS:
				if effect.status_id != &"":
					result.append("状態異常回復: " + _get_status_display_name(effect.status_id))

			ItemEffectData.EffectType.APPLY_STATUS:
				if effect.status_id != &"":
					result.append("状態異常付与: " + _get_status_display_name(effect.status_id))

			ItemEffectData.EffectType.APPLY_MODIFIER:
				result.append(_build_modifier_text(effect))

			ItemEffectData.EffectType.DEAL_DAMAGE:
				result.append(_build_damage_text(effect))

			ItemEffectData.EffectType.TELEPORT:
				result.append(_build_teleport_text(effect))

			ItemEffectData.EffectType.PERMANENT_STAT_GROWTH:
				if effect.stat_name != &"":
					result.append("永久成長: " + _get_stat_display_name(effect.stat_name))

			ItemEffectData.EffectType.LEARN_SKILL:
				result.append("スキル習得")

			ItemEffectData.EffectType.UNLOCK_RECIPE:
				result.append("レシピ解放")

			ItemEffectData.EffectType.IDENTIFY_ITEM:
				result.append("鑑定")

			ItemEffectData.EffectType.READ_DOCUMENT:
				result.append("読む")

			ItemEffectData.EffectType.SPAWN_OBJECT:
				result.append("設置")

	return result


static func get_effect_summary_text(item_id: String) -> String:
	var lines: Array[String] = get_effect_summary_lines(item_id)
	if lines.is_empty():
		return ""
	return "\n".join(lines)


static func _build_restore_resource_text(effect: ItemEffectData) -> String:
	var resource_name: String = _get_resource_display_name(effect.resource_type)

	match effect.value_mode:
		ItemEffectData.ValueMode.FULL:
			return resource_name + "全回復"

		ItemEffectData.ValueMode.PERCENT:
			return resource_name + "回復 " + str(int(round(effect.percent_value * 100.0))) + "%"

		_:
			if effect.power_min == effect.power_max:
				return resource_name + "回復 " + str(effect.power_min)
			return resource_name + "回復 " + str(effect.power_min) + "〜" + str(effect.power_max)


static func _build_modifier_text(effect: ItemEffectData) -> String:
	var stat_name: String = _get_stat_display_name(effect.stat_name)
	var kind_name: String = "上昇"

	if effect.modifier_kind == ItemEffectData.ModifierKind.DEBUFF:
		kind_name = "低下"

	var value_text: String = ""
	if effect.stat_percent != 0.0:
		value_text = str(int(round(abs(effect.stat_percent) * 100.0))) + "%"
	elif effect.stat_flat != 0:
		value_text = str(abs(effect.stat_flat))
	else:
		value_text = "0"

	var duration_text: String = ""
	match effect.duration_type:
		ItemEffectData.DurationType.TIME:
			duration_text = " / " + str(int(round(effect.duration_value))) + "秒"
		ItemEffectData.DurationType.TURN:
			duration_text = " / " + str(int(round(effect.duration_value))) + "ターン"
		ItemEffectData.DurationType.ACTION:
			duration_text = " / " + str(int(round(effect.duration_value))) + "行動"

	return stat_name + kind_name + " " + value_text + duration_text


static func _build_damage_text(effect: ItemEffectData) -> String:
	if effect.power_min == effect.power_max:
		return "ダメージ " + str(effect.power_min)
	return "ダメージ " + str(effect.power_min) + "〜" + str(effect.power_max)


static func _build_teleport_text(effect: ItemEffectData) -> String:
	match effect.teleport_mode:
		ItemEffectData.TeleportMode.RANDOM:
			return "ランダムテレポート"
		ItemEffectData.TeleportMode.POINT:
			return "指定地点へ転移"
		ItemEffectData.TeleportMode.HOME:
			return "拠点へ帰還"
		ItemEffectData.TeleportMode.DUNGEON_EXIT:
			return "ダンジョン脱出"

	return "テレポート"


static func _get_resource_display_name(resource_type: int) -> String:
	match resource_type:
		ItemEffectData.ResourceType.HP:
			return "HP"
		ItemEffectData.ResourceType.MP:
			return "MP"
		ItemEffectData.ResourceType.STAMINA:
			return "スタミナ"
		ItemEffectData.ResourceType.HUNGER:
			return "空腹度"
	return "リソース"


static func _get_status_display_name(status_id: StringName) -> String:
	match String(status_id):
		"poison":
			return "毒"
		"paralysis":
			return "麻痺"
		"burning":
			return "炎上"
		"frostbite":
			return "凍傷"
		"sleep":
			return "眠り"
		"confusion":
			return "混乱"
		"blind":
			return "盲目"
		"hallucination":
			return "幻覚"
		"curse":
			return "呪い"
	return String(status_id)


static func _get_stat_display_name(stat_name: StringName) -> String:
	match String(stat_name):
		"max_hp":
			return "最大HP"
		"attack":
			return "攻撃力"
		"defense":
			return "防御力"
		"speed":
			return "速度"
		"accuracy":
			return "命中"
		"evasion":
			return "回避"
		"crit_rate":
			return "会心率"
		"crit_damage":
			return "会心ダメージ"
		"luck":
			return "運"
		"strength":
			return "筋力"
		"vitality":
			return "体力"
		"agility":
			return "敏捷"
		"dexterity":
			return "器用"
		"intelligence":
			return "知力"
		"spirit":
			return "精神"
		"sense":
			return "感覚"
		"charm":
			return "魅力"
	return String(stat_name)


static func get_base_price(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0

	if "base_price" in data:
		return int(data.base_price)

	return 0


static func can_sell(item_id: String) -> bool:
	var data = get_item_resource(item_id)
	if data == null:
		return false

	if "can_sell" in data:
		return bool(data.can_sell)

	return true


static func get_entry_display_name(entry: Dictionary) -> String:
	var item_id: String = String(entry.get("item_id", ""))
	var base_name: String = get_display_name(item_id)

	if item_id == "":
		return ""

	var instance_data: Variant = entry.get("instance_data", {})
	if typeof(instance_data) != TYPE_DICTIONARY:
		return base_name

	var enchantments: Variant = instance_data.get("enchantments", [])
	if not (enchantments is Array):
		return base_name

	if enchantments.is_empty():
		return base_name

	var first_data: Variant = enchantments[0]
	if typeof(first_data) != TYPE_DICTIONARY:
		return base_name

	var enchant_id: String = String(first_data.get("id", ""))
	match enchant_id:
		"atk_up_small":
			return "鋭い" + base_name
		"def_up_small":
			return "守りの" + base_name
		"hp_up_small":
			return "生命の" + base_name
		_:
			return base_name


static func _debug_enchant_log(message: String) -> void:
	if DebugSettings != null and DebugSettings.debug_enchant:
		print(message)


static func _shuffle_string_array(values: Array[String], rng: RandomNumberGenerator) -> Array[String]:
	var result: Array[String] = values.duplicate()

	for i in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = result[i]
		result[i] = result[j]
		result[j] = tmp

	return result


static func build_random_equipment_entry(item_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var entry: Dictionary = {
		"item_id": item_id,
		"amount": 1
	}

	var equipment_resource: EquipmentData = get_equipment_resource(item_id)
	if equipment_resource == null:
		_debug_enchant_log("[ENCHANT][ItemDatabase] BUILD RANDOM EQUIPMENT ENTRY = %s" % str(entry))
		return entry

	var enchant_roll: float = rng.randf()
	_debug_enchant_log("[ENCHANT][ItemDatabase] roll item_id=%s roll=%s chance=%s" % [item_id, str(enchant_roll), str(EQUIPMENT_ENCHANT_CHANCE)])
	if enchant_roll >= EQUIPMENT_ENCHANT_CHANCE:
		_debug_enchant_log("[ENCHANT][ItemDatabase] no enchant item_id=%s" % item_id)
		return entry

	var slot_name: String = equipment_resource.get_slot_name()
	var candidate_ids: Array[String] = EnchantmentDatabase.get_candidate_enchantment_ids_for_slot(slot_name)
	_debug_enchant_log("[ENCHANT][ItemDatabase] candidates item_id=%s slot=%s candidate_ids=%s" % [item_id, slot_name, str(candidate_ids)])
	if candidate_ids.is_empty():
		_debug_enchant_log("[ENCHANT][ItemDatabase] no candidates item_id=%s slot=%s" % [item_id, slot_name])
		return entry

	var requested_count: int = rng.randi_range(1, 10)
	var enchant_count: int = min(requested_count, candidate_ids.size())

	var shuffled_ids: Array[String] = _shuffle_string_array(candidate_ids, rng)
	var enchantments: Array = []

	for i in range(enchant_count):
		var enchant_id: String = shuffled_ids[i]
		var enchant_data: EnchantmentData = EnchantmentDatabase.get_enchantment(enchant_id)
		if enchant_data == null:
			continue

		var value: int = rng.randi_range(enchant_data.min_value, enchant_data.max_value)
		enchantments.append({
			"id": enchant_id,
			"value": value
		})

	if enchantments.is_empty():
		_debug_enchant_log("[ENCHANT][ItemDatabase] empty enchantments item_id=%s" % item_id)
		return entry

	entry["instance_data"] = {
		"enchantments": enchantments
	}
	_debug_enchant_log("[ENCHANT][ItemDatabase] BUILD RANDOM EQUIPMENT ENTRY = %s" % str(entry))
	return entry


static func build_equipment_entry(item_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"amount": 1
	}


static func get_sell_price(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0

	if not can_sell(item_id):
		return 0

	var base_price: int = get_base_price(item_id)
	return max(0, int(base_price / 2))

	
static func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []

	for item_id in ITEM_RESOURCES.keys():
		result.append(String(item_id))

	return result


static func get_spawnable_item_ids() -> Array[String]:
	var result: Array[String] = []

	for item_id in ITEM_RESOURCES.keys():
		var id_text: String = String(item_id)
		var data = get_item_resource(id_text)
		if data == null:
			continue

		if data is ItemData or data is EquipmentData:
			result.append(id_text)

	return result


static func get_rarity(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 1

	if data is ItemData:
		return data.get_rarity_value()

	if data is EquipmentData:
		if "rarity" in data:
			return clampi(int(data.rarity), 1, 10)

	return 1


static func get_spawn_weight(item_id: String) -> int:
	var data = get_item_resource(item_id)
	if data == null:
		return 0

	if data is ItemData:
		return data.get_spawn_weight_value()

	if data is EquipmentData:
		if "spawn_weight" in data:
			return max(0, int(data.spawn_weight))

	return 100
