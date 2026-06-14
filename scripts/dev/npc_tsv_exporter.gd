@tool
extends EditorScript

# 使い方:
# 1. まだ古い NpcDatabase.gd(preload版) の状態でこのスクリプトを実行する
# 2. res://data/master/npcs.tsv が生成される
# 3. 生成後に NpcDatabase.gd を npc_database_tsv_only.gd に置き換える
#
# 実行方法:
# Godot エディタでこのファイルを開く -> File -> Run


const OUTPUT_PATH: String = "res://data/master/npcs.tsv"

const COLUMNS: Array[String] = [
	"npc_name",
	"npc_type_id",
	"faction",
	"base_difficulty",
	"spawn_generator_tags",
	"rarity",
	"is_nocturnal",
	"max_hp",
	"attack",
	"defense",
	"speed",
	"accuracy",
	"evasion",
	"crit_rate",
	"crit_damage",
	"luck",
	"element",
	"element_resistances",
	"strength",
	"vitality",
	"agility",
	"dexterity",
	"intelligence",
	"spirit",
	"sense",
	"charm",
	"gathering",
	"investigation",
	"stealth",
	"trap_disarm",
	"fishing",
	"appraisal",
	"cooking",
	"repair",
	"smithing",
	"alchemy",
	"negotiation",
	"speech",
	"medical",
	"equipped_weapon",
	"equipped_armor",
	"equipped_accessory",
	"equipped_right_hand",
	"equipped_left_hand",
	"equipped_head",
	"equipped_body",
	"equipped_hands",
	"equipped_waist",
	"equipped_feet",
	"equipped_accessory_1",
	"equipped_accessory_2",
	"equipped_accessory_3",
	"equipped_accessory_4",
	"initial_inventory_items",
	"drop_inventory_on_death",
	"drop_equipped_items_on_death",
	"death_inventory_drop_radius",
	"attacked_by_player_behavior_path",
	"override_combat_style",
	"combat_style",
	"override_move_style",
	"move_style",
	"talk_display_name",
	"talk_greeting_text",
	"talk_portrait_path",
	"unit_roles",
	"friendliness",
	"disable_hunger_decay",
	"auto_eat_food_when_hungry",
	"auto_generate_food_when_hungry",
	"auto_generated_food_item_id",
	"can_offer_request",
	"can_trade",
	"can_receive_order",
	"extra_interact_actions",
	"can_generate_shop_inventory",
	"shop_min_items",
	"shop_max_items",
	"shop_loot_categories",
	"request_description",
	"request_accept_text",
	"request_decline_text",
	"random_talk_texts",
	"animation_profile_path",
	"sprite_scale_x",
	"sprite_scale_y",
	"idle_right_frames",
	"walk_right_frames",
	"idle_left_frames",
	"walk_left_frames",
	"idle_down_frames",
	"walk_down_frames",
	"idle_up_frames",
	"walk_up_frames",
]


func _run() -> void:
	var npcs: Array = NpcDatabase.get_all_npc_data()
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open: " + OUTPUT_PATH)
		return

	file.store_line("	".join(COLUMNS))

	var exported_count: int = 0
	var skipped_count: int = 0

	for raw_npc in npcs:
		var npc: NpcData = raw_npc as NpcData
		if npc == null:
			skipped_count += 1
			continue

		var row: Dictionary = _npc_to_row(npc)
		var values: Array[String] = []

		for column in COLUMNS:
			values.append(_escape_cell(str(row.get(column, ""))))

		file.store_line("	".join(values))
		exported_count += 1

	file.flush()
	file.close()

	print("[NpcTSVExporter] source npcs: ", npcs.size())
	print("[NpcTSVExporter] exported rows: ", exported_count)
	print("[NpcTSVExporter] skipped rows: ", skipped_count)
	print("[NpcTSVExporter] output: ", OUTPUT_PATH)


func _npc_to_row(npc: NpcData) -> Dictionary:
	var row: Dictionary = {}

	row["npc_name"] = npc.npc_name
	row["npc_type_id"] = npc.npc_type_id
	row["faction"] = npc.faction

	row["base_difficulty"] = npc.base_difficulty
	row["spawn_generator_tags"] = _join_string_array(npc.spawn_generator_tags)
	row["rarity"] = npc.rarity
	row["is_nocturnal"] = npc.is_nocturnal

	row["max_hp"] = npc.max_hp
	row["attack"] = npc.attack
	row["defense"] = npc.defense
	row["speed"] = npc.speed

	row["accuracy"] = npc.accuracy
	row["evasion"] = npc.evasion
	row["crit_rate"] = npc.crit_rate
	row["crit_damage"] = npc.crit_damage
	row["luck"] = npc.luck

	row["element"] = npc.element
	row["element_resistances"] = _join_float_dict(npc.element_resistances)

	row["strength"] = npc.strength
	row["vitality"] = npc.vitality
	row["agility"] = npc.agility
	row["dexterity"] = npc.dexterity
	row["intelligence"] = npc.intelligence
	row["spirit"] = npc.spirit
	row["sense"] = npc.sense
	row["charm"] = npc.charm

	row["gathering"] = npc.gathering
	row["investigation"] = npc.investigation
	row["stealth"] = npc.stealth
	row["trap_disarm"] = npc.trap_disarm
	row["fishing"] = npc.fishing
	row["appraisal"] = npc.appraisal
	row["cooking"] = npc.cooking
	row["repair"] = npc.repair
	row["smithing"] = npc.smithing
	row["alchemy"] = npc.alchemy
	row["negotiation"] = npc.negotiation
	row["speech"] = npc.speech
	row["medical"] = npc.medical

	row["equipped_weapon"] = _equipment_item_id(npc.equipped_weapon)
	row["equipped_armor"] = _equipment_item_id(npc.equipped_armor)
	row["equipped_accessory"] = _equipment_item_id(npc.equipped_accessory)
	row["equipped_right_hand"] = _equipment_item_id(npc.equipped_right_hand)
	row["equipped_left_hand"] = _equipment_item_id(npc.equipped_left_hand)
	row["equipped_head"] = _equipment_item_id(npc.equipped_head)
	row["equipped_body"] = _equipment_item_id(npc.equipped_body)
	row["equipped_hands"] = _equipment_item_id(npc.equipped_hands)
	row["equipped_waist"] = _equipment_item_id(npc.equipped_waist)
	row["equipped_feet"] = _equipment_item_id(npc.equipped_feet)
	row["equipped_accessory_1"] = _equipment_item_id(npc.equipped_accessory_1)
	row["equipped_accessory_2"] = _equipment_item_id(npc.equipped_accessory_2)
	row["equipped_accessory_3"] = _equipment_item_id(npc.equipped_accessory_3)
	row["equipped_accessory_4"] = _equipment_item_id(npc.equipped_accessory_4)

	row["initial_inventory_items"] = _join_initial_inventory(npc.initial_inventory_items)
	row["drop_inventory_on_death"] = npc.drop_inventory_on_death
	row["drop_equipped_items_on_death"] = npc.drop_equipped_items_on_death
	row["death_inventory_drop_radius"] = npc.death_inventory_drop_radius
	row["attacked_by_player_behavior_path"] = _resource_path(npc.attacked_by_player_behavior)

	row["override_combat_style"] = npc.override_combat_style
	row["combat_style"] = npc.combat_style
	row["override_move_style"] = npc.override_move_style
	row["move_style"] = npc.move_style

	row["talk_display_name"] = npc.talk_display_name
	row["talk_greeting_text"] = npc.talk_greeting_text
	row["talk_portrait_path"] = _resource_path(npc.talk_portrait)
	row["unit_roles"] = npc.unit_roles
	row["friendliness"] = npc.friendliness

	row["disable_hunger_decay"] = npc.disable_hunger_decay
	row["auto_eat_food_when_hungry"] = npc.auto_eat_food_when_hungry
	row["auto_generate_food_when_hungry"] = npc.auto_generate_food_when_hungry
	row["auto_generated_food_item_id"] = npc.auto_generated_food_item_id
	row["can_offer_request"] = npc.can_offer_request

	row["can_trade"] = npc.can_trade
	row["can_receive_order"] = npc.can_receive_order
	row["extra_interact_actions"] = _join_string_array(npc.extra_interact_actions)

	row["can_generate_shop_inventory"] = npc.can_generate_shop_inventory
	row["shop_min_items"] = npc.shop_min_items
	row["shop_max_items"] = npc.shop_max_items
	row["shop_loot_categories"] = _join_loot_categories(npc.shop_loot_categories)

	row["request_description"] = npc.request_description
	row["request_accept_text"] = npc.request_accept_text
	row["request_decline_text"] = npc.request_decline_text
	row["random_talk_texts"] = _join_string_array(npc.random_talk_texts)

	row["animation_profile_path"] = _resource_path(npc.animation_profile)
	row["sprite_scale_x"] = npc.sprite_scale.x
	row["sprite_scale_y"] = npc.sprite_scale.y

	row["idle_right_frames"] = _join_resource_paths(npc.idle_right_frames)
	row["walk_right_frames"] = _join_resource_paths(npc.walk_right_frames)
	row["idle_left_frames"] = _join_resource_paths(npc.idle_left_frames)
	row["walk_left_frames"] = _join_resource_paths(npc.walk_left_frames)
	row["idle_down_frames"] = _join_resource_paths(npc.idle_down_frames)
	row["walk_down_frames"] = _join_resource_paths(npc.walk_down_frames)
	row["idle_up_frames"] = _join_resource_paths(npc.idle_up_frames)
	row["walk_up_frames"] = _join_resource_paths(npc.walk_up_frames)

	return row


func _equipment_item_id(equipment: EquipmentData) -> String:
	if equipment == null:
		return ""
	return str(equipment.item_id)


func _resource_path(resource: Resource) -> String:
	if resource == null:
		return ""
	return str(resource.resource_path)


func _join_resource_paths(resources: Array) -> String:
	var result: Array[String] = []

	for resource in resources:
		if resource == null:
			continue
		if resource is Resource:
			var path := str(resource.resource_path)
			if path != "":
				result.append(path)

	return "|".join(result)


func _join_string_array(values: Array) -> String:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return "|".join(result)


func _join_float_dict(dict: Dictionary) -> String:
	var result: Array[String] = []
	for key in dict.keys():
		result.append(str(key) + "=" + str(float(dict[key])))
	return "|".join(result)


func _join_initial_inventory(entries: Array[InitialInventoryEntry]) -> String:
	var result: Array[String] = []

	for entry in entries:
		if entry == null:
			continue

		result.append(
			"%s,%s,%s,%s,%s" % [
				str(entry.item_id),
				str(entry.amount_min),
				str(entry.amount_max),
				str(entry.chance),
				str(entry.roll_equipment_enchantments)
			]
		)

	return ";".join(result)


func _join_loot_categories(entries: Array[LootCategoryEntry]) -> String:
	var result: Array[String] = []

	for entry in entries:
		if entry == null:
			continue

		result.append(
			"%s,%s,%s,%s" % [
				str(entry.item_type),
				str(entry.weight),
				str(entry.min_amount),
				str(entry.max_amount)
			]
		)

	return ";".join(result)


func _escape_cell(value: String) -> String:
	return value.replace("	", " ").replace("\r", "\\n").replace("\n", "\\n")
