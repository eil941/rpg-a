extends Node2D
class_name QuestBoard

@export var board_id: String = "board_1"
@export var board_display_name: String = "依頼板"
@export var linked_unit_ids: Array[String] = []
@export var tile_coords: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if not is_in_group("quest_boards"):
		add_to_group("quest_boards")

func can_open_board() -> bool:
	return true

func open_board(player_unit) -> void:
	print("[QUEST BOARD] open_board called: ", name, " tile=", tile_coords)

	if QuestBoardManager == null:
		push_error("QuestBoardManager is null")
		return

	if QuestBoardManager.has_method("open_board"):
		QuestBoardManager.open_board(self, player_unit)
