extends Node

const SECONDS_PER_DAY := 24.0 * 60.0 * 60.0

var world_time_seconds: float = 0.0
var is_resolving_turn: bool = false


func advance_time(units_node: Node, player_speed: float) -> void:
	if player_speed <= 0.0:
		return

	if units_node == null:
		return

	var elapsed_seconds = SECONDS_PER_DAY / player_speed
	world_time_seconds += elapsed_seconds

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
	var remain = get_day_seconds() - float(get_hour()) * 3600.0
	return int(remain / 60.0)


func get_time_of_day() -> String:
	var hour = get_hour()

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
