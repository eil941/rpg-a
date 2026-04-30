extends CharacterBody2D

@export var tile_size: int = 32
@export var move_speed: float = 220.0
@export var repeat_delay: float = 0.0

@export var start_tile: Vector2i = Vector2i(1, 1)
@export var can_trigger_scene_transition: bool = false

@export var can_bump_attack: bool = false
@export var is_enemy: bool = false

@export var receives_time_turns: bool = true
@export var instant_move: bool = true

@export var unit_id: String = ""
@export var is_player_unit: bool = false
@export var map_id: String = ""
@export_enum("PLAYER", "NPC", "ENEMY")
var faction: String = "PLAYER"

@export var animation_profile: AnimationProfile

@export var equipment_slot_order: Array[String] = [
	"right_hand",
	"left_hand",
	"head",
	"body",
	"hands",
	"waist",
	"feet",
	"accessory_1",
	"accessory_2",
	"accessory_3",
	"accessory_4"
]

var equipped_items: Dictionary = {}

enum AICombatStyle {
	AUTO,
	MELEE,
	MID,
	LONG,
	SUPPORTER,
	HIT_AND_RUN,
	DEFENSIVE
}

enum AIMoveStyle {
	AUTO,
	APPROACH,
	KEEP_DISTANCE,
	FLEE,
	HOLD
}

enum UnitRole {
	VILLAGER = 1,
	MERCHANT = 2,
	GUARD = 4,
	RECRUIT = 8,
	QUEST_GIVER = 16,
	ENEMY_BOSS = 32
}

@export var override_combat_style: bool = false
@export var combat_style: int = AICombatStyle.AUTO

@export var override_move_style: bool = false
@export var move_style: int = AIMoveStyle.AUTO

@export var sprite_offset_adjust: Vector2 = Vector2.ZERO

@export var can_talk: bool = true
@export var talk_display_name: String = ""
@export_multiline var talk_greeting_text: String = "……"
@export var talk_portrait: Texture2D
@export_flags("VILLAGER", "MERCHANT", "GUARD", "RECRUIT", "QUEST_GIVER", "ENEMY_BOSS")
var unit_roles: int = 0
@export var friendliness: int = 0

# 空腹まわりの挙動設定
@export var disable_hunger_decay: bool = false
@export var auto_eat_food_when_hungry: bool = false
@export var auto_generate_food_when_hungry: bool = false
@export var auto_generated_food_item_id: String = "apple"
@export var print_hunger_to_output: bool = false

# 死亡時に、このUnitのInventory内アイテムを地面へ落とすか。
# プレイヤー/敵/NPCごとにインスペクターで切り替え可能。
@export var drop_inventory_on_death: bool = true
@export var death_inventory_drop_radius: int = 5

@export var can_offer_request: bool = false
@export var can_trade: bool = false
@export var can_receive_order: bool = false
@export var extra_interact_actions: Array[String] = []

@export var offered_quests: Array[QuestData] = []
@export var use_generated_quests: bool = true
@export var quest_offer_count_min: int = 1
@export var quest_offer_count_max: int = 2
@export var quest_template_pool: Array[QuestData] = []

@export_multiline var request_description: String = ""
@export_multiline var request_accept_text: String = "ありがとうございます。"
@export_multiline var request_decline_text: String = "また今度おねがいします。"
@export var random_talk_texts: Array[String] = []

@export var idle_right_frames: Array[Texture2D] = []
@export var walk_right_frames: Array[Texture2D] = []

@export var idle_left_frames: Array[Texture2D] = []
@export var walk_left_frames: Array[Texture2D] = []

@export var idle_down_frames: Array[Texture2D] = []
@export var walk_down_frames: Array[Texture2D] = []

@export var idle_up_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []

@onready var inventory: Inventory = $Inventory
@onready var sprite: Sprite2D = $Sprite2D

var is_moving: bool = false
var target_position: Vector2
var repeat_timer: float = 0.0
var is_transitioning: bool = false

var enemy_data_to_apply: EnemyData = null
var npc_data_to_apply: NpcData = null

var map_root: Node = null
var ground_layer: TileMapLayer = null
var wall_layer: TileMapLayer = null
var event_layer: TileMapLayer = null
var units_node: Node = null

@onready var stats: Stats = $Stats
@onready var skills: Skills = get_node_or_null("Skills") as Skills
@onready var controller = $Controller
@onready var targeting = Targeting
@onready var combat_manager = CombatManager

enum Facing {
	RIGHT,
	LEFT,
	DOWN,
	UP
}

var facing: int = Facing.DOWN
var walk_frame_index: int = -1

var active_effect_runtimes: Array[UnitEffectRuntime] = []
var last_effect_update_time: float = 0.0
var starvation_damage_accumulator: float = 0.0

var runtime_attack_multiplier: float = 1.0
var runtime_defense_multiplier: float = 1.0
var runtime_speed_multiplier: float = 1.0
var runtime_accuracy_multiplier: float = 1.0
var runtime_evasion_multiplier: float = 1.0
var runtime_crit_rate_multiplier: float = 1.0

var runtime_attack_flat: int = 0
var runtime_defense_flat: int = 0
var runtime_speed_flat: int = 0
var runtime_accuracy_flat: int = 0
var runtime_evasion_flat: int = 0
var runtime_crit_rate_flat: int = 0



func _ready() -> void:
	print("UNIT READY name=", name)
	print("UNIT has Inventory =", has_node("Inventory"))
	print("UNIT children = ", get_children().map(func(c): return c.name))

	if not is_in_group("units"):
		add_to_group("units")

	resolve_map_references()

	if ground_layer == null or wall_layer == null or event_layer == null:
		push_error("Unit: GroundLayer / WallLayer / EventLayer の取得に失敗")
		return

	sync_map_id_from_scene()

	global_position = ground_layer.to_global(ground_layer.map_to_local(start_tile))
	target_position = global_position

	if controller != null and controller.has_method("setup"):
		controller.setup(self)

	if animation_profile != null:
		apply_animation_profile(animation_profile)
	else:
		apply_current_sprite_offset_only()

	if enemy_data_to_apply != null:
		apply_enemy_data(enemy_data_to_apply)

	if npc_data_to_apply != null:
		apply_npc_data(npc_data_to_apply)

	load_persistent_stats()
	apply_debug_start_items_if_needed()

	if is_player_unit:
		faction = "PLAYER"

	if is_player_unit and GlobalPlayerSpawn.has_next_tile:
		if not PlayerData.map_positions.has(map_id):
			global_position = ground_layer.to_global(ground_layer.map_to_local(GlobalPlayerSpawn.next_tile))
			target_position = global_position
		GlobalPlayerSpawn.has_next_tile = false

	is_transitioning = false
	is_moving = false
	repeat_timer = 0.0
	target_position = global_position

	if is_player_unit:
		print("READY map_id =", map_id)
		print("READY has_next_tile =", GlobalPlayerSpawn.has_next_tile)
		print("READY next_tile =", GlobalPlayerSpawn.next_tile)
		print("READY saved_positions =", PlayerData.map_positions)
		print("READY saved_equipment =", PlayerData.equipment_data)
		print("READY debug_start_items_applied =", PlayerData.debug_start_items_applied)
		print("READY units_node =", units_node)
		print("READY map_root =", map_root)
		print("READY controller =", controller)

	TimeManager.is_resolving_turn = false
	set_idle_animation()


func _physics_process(delta: float) -> void:
	if is_player_unit and is_any_ui_locked():
		return

	if is_transitioning:
		return

	if is_moving:
		global_position = global_position.move_toward(target_position, move_speed * delta)

		if global_position.distance_to(target_position) < 1.0:
			global_position = target_position
			is_moving = false
			repeat_timer = repeat_delay

			debug_print_current_tile_info()

			if is_player_unit:
				try_pickup_items_on_current_tile()

			if units_node != null:
				TimeManager.notify_unit_move_finished(units_node)

			if is_player_unit:
				if try_auto_use_dungeon_stairs_on_touch():
					return
			return

		return

	if repeat_timer > 0.0:
		repeat_timer -= delta
		return



func on_time_advanced(elapsed_seconds: float) -> void:
	advance_effect_runtimes(elapsed_seconds)

	if _should_apply_hunger_decay():
		_apply_hunger_time_decay(elapsed_seconds, true)
		_try_auto_eat_food_if_needed()
		_apply_hunger_starvation_damage(elapsed_seconds)

	if not receives_time_turns:
		return

	stats.action_progress_seconds += elapsed_seconds

	var effective_speed: float = get_total_speed()
	if effective_speed <= 0.0:
		return

	var action_cost_seconds: float = 86400.0 / effective_speed

	while stats.action_progress_seconds >= action_cost_seconds:
		stats.action_progress_seconds -= action_cost_seconds
		stats.pending_actions += 1
		consume_effect_turns(1)
func get_tile_data_at_coords(coords: Vector2i):
	return event_layer.get_cell_tile_data(coords)


func get_current_tile_coords() -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(global_position))


func get_current_tile_data():
	var coords: Vector2i = get_current_tile_coords()
	return event_layer.get_cell_tile_data(coords)


func get_equipped_entry(slot_name: String) -> Dictionary:
	if not equipped_items.has(slot_name):
		return {}

	var value: Variant = equipped_items[slot_name]
	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return (value as Dictionary).duplicate(true)


func get_equipped_resource(slot_name: String) -> EquipmentData:
	var entry: Dictionary = get_equipped_entry(slot_name)
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return null

	return ItemDatabase.get_equipment_resource(item_id)


func get_equipped_enchantments(slot_name: String) -> Array:
	var entry: Dictionary = get_equipped_entry(slot_name)
	var instance_data: Variant = entry.get("instance_data", {})

	if typeof(instance_data) != TYPE_DICTIONARY:
		return []

	var enchantments: Variant = (instance_data as Dictionary).get("enchantments", [])
	if enchantments is Array:
		return (enchantments as Array).duplicate(true)

	return []


func get_all_equipped_resources() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []

	for slot_name in equipment_slot_order:
		var resource: EquipmentData = get_equipped_resource(slot_name)
		if resource != null:
			result.append(resource)

	return result


func get_main_weapon() -> EquipmentData:
	var right_hand: EquipmentData = get_equipped_resource("right_hand")
	if right_hand != null:
		return right_hand

	var left_hand: EquipmentData = get_equipped_resource("left_hand")
	if left_hand != null:
		return left_hand

	return null


func apply_legacy_equipment_fields(source: Object) -> void:
	if source == null:
		return

	var right_hand = source.get("equipped_weapon")
	if right_hand is EquipmentData:
		equipped_items["right_hand"] = {
			"item_id": String((right_hand as EquipmentData).item_id),
			"amount": 1
		}

	var body = source.get("equipped_armor")
	if body is EquipmentData:
		equipped_items["body"] = {
			"item_id": String((body as EquipmentData).item_id),
			"amount": 1
		}

	var accessory = source.get("equipped_accessory")
	if accessory is EquipmentData:
		equipped_items["accessory_1"] = {
			"item_id": String((accessory as EquipmentData).item_id),
			"amount": 1
		}


func _get_enchantment_stat_bonus(slot_name: String, stat_name: String) -> int:
	var total: int = 0
	var enchantments: Array = get_equipped_enchantments(slot_name)

	for raw_data in enchantments:
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue

		var data: Dictionary = raw_data
		var enchant_id: String = String(data.get("id", ""))
		var value: int = int(data.get("value", 0))
		var enchant_data: EnchantmentData = EnchantmentDatabase.get_enchantment(enchant_id)
		if enchant_data == null:
			continue
		if enchant_data.effect_type != EnchantmentData.EffectType.STAT:
			continue
		if enchant_data.stat_name != stat_name:
			continue
		total += value

	return total


func _get_total_enchantment_bonus(stat_name: String) -> int:
	var total: int = 0
	for slot_name in equipment_slot_order:
		total += _get_enchantment_stat_bonus(slot_name, stat_name)
	return total


func get_total_max_hp() -> int:
	if stats == null:
		return 1

	var total: int = 1

	if stats.has_method("get_effective_max_hp"):
		total = int(stats.get_effective_max_hp())
	else:
		total = int(stats.max_hp)

	for equipment in get_all_equipped_resources():
		total += equipment.max_hp_bonus

	total += _get_total_enchantment_bonus("max_hp")

	return max(total, 1)


func get_total_attack() -> int:
	if stats == null:
		return 0

	var total: int = 0

	if stats.has_method("get_effective_attack"):
		total = int(round(stats.get_effective_attack()))
	else:
		total = int(stats.attack)

	for equipment in get_all_equipped_resources():
		total += equipment.attack_bonus

	total += _get_total_enchantment_bonus("attack")

	return get_modified_stat_value(&"attack", max(total, 0))


func get_total_defense() -> int:
	if stats == null:
		return 0

	var total: int = 0

	if stats.has_method("get_effective_defense"):
		total = int(round(stats.get_effective_defense()))
	else:
		total = int(stats.defense)

	for equipment in get_all_equipped_resources():
		total += equipment.defense_bonus

	total += _get_total_enchantment_bonus("defense")

	return get_modified_stat_value(&"defense", max(total, 0))


func get_total_speed() -> float:
	if stats == null:
		return 1.0

	var total: int = 1

	if stats.has_method("get_effective_speed"):
		total = int(round(stats.get_effective_speed()))
	else:
		total = int(round(float(stats.speed)))

	for equipment in get_all_equipped_resources():
		total += equipment.speed_bonus

	total += _get_total_enchantment_bonus("speed")

	return float(get_modified_stat_value(&"speed", max(total, 1)))


func get_total_accuracy() -> float:
	if stats == null:
		return 0.0

	var base_accuracy: float = 0.0
	if stats.has_method("get_effective_accuracy"):
		base_accuracy = float(stats.get_effective_accuracy())
	else:
		base_accuracy = float(stats.accuracy)

	var scaled_accuracy: int = int(round(base_accuracy * 1000.0))
	var modified_accuracy: int = get_modified_stat_value(&"accuracy", scaled_accuracy)

	return clamp(float(modified_accuracy) / 1000.0, 0.0, 1.0)


func get_total_evasion() -> float:
	if stats == null:
		return 0.0

	var base_evasion: float = 0.0
	if stats.has_method("get_effective_evasion"):
		base_evasion = float(stats.get_effective_evasion())
	else:
		base_evasion = float(stats.evasion)

	var scaled_evasion: int = int(round(base_evasion * 1000.0))
	var modified_evasion: int = get_modified_stat_value(&"evasion", scaled_evasion)

	return clamp(float(modified_evasion) / 1000.0, 0.0, 1.0)


func get_total_crit_rate() -> float:
	if stats == null:
		return 0.0

	var base_crit_rate: float = 0.0
	if stats.has_method("get_effective_crit_rate"):
		base_crit_rate = float(stats.get_effective_crit_rate())
	else:
		base_crit_rate = float(stats.crit_rate)

	var scaled_crit_rate: int = int(round(base_crit_rate * 1000.0))
	var modified_crit_rate: int = get_modified_stat_value(&"crit_rate", scaled_crit_rate)

	return clamp(float(modified_crit_rate) / 1000.0, 0.0, 1.0)


func get_total_crit_damage() -> float:
	if stats == null:
		return 1.5

	if stats.has_method("get_effective_crit_damage"):
		return max(1.0, float(stats.get_effective_crit_damage()))

	return max(1.0, float(stats.crit_damage))


func get_total_luck() -> int:
	if stats == null:
		return 0

	if stats.has_method("get_effective_luck"):
		return int(stats.get_effective_luck())

	return int(stats.luck)


func get_total_combat_stats() -> Dictionary:
	var current_hp: int = 0
	var current_element: String = "neutral"

	if stats != null:
		current_hp = int(stats.hp)
		current_element = String(stats.element)

	return {
		"hp": current_hp,
		"max_hp": get_total_max_hp(),
		"attack": get_total_attack(),
		"defense": get_total_defense(),
		"speed": get_total_speed(),
		"accuracy": get_total_accuracy(),
		"evasion": get_total_evasion(),
		"crit_rate": get_total_crit_rate(),
		"crit_damage": get_total_crit_damage(),
		"luck": get_total_luck(),
		"element": current_element
	}


# =========================
# 基礎ステータス成長入口
# =========================
# 成長プロフィールの中身は Stats.gd に集約する。
# 他スクリプトからは基本的に unit.apply_base_growth_profile() を呼ぶ。
# まだ各行動には散らばせず、ここは呼び出し口だけ用意しておく。

func apply_base_growth_profile(profile_id: StringName, multiplier: int = 1) -> void:
	if stats == null:
		return

	if not stats.has_method("apply_base_growth_profile"):
		return

	stats.apply_base_growth_profile(profile_id, multiplier)


func has_base_growth_profile(profile_id: StringName) -> bool:
	if stats == null:
		return false

	if not stats.has_method("has_base_growth_profile"):
		return false

	return stats.has_base_growth_profile(profile_id)


func get_base_growth_profile(profile_id: StringName) -> Dictionary:
	if stats == null:
		return {}

	if not stats.has_method("get_base_growth_profile"):
		return {}

	return stats.get_base_growth_profile(profile_id)


func get_attack_type_id() -> String:
	var weapon: EquipmentData = get_main_weapon()
	if weapon != null:
		return weapon.attack_type_id
	return "melee"


func get_attack_min_range() -> int:
	var weapon: EquipmentData = get_main_weapon()
	if weapon != null:
		return weapon.attack_min_range
	return 1


func get_attack_max_range() -> int:
	var weapon: EquipmentData = get_main_weapon()
	if weapon != null:
		return weapon.attack_max_range
	return 1


func get_equipment_slot_order() -> Array:
	return equipment_slot_order.duplicate()


func get_equipped_item_entry(slot_name: String) -> Dictionary:
	var entry: Dictionary = get_equipped_entry(slot_name)
	if entry.is_empty():
		return {
			"item_id": "",
			"amount": 0
		}
	return entry


func can_equip_item_id_to_slot(item_id: String, slot_name: String) -> bool:
	var equipment_resource = ItemDatabase.get_equipment_resource(item_id)
	if equipment_resource == null:
		return false

	var item_slot: String = equipment_resource.get_slot_name()

	if item_slot == "hand":
		return slot_name == "right_hand" or slot_name == "left_hand"

	if slot_name.begins_with("accessory_"):
		return item_slot == "accessory"

	return item_slot == slot_name


func set_equipped_entry(slot_name: String, entry: Dictionary) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	if item_id == "":
		return false

	if not can_equip_item_id_to_slot(item_id, slot_name):
		return false

	equipped_items[slot_name] = entry.duplicate(true)
	return true


func set_equipped_item_by_id(slot_name: String, item_id: String) -> bool:
	var equipment_resource = ItemDatabase.get_equipment_resource(item_id)
	if equipment_resource == null:
		return false

	if not can_equip_item_id_to_slot(item_id, slot_name):
		return false

	equipped_items[slot_name] = {
		"item_id": item_id,
		"amount": 1
	}
	return true


func clear_equipment_slot(slot_name: String) -> void:
	equipped_items.erase(slot_name)


func get_equipment_save_data() -> Dictionary:
	var data: Dictionary = {}

	for slot_name in equipment_slot_order:
		data[slot_name] = get_equipped_item_entry(slot_name)

	return data


func apply_equipment_save_data(data: Dictionary) -> void:
	equipped_items.clear()

	for slot_name in equipment_slot_order:
		var raw_value: Variant = data.get(slot_name, {})
		var entry: Dictionary = {}

		if typeof(raw_value) == TYPE_DICTIONARY:
			entry = (raw_value as Dictionary).duplicate(true)
		else:
			var item_id: String = String(raw_value)
			if item_id != "":
				entry = {
					"item_id": item_id,
					"amount": 1
				}

		if entry.is_empty():
			continue

		var item_id2: String = String(entry.get("item_id", ""))
		if item_id2 == "":
			continue

		if can_equip_item_id_to_slot(item_id2, slot_name):
			equipped_items[slot_name] = entry


func apply_debug_start_items_if_needed() -> void:
	if not is_player_unit:
		return

	if not DebugSettings.debug_give_player_start_items:
		return

	if PlayerData.debug_start_items_applied:
		print("DEBUG START ITEMS SKIP: already applied")
		return

	if inventory == null:
		print("DEBUG START ITEMS SKIP: inventory is null")
		return

	for entry in DebugSettings.debug_player_start_items:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 1))

		if item_id == "" or amount <= 0:
			continue

		var normalized_entry: Dictionary = entry.duplicate(true)
		normalized_entry["item_id"] = item_id
		normalized_entry["amount"] = amount
		var added: bool = inventory.add_item_entry(normalized_entry)

		if added:
			print("DEBUG START ITEM ADDED: ", item_id, " x", amount)
		else:
			print("DEBUG START ITEM FAILED: ", item_id, " x", amount)
			notify_hud_log("デバッグアイテム追加失敗: %s x%d" % [item_id, amount])

	PlayerData.inventory_data = inventory.save_inventory_data()
	PlayerData.debug_start_items_applied = true
	print("DEBUG START ITEMS APPLIED")


func apply_initial_inventory_from_data(initial_inventory_items: Array) -> void:
	if inventory == null:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	for raw_entry in initial_inventory_items:
		if raw_entry == null:
			continue

		# 新形式: InitialInventoryEntry Resource。
		var resource_entry: InitialInventoryEntry = raw_entry as InitialInventoryEntry
		if resource_entry != null:
			var built_entries: Array = resource_entry.build_entries(rng)
			for built_entry in built_entries:
				if typeof(built_entry) != TYPE_DICTIONARY:
					continue

				_add_initial_inventory_entry((built_entry as Dictionary).duplicate(true))
			continue

		# 念のため旧Dictionary形式も読む。
		# 既存.tresに古い値が残っていても、最低限は移行できるようにする。
		if typeof(raw_entry) == TYPE_DICTIONARY:
			var raw_dict: Dictionary = raw_entry
			if not _roll_initial_inventory_entry(raw_dict):
				continue

			var entry: Dictionary = _normalize_initial_inventory_entry(raw_dict)
			_add_initial_inventory_entry(entry)


func _add_initial_inventory_entry(entry: Dictionary) -> void:
	var normalized_entry: Dictionary = _normalize_initial_inventory_entry(entry)
	if _is_inventory_drop_entry_empty(normalized_entry):
		return

	var added: bool = inventory.add_item_entry(normalized_entry)
	if not added:
		print("[INITIAL INVENTORY] add failed unit=", name, " entry=", normalized_entry)


func _roll_initial_inventory_entry(entry: Dictionary) -> bool:
	var chance: float = 1.0

	if entry.has("chance"):
		chance = float(entry.get("chance", 1.0))
	elif entry.has("drop_chance"):
		chance = float(entry.get("drop_chance", 1.0))

	return _roll_initial_inventory_chance(chance)


func _roll_initial_inventory_chance(chance: float) -> bool:
	chance = clamp(chance, 0.0, 1.0)

	if chance >= 1.0:
		return true

	if chance <= 0.0:
		return false

	return randf() <= chance


func _normalize_initial_inventory_entry(entry: Dictionary) -> Dictionary:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 1))

	if entry.has("amount_min") or entry.has("amount_max"):
		var amount_min: int = int(entry.get("amount_min", amount))
		var amount_max: int = int(entry.get("amount_max", amount_min))
		if amount_max < amount_min:
			var tmp_amount: int = amount_min
			amount_min = amount_max
			amount_max = tmp_amount
		amount = randi_range(amount_min, amount_max)
	elif entry.has("min_amount") or entry.has("max_amount"):
		var min_amount: int = int(entry.get("min_amount", amount))
		var max_amount: int = int(entry.get("max_amount", min_amount))
		if max_amount < min_amount:
			var tmp_amount2: int = min_amount
			min_amount = max_amount
			max_amount = tmp_amount2
		amount = randi_range(min_amount, max_amount)

	if item_id == "" or amount <= 0:
		return {}

	var result: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}

	if entry.has("instance_data"):
		var instance_data: Variant = entry.get("instance_data", {})
		if typeof(instance_data) == TYPE_DICTIONARY and not (instance_data as Dictionary).is_empty():
			result["instance_data"] = (instance_data as Dictionary).duplicate(true)

	return result


func apply_shop_inventory_from_data(
	can_generate_shop_inventory: bool,
	shop_min_items: int,
	shop_max_items: int,
	shop_loot_categories: Array
) -> void:
	if not can_generate_shop_inventory:
		return

	if inventory == null:
		return

	if shop_loot_categories.is_empty():
		print("[SHOP INVENTORY] skip: shop_loot_categories is empty unit=", name)
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var min_count: int = max(0, shop_min_items)
	var max_count: int = max(min_count, shop_max_items)
	var generate_count: int = rng.randi_range(min_count, max_count)

	for i in range(generate_count):
		var category_entry: LootCategoryEntry = _pick_shop_loot_category(shop_loot_categories, rng)
		if category_entry == null:
			continue

		var item_type: String = category_entry.get_normalized_item_type()
		var item_id: String = ItemDatabase.get_random_item_id_by_category(item_type, rng)
		if item_id == "":
			print("[SHOP INVENTORY] no item for type=", item_type, " unit=", name)
			continue

		var min_amount: int = max(1, int(category_entry.min_amount))
		var max_amount: int = max(min_amount, int(category_entry.max_amount))
		var amount: int = rng.randi_range(min_amount, max_amount)

		_add_generated_shop_item_to_inventory(item_id, amount, rng)


func _pick_shop_loot_category(shop_loot_categories: Array, rng: RandomNumberGenerator) -> LootCategoryEntry:
	var total_weight: int = 0

	for raw_entry in shop_loot_categories:
		var entry: LootCategoryEntry = raw_entry as LootCategoryEntry
		if entry == null:
			continue

		var weight: int = max(0, int(entry.weight))
		total_weight += weight

	if total_weight <= 0:
		return null

	var roll: int = rng.randi_range(1, total_weight)
	var current: int = 0

	for raw_entry2 in shop_loot_categories:
		var entry2: LootCategoryEntry = raw_entry2 as LootCategoryEntry
		if entry2 == null:
			continue

		current += max(0, int(entry2.weight))
		if roll <= current:
			return entry2

	return null


func _add_generated_shop_item_to_inventory(item_id: String, amount: int, rng: RandomNumberGenerator) -> void:
	if item_id == "" or amount <= 0:
		return

	if inventory == null:
		return

	if ItemDatabase.is_equipment(item_id):
		for i in range(amount):
			var equipment_entry: Dictionary = ItemDatabase.build_random_equipment_entry(item_id, rng)
			equipment_entry["amount"] = 1
			var added_equipment: bool = inventory.add_item_entry(equipment_entry)
			if not added_equipment:
				print("[SHOP INVENTORY] add equipment failed unit=", name, " entry=", equipment_entry)
		return

	var entry: Dictionary = {
		"item_id": item_id,
		"amount": amount
	}

	var added: bool = inventory.add_item_entry(entry)
	if not added:
		print("[SHOP INVENTORY] add failed unit=", name, " entry=", entry)


func get_effective_combat_style() -> int:
	if override_combat_style and combat_style != AICombatStyle.AUTO:
		return combat_style

	var weapon: EquipmentData = get_main_weapon()
	if weapon != null:
		if int(weapon.combat_style) != AICombatStyle.AUTO:
			return int(weapon.combat_style)

	return AICombatStyle.MELEE


func get_effective_move_style() -> int:
	if override_move_style and move_style != AIMoveStyle.AUTO:
		return move_style

	var weapon: EquipmentData = get_main_weapon()
	if weapon != null:
		if int(weapon.move_style) != AIMoveStyle.AUTO:
			return int(weapon.move_style)

	return AIMoveStyle.APPROACH


func debug_print_current_tile_info() -> void:
	if not DebugSettings.print_tile_info:
		return
	if not is_player_unit:
		return

	var coords: Vector2i = get_current_tile_coords()

	var ground_source_id: int = ground_layer.get_cell_source_id(coords)
	var ground_atlas_coords: Vector2i = ground_layer.get_cell_atlas_coords(coords)
	var ground_alternative_tile: int = ground_layer.get_cell_alternative_tile(coords)

	var wall_source_id: int = wall_layer.get_cell_source_id(coords)
	var wall_atlas_coords: Vector2i = wall_layer.get_cell_atlas_coords(coords)
	var wall_alternative_tile: int = wall_layer.get_cell_alternative_tile(coords)

	print("===== CURRENT TILE INFO =====")
	print("unit=", name)
	print("map_id=", map_id)
	print("coords=", coords)

	print("--- ground layer ---")
	print("source_id=", ground_source_id)
	print("atlas_coords=", ground_atlas_coords)
	print("alternative_tile=", ground_alternative_tile)

	print("--- wall layer ---")
	print("source_id=", wall_source_id)
	print("atlas_coords=", wall_atlas_coords)
	print("alternative_tile=", wall_alternative_tile)

	var tile_data = get_current_tile_data()
	if tile_data == null:
		print("--- event layer ---")
		print("tile_data = null")
		print("============================")
		return

	print("--- event layer custom data ---")
	print("scene_transfer=", tile_data.get_custom_data("scene_transfer"))
	print("enter_scene=", tile_data.get_custom_data("enter_scene"))
	print("can_enter=", tile_data.get_custom_data("can_enter"))
	print("spawn_x=", tile_data.get_custom_data("spawn_x"))
	print("spawn_y=", tile_data.get_custom_data("spawn_y"))
	print("detail_generator=", tile_data.get_custom_data("detail_generator"))
	print("============================")


func get_occupied_tile_coords() -> Vector2i:
	if is_moving:
		return ground_layer.local_to_map(ground_layer.to_local(target_position))
	return get_current_tile_coords()


func get_facing_vector() -> Vector2i:
	match facing:
		Facing.RIGHT:
			return Vector2i.RIGHT
		Facing.LEFT:
			return Vector2i.LEFT
		Facing.DOWN:
			return Vector2i.DOWN
		Facing.UP:
			return Vector2i.UP
	return Vector2i.DOWN


func get_front_tile_coords() -> Vector2i:
	return get_current_tile_coords() + get_facing_vector()


func get_unit_in_front():
	if units_node == null:
		return null

	var front_tile: Vector2i = get_front_tile_coords()

	for other in units_node.get_children():
		if other == null:
			continue
		if other == self:
			continue
		if not other.has_method("get_occupied_tile_coords"):
			continue
		if other.get_occupied_tile_coords() == front_tile:
			return other

	return null


func get_board_tile_coords(board) -> Vector2i:
	var tile_value = board.get("tile_coords")
	if typeof(tile_value) == TYPE_VECTOR2I:
		return tile_value

	if board is Node2D and ground_layer != null:
		var board_node: Node2D = board as Node2D
		return ground_layer.local_to_map(ground_layer.to_local(board_node.global_position))

	return Vector2i(999999, 999999)


func get_board_in_front():
	var front_tile: Vector2i = get_front_tile_coords()
	print("[BOARD] front_tile = ", front_tile)

	var candidates: Array = []

	if map_root != null:
		var boards_node = map_root.get_node_or_null("QuestBoards")
		if boards_node != null:
			for child in boards_node.get_children():
				candidates.append(child)

	for node in get_tree().get_nodes_in_group("quest_boards"):
		if not candidates.has(node):
			candidates.append(node)

	print("[BOARD] candidate count = ", candidates.size())

	for board in candidates:
		if board == null:
			continue

		if not board.has_method("can_open_board"):
			print("[BOARD] skip no can_open_board: ", board.name)
			continue

		var board_tile: Vector2i = get_board_tile_coords(board)
		print("[BOARD] check board=", board.name, " tile=", board_tile)

		if board_tile == front_tile:
			print("[BOARD] matched board = ", board.name)
			return board

	print("[BOARD] no board matched")
	return null


func try_open_quest_board() -> bool:
	if not is_player_unit:
		return false

	var board = get_board_in_front()
	if board == null:
		print("[BOARD] try_open_quest_board: board is null")
		return false

	if not board.can_open_board():
		print("[BOARD] try_open_quest_board: can_open_board false")
		return false

	print("[BOARD] opening board: ", board.name)
	board.open_board(self)
	return true


func can_start_talk() -> bool:
	return can_talk


func get_talk_name() -> String:
	if talk_display_name != "":
		return talk_display_name
	return name


func get_interact_header_text() -> String:
	return UnitInteractionLogic.build_header_text(self)


func get_interact_actions() -> Array:
	return UnitInteractionLogic.build_actions(self)


func build_talk_context() -> Dictionary:
	return {
		"name": get_talk_name(),
		"portrait": talk_portrait,
		"text": get_interact_header_text(),
		"unit": self,
		"actions": get_interact_actions()
	}


func handle_interact_action(action_id: String) -> Dictionary:
	return UnitInteractionLogic.handle_action(self, action_id)


func find_game_root_node() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("is_inventory_open"):
			return node
		node = node.get_parent()
	return null


func is_inventory_open_from_root() -> bool:
	var root = find_game_root_node()
	if root == null:
		return false
	return root.is_inventory_open()


func is_failed_quest_dialog_locked() -> bool:
	if DialogueManager == null:
		return false

	if DialogueManager.has_method("is_input_locked_by_failed_quest_dialog"):
		return DialogueManager.is_input_locked_by_failed_quest_dialog()

	return false


func is_any_ui_locked() -> bool:
	if DialogueManager != null:
		if DialogueManager.has_method("is_dialog_open") and DialogueManager.is_dialog_open():
			return true

	if QuestBoardManager != null:
		if QuestBoardManager.has_method("is_board_open") and QuestBoardManager.is_board_open():
			return true

	return false


func try_talk_to_front_unit() -> bool:
	if not is_player_unit:
		return false

	if is_failed_quest_dialog_locked():
		return false

	if is_inventory_open_from_root():
		return false

	if DialogueManager != null and DialogueManager.has_method("is_dialog_open"):
		if DialogueManager.is_dialog_open():
			return false

	var target_unit = get_unit_in_front()
	if target_unit == null:
		return false

	if not target_unit.has_method("can_start_talk"):
		return false

	if not target_unit.can_start_talk():
		return false

	DialogueManager.open_unit_dialog(target_unit, self)
	return true


func facing_from_dir(dir: Vector2) -> int:
	if dir == Vector2.RIGHT:
		return Facing.RIGHT
	elif dir == Vector2.LEFT:
		return Facing.LEFT
	elif dir == Vector2.DOWN:
		return Facing.DOWN
	elif dir == Vector2.UP:
		return Facing.UP
	return facing


func get_idle_frames_for_facing(face: int) -> Array[Texture2D]:
	match face:
		Facing.RIGHT:
			return idle_right_frames
		Facing.LEFT:
			return idle_left_frames
		Facing.DOWN:
			return idle_down_frames
		Facing.UP:
			return idle_up_frames
	return []


func get_walk_frames_for_facing(face: int) -> Array[Texture2D]:
	match face:
		Facing.RIGHT:
			return walk_right_frames
		Facing.LEFT:
			return walk_left_frames
		Facing.DOWN:
			return walk_down_frames
		Facing.UP:
			return walk_up_frames
	return []


func set_idle_animation() -> void:
	if sprite == null:
		return

	var frames: Array[Texture2D] = get_idle_frames_for_facing(facing)
	if frames.is_empty():
		return
	sprite.texture = frames[0]


func update_facing_only(dir: Vector2) -> void:
	facing = facing_from_dir(dir)
	set_idle_animation()


func update_walk_animation_for_move(dir: Vector2) -> void:
	facing = facing_from_dir(dir)

	if sprite == null:
		return

	var frames: Array[Texture2D] = get_walk_frames_for_facing(facing)
	if frames.is_empty():
		return

	walk_frame_index += 1
	walk_frame_index %= frames.size()
	sprite.texture = frames[walk_frame_index]


func build_frame_from_index(sheet: Texture2D, frame_w: int, frame_h: int, index: int) -> Texture2D:
	if sheet == null:
		return null
	if frame_w <= 0 or frame_h <= 0:
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = sheet

	var columns: int = int(float(sheet.get_width()) / float(frame_w))
	if columns <= 0:
		return null

	var x: int = index % columns
	var y: int = int(float(index) / float(columns))

	atlas.region = Rect2(
		x * frame_w,
		y * frame_h,
		frame_w,
		frame_h
	)

	return atlas


func build_frames_from_indices(sheet: Texture2D, frame_w: int, frame_h: int, indices: Array[int]) -> Array[Texture2D]:
	var result: Array[Texture2D] = []

	for index in indices:
		var frame = build_frame_from_index(sheet, frame_w, frame_h, index)
		if frame != null:
			result.append(frame)

	return result


func apply_sprite_offset_from_profile(profile: AnimationProfile) -> void:
	if sprite == null:
		return

	if profile == null:
		sprite.offset = sprite_offset_adjust
		return

	var auto_offset: Vector2 = Vector2.ZERO
	var actual_frame_height: int = profile.get_frame_height()

	if profile.auto_bottom_align:
		auto_offset.y = -float(actual_frame_height - profile.base_tile_height) / 2.0

	sprite.offset = auto_offset + profile.profile_offset + sprite_offset_adjust


func apply_current_sprite_offset_only() -> void:
	if sprite == null:
		return

	sprite.offset = sprite_offset_adjust


func apply_animation_profile(profile: AnimationProfile) -> void:
	if profile == null:
		return
	if profile.sprite_sheet == null:
		return

	var sheet: Texture2D = profile.sprite_sheet
	var fw: int = profile.get_frame_width()
	var fh: int = profile.get_frame_height()

	idle_right_frames = build_frames_from_indices(sheet, fw, fh, profile.idle_right_indices)
	walk_right_frames = build_frames_from_indices(sheet, fw, fh, profile.walk_right_indices)

	idle_left_frames = build_frames_from_indices(sheet, fw, fh, profile.idle_left_indices)
	walk_left_frames = build_frames_from_indices(sheet, fw, fh, profile.walk_left_indices)

	idle_down_frames = build_frames_from_indices(sheet, fw, fh, profile.idle_down_indices)
	walk_down_frames = build_frames_from_indices(sheet, fw, fh, profile.walk_down_indices)

	idle_up_frames = build_frames_from_indices(sheet, fw, fh, profile.idle_up_indices)
	walk_up_frames = build_frames_from_indices(sheet, fw, fh, profile.walk_up_indices)

	walk_frame_index = -1
	apply_sprite_offset_from_profile(profile)
	set_idle_animation()


func apply_animation_frames(
	p_idle_right: Array[Texture2D],
	p_walk_right: Array[Texture2D],
	p_idle_left: Array[Texture2D],
	p_walk_left: Array[Texture2D],
	p_idle_down: Array[Texture2D],
	p_walk_down: Array[Texture2D],
	p_idle_up: Array[Texture2D],
	p_walk_up: Array[Texture2D]
) -> void:
	idle_right_frames = p_idle_right.duplicate()
	walk_right_frames = p_walk_right.duplicate()

	idle_left_frames = p_idle_left.duplicate()
	walk_left_frames = p_walk_left.duplicate()

	idle_down_frames = p_idle_down.duplicate()
	walk_down_frames = p_walk_down.duplicate()

	idle_up_frames = p_idle_up.duplicate()
	walk_up_frames = p_walk_up.duplicate()

	walk_frame_index = -1
	apply_current_sprite_offset_only()
	set_idle_animation()


func try_move(dir: Vector2) -> bool:
	if is_player_unit and is_any_ui_locked():
		return false

	var next_facing: int = facing_from_dir(dir)
	if next_facing != facing:
		update_facing_only(dir)

	var next_pos: Vector2 = global_position + dir * tile_size
	var next_tile: Vector2i = ground_layer.local_to_map(ground_layer.to_local(next_pos))

	var next_tile_data = get_tile_data_at_coords(next_tile)
	if next_tile_data != null:
		var next_scene_transfer = next_tile_data.get_custom_data("scene_transfer")
		if not can_trigger_scene_transition and next_scene_transfer == true:
			return false

	var target_unit = targeting.get_unit_on_tile(units_node, next_tile, self)

	if target_unit != null:
		if combat_manager.try_bump_attack(self, target_unit):
			return true
		return false

	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = $CollisionShape2D.shape
	query.transform = Transform2D(0, next_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query)

	if result.is_empty():
		update_walk_animation_for_move(dir)

		if instant_move:
			global_position = next_pos
			target_position = next_pos
			is_moving = false

			debug_print_current_tile_info()

			if is_player_unit:
				try_pickup_items_on_current_tile()

			if units_node != null:
				TimeManager.notify_unit_move_finished(units_node)

			if is_player_unit:
				if try_auto_use_dungeon_stairs_on_touch():
					return true
		else:
			target_position = next_pos
			is_moving = true

		return true

	var tile_data = get_tile_data_at_coords(next_tile)
	if tile_data == null:
		return false

	var scene_transfer = tile_data.get_custom_data("scene_transfer")

	if can_trigger_scene_transition and scene_transfer != null and scene_transfer == true:
		var next_scene: String = String(tile_data.get_custom_data("enter_scene"))

		var spawn_x_data = tile_data.get_custom_data("spawn_x")
		var spawn_y_data = tile_data.get_custom_data("spawn_y")

		var current_tile: Vector2i = get_current_tile_coords()

		if next_scene != "":
			if next_scene == "res://scenes/dungeon_main.tscn":
				var dungeon_id: String = ""

				if map_root != null and map_root.has_method("get_dungeon_id_at_cell"):
					dungeon_id = map_root.get_dungeon_id_at_cell(next_tile)

				print("DUNGEON TRANSFER next_tile = ", next_tile)
				print("DUNGEON TRANSFER dungeon_id = ", dungeon_id)

				if dungeon_id == "":
					push_error("Dungeon transfer failed: dungeon_id is empty")
					return false

				GlobalDungeon.current_dungeon_id = dungeon_id
				GlobalDungeon.current_floor = 1
				GlobalDungeon.return_field_map_id = map_id
				GlobalDungeon.return_field_cell = next_tile

				if is_player_unit:
					PlayerData.last_map_id = map_id
					PlayerData.last_tile = current_tile

				if map_root != null and map_root.has_method("save_all_units"):
					map_root.save_all_units()

				is_transitioning = true
				GlobalPlayerSpawn.has_next_tile = false
				notify_hud_log(next_scene + "へ移動")
				request_map_change(next_scene)
				return true

			if spawn_x_data == null or spawn_y_data == null:
				return false

			var spawn_x: int = int(spawn_x_data)
			var spawn_y: int = int(spawn_y_data)

			var field_tile: Vector2i = current_tile
			var detail_map_key: String = "field_%d_%d" % [field_tile.x, field_tile.y]

			var generator_type = tile_data.get_custom_data("detail_generator")
			if generator_type == null:
				generator_type = "plain"

			var return_to_field_map: bool = next_scene == "res://scenes/field_map.tscn"

			if return_to_field_map:
				spawn_x = GlobalDetailMap.from_field_tile.x
				spawn_y = GlobalDetailMap.from_field_tile.y
			else:
				GlobalDetailMap.current_detail_map_key = detail_map_key
				GlobalDetailMap.current_generator_type = String(generator_type)
				GlobalDetailMap.from_field_tile = field_tile

				if not WorldState.field_detail_map_data.has(detail_map_key):
					WorldState.field_detail_map_data[detail_map_key] = create_detail_map_config(
						String(generator_type),
						field_tile
					)

				print("DETAIL MAP KEY =", detail_map_key)
				print("DETAIL GENERATOR =", generator_type)

			if is_player_unit:
				PlayerData.last_map_id = map_id
				PlayerData.last_tile = current_tile

			if map_root != null and map_root.has_method("save_all_units"):
				map_root.save_all_units()

			is_transitioning = true
			GlobalPlayerSpawn.has_next_tile = true
			GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)
			notify_hud_log(next_scene + "へ移動")
			request_map_change(next_scene)
			return true

	return false


func try_interact_transition() -> void:
	if not can_trigger_scene_transition:
		return

	if map_root != null and map_root.has_method("try_use_dungeon_stairs_from_player_position"):
		if map_root.try_use_dungeon_stairs_from_player_position():
			print("STAIRS TRANSITION HANDLED")
			return

	var tile_data = get_current_tile_data()
	if tile_data == null:
		return

	var can_enter = tile_data.get_custom_data("can_enter")
	if can_enter == null or can_enter == false:
		return

	var next_scene: String = String(tile_data.get_custom_data("enter_scene"))
	if next_scene == "":
		return

	var current_tile: Vector2i = get_current_tile_coords()

	if next_scene == "res://scenes/dungeon_main.tscn":
		var dungeon_id: String = ""

		if map_root != null and map_root.has_method("get_dungeon_id_at_cell"):
			dungeon_id = map_root.get_dungeon_id_at_cell(current_tile)

		print("INTERACT DUNGEON TRANSFER current_tile = ", current_tile)
		print("INTERACT DUNGEON TRANSFER dungeon_id = ", dungeon_id)

		if dungeon_id == "":
			push_error("Dungeon interact transfer failed: dungeon_id is empty")
			return

		GlobalDungeon.current_dungeon_id = dungeon_id
		GlobalDungeon.current_floor = 1
		GlobalDungeon.return_field_map_id = map_id
		GlobalDungeon.return_field_cell = current_tile
		GlobalDungeon.pending_spawn_stair_type = "RETURN"

		if is_player_unit:
			PlayerData.last_map_id = map_id
			PlayerData.last_tile = current_tile

		if map_root != null and map_root.has_method("save_all_units"):
			map_root.save_all_units()

		is_transitioning = true
		GlobalPlayerSpawn.has_next_tile = false
		notify_hud_log(next_scene + "へ移動")
		request_map_change(next_scene)
		return

	var spawn_x_data = tile_data.get_custom_data("spawn_x")
	var spawn_y_data = tile_data.get_custom_data("spawn_y")

	if spawn_x_data == null or spawn_y_data == null:
		push_error("spawn_x or spawn_y is missing on event tile")
		return

	var spawn_x: int = int(spawn_x_data)
	var spawn_y: int = int(spawn_y_data)

	var field_tile: Vector2i = current_tile
	var detail_map_key: String = "field_%d_%d" % [field_tile.x, field_tile.y]

	var generator_type = tile_data.get_custom_data("detail_generator")
	if generator_type == null:
		generator_type = "plain"

	var return_to_field_map: bool = next_scene == "res://scenes/field_map.tscn"

	if return_to_field_map:
		spawn_x = GlobalDetailMap.from_field_tile.x
		spawn_y = GlobalDetailMap.from_field_tile.y
	else:
		var detail_config: Dictionary = {}

		if not WorldState.field_detail_map_data.has(detail_map_key):
			detail_config = create_detail_map_config(String(generator_type), field_tile)
			WorldState.field_detail_map_data[detail_map_key] = detail_config
		else:
			detail_config = WorldState.field_detail_map_data[detail_map_key]

		GlobalDetailMap.current_detail_map_key = detail_map_key
		GlobalDetailMap.current_generator_type = String(generator_type)
		GlobalDetailMap.from_field_tile = field_tile
		GlobalDetailMap.current_area_difficulty = int(detail_config.get("area_difficulty", 0))

		print("DETAIL MAP KEY =", detail_map_key)
		print("DETAIL GENERATOR =", generator_type)
		print("DETAIL AREA DIFFICULTY =", GlobalDetailMap.current_area_difficulty)

	if is_player_unit:
		PlayerData.last_map_id = map_id
		PlayerData.last_tile = current_tile

	if map_root != null and map_root.has_method("save_all_units"):
		map_root.save_all_units()

	print("INTERACT TRANSFER next_scene=", next_scene)
	print("INTERACT TRANSFER spawn_x=", spawn_x, " spawn_y=", spawn_y)
	print("INTERACT TRANSFER set next_tile=", Vector2i(spawn_x, spawn_y))

	is_transitioning = true
	GlobalPlayerSpawn.has_next_tile = true
	GlobalPlayerSpawn.next_tile = Vector2i(spawn_x, spawn_y)

	notify_hud_log(next_scene + "へ移動")
	request_map_change(next_scene)


func wait_action() -> void:
	is_moving = false
	repeat_timer = repeat_delay
	set_idle_animation()


func get_hp_status_text() -> String:
	return "%s HP: %d/%d" % [name, stats.hp, get_total_max_hp()]



func get_stats_data() -> Dictionary:
	var data: Dictionary = stats.get_stats_data()
	data["tile_x"] = get_current_tile_coords().x
	data["tile_y"] = get_current_tile_coords().y
	data["inventory"] = inventory.save_inventory_data() if inventory != null else []
	data["equipment"] = get_equipment_save_data()
	data["effect_runtimes"] = get_effect_runtimes_save_data()

	if TimeManager != null:
		data["last_effect_update_time"] = float(TimeManager.world_time_seconds)
	else:
		data["last_effect_update_time"] = last_effect_update_time

	if skills != null:
		data["skills"] = skills.get_skills_data()

	return data

func apply_stats_data(data: Dictionary) -> void:
	if stats != null:
		stats.apply_stats_data(data)

	if data.has("tile_x") and data.has("tile_y"):
		var saved_tile: Vector2i = Vector2i(int(data["tile_x"]), int(data["tile_y"]))
		global_position = ground_layer.to_global(ground_layer.map_to_local(saved_tile))
		target_position = global_position

	if data.has("inventory") and inventory != null:
		inventory.load_inventory_data(data["inventory"])

	if data.has("equipment"):
		apply_equipment_save_data(data["equipment"])

	if data.has("skills") and skills != null:
		skills.apply_skills_data(data["skills"])

	if data.has("effect_runtimes"):
		load_effect_runtimes_save_data(data["effect_runtimes"])
	else:
		active_effect_runtimes.clear()
		recompute_runtime_modifiers()

	var saved_update_time: float = float(data.get("last_effect_update_time", 0.0))
	var current_world_time: float = 0.0
	if TimeManager != null:
		current_world_time = float(TimeManager.world_time_seconds)

	var elapsed: float = max(0.0, current_world_time - saved_update_time)
	if elapsed > 0.0:
		apply_offscreen_effect_elapsed(elapsed)
	else:
		last_effect_update_time = current_world_time

func save_persistent_stats() -> void:
	print("SAVE unit_id=", unit_id, " hp=", stats.hp)

	if is_player_unit:
		PlayerData.max_hp = stats.max_hp
		PlayerData.hp = stats.hp
		PlayerData.attack = stats.attack
		PlayerData.defense = stats.defense
		PlayerData.speed = stats.speed
		PlayerData.extended_stats_data = stats.get_stats_data()
		PlayerData.effect_runtimes_data = get_effect_runtimes_save_data()

		if TimeManager != null:
			PlayerData.last_effect_update_time = float(TimeManager.world_time_seconds)
		else:
			PlayerData.last_effect_update_time = last_effect_update_time

		if skills != null:
			PlayerData.skills_data = skills.get_skills_data()

		if inventory != null:
			PlayerData.inventory_data = inventory.save_inventory_data()

		PlayerData.equipment_data = get_equipment_save_data()

		print("PLAYER SAVE map_id=", map_id)
		print("PLAYER SAVE global_position=", global_position)
		print("PLAYER SAVE local position=", position)
		print("PLAYER SAVE current_tile=", get_current_tile_coords())
		print("PLAYER SAVE equipment_data=", PlayerData.equipment_data)

		if map_id != "":
			PlayerData.map_positions[map_id] = get_current_tile_coords()
			print("PLAYER SAVE map_positions=", PlayerData.map_positions)
		else:
			print("PLAYER SAVE FAILED: map_id is empty")

		return

	if unit_id != "":
		var data: Dictionary = get_stats_data()
		data["is_dead"] = stats.hp <= 0
		WorldState.unit_states[unit_id] = data
		print("SAVE unit_id=", unit_id, " hp=", stats.hp)

func load_persistent_stats() -> void:
	if is_player_unit:
		print("PLAYER LOAD map_id=", map_id)
		print("PLAYER LOAD map_positions=", PlayerData.map_positions)

		if PlayerData.extended_stats_data.size() > 0:
			stats.apply_stats_data(PlayerData.extended_stats_data)
		else:
			stats.max_hp = PlayerData.max_hp
			stats.hp = PlayerData.hp
			stats.attack = PlayerData.attack
			stats.defense = PlayerData.defense
			stats.speed = PlayerData.speed

		if skills != null and PlayerData.skills_data.size() > 0:
			skills.apply_skills_data(PlayerData.skills_data)

		if inventory != null:
			inventory.load_inventory_data(PlayerData.inventory_data)

		apply_equipment_save_data(PlayerData.equipment_data)

		if PlayerData.effect_runtimes_data.size() > 0:
			load_effect_runtimes_save_data(PlayerData.effect_runtimes_data)

			var current_world_time: float = 0.0
			if TimeManager != null:
				current_world_time = float(TimeManager.world_time_seconds)

			var elapsed: float = max(0.0, current_world_time - float(PlayerData.last_effect_update_time))
			if elapsed > 0.0:
				apply_offscreen_effect_elapsed(elapsed)
			else:
				last_effect_update_time = current_world_time
		else:
			active_effect_runtimes.clear()
			recompute_runtime_modifiers()
			if TimeManager != null:
				last_effect_update_time = float(TimeManager.world_time_seconds)

		if map_id != "" and PlayerData.map_positions.has(map_id):
			var saved_tile: Vector2i = PlayerData.map_positions[map_id]
			print("PLAYER RESTORE tile=", saved_tile)
			global_position = ground_layer.to_global(ground_layer.map_to_local(saved_tile))
			target_position = global_position

		return

	if unit_id != "" and WorldState.unit_states.has(unit_id):
		print("LOAD unit_id=", unit_id, " hp=", WorldState.unit_states[unit_id]["hp"])
		apply_stats_data(WorldState.unit_states[unit_id])
func apply_enemy_data(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		return

	name = enemy_data.enemy_name
	faction = enemy_data.faction.to_upper()

	stats.max_hp = enemy_data.max_hp
	stats.hp = enemy_data.max_hp
	stats.attack = enemy_data.attack
	stats.defense = enemy_data.defense
	stats.speed = enemy_data.speed
	stats.accuracy = enemy_data.accuracy
	stats.evasion = enemy_data.evasion
	stats.crit_rate = enemy_data.crit_rate
	stats.crit_damage = enemy_data.crit_damage
	stats.luck = enemy_data.luck
	stats.element = enemy_data.element
	stats.element_resistances = enemy_data.element_resistances.duplicate(true)

	stats.strength = enemy_data.strength
	stats.vitality = enemy_data.vitality
	stats.agility = enemy_data.agility
	stats.dexterity = enemy_data.dexterity
	stats.intelligence = enemy_data.intelligence
	stats.spirit = enemy_data.spirit
	stats.sense = enemy_data.sense
	stats.charm = enemy_data.charm

	# 基礎ステータスから派生した最大HPを反映し、出現時は満タンにする。
	if stats.has_method("refresh_derived_max_hp"):
		stats.refresh_derived_max_hp(false)
		stats.hp = stats.max_hp

	if skills != null:
		skills.gathering = enemy_data.gathering
		skills.investigation = enemy_data.investigation
		skills.stealth = enemy_data.stealth
		skills.trap_disarm = enemy_data.trap_disarm
		skills.fishing = enemy_data.fishing
		skills.appraisal = enemy_data.appraisal
		skills.cooking = enemy_data.cooking
		skills.repair = enemy_data.repair
		skills.smithing = enemy_data.smithing
		skills.alchemy = enemy_data.alchemy
		skills.negotiation = enemy_data.negotiation
		skills.speech = enemy_data.speech
		skills.medical = enemy_data.medical

	equipped_items.clear()
	apply_legacy_equipment_fields(enemy_data)

	override_combat_style = enemy_data.override_combat_style
	combat_style = enemy_data.combat_style
	override_move_style = enemy_data.override_move_style
	move_style = enemy_data.move_style

	talk_display_name = enemy_data.talk_display_name
	talk_greeting_text = enemy_data.talk_greeting_text
	talk_portrait = enemy_data.talk_portrait
	unit_roles = enemy_data.unit_roles
	friendliness = enemy_data.friendliness
	disable_hunger_decay = enemy_data.disable_hunger_decay
	auto_eat_food_when_hungry = enemy_data.auto_eat_food_when_hungry
	auto_generate_food_when_hungry = enemy_data.auto_generate_food_when_hungry
	auto_generated_food_item_id = enemy_data.auto_generated_food_item_id
	print_hunger_to_output = false
	can_offer_request = enemy_data.can_offer_request
	can_trade = enemy_data.can_trade
	can_receive_order = enemy_data.can_receive_order
	extra_interact_actions = enemy_data.extra_interact_actions.duplicate()
	request_description = enemy_data.request_description
	request_accept_text = enemy_data.request_accept_text
	request_decline_text = enemy_data.request_decline_text
	random_talk_texts = enemy_data.random_talk_texts.duplicate()
	drop_inventory_on_death = enemy_data.drop_inventory_on_death
	death_inventory_drop_radius = enemy_data.death_inventory_drop_radius

	apply_initial_inventory_from_data(enemy_data.initial_inventory_items)

	apply_shop_inventory_from_data(
		enemy_data.can_generate_shop_inventory,
		enemy_data.shop_min_items,
		enemy_data.shop_max_items,
		enemy_data.shop_loot_categories
	)

	if sprite != null:
		sprite.scale = enemy_data.sprite_scale

	if enemy_data.animation_profile != null:
		apply_animation_profile(enemy_data.animation_profile)
	else:
		apply_animation_frames(
			enemy_data.idle_right_frames,
			enemy_data.walk_right_frames,
			enemy_data.idle_left_frames,
			enemy_data.walk_left_frames,
			enemy_data.idle_down_frames,
			enemy_data.walk_down_frames,
			enemy_data.idle_up_frames,
			enemy_data.walk_up_frames
		)


func handle_death() -> void:
	drop_inventory_items_on_death_if_needed()

	if is_player_unit:
		print("プレイヤー死亡")
		return

	if unit_id != "":
		var data: Dictionary = get_stats_data()
		data["is_dead"] = true
		WorldState.unit_states[unit_id] = data

	queue_free()


func drop_inventory_items_on_death_if_needed() -> void:
	if not drop_inventory_on_death:
		return

	if inventory == null:
		return

	var drop_targets: Array[Dictionary] = _collect_inventory_drop_targets()
	if drop_targets.is_empty():
		return

	var dropped_count: int = 0
	var failed_count: int = 0
	var max_radius: int = max(1, death_inventory_drop_radius)

	for target in drop_targets:
		var entry_value: Variant = target.get("entry", {})
		if typeof(entry_value) != TYPE_DICTIONARY:
			failed_count += 1
			continue

		var entry: Dictionary = (entry_value as Dictionary).duplicate(true)
		if _is_inventory_drop_entry_empty(entry):
			continue

		var dropped: bool = ItemDropHelper.drop_entry_near_unit(entry, self, max_radius)
		if dropped:
			dropped_count += 1
			_clear_inventory_drop_target(target)
		else:
			failed_count += 1

	if dropped_count <= 0:
		if failed_count > 0:
			print("[DEATH DROP] failed: ", name, " failed=", failed_count)
		return

	if is_player_unit:
		PlayerData.inventory_data = inventory.save_inventory_data()

	notify_inventory_refresh()
	print("[DEATH DROP] unit=", name, " dropped=", dropped_count, " failed=", failed_count)


func _collect_inventory_drop_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if inventory == null:
		return result

	if inventory.has_method("get_all_items"):
		var bag_items: Array = inventory.get_all_items()
		for i in range(bag_items.size()):
			var raw_entry: Variant = bag_items[i]
			if typeof(raw_entry) != TYPE_DICTIONARY:
				continue

			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			if _is_inventory_drop_entry_empty(entry):
				continue

			result.append({
				"source": "bag",
				"index": i,
				"entry": entry
			})

	if inventory.has_method("get_all_hotbar_items"):
		var hotbar_items: Array = inventory.get_all_hotbar_items()
		for i in range(hotbar_items.size()):
			var raw_hotbar_entry: Variant = hotbar_items[i]
			if typeof(raw_hotbar_entry) != TYPE_DICTIONARY:
				continue

			var hotbar_entry: Dictionary = (raw_hotbar_entry as Dictionary).duplicate(true)
			if _is_inventory_drop_entry_empty(hotbar_entry):
				continue

			result.append({
				"source": "hotbar",
				"index": i,
				"entry": hotbar_entry
			})

	return result


func _is_inventory_drop_entry_empty(entry: Dictionary) -> bool:
	var item_id: String = String(entry.get("item_id", ""))
	var amount: int = int(entry.get("amount", 0))
	return item_id == "" or amount <= 0


func _clear_inventory_drop_target(target: Dictionary) -> void:
	if inventory == null:
		return

	var source: String = String(target.get("source", ""))
	var index: int = int(target.get("index", -1))

	if index < 0:
		return

	if source == "bag":
		if inventory.has_method("clear_slot"):
			inventory.clear_slot(index)
		elif inventory.has_method("set_item_data_at"):
			inventory.set_item_data_at(index, {})
		return

	if source == "hotbar":
		if inventory.has_method("clear_hotbar_slot"):
			inventory.clear_hotbar_slot(index)
		elif inventory.has_method("set_hotbar_item_data_at"):
			inventory.set_hotbar_item_data_at(index, {})
		return


func apply_npc_data(npc_data: NpcData) -> void:
	if npc_data == null:
		return

	name = npc_data.npc_name
	faction = npc_data.faction.to_upper()

	stats.max_hp = npc_data.max_hp
	stats.hp = npc_data.max_hp
	stats.attack = npc_data.attack
	stats.defense = npc_data.defense
	stats.speed = npc_data.speed
	stats.accuracy = npc_data.accuracy
	stats.evasion = npc_data.evasion
	stats.crit_rate = npc_data.crit_rate
	stats.crit_damage = npc_data.crit_damage
	stats.luck = npc_data.luck
	stats.element = npc_data.element
	stats.element_resistances = npc_data.element_resistances.duplicate(true)

	stats.strength = npc_data.strength
	stats.vitality = npc_data.vitality
	stats.agility = npc_data.agility
	stats.dexterity = npc_data.dexterity
	stats.intelligence = npc_data.intelligence
	stats.spirit = npc_data.spirit
	stats.sense = npc_data.sense
	stats.charm = npc_data.charm

	# 基礎ステータスから派生した最大HPを反映し、出現時は満タンにする。
	if stats.has_method("refresh_derived_max_hp"):
		stats.refresh_derived_max_hp(false)
		stats.hp = stats.max_hp

	if skills != null:
		skills.gathering = npc_data.gathering
		skills.investigation = npc_data.investigation
		skills.stealth = npc_data.stealth
		skills.trap_disarm = npc_data.trap_disarm
		skills.fishing = npc_data.fishing
		skills.appraisal = npc_data.appraisal
		skills.cooking = npc_data.cooking
		skills.repair = npc_data.repair
		skills.smithing = npc_data.smithing
		skills.alchemy = npc_data.alchemy
		skills.negotiation = npc_data.negotiation
		skills.speech = npc_data.speech
		skills.medical = npc_data.medical

	equipped_items.clear()
	apply_legacy_equipment_fields(npc_data)

	override_combat_style = npc_data.override_combat_style
	combat_style = npc_data.combat_style
	override_move_style = npc_data.override_move_style
	move_style = npc_data.move_style

	talk_display_name = npc_data.talk_display_name
	talk_greeting_text = npc_data.talk_greeting_text
	talk_portrait = npc_data.talk_portrait
	unit_roles = npc_data.unit_roles
	friendliness = npc_data.friendliness
	disable_hunger_decay = npc_data.disable_hunger_decay
	auto_eat_food_when_hungry = npc_data.auto_eat_food_when_hungry
	auto_generate_food_when_hungry = npc_data.auto_generate_food_when_hungry
	auto_generated_food_item_id = npc_data.auto_generated_food_item_id
	print_hunger_to_output = true
	can_offer_request = npc_data.can_offer_request
	can_trade = npc_data.can_trade
	can_receive_order = npc_data.can_receive_order
	extra_interact_actions = npc_data.extra_interact_actions.duplicate()
	request_description = npc_data.request_description
	request_accept_text = npc_data.request_accept_text
	request_decline_text = npc_data.request_decline_text
	random_talk_texts = npc_data.random_talk_texts.duplicate()
	drop_inventory_on_death = npc_data.drop_inventory_on_death
	death_inventory_drop_radius = npc_data.death_inventory_drop_radius

	apply_initial_inventory_from_data(npc_data.initial_inventory_items)

	apply_shop_inventory_from_data(
		npc_data.can_generate_shop_inventory,
		npc_data.shop_min_items,
		npc_data.shop_max_items,
		npc_data.shop_loot_categories
	)

	if npc_data.animation_profile != null:
		apply_animation_profile(npc_data.animation_profile)
	else:
		apply_animation_frames(
			npc_data.idle_right_frames,
			npc_data.walk_right_frames,
			npc_data.idle_left_frames,
			npc_data.walk_left_frames,
			npc_data.idle_down_frames,
			npc_data.walk_down_frames,
			npc_data.idle_up_frames,
			npc_data.walk_up_frames
		)


func sync_map_id_from_scene() -> void:
	if map_root != null:
		var scene_map_id = map_root.get("map_id")
		if scene_map_id != null and String(scene_map_id) != "":
			map_id = String(scene_map_id)
			return

	if GlobalDetailMap.current_detail_map_key != "":
		map_id = GlobalDetailMap.current_detail_map_key


func calculate_field_area_difficulty(field_tile: Vector2i) -> int:
	return randi_range(1, 5)


func create_detail_map_config(generator_type: String, field_tile: Vector2i) -> Dictionary:
	generator_type = generator_type.strip_edges().replace("\"", "").to_upper()

	print("CONFIG generator_type normalized = ", generator_type)

	var config = {
		"generator_type": String(generator_type),
		"field_x": field_tile.x,
		"field_y": field_tile.y,
		"area_difficulty": calculate_field_area_difficulty(field_tile),
		"enemy_spawn_count": 5,
		"npc_spawn_count": 3,
		"enemy_type_ids": ["bat", "slime"],
		"npc_type_ids": ["villager"]
	}

	match generator_type:
		"GRASS":
			config["enemy_spawn_count"] = 5
			config["npc_spawn_count"] = 10
			config["enemy_type_ids"] = ["bat", "slime"]
			config["npc_type_ids"] = ["sabo"]

		"FOREST":
			config["enemy_spawn_count"] = 8
			config["npc_spawn_count"] = 10
			config["enemy_type_ids"] = ["bat", "orc"]
			config["npc_type_ids"] = ["npc-1"]

		"SAND":
			config["enemy_spawn_count"] = 4
			config["npc_spawn_count"] = 10
			config["enemy_type_ids"] = ["slime"]
			config["npc_type_ids"] = []

		"SEA":
			config["enemy_spawn_count"] = 6
			config["npc_spawn_count"] = 10
			config["enemy_type_ids"] = ["bat"]
			config["npc_type_ids"] = []

		"BEACH":
			config["enemy_spawn_count"] = 3
			config["npc_spawn_count"] = 12
			config["enemy_type_ids"] = ["slime"]
			config["npc_type_ids"] = ["sabo"]

	print("CONFIG result = ", config)
	return config


func resolve_map_references() -> void:
	var node: Node = self

	while node != null:
		if node.has_node("GroundLayer") and node.has_node("WallLayer") and node.has_node("EventLayer"):
			map_root = node
			break
		node = node.get_parent()

	if map_root == null:
		push_error("Unit: map_root が見つかりません")
		return

	ground_layer = map_root.get_node("GroundLayer") as TileMapLayer
	wall_layer = map_root.get_node("WallLayer") as TileMapLayer
	event_layer = map_root.get_node("EventLayer") as TileMapLayer
	units_node = map_root.get_node_or_null("Units")


func request_map_change(next_scene: String) -> bool:
	var node: Node = self

	while node != null:
		print("REQUEST MAP CHECK:", node.name, " script=", node.get_script())
		if node.has_method("load_map_by_path"):
			print("REQUEST MAP FOUND:", node.name, " next_scene=", next_scene)
			node.load_map_by_path(next_scene)
			print("REQUEST MAP CALLED")
			return true
		node = node.get_parent()

	push_error("Unit: load_map_by_path を持つ親が見つかりません")
	return false


func notify_hud_log(text: String) -> void:
	var node: Node = self

	while node != null:
		if node.has_method("add_hud_log"):
			node.add_hud_log(text)
			return
		node = node.get_parent()


func notify_hud_player_status_refresh() -> void:
	var node: Node = self

	while node != null:
		if node.has_method("update_hud_player_status"):
			node.update_hud_player_status()
			return
		node = node.get_parent()


func notify_hud_effects_refresh() -> void:
	var node: Node = self

	while node != null:
		if node.has_method("update_hud_effects"):
			node.update_hud_effects()
			return
		node = node.get_parent()


func _should_apply_hunger_decay() -> bool:
	if disable_hunger_decay:
		return false
	if stats == null:
		return false
	if not _stats_has_property(stats, "hunger"):
		return false
	if not _stats_has_property(stats, "max_hunger"):
		return false
	return true


func _is_party_member_unit() -> bool:
	# パーティー未実装。
	# 実装後にここを差し替える想定。
	return false


func _is_food_item_id(item_id: String) -> bool:
	if item_id == "":
		return false
	if not ItemDatabase.exists(item_id):
		return false

	var item_res = ItemDatabase.get_item_resource(item_id)
	if item_res == null:
		return false

	for info in item_res.get_property_list():
		if String(info.get("name", "")) == "category":
			return String(item_res.get("category")).strip_edges().to_lower() == "food"

	return false


func _find_food_item_id_in_inventory() -> String:
	if inventory == null:
		return ""
	if not inventory.has_method("get_all_items"):
		return ""

	var items: Array = inventory.get_all_items()
	for raw_entry in items:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 0))
		if item_id == "" or amount <= 0:
			continue
		if _is_food_item_id(item_id):
			return item_id

	return ""


func _get_all_food_item_ids() -> Array[String]:
	var result: Array[String] = []

	if ItemDatabase == null:
		return result

	var resources_dict: Dictionary = ItemDatabase.ITEM_RESOURCES
	for raw_item_id in resources_dict.keys():
		var item_id: String = String(raw_item_id)
		if item_id == "":
			continue
		if _is_food_item_id(item_id):
			result.append(item_id)

	return result


func _spawn_auto_generated_food() -> bool:
	if inventory == null:
		return false
	if not inventory.has_method("add_item_entry"):
		return false

	var item_id: String = ""
	var food_ids: Array[String] = _get_all_food_item_ids()
	if not food_ids.is_empty():
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		item_id = food_ids[rng.randi_range(0, food_ids.size() - 1)]
	elif auto_generated_food_item_id != "" and ItemDatabase.exists(auto_generated_food_item_id):
		item_id = auto_generated_food_item_id

	if item_id == "":
		return false

	var added: bool = inventory.add_item_entry({
		"item_id": item_id,
		"amount": 1
	})
	if added:
		notify_inventory_refresh()
		if _should_print_hunger_output():
			print("[HUNGER] ", name, " が食料を生成: ", ItemDatabase.get_display_name(item_id))
	return added


func _try_consume_food_from_inventory() -> bool:
	var food_item_id: String = _find_food_item_id_in_inventory()
	if food_item_id == "":
		return false

	var item_data = ItemDatabase.get_item_data(food_item_id)
	if item_data == null:
		return false

	if not ItemEffectManager.apply_item_effect(self, self, item_data):
		return false

	var consumed: bool = false
	if inventory != null:
		if inventory.has_method("consume_total_amount_ignore_instance"):
			consumed = inventory.consume_total_amount_ignore_instance(food_item_id, 1)
		elif inventory.has_method("consume_item_amount"):
			consumed = inventory.consume_item_amount(food_item_id, 1)

	if consumed:
		notify_inventory_refresh()
		if _should_print_hunger_output():
			print("[HUNGER] ", name, " が食べた: ", ItemDatabase.get_display_name(food_item_id), " / ", _get_hunger_status_text())

	return consumed


func _try_auto_eat_food_if_needed() -> void:
	if not auto_eat_food_when_hungry:
		return
	if stats == null:
		return
	if not _stats_has_property(stats, "hunger"):
		return

	var hunger_key: String = _get_hunger_condition_key_from_value(float(stats.hunger))
	if hunger_key != "hungry" and hunger_key != "starving" and hunger_key != "starving_dead":
		return

	if _try_consume_food_from_inventory():
		return

	if not auto_generate_food_when_hungry:
		return

	if _spawn_auto_generated_food():
		_try_consume_food_from_inventory()


func _should_print_hunger_output() -> bool:
	if is_player_unit:
		return true
	if print_hunger_to_output:
		return true
	if faction.to_upper() == "NPC":
		return true
	return false


func _get_hunger_condition_key_from_value(hunger_value: float) -> String:
	if stats == null:
		return ""
	if not _stats_has_property(stats, "max_hunger"):
		return ""

	var max_hunger_value: float = float(stats.max_hunger)
	if max_hunger_value <= 0.0:
		return ""

	var ratio: float = clamp(hunger_value / max_hunger_value, 0.0, 1.0)

	# 餓死は 0% のときだけ
	if is_equal_approx(ratio, 0.0):
		return "starving_dead"
	if ratio <= 0.10:
		return "starving"
	if ratio <= 0.40:
		return "hungry"
	if ratio >= 0.80:
		return "full"

	return ""



func _apply_hunger_time_decay(elapsed_seconds: float, print_output: bool) -> void:
	if elapsed_seconds <= 0.0:
		return
	if stats == null:
		return
	if not _stats_has_property(stats, "hunger"):
		return
	if not _stats_has_property(stats, "max_hunger"):
		return

	var max_hunger_value: float = float(stats.max_hunger)
	if max_hunger_value <= 0.0:
		return

	var days_to_ten_percent: float = 3.0
	if _stats_has_property(stats, "hunger_days_to_ten_percent"):
		days_to_ten_percent = max(0.01, float(stats.hunger_days_to_ten_percent))

	var hunger_loss_per_second: float = (max_hunger_value * 0.90) / (days_to_ten_percent * 86400.0)
	var old_hunger: float = float(stats.hunger)
	var new_hunger: float = max(0.0, old_hunger - hunger_loss_per_second * elapsed_seconds)

	if is_equal_approx(old_hunger, new_hunger):
		return

	stats.hunger = new_hunger
	notify_hud_effects_refresh()

	if print_output and _should_print_hunger_output():
		print("[HUNGER] ", name, " / ", _get_hunger_status_text())


func _apply_hunger_starvation_damage(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return
	if stats == null:
		return
	if not _stats_has_property(stats, "hunger"):
		return
	if float(stats.hunger) > 0.0:
		starvation_damage_accumulator = 0.0
		return
	if not _stats_has_property(stats, "hp"):
		return

	var starvation_damage_per_second: float = 0.1
	starvation_damage_accumulator += starvation_damage_per_second * elapsed_seconds

	var damage_value: int = int(floor(starvation_damage_accumulator))
	if damage_value <= 0:
		return

	starvation_damage_accumulator -= float(damage_value)

	if stats.has_method("take_damage"):
		stats.take_damage(damage_value)
	else:
		stats.hp = max(0, int(stats.hp) - damage_value)

	if _should_print_hunger_output():
		print("[HUNGER] ", name, " / 餓死ダメージ ", damage_value, " / ", _get_hunger_status_text())

	notify_hud_player_status_refresh()
	notify_hud_effects_refresh()


func _get_hunger_status_text() -> String:
	if stats == null:
		return "0%"

	var current_value: float = 0.0
	var max_value: float = 0.0

	if _stats_has_property(stats, "hunger"):
		current_value = float(stats.hunger)
	if _stats_has_property(stats, "max_hunger"):
		max_value = float(stats.max_hunger)

	if max_value <= 0.0:
		return "0%"

	var ratio_percent: int = int(round(clamp(current_value / max_value, 0.0, 1.0) * 100.0))
	return "%d%% (%.1f/%.1f)" % [ratio_percent, current_value, max_value]


func consume_blocked_action_turn(log_text: String = "今は行動できない") -> void:
	if log_text != "":
		notify_hud_log(log_text)

	if DebugSettings.debug_free_action:
		return

	if units_node == null:
		return

	TimeManager.advance_time(units_node, get_total_speed())

	var node: Node = self
	while node != null:
		if node.has_method("refresh_hud"):
			node.refresh_hud()

			if node.has_method("force_sync_hallucination_visuals"):
				node.force_sync_hallucination_visuals()
			break
		node = node.get_parent()

	TimeManager.resolve_ai_turns(units_node)


func try_auto_use_dungeon_stairs_on_touch() -> bool:
	if map_root == null:
		return false

	if map_root.has_method("can_trigger_stairs_on_touch"):
		if not map_root.can_trigger_stairs_on_touch():
			return false

	if not map_root.has_method("try_use_dungeon_stairs_from_player_position"):
		return false

	return map_root.try_use_dungeon_stairs_from_player_position()


func reset_after_map_transition() -> void:
	is_transitioning = false
	is_moving = false
	repeat_timer = 0.0
	velocity = Vector2.ZERO
	target_position = global_position

	if has_node("Controller"):
		var c = $Controller
		if c != null and c.has_method("reset_input_state"):
			c.reset_input_state()

	TimeManager.is_resolving_turn = false


func try_pickup_items_on_current_tile() -> bool:
	var map_root_local: Node = get_parent().get_parent()
	if map_root_local == null:
		return false

	var item_pickups_node = map_root_local.get_node_or_null("ItemPickups")
	if item_pickups_node == null:
		return false

	var current_tile = ground_layer.local_to_map(
		ground_layer.to_local(global_position)
	)

	for pickup in item_pickups_node.get_children():
		if pickup == null:
			continue
		if pickup.tile_coords != current_tile:
			continue

		var pickup_entry: Dictionary = {}
		if pickup.has_method("get_item_entry"):
			pickup_entry = pickup.get_item_entry()
		else:
			pickup_entry = {
				"item_id": pickup.item_id,
				"amount": pickup.amount
			}

		var added: bool = inventory.add_item_entry(pickup_entry)
		if not added:
			continue

		print("%s x%d を拾った" % [
			ItemDatabase.get_entry_display_name(pickup_entry),
			int(pickup_entry.get("amount", 1))
		])

		pickup.queue_free()
		return true

	return false


func notify_inventory_refresh() -> void:
	var node: Node = self

	while node != null:
		if node.has_method("refresh_inventory_ui"):
			node.refresh_inventory_ui()
			return
		node = node.get_parent()


func try_interact_action() -> void:
	print("[INTERACT] called")

	if is_any_ui_locked():
		print("[INTERACT] blocked by ui lock")
		return

	if is_inventory_open_from_root():
		print("[INTERACT] blocked by inventory")
		return

	if try_open_quest_board():
		print("[INTERACT] opened quest board")
		return

	if try_talk_to_front_unit():
		print("[INTERACT] opened talk")
		return

	if try_pickup_items_on_current_tile():
		print("[INTERACT] picked item")
		return

	if try_open_chest_on_current_tile():
		print("[INTERACT] opened chest")
		return

	print("[INTERACT] fallback transition")
	try_interact_transition()


func try_open_chest_on_current_tile() -> bool:
	if not is_player_unit:
		return false

	if map_root == null:
		return false

	var chests_node = map_root.get_node_or_null("Chests")
	if chests_node == null:
		return false

	var current_tile: Vector2i = get_current_tile_coords()

	for chest in chests_node.get_children():
		if chest == null:
			continue

		if chest.tile_coords != current_tile:
			continue

		chest.open_chest(self)
		return true

	return false
func get_stats_node():
	return get_node_or_null("Stats")


func add_status_effect_runtime(runtime: UnitEffectRuntime) -> void:
	if runtime == null:
		return

	if runtime.is_status_effect() and runtime.status_id != &"":
		remove_status_effect(runtime.status_id)

	if runtime.status_id == &"poison" or runtime.status_id == &"burning" or runtime.status_id == &"frostbite":
		runtime.tick_interval_seconds = 1.0

	print("[STATUS ADD] unit=", name, " status=", String(runtime.status_id), " effect_type=", runtime.effect_type, " duration=", runtime.remaining_duration)

	active_effect_runtimes.append(runtime)
	recompute_runtime_modifiers()


func remove_status_effect(status_id: StringName) -> void:
	if status_id == &"":
		return

	var remained: Array[UnitEffectRuntime] = []

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue

		if runtime.is_status_effect() and runtime.status_id == status_id:
			continue

		remained.append(runtime)

	var removed_count: int = active_effect_runtimes.size() - remained.size()
	active_effect_runtimes = remained
	if removed_count > 0:
		print("[STATUS EXPIRE] unit=", name, " removed=", removed_count)
	print("[STATUS REMOVE] unit=", name, " status=", String(status_id), " remaining=", active_effect_runtimes.size())
	recompute_runtime_modifiers()


func has_status_effect(status_id: StringName) -> bool:
	if status_id == &"":
		return false

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		if runtime.is_status_effect() and runtime.status_id == status_id:
			return true

	return false



func advance_effect_runtimes(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return

	var had_runtime: bool = not active_effect_runtimes.is_empty()

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		runtime.advance_time(elapsed_seconds)

	process_effect_ticks()

	var removed_count: int = remove_expired_effect_runtimes()
	if had_runtime or removed_count > 0:
		recompute_runtime_modifiers()

	if TimeManager != null:
		last_effect_update_time = float(TimeManager.world_time_seconds)
	else:
		last_effect_update_time += elapsed_seconds

func consume_effect_turns(turn_count: int = 1) -> void:
	if turn_count <= 0:
		return

	var had_runtime: bool = not active_effect_runtimes.is_empty()

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		runtime.consume_turn(turn_count)

	var removed_count: int = remove_expired_effect_runtimes()
	if had_runtime or removed_count > 0:
		recompute_runtime_modifiers()

func consume_effect_actions(action_count: int = 1) -> void:
	if action_count <= 0:
		return

	var had_runtime: bool = not active_effect_runtimes.is_empty()

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		runtime.consume_action(action_count)

	var removed_count: int = remove_expired_effect_runtimes()
	if had_runtime or removed_count > 0:
		recompute_runtime_modifiers()
func process_effect_ticks() -> void:
	var stats_node = get_stats_node()
	if stats_node == null:
		return

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue

		while runtime.can_consume_tick():
			runtime.consume_one_tick()
			_apply_runtime_tick(runtime, stats_node)


func _apply_runtime_damage(stats_node, status_label: String, damage_value: int) -> void:
	if stats_node == null:
		return
	if damage_value <= 0:
		return

	if stats_node.has_method("take_damage"):
		stats_node.take_damage(damage_value)
	elif _stats_has_property(stats_node, "hp"):
		stats_node.hp = max(0, int(stats_node.hp) - damage_value)

	print("[STATUS TICK] unit=", name, " status=", status_label, " damage=", damage_value, " hp=", stats_node.hp)

	notify_hud_player_status_refresh()
	notify_hud_effects_refresh()


func _apply_runtime_tick(runtime: UnitEffectRuntime, stats_node) -> void:
	if runtime == null:
		return
	if stats_node == null:
		return

	if runtime.status_id == &"poison":
		if _stats_has_property(stats_node, "hp"):
			var damage_value: int = max(1, runtime.status_power)
			stats_node.hp = max(0, int(stats_node.hp) - damage_value)
			print("[STATUS TICK] unit=", name, " status=poison damage=", damage_value, " hp=", stats_node.hp)
		return

	if runtime.status_id == &"burning":
		if _stats_has_property(stats_node, "hp"):
			var damage_value: int = max(1, runtime.status_power)
			stats_node.hp = max(0, int(stats_node.hp) - damage_value)
			print("[STATUS TICK] unit=", name, " status=burning damage=", damage_value, " hp=", stats_node.hp)
		return

	if runtime.status_id == &"frostbite":
		if _stats_has_property(stats_node, "hp"):
			var damage_value: int = max(1, runtime.status_power)
			stats_node.hp = max(0, int(stats_node.hp) - damage_value)
			print("[STATUS TICK] unit=", name, " status=frostbite damage=", damage_value, " hp=", stats_node.hp)
		return



func remove_expired_effect_runtimes() -> int:
	var remained: Array[UnitEffectRuntime] = []
	var removed_count: int = 0

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		if runtime.is_expired():
			removed_count += 1
			continue
		remained.append(runtime)

	active_effect_runtimes = remained
	return removed_count
func recompute_runtime_modifiers() -> void:
	runtime_attack_multiplier = 1.0
	runtime_defense_multiplier = 1.0
	runtime_speed_multiplier = 1.0
	runtime_accuracy_multiplier = 1.0
	runtime_evasion_multiplier = 1.0
	runtime_crit_rate_multiplier = 1.0

	runtime_attack_flat = 0
	runtime_defense_flat = 0
	runtime_speed_flat = 0
	runtime_accuracy_flat = 0
	runtime_evasion_flat = 0
	runtime_crit_rate_flat = 0

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue
		if not runtime.is_modifier_effect():
			continue

		var modifier_sign: float = 1.0
		if runtime.modifier_kind == ItemEffectData.ModifierKind.DEBUFF:
			modifier_sign = -1.0

		match String(runtime.stat_name):
			"attack":
				runtime_attack_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_attack_multiplier += modifier_sign * runtime.stat_percent

			"defense":
				runtime_defense_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_defense_multiplier += modifier_sign * runtime.stat_percent

			"speed":
				runtime_speed_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_speed_multiplier += modifier_sign * runtime.stat_percent

			"accuracy":
				runtime_accuracy_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_accuracy_multiplier += modifier_sign * runtime.stat_percent

			"evasion":
				runtime_evasion_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_evasion_multiplier += modifier_sign * runtime.stat_percent

			"crit_rate":
				runtime_crit_rate_flat += int(modifier_sign * float(runtime.stat_flat))
				runtime_crit_rate_multiplier += modifier_sign * runtime.stat_percent

	runtime_attack_multiplier = max(0.0, runtime_attack_multiplier)
	runtime_defense_multiplier = max(0.0, runtime_defense_multiplier)
	runtime_speed_multiplier = max(0.0, runtime_speed_multiplier)
	runtime_accuracy_multiplier = max(0.0, runtime_accuracy_multiplier)
	runtime_evasion_multiplier = max(0.0, runtime_evasion_multiplier)
	runtime_crit_rate_multiplier = max(0.0, runtime_crit_rate_multiplier)

	print("[MODIFIER] unit=", name, " atk=", runtime_attack_multiplier, " def=", runtime_defense_multiplier, " spd=", runtime_speed_multiplier, " acc=", runtime_accuracy_multiplier, " eva=", runtime_evasion_multiplier, " crit=", runtime_crit_rate_multiplier)


func get_modified_stat_value(stat_name: StringName, base_value: int) -> int:
	match String(stat_name):
		"attack":
			return max(0, int(round((float(base_value) + float(runtime_attack_flat)) * runtime_attack_multiplier)))

		"defense":
			return max(0, int(round((float(base_value) + float(runtime_defense_flat)) * runtime_defense_multiplier)))

		"speed":
			return max(1, int(round((float(base_value) + float(runtime_speed_flat)) * runtime_speed_multiplier)))

		"accuracy":
			return max(0, int(round((float(base_value) + float(runtime_accuracy_flat)) * runtime_accuracy_multiplier)))

		"evasion":
			return max(0, int(round((float(base_value) + float(runtime_evasion_flat)) * runtime_evasion_multiplier)))

		"crit_rate":
			return max(0, int(round((float(base_value) + float(runtime_crit_rate_flat)) * runtime_crit_rate_multiplier)))

	return base_value


func is_action_blocked_by_status() -> bool:
	if has_status_effect(&"paralysis"):
		return true
	if has_status_effect(&"sleep"):
		return true
	return false


func _build_grant_item_candidate_ids(effect: ItemEffectData) -> Array[String]:
	var result: Array[String] = []

	if effect == null:
		return result

	if effect.grant_item_id != "":
		if ItemDatabase.exists(effect.grant_item_id):
			result.append(effect.grant_item_id)

	for raw_id in effect.grant_item_ids:
		var item_id: String = String(raw_id)
		if item_id == "":
			continue
		if not ItemDatabase.exists(item_id):
			continue
		if not result.has(item_id):
			result.append(item_id)

	var normalized_categories: Array[String] = []
	for raw_category in effect.grant_item_categories:
		var category_text: String = ItemCategories.normalize(String(raw_category))
		if category_text == "":
			continue
		if not normalized_categories.has(category_text):
			normalized_categories.append(category_text)

	if not normalized_categories.is_empty():
		var category_items: Array[String] = ItemDatabase.get_item_ids_by_categories(normalized_categories)
		for item_id in category_items:
			if item_id == "":
				continue
			if not result.has(item_id):
				result.append(item_id)

	return result


func _roll_grant_item_entries(effect: ItemEffectData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if effect == null:
		return result

	var candidate_ids: Array[String] = _build_grant_item_candidate_ids(effect)
	if candidate_ids.is_empty():
		return result

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var kind_count: int = effect.get_rolled_grant_item_kind_count()
	kind_count = clamp(kind_count, 1, candidate_ids.size())

	var pool: Array[String] = candidate_ids.duplicate()

	for i in range(kind_count):
		if pool.is_empty():
			break

		var pick_index: int = rng.randi_range(0, pool.size() - 1)
		var item_id: String = pool[pick_index]
		pool.remove_at(pick_index)

		var amount: int = effect.get_rolled_grant_item_amount()
		amount = max(1, amount)

		result.append({
			"item_id": item_id,
			"amount": amount
		})

	return result


func _can_add_all_entries_to_inventory(entries: Array[Dictionary]) -> bool:
	if inventory == null:
		return false

	var temp_inventory: Inventory = Inventory.new()
	temp_inventory.max_slots = inventory.max_slots
	temp_inventory.initialize_empty_slots()
	temp_inventory.load_inventory_data(inventory.save_inventory_data())

	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		if not temp_inventory.add_item_entry(entry):
			return false

	return true


func grant_items_from_effect(effect: ItemEffectData) -> bool:
	if effect == null:
		return false
	if inventory == null:
		return false

	var rolled_entries: Array[Dictionary] = _roll_grant_item_entries(effect)
	if rolled_entries.is_empty():
		notify_hud_log("補給袋の中身が決まらなかった")
		return false

	if not _can_add_all_entries_to_inventory(rolled_entries):
		notify_hud_log("持ち物がいっぱいで受け取れない")
		return false

	for entry in rolled_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var item_id: String = String(entry.get("item_id", ""))
		var amount: int = int(entry.get("amount", 0))
		if item_id == "" or amount <= 0:
			continue

		inventory.add_item_entry({
			"item_id": item_id,
			"amount": amount
		})

		notify_hud_log("入手: %s x%d" % [ItemDatabase.get_display_name(item_id), amount])

	PlayerData.inventory_data = inventory.save_inventory_data()
	notify_inventory_refresh()
	return true


func grant_item_from_effect(item_id: String, amount: int) -> bool:
	if item_id == "" or amount <= 0:
		return false
	if inventory == null:
		return false
	if not inventory.add_item(item_id, amount):
		notify_hud_log("持ち物がいっぱいで受け取れない")
		return false

	PlayerData.inventory_data = inventory.save_inventory_data()
	notify_inventory_refresh()
	notify_hud_log("入手: %s x%d" % [ItemDatabase.get_display_name(item_id), amount])
	return true


func grant_currency_from_effect(effect_or_amount) -> bool:
	if inventory == null:
		return false

	var amount: int = 0

	if effect_or_amount is ItemEffectData:
		amount = effect_or_amount.get_rolled_grant_currency_amount()
	else:
		amount = int(effect_or_amount)

	if amount <= 0:
		return false

	if not inventory.add_item("gold", amount):
		notify_hud_log("持ち物がいっぱいで金貨を受け取れない")
		return false

	PlayerData.inventory_data = inventory.save_inventory_data()
	notify_inventory_refresh()
	notify_hud_log("入手: Gold x%d" % amount)
	return true


func apply_item_teleport_effect(effect: ItemEffectData) -> bool:
	if effect == null:
		return false

	print("[ITEM EFFECT] teleport requested mode=", effect.get_teleport_mode_name())

	match effect.teleport_mode:
		ItemEffectData.TeleportMode.RANDOM:
			return _apply_random_teleport(effect)
		_:
			notify_hud_log("今はランダムテレポートのみ対応")
			return false


func _apply_random_teleport(effect: ItemEffectData) -> bool:
	if ground_layer == null:
		return false

	var current_tile: Vector2i = get_current_tile_coords()
	var min_range: int = max(0, int(effect.teleport_min_range))
	var max_range: int = max(min_range, int(effect.teleport_max_range))

	var candidates: Array[Vector2i] = _collect_random_teleport_candidates(current_tile, min_range, max_range)
	if candidates.is_empty():
		notify_hud_log("テレポート先が見つからない")
		return false

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var picked_index: int = rng.randi_range(0, candidates.size() - 1)
	var target_tile: Vector2i = candidates[picked_index]

	_teleport_to_tile(target_tile)
	notify_hud_log("ランダムテレポートした")
	return true


func _collect_random_teleport_candidates(origin_tile: Vector2i, min_range: int, max_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			var distance: int = absi(dx) + absi(dy)
			if distance < min_range:
				continue
			if distance > max_range:
				continue
			if dx == 0 and dy == 0:
				continue

			var target_tile: Vector2i = origin_tile + Vector2i(dx, dy)
			if _can_teleport_to_tile(target_tile):
				result.append(target_tile)

	return result


func _can_teleport_to_tile(tile_coords: Vector2i) -> bool:
	if ground_layer == null:
		return false

	if ground_layer.get_cell_source_id(tile_coords) == -1:
		return false

	if units_node != null:
		for other in units_node.get_children():
			if other == null:
				continue
			if other == self:
				continue
			if not other.has_method("get_occupied_tile_coords"):
				continue
			if other.get_occupied_tile_coords() == tile_coords:
				return false

	var tile_data = get_tile_data_at_coords(tile_coords)
	if tile_data != null:
		var scene_transfer = tile_data.get_custom_data("scene_transfer")
		if scene_transfer == true:
			return false

	var target_pos: Vector2 = ground_layer.to_global(ground_layer.map_to_local(tile_coords))
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if shape_node == null or shape_node.shape == null:
		return false

	var space_state = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = Transform2D(0, target_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Array = space_state.intersect_shape(query)
	if not result.is_empty():
		return false

	return true


func _teleport_to_tile(tile_coords: Vector2i) -> void:
	var target_pos: Vector2 = ground_layer.to_global(ground_layer.map_to_local(tile_coords))

	is_transitioning = false
	is_moving = false
	repeat_timer = repeat_delay
	velocity = Vector2.ZERO
	global_position = target_pos
	target_position = target_pos

	debug_print_current_tile_info()

	if is_player_unit:
		try_pickup_items_on_current_tile()



func get_effect_runtimes_save_data() -> Array:
	var result: Array = []

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue

		result.append({
			"source_item_id": runtime.source_item_id,
			"source_unit_id": runtime.source_unit_id,
			"effect_type": runtime.effect_type,
			"status_id": String(runtime.status_id),
			"status_power": runtime.status_power,
			"modifier_kind": runtime.modifier_kind,
			"stat_name": String(runtime.stat_name),
			"stat_flat": runtime.stat_flat,
			"stat_percent": runtime.stat_percent,
			"duration_type": runtime.duration_type,
			"remaining_duration": runtime.remaining_duration,
			"tick_interval_seconds": runtime.tick_interval_seconds,
			"tick_accumulator_seconds": runtime.tick_accumulator_seconds,
			"extra_data": runtime.extra_data.duplicate(true)
		})

	return result


func load_effect_runtimes_save_data(data_list: Array) -> void:
	active_effect_runtimes.clear()

	for entry in data_list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var runtime := UnitEffectRuntime.new()
		runtime.source_item_id = String(entry.get("source_item_id", ""))
		runtime.source_unit_id = String(entry.get("source_unit_id", ""))
		runtime.effect_type = int(entry.get("effect_type", ItemEffectData.EffectType.NONE))
		runtime.status_id = StringName(String(entry.get("status_id", "")))
		runtime.status_power = int(entry.get("status_power", 0))
		runtime.modifier_kind = int(entry.get("modifier_kind", ItemEffectData.ModifierKind.BUFF))
		runtime.stat_name = StringName(String(entry.get("stat_name", "")))
		runtime.stat_flat = int(entry.get("stat_flat", 0))
		runtime.stat_percent = float(entry.get("stat_percent", 0.0))
		runtime.duration_type = int(entry.get("duration_type", ItemEffectData.DurationType.NONE))
		runtime.remaining_duration = float(entry.get("remaining_duration", 0.0))
		runtime.tick_interval_seconds = float(entry.get("tick_interval_seconds", 0.0))
		runtime.tick_accumulator_seconds = float(entry.get("tick_accumulator_seconds", 0.0))

		var extra_value: Variant = entry.get("extra_data", {})
		if typeof(extra_value) == TYPE_DICTIONARY:
			runtime.extra_data = (extra_value as Dictionary).duplicate(true)
		else:
			runtime.extra_data = {}

		if runtime.is_expired():
			continue

		active_effect_runtimes.append(runtime)

	recompute_runtime_modifiers()

func apply_offscreen_effect_elapsed(elapsed_seconds: float) -> void:
	if elapsed_seconds <= 0.0:
		return

	if active_effect_runtimes.is_empty():
		if TimeManager != null:
			last_effect_update_time = float(TimeManager.world_time_seconds)
		else:
			last_effect_update_time += elapsed_seconds
		return

	var stats_node = get_stats_node()

	for runtime in active_effect_runtimes:
		if runtime == null:
			continue

		var effective_elapsed: float = elapsed_seconds

		if runtime.duration_type == ItemEffectData.DurationType.TIME:
			effective_elapsed = min(elapsed_seconds, max(0.0, runtime.remaining_duration))
			runtime.remaining_duration -= effective_elapsed

		if stats_node == null:
			continue
		if runtime.tick_interval_seconds <= 0.0:
			continue
		if effective_elapsed <= 0.0:
			continue

		var total_accumulated: float = runtime.tick_accumulator_seconds + effective_elapsed
		var tick_count: int = int(floor(total_accumulated / runtime.tick_interval_seconds))
		runtime.tick_accumulator_seconds = fmod(total_accumulated, runtime.tick_interval_seconds)

		if tick_count <= 0:
			continue

		if runtime.status_id == &"poison" or runtime.status_id == &"burning" or runtime.status_id == &"frostbite":
			if _stats_has_property(stats_node, "hp"):
				var damage_per_tick: int = max(1, runtime.status_power)
				var total_damage: int = damage_per_tick * tick_count
				stats_node.hp = max(0, int(stats_node.hp) - total_damage)

	var removed_count: int = remove_expired_effect_runtimes()
	if not active_effect_runtimes.is_empty() or removed_count > 0:
		recompute_runtime_modifiers()

	if TimeManager != null:
		last_effect_update_time = float(TimeManager.world_time_seconds)
	else:
		last_effect_update_time += elapsed_seconds

func _stats_has_property(stats_node, property_name: String) -> bool:
	if stats_node == null:
		return false

	for info in stats_node.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false
