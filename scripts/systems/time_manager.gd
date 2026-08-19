extends Node

const SECONDS_PER_DAY: float = 24.0 * 60.0 * 60.0

# デバッグ用のマップ/ダンジョン/詳細マップのリセット間隔。
# 1 = 1日ごとにリセット予約。
# 本番で30日ごとに戻す場合は 30 にする。
const DAYS_PER_RESET: int = 1

# NPC用のリセット間隔。
# 商人の在庫・NPC生成依頼など、NPC関連だけを別周期で更新したい時に使う。
# 例: 1 = 毎日, 7 = 7日ごと, 30 = 30日ごと
const NPC_DAYS_PER_RESET: int = 1

var world_time_seconds: float = 0.0
var is_resolving_turn: bool = false
var last_reset_debug_month_index: int = -1
var last_reset_debug_npc_index: int = -1


func advance_time(units_node: Node, player_speed: float) -> void:
	if player_speed <= 0.0:
		return

	if units_node == null:
		return

	var elapsed_seconds: float = SECONDS_PER_DAY / player_speed
	world_time_seconds += elapsed_seconds
	print_reset_debug_if_index_changed()

	if WorldState != null:
		if WorldState.has_method("update_monthly_reset_pending"):
			WorldState.update_monthly_reset_pending(get_month_index())

		if WorldState.has_method("update_npc_reset_pending"):
			WorldState.update_npc_reset_pending(get_npc_reset_index())

		# NPC/クエスト/商人在庫リセットはリアルタイムで実行する。
		# マップ/ダンジョン/詳細マップリセットは pending のまま FieldMap 側で処理するが、
		# クエストリセットだけは表示・受注状態に直結するので、時間が進んだ瞬間に適用する。
		if WorldState.has_method("run_npc_reset_if_needed"):
			WorldState.run_npc_reset_if_needed(get_npc_reset_index())

	if BountyManager != null:
		BountyManager.expire_bounties_and_remove_runtime(get_tree())

	#print_current_time()

	for unit in units_node.get_children():
		if unit == null:
			continue

		if unit.has_method("on_time_advanced"):
			unit.on_time_advanced(elapsed_seconds)

	if QuestManager != null and QuestManager.has_method("check_time_limit_failures"):
		QuestManager.check_time_limit_failures()


func resolve_ai_turns(units_node: Node) -> void:
	if units_node == null:
		is_resolving_turn = false
		return

	is_resolving_turn = true

	# まず移動中ユニットがいるなら、その完了待ち
	for unit in units_node.get_children():
		if unit == null:
			continue

		if unit.is_moving:
			return

	# 1回の呼び出しで AI を1体だけ行動させる
	for unit in units_node.get_children():
		if unit == null:
			continue

		if unit.is_player_unit:
			continue

		if unit.is_transitioning:
			continue

		if not unit.receives_time_turns:
			continue

		if unit.stats.pending_actions <= 0:
			continue

		var controller = unit.get_node_or_null("Controller")
		if controller == null:
			continue

		if controller.has_method("take_turn"):
			controller.take_turn()

			# 行動後に移動開始したなら、移動完了時に次へ
			if unit.is_moving:
				return

			# 即時移動や待機なら、次のAI解決を次フレームへ回す
			call_deferred("resolve_ai_turns", units_node)
			return

	# 誰も行動しなかったら解決終了
	is_resolving_turn = false


func notify_unit_move_finished(units_node: Node) -> void:
	if units_node == null:
		is_resolving_turn = false
		return

	call_deferred("resolve_ai_turns", units_node)


func print_enemy_hp(units_node: Node) -> void:
	if units_node == null:
		return

	for unit in units_node.get_children():
		if unit == null:
			continue
		if not unit.is_enemy:
			continue
		if not unit.has_method("get_hp_status_text"):
			continue

		print(unit.get_hp_status_text())


func update_turn_state(units_node: Node) -> void:
	if units_node == null:
		is_resolving_turn = false
		return

	for unit in units_node.get_children():
		if unit == null:
			continue

		if unit.is_moving:
			is_resolving_turn = true
			return

		if unit.receives_time_turns and unit.stats.pending_actions > 0:
			if unit.is_player_unit:
				continue
			is_resolving_turn = true
			return

	is_resolving_turn = false


func get_day() -> int:
	return int(world_time_seconds / SECONDS_PER_DAY) + 1


func get_day_seconds() -> float:
	return fmod(world_time_seconds, SECONDS_PER_DAY)


func get_hour() -> int:
	return int(get_day_seconds() / 3600.0)


func get_minute() -> int:
	var remain: float = get_day_seconds() - float(get_hour()) * 3600.0
	return int(remain / 60.0)


func get_time_of_day() -> String:
	var hour: int = get_hour()

	if hour >= 6 and hour < 12:
		return "朝"
	elif hour >= 12 and hour < 17:
		return "昼"
	elif hour >= 17 and hour < 20:
		return "夕"
	else:
		return "夜"


func get_time_string() -> String:
	return "Day %d %02d:%02d" % [get_day(), get_hour(), get_minute()]


#func print_current_time() -> void:
	#print(get_time_string(), " / ", get_time_of_day())

func get_month_index() -> int:
	# マップリセット用の期間番号。
	# get_day() は1始まりなので、DAYS_PER_RESET=1なら
	# Day 1 -> 0, Day 2 -> 1, Day 3 -> 2。
	# DAYS_PER_RESET=30なら Day 1〜30 -> 0, Day 31〜60 -> 1。
	return int((get_day() - 1) / DAYS_PER_RESET)


func get_npc_reset_index() -> int:
	# NPCリセット用の期間番号。
	# get_month_index() とは独立した周期にする。
	return int((get_day() - 1) / NPC_DAYS_PER_RESET)


func print_reset_debug_if_index_changed() -> void:
	var current_month_index: int = get_month_index()
	var current_npc_index: int = get_npc_reset_index()

	if current_month_index == last_reset_debug_month_index and current_npc_index == last_reset_debug_npc_index:
		return

	last_reset_debug_month_index = current_month_index
	last_reset_debug_npc_index = current_npc_index

	print(
		"[RESET DEBUG] Day=", get_day(),
		" 通常リセット間隔=", DAYS_PER_RESET,
		"日 index=", current_month_index,
		" NPCリセット間隔=", NPC_DAYS_PER_RESET,
		"日 npc_index=", current_npc_index
	)


func reset_time() -> void:
	world_time_seconds = 0.0
	is_resolving_turn = false
	last_reset_debug_month_index = -1
	last_reset_debug_npc_index = -1
