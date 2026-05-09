extends CanvasLayer
class_name DeathMenu

@export_file("*.tscn") var game_scene_path: String = "res://scenes/game_and_hud.tscn"
@export_file("*.tscn") var title_scene_path: String = "res://scenes/TitleScreen.tscn"
@export_file("*.tscn") var first_map_scene_path: String = "res://scenes/npc_debug_map_special_reworked.tscn"

@onready var root_panel: Control = $RootPanel
@onready var title_label: Label = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var cause_label: Label = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/CauseLabel
@onready var status_label: Label = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var continue_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/NewGameButton
@onready var title_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/TitleButton
@onready var quit_button: Button = $RootPanel/CenterContainer/PanelContainer/VBoxContainer/QuitButton

var death_cause: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	title_button.pressed.connect(_on_title_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	title_label.text = "死亡しました"
	status_label.text = ""

	_refresh_continue_button()
	_update_cause_label()

	continue_button.grab_focus()


func set_context_paths(new_game_scene_path: String, new_title_scene_path: String, new_first_map_scene_path: String) -> void:
	if new_game_scene_path.strip_edges() != "":
		game_scene_path = new_game_scene_path

	if new_title_scene_path.strip_edges() != "":
		title_scene_path = new_title_scene_path

	if new_first_map_scene_path.strip_edges() != "":
		first_map_scene_path = new_first_map_scene_path


func set_death_cause(cause: String) -> void:
	death_cause = cause
	_update_cause_label()


func _update_cause_label() -> void:
	if cause_label == null:
		return

	if death_cause.strip_edges() == "":
		cause_label.text = "前回のセーブ地点から再開するか、はじめからやり直してください。"
	else:
		cause_label.text = "死因: " + death_cause + "\n前回のセーブ地点から再開するか、はじめからやり直してください。"


func _refresh_continue_button() -> void:
	if continue_button == null:
		return

	if SaveManager == null:
		continue_button.disabled = true
		return

	continue_button.disabled = not SaveManager.has_save_file()


func _on_continue_pressed() -> void:
	if SaveManager == null:
		status_label.text = "SaveManager がありません。"
		continue_button.disabled = true
		return

	if not SaveManager.has_save_file():
		status_label.text = "セーブデータがありません。"
		continue_button.disabled = true
		return

	if not SaveManager.request_load_game():
		status_label.text = "ロードに失敗しました。"
		return

	_change_to_game_scene()


func _on_new_game_pressed() -> void:
	if SaveManager == null:
		status_label.text = "SaveManager がありません。"
		return

	SaveManager.start_new_game(first_map_scene_path)
	_change_to_game_scene()


func _on_title_pressed() -> void:
	get_tree().paused = false

	if title_scene_path.strip_edges() == "":
		status_label.text = "タイトルシーンのパスが空です。"
		return

	var error: Error = get_tree().change_scene_to_file(title_scene_path)
	if error != OK:
		status_label.text = "タイトルへ戻れませんでした。"
		push_error("DeathMenu: タイトルへ戻れませんでした: " + title_scene_path)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _change_to_game_scene() -> void:
	get_tree().paused = false

	if game_scene_path.strip_edges() == "":
		status_label.text = "ゲームシーンのパスが空です。"
		return

	var error: Error = get_tree().change_scene_to_file(game_scene_path)
	if error != OK:
		status_label.text = "ゲームシーンを開けませんでした。"
		push_error("DeathMenu: ゲームシーンを開けませんでした: " + game_scene_path)
