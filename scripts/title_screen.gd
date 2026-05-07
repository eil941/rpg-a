extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/game_and_hud.tscn"

# メモ用。
# 現在の GameAndHud.tscn 側で最初に表示するマップを持っているなら、この値はまだ使いません。
# 将来 GameStartState などのautoloadを作った時に利用できます。
@export_file("*.tscn") var first_map_scene_path: String = "res://scenes/npc_debug_map_special_reworked.tscn"

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var info_label: Label = $CenterContainer/VBoxContainer/InfoLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	info_label.text = "仮タイトル画面です。"


func _on_new_game_pressed() -> void:
	_reset_new_game_state()
	_start_game_scene()


func _on_continue_pressed() -> void:
	# 仮実装。
	# まだセーブ/ロードを作り込んでいないので、状態を消さずにGameAndHudへ入るだけ。
	_start_game_scene()


func _on_options_pressed() -> void:
	info_label.text = "設定画面は未実装です。"


func _on_quit_pressed() -> void:
	get_tree().quit()


func _start_game_scene() -> void:
	if game_scene_path.strip_edges() == "":
		push_error("TitleScreen: game_scene_path が空です")
		return

	var error: Error = get_tree().change_scene_to_file(game_scene_path)
	if error != OK:
		push_error("TitleScreen: ゲームシーンを開けません: " + game_scene_path)


func _reset_new_game_state() -> void:
	_reset_world_state()
	_reset_player_data()
	_reset_global_detail_map()
	_reset_global_dungeon()
	_reset_global_player_spawn()


func _reset_world_state() -> void:
	if WorldState == null:
		return

	_clear_dictionary_property(WorldState, "unit_states")
	_clear_dictionary_property(WorldState, "map_enemy_spawns")
	_clear_dictionary_property(WorldState, "map_npc_spawns")
	_clear_dictionary_property(WorldState, "map_tile_data")
	_clear_dictionary_property(WorldState, "dungeon_map_data")
	_clear_dictionary_property(WorldState, "field_detail_map_data")
	_clear_dictionary_property(WorldState, "field_dungeon_entrances")
	_clear_dictionary_property(WorldState, "dungeon_data")
	_clear_dictionary_property(WorldState, "dungeon_floor_data")
	_clear_dictionary_property(WorldState, "field_special_places")
	_clear_dictionary_property(WorldState, "unique_map_instances")
	_clear_dictionary_property(WorldState, "map_item_pickups")
	_clear_dictionary_property(WorldState, "map_chests")

	_clear_dictionary_property(WorldState, "quest_active_data")
	_clear_dictionary_property(WorldState, "quest_completed_data")
	_clear_dictionary_property(WorldState, "quest_failed_data")
	_clear_dictionary_property(WorldState, "unit_generated_quests")


func _reset_player_data() -> void:
	if PlayerData == null:
		return

	if PlayerData.has_method("reset_for_new_game"):
		PlayerData.reset_for_new_game()
		return

	_clear_dictionary_property(PlayerData, "map_positions")

	if "last_map_id" in PlayerData:
		PlayerData.last_map_id = ""

	if "last_tile" in PlayerData:
		PlayerData.last_tile = Vector2i.ZERO

	if "debug_start_items_applied" in PlayerData:
		PlayerData.debug_start_items_applied = false

	if "equipment_data" in PlayerData:
		var equipment_data = PlayerData.get("equipment_data")
		if typeof(equipment_data) == TYPE_DICTIONARY:
			equipment_data.clear()


func _reset_global_detail_map() -> void:
	if GlobalDetailMap == null:
		return

	if "current_detail_map_key" in GlobalDetailMap:
		GlobalDetailMap.current_detail_map_key = ""

	if "current_generator_type" in GlobalDetailMap:
		GlobalDetailMap.current_generator_type = ""

	if "from_field_tile" in GlobalDetailMap:
		GlobalDetailMap.from_field_tile = Vector2i.ZERO

	if "current_area_difficulty" in GlobalDetailMap:
		GlobalDetailMap.current_area_difficulty = 0

	if GlobalDetailMap.has_method("clear_unique_map_context"):
		GlobalDetailMap.clear_unique_map_context()

	if GlobalDetailMap.has_method("clear_pending_unique_map_return"):
		GlobalDetailMap.clear_pending_unique_map_return()


func _reset_global_dungeon() -> void:
	if GlobalDungeon == null:
		return

	if "current_dungeon_id" in GlobalDungeon:
		GlobalDungeon.current_dungeon_id = ""

	if "current_floor" in GlobalDungeon:
		GlobalDungeon.current_floor = 1

	if "return_field_map_id" in GlobalDungeon:
		GlobalDungeon.return_field_map_id = ""

	if "return_field_cell" in GlobalDungeon:
		GlobalDungeon.return_field_cell = Vector2i.ZERO

	if "pending_spawn_stair_type" in GlobalDungeon:
		GlobalDungeon.pending_spawn_stair_type = ""


func _reset_global_player_spawn() -> void:
	if GlobalPlayerSpawn == null:
		return

	if "has_next_tile" in GlobalPlayerSpawn:
		GlobalPlayerSpawn.has_next_tile = false

	if "next_tile" in GlobalPlayerSpawn:
		GlobalPlayerSpawn.next_tile = Vector2i.ZERO


func _clear_dictionary_property(target: Object, property_name: String) -> void:
	if target == null:
		return

	if not (property_name in target):
		return

	var value = target.get(property_name)
	if typeof(value) == TYPE_DICTIONARY:
		value.clear()
