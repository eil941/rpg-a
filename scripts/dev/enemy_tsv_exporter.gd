@tool
extends EditorScript

# 使い方:
# 1. まだ古い EnemyDatabase.gd(preload版) の状態でこのスクリプトを実行する
# 2. res://data/master/enemies.tsv が生成される
# 3. 生成後に EnemyDatabase.gd を enemy_database_tsv_only.gd に置き換える
#
# 実行方法:
# Godot エディタでこのファイルを開く -> File -> Run


const OUTPUT_PATH: String = "res://data/master/enemies.tsv"

const COLUMNS: Array[String] = [
	"enemy_type_id",
	"enemy_name",
	"base_difficulty",
	"spawn_generator_tags",
	"habitat_tags",
	"rarity",
	"can_be_quest_target",
	"quest_rank",
	"is_nocturnal",
	"faction",
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
	"initial_inventory_table_id",
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
	"walk_up_frames"
]


func _run() -> void:
	var enemies: Array = EnemyDatabase.get_all_enemy_data()
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open: " + OUTPUT_PATH)
		return

	file.store_line("\t".join(COLUMNS))

	var exported_count: int = 0
	var skipped_count: int = 0

	for raw_enemy in enemies:
		var enemy: EnemyData = raw_enemy as EnemyData
		if enemy == null:
			skipped_count += 1
			continue

		var row: Dictionary = _enemy_to_row(enemy)
		var values: Array[String] = []

		for column in COLUMNS:
			values.append(_escape_cell(str(row.get(column, ""))))

		file.store_line("\t".join(values))
		exported_count += 1

	file.flush()
	file.close()

	print("[EnemyTSVExporter] source enemies: ", enemies.size())
	print("[EnemyTSVExporter] exported rows: ", exported_count)
	print("[EnemyTSVExporter] skipped rows: ", skipped_count)
	print("[EnemyTSVExporter] output: ", OUTPUT_PATH)


func _enemy_to_row(enemy: EnemyData) -> Dictionary:
	var row: Dictionary = {}

	row["enemy_type_id"] = enemy.enemy_type_id
	row["enemy_name"] = enemy.enemy_name
	row["base_difficulty"] = enemy.base_difficulty
	row["spawn_generator_tags"] = _join_string_array(enemy.spawn_generator_tags)
	row["habitat_tags"] = _join_string_array(enemy.habitat_tags)
	row["rarity"] = enemy.rarity
	row["can_be_quest_target"] = enemy.can_be_quest_target
	row["quest_rank"] = enemy.quest_rank
	row["is_nocturnal"] = enemy.is_nocturnal
	row["faction"] = enemy.faction

	row["max_hp"] = enemy.max_hp
	row["attack"] = enemy.attack
	row["defense"] = enemy.defense
	row["speed"] = enemy.speed
	row["accuracy"] = enemy.accuracy
	row["evasion"] = enemy.evasion
	row["crit_rate"] = enemy.crit_rate
	row["crit_damage"] = enemy.crit_damage
	row["luck"] = enemy.luck
	row["element"] = enemy.element
	row["element_resistances"] = _join_float_dict(enemy.element_resistances)

	row["strength"] = enemy.strength
	row["vitality"] = enemy.vitality
	row["agility"] = enemy.agility
	row["dexterity"] = enemy.dexterity
	row["intelligence"] = enemy.intelligence
	row["spirit"] = enemy.spirit
	row["sense"] = enemy.sense
	row["charm"] = enemy.charm

	row["gathering"] = enemy.gathering
	row["investigation"] = enemy.investigation
	row["stealth"] = enemy.stealth
	row["trap_disarm"] = enemy.trap_disarm
	row["fishing"] = enemy.fishing
	row["appraisal"] = enemy.appraisal
	row["cooking"] = enemy.cooking
	row["repair"] = enemy.repair
	row["smithing"] = enemy.smithing
	row["alchemy"] = enemy.alchemy
	row["negotiation"] = enemy.negotiation
	row["speech"] = enemy.speech
	row["medical"] = enemy.medical

	row["equipped_weapon"] = _equipment_item_id(enemy.equipped_weapon)
	row["equipped_armor"] = _equipment_item_id(enemy.equipped_armor)
	row["equipped_accessory"] = _equipment_item_id(enemy.equipped_accessory)
	row["equipped_right_hand"] = _equipment_item_id(enemy.equipped_right_hand)
	row["equipped_left_hand"] = _equipment_item_id(enemy.equipped_left_hand)
	row["equipped_head"] = _equipment_item_id(enemy.equipped_head)
	row["equipped_body"] = _equipment_item_id(enemy.equipped_body)
	row["equipped_hands"] = _equipment_item_id(enemy.equipped_hands)
	row["equipped_waist"] = _equipment_item_id(enemy.equipped_waist)
	row["equipped_feet"] = _equipment_item_id(enemy.equipped_feet)
	row["equipped_accessory_1"] = _equipment_item_id(enemy.equipped_accessory_1)
	row["equipped_accessory_2"] = _equipment_item_id(enemy.equipped_accessory_2)
	row["equipped_accessory_3"] = _equipment_item_id(enemy.equipped_accessory_3)
	row["equipped_accessory_4"] = _equipment_item_id(enemy.equipped_accessory_4)

	row["initial_inventory_table_id"] = enemy.initial_inventory_table_id if "initial_inventory_table_id" in enemy else ""
	row["initial_inventory_items"] = _join_initial_inventory(enemy.initial_inventory_items)
	row["drop_inventory_on_death"] = enemy.drop_inventory_on_death
	row["drop_equipped_items_on_death"] = enemy.drop_equipped_items_on_death
	row["death_inventory_drop_radius"] = enemy.death_inventory_drop_radius
	row["attacked_by_player_behavior_path"] = _resource_path(enemy.attacked_by_player_behavior)

	row["override_combat_style"] = enemy.override_combat_style
	row["combat_style"] = enemy.combat_style
	row["override_move_style"] = enemy.override_move_style
	row["move_style"] = enemy.move_style

	row["talk_display_name"] = enemy.talk_display_name
	row["talk_greeting_text"] = enemy.talk_greeting_text
	row["talk_portrait_path"] = _resource_path(enemy.talk_portrait)
	row["unit_roles"] = enemy.unit_roles
	row["friendliness"] = enemy.friendliness

	row["disable_hunger_decay"] = enemy.disable_hunger_decay
	row["auto_eat_food_when_hungry"] = enemy.auto_eat_food_when_hungry
	row["auto_generate_food_when_hungry"] = enemy.auto_generate_food_when_hungry
	row["auto_generated_food_item_id"] = enemy.auto_generated_food_item_id
	row["can_offer_request"] = enemy.can_offer_request

	row["can_trade"] = enemy.can_trade
	row["can_receive_order"] = enemy.can_receive_order
	row["extra_interact_actions"] = _join_string_array(enemy.extra_interact_actions)
	row["can_generate_shop_inventory"] = enemy.can_generate_shop_inventory
	row["shop_min_items"] = enemy.shop_min_items
	row["shop_max_items"] = enemy.shop_max_items

	row["request_description"] = enemy.request_description
	row["request_accept_text"] = enemy.request_accept_text
	row["request_decline_text"] = enemy.request_decline_text
	row["random_talk_texts"] = _join_string_array(enemy.random_talk_texts)

	row["animation_profile_path"] = _resource_path(enemy.animation_profile)
	row["sprite_scale_x"] = enemy.sprite_scale.x
	row["sprite_scale_y"] = enemy.sprite_scale.y

	row["idle_right_frames"] = _join_resource_paths(enemy.idle_right_frames)
	row["walk_right_frames"] = _join_resource_paths(enemy.walk_right_frames)
	row["idle_left_frames"] = _join_resource_paths(enemy.idle_left_frames)
	row["walk_left_frames"] = _join_resource_paths(enemy.walk_left_frames)
	row["idle_down_frames"] = _join_resource_paths(enemy.idle_down_frames)
	row["walk_down_frames"] = _join_resource_paths(enemy.walk_down_frames)
	row["idle_up_frames"] = _join_resource_paths(enemy.idle_up_frames)
	row["walk_up_frames"] = _join_resource_paths(enemy.walk_up_frames)

	return row


func _equipment_item_id(equipment: EquipmentData) -> String:
	if equipment == null:
		return ""
	return String(equipment.item_id)


func _resource_path(resource: Resource) -> String:
	if resource == null:
		return ""
	return String(resource.resource_path)


func _join_resource_paths(resources: Array) -> String:
	var result: Array[String] = []

	for resource in resources:
		if resource == null:
			continue
		if resource is Resource:
			var path := String(resource.resource_path)
			if path != "":
				result.append(path)

	return "|".join(result)


func _join_string_array(values: Array) -> String:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return "|".join(result)


func _join_float_dict(dict: Dictionary) -> String:
	var result: Array[String] = []
	for key in dict.keys():
		result.append(String(key) + "=" + str(float(dict[key])))
	return "|".join(result)


func _join_initial_inventory(entries: Array[InitialInventoryEntry]) -> String:
	var result: Array[String] = []

	for entry in entries:
		if entry == null:
			continue

		result.append(
			"%s,%s,%s,%s,%s" % [
				String(entry.item_id),
				str(entry.amount_min),
				str(entry.amount_max),
				str(entry.chance),
				str(entry.roll_equipment_enchantments)
			]
		)

	return ";".join(result)


func _escape_cell(value: String) -> String:
	return value.replace("\t", " ").replace("\r", "\\n").replace("\n", "\\n")
