extends Node

var board_ui = null
var current_board: QuestBoard = null
var current_player_unit = null
var is_open: bool = false


func register_ui(ui) -> void:
	print("[QBM] register_ui ui=", ui)
	board_ui = ui


func open_board(board: QuestBoard, player_unit) -> void:
	print("[QBM] open_board called board=", board, " player=", player_unit)
	print("[QBM] board_ui=", board_ui)

	if board == null:
		return

	if board_ui == null:
		push_error("QuestBoardUI is not registered.")
		return

	current_board = board
	current_player_unit = player_unit
	is_open = true

	print("[QBM] calling board_ui.open_with_board()")
	board_ui.open_with_board(board, player_unit)


func close_board() -> void:
	print("[QBM] close_board")

	is_open = false
	current_board = null
	current_player_unit = null

	if board_ui != null and board_ui.has_method("close_ui"):
		board_ui.close_ui()


func is_board_open() -> bool:
	return is_open
