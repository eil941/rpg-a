extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/game_and_hud.tscn"
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

	if SaveManager != null:
		continue_button.disabled = not SaveManager.has_save_file()
	else:
		continue_button.disabled = true
		info_label.text = "SaveManager がありません。"


func _on_new_game_pressed() -> void:
	if SaveManager == null:
		push_error("TitleScreen: SaveManager がありません")
		return

	SaveManager.start_new_game(first_map_scene_path)
	_start_game_scene()


func _on_continue_pressed() -> void:
	if SaveManager == null:
		push_error("TitleScreen: SaveManager がありません")
		return

	if not SaveManager.request_load_game():
		info_label.text = "セーブデータがありません。"
		continue_button.disabled = true
		return

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
