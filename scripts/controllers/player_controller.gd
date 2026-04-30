extends Node

var unit = null
var units_node = null

@export var first_move_hold_time: float = 0.08
@export var repeat_move_interval: float = 0.00

var held_dir: Vector2 = Vector2.ZERO
var held_time: float = 0.0
var repeat_time: float = 0.0
var is_holding_move: bool = false
var first_move_done: bool = false

@export var mouse_auto_move_max_search_tiles: int = 12000
@export var mouse_auto_move_search_margin: int = 4

var mouse_auto_path: Array[Vector2i] = []
var mouse_auto_target_tile: Vector2i = Vector2i.ZERO
var mouse_auto_target_kind: StringName = &"none"
var mouse_auto_target_unit = null
var mouse_auto_target_object = null
var mouse_has_pending_click: bool = false
var mouse_pending_click_tile: Vector2i = Vector2i.ZERO

@export var show_mouse_route_preview: bool = true
@export var show_mouse_hover_highlight: bool = false
# マウス操作時の足元/ホバー枠カーソル。
# キーボード攻撃選択時だけ攻撃範囲カーソルを出したい場合は false のままにする。
@export var enable_mouse_hover_cursor: bool = false
@export var mouse_route_preview_color: Color = Color(0.2, 0.8, 1.0, 0.75)
@export var mouse_hover_move_color: Color = Color(0.2, 0.8, 1.0, 0.45)
@export var mouse_hover_enemy_color: Color = Color(1.0, 0.25, 0.2, 0.55)
@export var mouse_hover_interact_color: Color = Color(1.0, 0.85, 0.2, 0.55)
@export var mouse_hover_blocked_color: Color = Color(0.6, 0.6, 0.6, 0.35)

var mouse_visual_root: Node2D = null
var mouse_route_line: Line2D = null
var mouse_hover_line: Line2D = null
var mouse_context_menu: PopupMenu = null
var mouse_context_target_kind: StringName = &"none"
var mouse_context_target_tile: Vector2i = Vector2i.ZERO
var mouse_context_target_unit = null
var mouse_context_target_object = null

@export var show_keyboard_target_highlight: bool = true

# 攻撃モードでは、射程内に敵がいなくても攻撃範囲だけ表示する。
# カーソル/候補枠は「現在の武器で攻撃可能な範囲内にいる敵」だけに出す。
@export var keyboard_attack_mode_can_start_without_target: bool = true

# 攻撃範囲可視化モードをON/OFFするInput Map名。
# Project Settings > Input Map に attack_mode を追加して、好きなキーを割り当てる。
@export var keyboard_attack_mode_action: StringName = &"attack_mode"

# フィールドマップでは攻撃範囲表示モードを使わない。
# 詳細マップ/ダンジョンなど、実際に戦闘するマップだけで表示する。
@export var allow_keyboard_attack_mode_on_field_map: bool = false
@export var field_map_scene_path: String = "res://scenes/field_map.tscn"

# attack_mode がまだInput Mapに無い場合だけ、旧互換として attack キーでも可視化モードに入れる。
# attack_mode を登録した後は false 扱いになり、attack は攻撃確定専用になる。
@export var keyboard_attack_key_starts_mode_if_mode_action_missing: bool = false

# 可視化中の候補/範囲更新間隔。毎フレーム全範囲を描き直すと重いので、
# 移動・射程変更・一定間隔のときだけ更新する。
@export var keyboard_attack_mode_refresh_interval: float = 0.12

# 攻撃モード中に敵候補を探す最大範囲。
# 0以下なら同じUnitsノード内の敵対Unitを全て走査する。
# 実際にカーソルを出す対象は、さらに武器の attack_min_range / attack_max_range 内に限定する。
@export var keyboard_target_selection_radius: int = 12

# キーボード攻撃ターゲット選択中に、武器の攻撃可能範囲を表示する。
@export var show_keyboard_attack_range_highlight: bool = true
@export var keyboard_attack_range_fill_color: Color = Color(0.2, 0.7, 1.0, 0.34)
@export var keyboard_attack_range_border_color: Color = Color(0.1, 0.8, 1.0, 1.0)
@export var keyboard_attack_range_border_width: float = 2.0

# 攻撃候補になっている敵Unitのいるマスを強調する。
# 選択中ではない候補は控えめな枠だけにして、カーソルが見やすいようにする。
@export var keyboard_target_candidate_show_fill: bool = false
@export var keyboard_target_candidate_fill_color: Color = Color(1.0, 0.85, 0.1, 0.10)
@export var keyboard_target_candidate_color: Color = Color(1.0, 0.95, 0.15, 1.0)
@export var keyboard_target_candidate_width: float = 4.0

# 現在選択中の敵Unitのいるマス。
# Inventoryの選択カーソルのように、黄色い四角い枠で表示する。
@export var keyboard_target_selected_fill_color: Color = Color(1.0, 0.95, 0.05, 0.10)
@export var keyboard_target_cursor_color: Color = Color(1.0, 0.95, 0.05, 1.0)
@export var keyboard_target_cursor_width: float = 5.0
@export var keyboard_target_cursor_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.85)
@export var keyboard_target_cursor_shadow_width: float = 8.0
@export var keyboard_target_cursor_inset: float = 2.0

var keyboard_target_mode: bool = false
var keyboard_target_candidates: Array = []
var keyboard_target_index: int = -1
var keyboard_target_visual_root: Node2D = null
var keyboard_target_visual_dirty: bool = false
var keyboard_target_refresh_timer: float = 999.0
var keyboard_target_last_player_tile: Vector2i = Vector2i(999999, 999999)
var keyboard_target_last_min_range: int = -1
var keyboard_target_last_max_range: int = -1


func setup(owner_unit) -> void:
	unit = owner_unit
	units_node = unit.units_node
	ensure_mouse_visual_nodes()
	ensure_keyboard_target_visual_nodes()
	ensure_mouse_context_menu()


func _process(delta: float) -> void:
	update_mouse_visual_feedback()

	if keyboard_target_mode:
		keyboard_target_refresh_timer += delta
		refresh_keyboard_attack_mode_if_needed(false)

		if keyboard_target_visual_dirty:
			update_keyboard_target_visual_feedback()
			keyboard_target_visual_dirty = false


func _unhandled_input(event: InputEvent) -> void:
	# 自動移動中にキーボード/右クリックなど別操作をしたら、移動予約をキャンセルする。
	# 左クリックだけは「別の目的地へ再指定」として扱うので、ここではキャンセルしない。
	if should_cancel_mouse_auto_move_by_input(event):
		clear_mouse_auto_navigation()

	if handle_mouse_map_input(event):
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if unit == null:
		return

	if units_node == null:
		units_node = unit.units_node

	if units_node == null:
		return

	if keyboard_target_mode:
		# フィールドマップに移動した場合は表示を消す。
		if not is_keyboard_attack_mode_allowed_on_current_map():
			cancel_keyboard_target_mode(false)
			return

		# 可視化モードは、移動・ターン解決では消さない。
		# UIを開く/マップ遷移/キャンセルキー/可視化キー再押しなど、意図的な操作でだけ消す。
		if is_ui_locked() or unit.is_transitioning:
			cancel_keyboard_target_mode(false)
			return

		# 攻撃モードは「範囲表示 + ターゲット指定」の状態として維持する。
		# 矢印キー/攻撃/キャンセルなど、攻撃モード専用入力だけ消費し、
		# それ以外の入力、特にWASD移動は通常処理に流す。
		if handle_keyboard_target_mode_input():
			return

	if Input.is_action_just_pressed("status"):
		clear_move_hold()
		clear_mouse_auto_navigation()
		if is_dialog_open():
			return
		toggle_status_ui()
		return

	if is_status_open():
		clear_move_hold()
		return

	if Input.is_action_just_pressed("inventory"):
		clear_mouse_auto_navigation()
		if is_dialog_open():
			return
		toggle_inventory_ui()
		return

	if is_ui_locked():
		clear_move_hold()
		clear_mouse_auto_navigation()
		return

	if TimeManager.is_resolving_turn:
		return

	if unit.is_transitioning:
		clear_move_hold()
		clear_mouse_auto_navigation()
		return

	if not unit.is_moving and unit.repeat_timer <= 0.0:
		if Input.is_action_just_pressed("pickup_test"):
			if unit.inventory != null:
				unit.inventory.add_item("potion", 1)
				unit.notify_hud_log("potionを手に入れた")

		if Input.is_action_just_pressed("interact"):
			clear_move_hold()
			clear_mouse_auto_navigation()
			if _is_player_action_blocked():
				return
			unit.try_interact_action()
			return

		if _is_keyboard_attack_mode_action_just_pressed():
			clear_move_hold()
			clear_mouse_auto_navigation()
			if _is_player_action_blocked():
				return
			toggle_keyboard_attack_target_mode()
			return

		if Input.is_action_just_pressed("attack"):
			clear_move_hold()
			clear_mouse_auto_navigation()
			if _is_player_action_blocked():
				return

			# attack_mode をまだInput Mapに登録していないプロジェクトでは旧互換としてattackで開始する。
			# attack_mode を登録した後は、attackは攻撃確定用に分離する。
			if keyboard_attack_key_starts_mode_if_mode_action_missing and not _has_input_action(keyboard_attack_mode_action):
				start_keyboard_attack_target_mode()
			else:
				if unit != null and unit.has_method("notify_hud_log"):
					unit.notify_hud_log("Qなどの attack_mode キーで攻撃範囲表示モードに入ってから、Enterで攻撃してください")
			return

		if Input.is_action_just_pressed("wait"):
			clear_move_hold()
			clear_mouse_auto_navigation()
			if _is_player_action_blocked():
				return
			unit.wait_action()
			_advance_player_turn_after_action()
			return

	if has_mouse_auto_path_or_target():
		if _is_player_action_blocked():
			clear_mouse_auto_navigation()
			return

		if process_mouse_pending_click_if_ready():
			return

		if process_mouse_auto_path_step():
			return

	handle_move_input(delta)


func is_ui_locked() -> bool:
	if is_dialog_open():
		return true

	if is_trade_ui_open():
		return true

	if is_status_open():
		return true

	return false


func handle_move_input(delta: float) -> void:
	var input_dir: Vector2 = get_input_direction()

	if input_dir != Vector2.ZERO:
		clear_mouse_auto_navigation()

	if input_dir == Vector2.ZERO:
		clear_move_hold()
		return

	if _is_sleeping():
		clear_move_hold()
		if _is_direction_attempt_just_pressed():
			_consume_blocked_action("眠っていて動けない")
		return

	if _is_paralyzed():
		clear_move_hold()
		if _is_direction_attempt_just_pressed():
			_consume_blocked_action("麻痺していて動けない")
		return

	if not is_holding_move:
		start_hold(input_dir)
		return

	if input_dir != held_dir:
		start_hold_and_move_immediately(input_dir)
		return

	if unit.is_moving or unit.repeat_timer > 0.0:
		return

	if not first_move_done:
		held_time += delta
		if held_time >= first_move_hold_time:
			first_move_done = true
			repeat_time = 0.0
			try_move_in_direction(held_dir)
		return

	repeat_time += delta
	if repeat_time >= repeat_move_interval:
		repeat_time = 0.0
		try_move_in_direction(held_dir)


func start_hold(dir: Vector2) -> void:
	held_dir = dir
	held_time = 0.0
	repeat_time = 0.0
	is_holding_move = true
	first_move_done = false
	face_direction_only(dir)


func start_hold_and_move_immediately(dir: Vector2) -> void:
	held_dir = dir
	held_time = first_move_hold_time
	repeat_time = 0.0
	is_holding_move = true
	first_move_done = true
	face_direction_only(dir)
	try_move_in_direction(dir)


func clear_move_hold() -> void:
	held_dir = Vector2.ZERO
	held_time = 0.0
	repeat_time = 0.0
	is_holding_move = false
	first_move_done = false


func _is_sleeping() -> bool:
	return _has_status_effect(&"sleep")


func _is_paralyzed() -> bool:
	return _has_status_effect(&"paralysis")


func _has_status_effect(status_id: StringName) -> bool:
	if unit == null:
		return false

	if not unit.has_method("has_status_effect"):
		return false

	return unit.has_status_effect(status_id)


func _is_direction_attempt_just_pressed() -> bool:
	if Input.is_action_just_pressed("ui_right"):
		return true

	if Input.is_action_just_pressed("ui_left"):
		return true

	if Input.is_action_just_pressed("ui_down"):
		return true

	if Input.is_action_just_pressed("ui_up"):
		return true

	return false


func _consume_blocked_action(message: String) -> void:
	clear_move_hold()

	if unit == null:
		return

	if unit.has_method("consume_blocked_action_turn"):
		unit.consume_blocked_action_turn(message)
	elif unit.has_method("notify_hud_log"):
		unit.notify_hud_log(message)


func face_direction_only(dir: Vector2) -> void:
	if unit == null:
		return

	if unit.has_method("update_facing_only"):
		unit.update_facing_only(dir)
		return

	if dir == Vector2.RIGHT:
		unit.facing = unit.Facing.RIGHT
	elif dir == Vector2.LEFT:
		unit.facing = unit.Facing.LEFT
	elif dir == Vector2.DOWN:
		unit.facing = unit.Facing.DOWN
	elif dir == Vector2.UP:
		unit.facing = unit.Facing.UP

	if unit.has_method("set_idle_animation"):
		unit.set_idle_animation()


func try_move_in_direction(dir: Vector2) -> bool:
	if _is_player_action_blocked():
		return false

	var actual_dir: Vector2 = _get_effective_move_direction(dir)
	var acted: bool = unit.try_move(actual_dir)

	if acted:
		apply_move_growth()
		_advance_player_turn_after_action()
		return true

	return false


func _advance_player_turn_after_action() -> void:
	if DebugSettings.debug_free_action:
		return

	TimeManager.advance_time(units_node, unit.get_total_speed())
	notify_hud()
	TimeManager.resolve_ai_turns(units_node)


func _is_player_action_blocked() -> bool:
	if unit == null:
		return false

	if _has_status_effect(&"sleep"):
		_consume_blocked_action("眠っていて行動できない")
		return true

	if _has_status_effect(&"paralysis"):
		_consume_blocked_action("麻痺していて行動できない")
		return true

	if unit.has_method("is_action_blocked_by_status"):
		if unit.is_action_blocked_by_status():
			if unit.has_method("notify_hud_log"):
				unit.notify_hud_log("今は行動できない")
			return true

	return false


func _get_effective_move_direction(dir: Vector2) -> Vector2:
	if unit == null:
		return dir

	if not unit.has_method("has_status_effect"):
		return dir

	if not unit.has_status_effect(&"confusion"):
		return dir

	var random_dirs: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.DOWN,
		Vector2.UP
	]

	return random_dirs[randi_range(0, random_dirs.size() - 1)]


func apply_move_growth() -> void:
	if unit == null:
		return

	if unit.stats != null:
		unit.stats.gain_base_stat_growth("agility", 1)
		unit.stats.gain_base_stat_growth("vitality", 1)

	if unit.skills != null:
		unit.skills.learn_skill("gathering")
		unit.skills.gain_skill_growth("gathering", 1)


func try_attack_action() -> bool:
	if unit == null:
		return false

	var target = CombatManager.get_best_attack_target(unit)
	if target == null:
		if unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃できる対象がいない")
		return false

	var acted: bool = CombatManager.perform_attack(unit, target)
	return acted


# =========================
# Keyboard Target Selection
# =========================
# 攻撃キーでターゲット選択モードに入り、候補をハイライトする。
# 攻撃/決定で攻撃、待機/キャンセルで中止、方向キーでターゲット変更。

func _has_input_action(action_name: StringName) -> bool:
	return InputMap.has_action(String(action_name))


func _is_input_action_just_pressed_safe(action_name: StringName) -> bool:
	if not _has_input_action(action_name):
		return false
	return Input.is_action_just_pressed(String(action_name))


func _is_keyboard_attack_mode_action_just_pressed() -> bool:
	return _is_input_action_just_pressed_safe(keyboard_attack_mode_action)


func mark_keyboard_target_visual_dirty() -> void:
	keyboard_target_visual_dirty = true


func is_keyboard_attack_mode_allowed_on_current_map() -> bool:
	# フィールドマップでは攻撃範囲表示モードを無効化する。
	# map_id は詳細マップでも field_13_10 のような名前になるため、map_id では判定しない。
	if allow_keyboard_attack_mode_on_field_map:
		return true

	var root: Node = get_map_root()
	if root == null:
		# 判定できない場合は、詳細マップなどで誤って無効化しないよう許可する。
		return true

	if field_map_scene_path != "" and String(root.scene_file_path) == field_map_scene_path:
		return false

	var script: Script = root.get_script() as Script
	if script != null:
		var script_path: String = String(script.resource_path)
		if script_path.ends_with("/FiledMap.gd"):
			return false
		if script_path.ends_with("/FieldMap.gd"):
			return false
		if script_path.ends_with("/field_map.gd"):
			return false

	var root_name: String = String(root.name).strip_edges().to_lower()
	if root_name == "fieldmap" or root_name == "field_map":
		return false

	return true


func notify_attack_mode_disabled_on_field_map() -> void:
	if unit == null:
		return

	if unit.has_method("notify_hud_log"):
		unit.notify_hud_log("フィールドマップでは攻撃範囲表示を使えません")


func toggle_keyboard_attack_target_mode() -> void:
	if keyboard_target_mode:
		cancel_keyboard_target_mode(true)
		return

	start_keyboard_attack_target_mode()


func start_keyboard_attack_target_mode() -> void:
	if unit == null:
		return

	if not is_keyboard_attack_mode_allowed_on_current_map():
		cancel_keyboard_target_mode(false)
		notify_attack_mode_disabled_on_field_map()
		return

	keyboard_target_mode = true
	keyboard_target_index = -1
	keyboard_target_candidates.clear()
	keyboard_target_last_player_tile = Vector2i(999999, 999999)
	keyboard_target_last_min_range = -1
	keyboard_target_last_max_range = -1
	keyboard_target_refresh_timer = 999.0

	refresh_keyboard_attack_mode_if_needed(true)

	if keyboard_target_candidates.is_empty():
		keyboard_target_index = -1
		mark_keyboard_target_visual_dirty()

		if unit.has_method("notify_hud_log"):
			if keyboard_attack_mode_can_start_without_target:
				unit.notify_hud_log("攻撃範囲表示中。範囲内に敵が入るとカーソル表示。移動可能、攻撃範囲キー/待機で終了")
			else:
				unit.notify_hud_log("攻撃できる対象がいない")
				cancel_keyboard_target_mode(false)
		return

	keyboard_target_index = 0
	select_keyboard_target_index(keyboard_target_index, true)
	mark_keyboard_target_visual_dirty()
	if unit.has_method("notify_hud_log"):
		unit.notify_hud_log("攻撃範囲表示中。矢印キーで対象変更、Enterで攻撃、WASDで移動、Q/待機/Escで終了")


func handle_keyboard_target_mode_input() -> bool:
	if not keyboard_target_mode:
		return false

	if _is_keyboard_attack_mode_action_just_pressed():
		cancel_keyboard_target_mode(true)
		return true

	if Input.is_action_just_pressed("wait") or Input.is_action_just_pressed("inventory") or Input.is_action_just_pressed("status") or Input.is_action_just_pressed("ui_cancel"):
		cancel_keyboard_target_mode(true)
		return true

	if Input.is_action_just_pressed("ui_right"):
		select_keyboard_target_by_direction(Vector2i.RIGHT)
		return true

	if Input.is_action_just_pressed("ui_left"):
		select_keyboard_target_by_direction(Vector2i.LEFT)
		return true

	if Input.is_action_just_pressed("ui_down"):
		select_keyboard_target_by_direction(Vector2i.DOWN)
		return true

	if Input.is_action_just_pressed("ui_up"):
		select_keyboard_target_by_direction(Vector2i.UP)
		return true

	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		confirm_keyboard_target_attack()
		return true

	# 攻撃モード中でも、専用入力でなければ通常の移動処理へ流す。
	return false



func get_keyboard_attack_candidates() -> Array:
	var result: Array = []

	if unit == null:
		return result

	if units_node == null:
		return result

	var player_tile: Vector2i = get_player_tile_coords()
	var select_radius: int = int(keyboard_target_selection_radius)

	for candidate in units_node.get_children():
		if not is_keyboard_target_candidate_valid(candidate):
			continue

		var candidate_tile: Vector2i = get_unit_tile_coords_for_mouse(candidate)

		# 探索範囲の上限。0以下なら探索上限なし。
		if select_radius > 0:
			var search_distance: int = get_mouse_tile_distance(player_tile, candidate_tile)
			if search_distance > select_radius:
				continue

		# カーソルと候補枠は、現在の武器で「今この位置から攻撃可能」な敵だけに出す。
		if not is_keyboard_target_in_current_attack_range(candidate):
			continue

		result.append(candidate)

	result.sort_custom(Callable(self, "_sort_keyboard_attack_candidates"))
	return result


func is_keyboard_target_in_current_attack_range(candidate) -> bool:
	if candidate == null:
		return false

	if not is_instance_valid(candidate):
		return false

	var player_tile: Vector2i = get_player_tile_coords()
	var candidate_tile: Vector2i = get_unit_tile_coords_for_mouse(candidate)

	if not is_target_tile_in_attack_range_from_tile(player_tile, candidate_tile):
		return false

	# CombatManager 側の最終攻撃条件にも合わせる。
	# これにより、死亡済み・敵対でない・状態異常で行動不能なども候補から外れる。
	if CombatManager != null and CombatManager.has_method("can_attack"):
		return CombatManager.can_attack(unit, candidate, true)

	return true


func _sort_keyboard_attack_candidates(a, b) -> bool:
	var player_tile: Vector2i = get_player_tile_coords()
	var a_tile: Vector2i = get_unit_tile_coords_for_mouse(a)
	var b_tile: Vector2i = get_unit_tile_coords_for_mouse(b)
	var a_dist: int = get_mouse_tile_distance(player_tile, a_tile)
	var b_dist: int = get_mouse_tile_distance(player_tile, b_tile)

	if a_dist != b_dist:
		return a_dist < b_dist

	if a_tile.y != b_tile.y:
		return a_tile.y < b_tile.y

	return a_tile.x < b_tile.x


func is_keyboard_target_candidate_valid(candidate) -> bool:
	if candidate == null:
		return false

	if not is_instance_valid(candidate):
		return false

	if candidate.is_queued_for_deletion():
		return false

	if candidate == unit:
		return false

	if not candidate.has_node("Stats"):
		return false

	if candidate.stats.hp <= 0:
		return false

	if not Targeting.is_hostile(unit, candidate):
		return false

	# ここでは敵対・生存などの基本条件だけを見る。
	# 射程内かどうかは get_keyboard_attack_candidates() 側で見る。
	return true



func refresh_keyboard_attack_mode_if_needed(force: bool) -> void:
	if not keyboard_target_mode:
		return

	var player_tile: Vector2i = get_player_tile_coords()
	var min_range: int = get_mouse_attack_min_range()
	var max_range: int = get_mouse_attack_max_range()
	var tile_changed: bool = player_tile != keyboard_target_last_player_tile
	var range_changed: bool = min_range != keyboard_target_last_min_range or max_range != keyboard_target_last_max_range
	var interval_elapsed: bool = keyboard_target_refresh_timer >= max(0.03, keyboard_attack_mode_refresh_interval)

	if not force and not tile_changed and not range_changed and not interval_elapsed:
		return

	keyboard_target_refresh_timer = 0.0
	keyboard_target_last_player_tile = player_tile
	keyboard_target_last_min_range = min_range
	keyboard_target_last_max_range = max_range
	refresh_keyboard_attack_candidates_preserving_target()
	mark_keyboard_target_visual_dirty()


func refresh_keyboard_attack_candidates_preserving_target() -> void:
	var selected_target = get_selected_keyboard_target()
	var new_candidates: Array = get_keyboard_attack_candidates()

	keyboard_target_candidates = new_candidates

	if keyboard_target_candidates.is_empty():
		keyboard_target_index = -1
		return

	keyboard_target_index = 0

	if selected_target != null and is_instance_valid(selected_target):
		for i in range(keyboard_target_candidates.size()):
			if keyboard_target_candidates[i] == selected_target:
				keyboard_target_index = i
				break

	select_keyboard_target_index(keyboard_target_index, false)



func get_selected_keyboard_target():
	if not keyboard_target_mode:
		return null

	if keyboard_target_index < 0 or keyboard_target_index >= keyboard_target_candidates.size():
		return null

	var target = keyboard_target_candidates[keyboard_target_index]
	if target == null:
		return null

	if not is_instance_valid(target):
		return null

	if target.is_queued_for_deletion():
		return null

	return target


func select_keyboard_target_index(index: int, announce: bool) -> void:
	if keyboard_target_candidates.is_empty():
		keyboard_target_index = -1
		return

	keyboard_target_index = clampi(index, 0, keyboard_target_candidates.size() - 1)
	var target = get_selected_keyboard_target()
	if target == null:
		return

	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(target)
	face_toward_tile_if_possible(target_tile)

	if announce and unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log("対象: %s" % String(target.name))

	mark_keyboard_target_visual_dirty()


func select_keyboard_target_by_direction(direction: Vector2i) -> void:
	if keyboard_target_candidates.is_empty():
		return

	var current_target = get_selected_keyboard_target()
	var current_tile: Vector2i = get_player_tile_coords()
	if current_target != null:
		current_tile = get_unit_tile_coords_for_mouse(current_target)

	var best_index: int = -1
	var best_score: int = 999999999

	for i in range(keyboard_target_candidates.size()):
		if i == keyboard_target_index:
			continue

		var candidate = keyboard_target_candidates[i]
		if candidate == null or not is_instance_valid(candidate):
			continue

		var candidate_tile: Vector2i = get_unit_tile_coords_for_mouse(candidate)
		var diff: Vector2i = candidate_tile - current_tile
		var primary: int = 0
		var secondary: int = 0

		if direction == Vector2i.RIGHT:
			if diff.x <= 0:
				continue
			primary = diff.x
			secondary = abs(diff.y)
		elif direction == Vector2i.LEFT:
			if diff.x >= 0:
				continue
			primary = -diff.x
			secondary = abs(diff.y)
		elif direction == Vector2i.DOWN:
			if diff.y <= 0:
				continue
			primary = diff.y
			secondary = abs(diff.x)
		elif direction == Vector2i.UP:
			if diff.y >= 0:
				continue
			primary = -diff.y
			secondary = abs(diff.x)

		var score: int = primary * 1000 + secondary
		if score < best_score:
			best_score = score
			best_index = i

	if best_index < 0:
		if direction == Vector2i.RIGHT or direction == Vector2i.DOWN:
			best_index = (keyboard_target_index + 1) % keyboard_target_candidates.size()
		else:
			best_index = (keyboard_target_index - 1 + keyboard_target_candidates.size()) % keyboard_target_candidates.size()

	select_keyboard_target_index(best_index, true)


func confirm_keyboard_target_attack() -> void:
	if unit != null:
		if unit.is_moving or unit.repeat_timer > 0.0 or TimeManager.is_resolving_turn:
			if unit.has_method("notify_hud_log"):
				unit.notify_hud_log("移動/ターン処理が終わってから攻撃してください")
			return

	refresh_keyboard_attack_mode_if_needed(true)
	var target = get_selected_keyboard_target()
	if target == null:
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃範囲内に敵がいません")
		mark_keyboard_target_visual_dirty()
		return

	if not CombatManager.can_attack(unit, target, true):
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("その対象は攻撃できません")
		refresh_keyboard_attack_candidates_preserving_target()
		mark_keyboard_target_visual_dirty()
		return

	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(target)
	face_toward_tile_if_possible(target_tile)

	var acted: bool = CombatManager.perform_attack(unit, target, true)

	# 攻撃しても攻撃範囲表示モードは解除しない。
	# 倒した敵・移動した敵・射程外になった敵を候補から外し、
	# 範囲内に別の敵がいれば次の対象へカーソルを移す。
	if acted:
		_advance_player_turn_after_action()
		refresh_keyboard_attack_mode_after_action()
	elif unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log("攻撃に失敗した")
		refresh_keyboard_attack_mode_after_action()


func refresh_keyboard_attack_mode_after_action() -> void:
	if not keyboard_target_mode:
		return

	if not is_keyboard_attack_mode_allowed_on_current_map():
		cancel_keyboard_target_mode(false)
		return

	keyboard_target_refresh_timer = 999.0
	refresh_keyboard_attack_mode_if_needed(true)
	mark_keyboard_target_visual_dirty()

	if keyboard_target_candidates.is_empty():
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃範囲内に敵がいません。攻撃範囲表示は継続中")
		return

	select_keyboard_target_index(keyboard_target_index, false)


func cancel_keyboard_target_mode(show_message: bool) -> void:
	keyboard_target_mode = false
	keyboard_target_candidates.clear()
	keyboard_target_index = -1
	keyboard_target_visual_dirty = false
	keyboard_target_refresh_timer = 999.0
	keyboard_target_last_player_tile = Vector2i(999999, 999999)
	keyboard_target_last_min_range = -1
	keyboard_target_last_max_range = -1
	clear_keyboard_target_visuals()

	if show_message and unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log("攻撃範囲表示を終了した")


# =========================
# Mouse Map Input
# =========================
# Input Mapへの登録は不要。
# UIが処理しなかった左クリックだけ _unhandled_input() で受け取る。
# 隣接クリック:
# - 空きタイル: 移動
# - 敵Unit: 攻撃
# - 非敵対Unit: 既存interact
# - チェスト: open_chest()
# - クエストボード: open_board()
#
# 遠距離クリック:
# - 空きタイル: ルートを作って1歩ずつ自動移動
# - Unit/チェスト/クエストボード: 隣接マスまで自動移動してからインタラクト

func handle_mouse_map_input(event: InputEvent) -> bool:
	if unit == null:
		return false

	if units_node == null:
		units_node = unit.units_node

	if units_node == null:
		return false

	if not event is InputEventMouseButton:
		return false

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton

	if not mouse_event.pressed:
		return false

	if mouse_event.button_index != MOUSE_BUTTON_LEFT and mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return false

	if is_ui_locked():
		return false

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		clear_move_hold()
		show_mouse_context_menu_for_current_tile()
		return true

	if unit.is_transitioning:
		return false

	clear_move_hold()

	# 移動アニメーション中/リピート待ち中の左クリックは、
	# TimeManager.is_resolving_turn 中でも必ず受け取る。
	# ここで古い自動移動予約を破棄し、最後にクリックしたタイルを次の目的地として上書きする。
	if unit.is_moving or unit.repeat_timer > 0.0:
		queue_mouse_click_after_current_step(get_mouse_tile_coords())
		return true

	if TimeManager.is_resolving_turn:
		return false

	if _is_player_action_blocked():
		clear_mouse_auto_navigation()
		return true

	return handle_left_click_on_map()


func handle_left_click_on_map() -> bool:
	return handle_left_click_on_tile(get_mouse_tile_coords())


func handle_left_click_on_tile(clicked_tile: Vector2i) -> bool:
	var player_tile: Vector2i = get_player_tile_coords()
	var diff: Vector2i = clicked_tile - player_tile
	var distance: int = abs(diff.x) + abs(diff.y)

	if distance == 0:
		clear_mouse_auto_navigation()
		if _is_player_action_blocked():
			return true
		if unit.has_method("wait_action"):
			unit.wait_action()
			_advance_player_turn_after_action()
			return true
		return false

	# 新しいクリックは、既存の自動移動予約を必ず上書きする。
	clear_mouse_auto_navigation()

	var clicked_unit = Targeting.get_unit_on_tile(units_node, clicked_tile, unit)
	var chest = get_chest_on_tile(clicked_tile)
	var quest_board = get_quest_board_on_tile(clicked_tile)

	# Unitそのものをクリックした場合は、移動先ではなく対象への操作として扱う。
	# 敵対Unitなら、射程内ならその場で攻撃、射程外なら攻撃可能位置まで自動移動する。
	# 非敵対Unitなら、隣接していなければUnit本体を追いかけて、隣接後に1回だけインタラクトする。
	if clicked_unit != null:
		return handle_mouse_clicked_unit(clicked_unit)

	if chest != null:
		if distance == 1:
			face_direction_only(Vector2(float(diff.x), float(diff.y)))
			return handle_mouse_clicked_chest(chest)
		return start_mouse_auto_path_to_interact_target(chest, &"chest")

	if quest_board != null:
		if distance == 1:
			face_direction_only(Vector2(float(diff.x), float(diff.y)))
			return handle_mouse_clicked_quest_board(quest_board)
		return start_mouse_auto_path_to_interact_target(quest_board, &"quest_board")

	if distance == 1:
		var dir: Vector2 = Vector2(float(diff.x), float(diff.y))
		face_direction_only(dir)
		try_move_in_direction(dir)
		return true

	return start_mouse_auto_path_to_empty_tile(clicked_tile)

func handle_mouse_clicked_unit(clicked_unit) -> bool:
	if clicked_unit == null:
		return false

	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(clicked_unit)
	var player_tile: Vector2i = get_player_tile_coords()
	var diff: Vector2i = target_tile - player_tile
	var distance: int = abs(diff.x) + abs(diff.y)

	if Targeting.is_hostile(unit, clicked_unit):
		# 敵そのものをクリックした場合:
		# 射程内ならその場で攻撃。射程外なら攻撃可能位置まで自動移動する。
		if not is_attack_target_in_current_range(clicked_unit):
			return start_mouse_auto_path_to_attack_target(clicked_unit)

		face_toward_tile_if_possible(target_tile)
		var acted: bool = CombatManager.perform_attack(unit, clicked_unit)
		if acted:
			_advance_player_turn_after_action()
		return true

	# 非敵対Unitは、隣接していれば既存interact、遠ければUnit本体を追いかける。
	if distance != 1:
		return start_mouse_auto_path_to_interact_target(clicked_unit, &"unit")

	face_direction_only(Vector2(float(diff.x), float(diff.y)))

	if unit.has_method("try_interact_action"):
		unit.try_interact_action()
		return true

	return false

func handle_mouse_clicked_chest(chest) -> bool:
	if chest == null:
		return false

	if chest.has_method("open_chest"):
		chest.open_chest(unit)
		return true

	if unit.has_method("try_interact_action"):
		unit.try_interact_action()
		return true

	return false


func handle_mouse_clicked_quest_board(quest_board) -> bool:
	if quest_board == null:
		return false

	if quest_board.has_method("open_board"):
		quest_board.open_board(unit)
		return true

	if unit.has_method("try_interact_action"):
		unit.try_interact_action()
		return true

	return false


func has_mouse_auto_path_or_target() -> bool:
	if mouse_has_pending_click:
		return true

	if not mouse_auto_path.is_empty():
		return true

	return mouse_auto_target_kind != &"none"


func clear_mouse_auto_path() -> void:
	mouse_auto_path.clear()
	mouse_auto_target_tile = Vector2i.ZERO
	mouse_auto_target_kind = &"none"
	mouse_auto_target_unit = null
	mouse_auto_target_object = null

func clear_mouse_pending_click() -> void:
	mouse_has_pending_click = false
	mouse_pending_click_tile = Vector2i.ZERO


func clear_mouse_auto_navigation() -> void:
	clear_mouse_auto_path()
	clear_mouse_pending_click()


func queue_mouse_click_after_current_step(clicked_tile: Vector2i) -> void:
	# 今の1歩はキャンセルできないので、終わった瞬間にこのクリック先へ再ルートする。
	clear_mouse_auto_path()
	mouse_pending_click_tile = clicked_tile
	mouse_has_pending_click = true


func process_mouse_pending_click_if_ready() -> bool:
	if not mouse_has_pending_click:
		return false

	if unit == null:
		clear_mouse_auto_navigation()
		return false

	if unit.is_moving or unit.repeat_timer > 0.0:
		return false

	if TimeManager.is_resolving_turn:
		return false

	if is_ui_locked():
		clear_mouse_auto_navigation()
		return false

	var clicked_tile: Vector2i = mouse_pending_click_tile
	clear_mouse_pending_click()

	if _is_player_action_blocked():
		clear_mouse_auto_navigation()
		return true

	return handle_left_click_on_tile(clicked_tile)


func should_cancel_mouse_auto_move_by_input(event: InputEvent) -> bool:
	if not has_mouse_auto_path_or_target():
		return false

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if not mouse_event.pressed:
			return false

		# 左クリックはキャンセルではなく、目的地の上書きとして handle_mouse_map_input() 側で処理する。
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			return false

		return true

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return key_event.pressed and not key_event.echo

	if event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event as InputEventJoypadButton
		return button_event.pressed

	return false


func start_mouse_auto_path_to_empty_tile(destination_tile: Vector2i) -> bool:
	var start_tile: Vector2i = get_player_tile_coords()
	var path: Array[Vector2i] = find_mouse_path(start_tile, destination_tile)

	if path.is_empty():
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("そこへは移動できない")
		return true

	mouse_auto_path = path
	mouse_auto_target_tile = destination_tile
	mouse_auto_target_kind = &"none"
	mouse_auto_target_object = null
	return true

func start_mouse_auto_path_to_target(target_tile: Vector2i, target_kind: StringName) -> bool:
	# 旧互換用。基本的には対象本体を保持できる
	# start_mouse_auto_path_to_interact_target() を使う。
	var start_tile: Vector2i = get_player_tile_coords()
	var path: Array[Vector2i] = find_mouse_path_to_adjacent_tile(start_tile, target_tile)

	if path.is_empty():
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("対象の近くまで移動できない")
		return true

	mouse_auto_path = path
	mouse_auto_target_tile = target_tile
	mouse_auto_target_kind = target_kind
	mouse_auto_target_object = null
	return true

func start_mouse_auto_path_to_interact_target(target_object, target_kind: StringName) -> bool:
	if target_object == null:
		return false

	if not is_instance_valid(target_object):
		return false

	var target_tile: Vector2i = get_mouse_auto_interact_object_tile(target_object, target_kind)
	var start_tile: Vector2i = get_player_tile_coords()

	# すでに隣接しているなら、その場で1回インタラクトする。
	if get_mouse_tile_distance(start_tile, target_tile) == 1:
		face_toward_tile_if_possible(target_tile)
		return handle_mouse_auto_interact_object(target_object, target_kind)

	var path: Array[Vector2i] = find_mouse_path_to_adjacent_tile(start_tile, target_tile)

	if path.is_empty():
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("対象の近くまで移動できない")
		return true

	mouse_auto_path = path
	mouse_auto_target_tile = target_tile
	mouse_auto_target_kind = target_kind
	mouse_auto_target_object = target_object
	return true


func start_mouse_auto_path_to_attack_target(target_unit) -> bool:
	return start_mouse_auto_path_to_attack_target_with_kind(target_unit, &"attack_unit")


func start_mouse_auto_path_to_force_attack_target(target_unit) -> bool:
	return start_mouse_auto_path_to_attack_target_with_kind(target_unit, &"force_attack_unit")


func start_mouse_auto_path_to_attack_target_with_kind(target_unit, target_kind: StringName) -> bool:
	if target_unit == null:
		return false

	var start_tile: Vector2i = get_player_tile_coords()
	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(target_unit)
	var path: Array[Vector2i] = find_mouse_path_to_attack_position(start_tile, target_tile)

	if path.is_empty():
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃できる位置まで移動できない")
		return true

	mouse_auto_path = path
	mouse_auto_target_tile = target_tile
	mouse_auto_target_kind = target_kind
	mouse_auto_target_unit = target_unit
	mouse_auto_target_object = null
	return true

func process_mouse_auto_path_step() -> bool:
	if unit == null:
		clear_mouse_auto_path()
		return false

	if unit.is_moving or unit.repeat_timer > 0.0:
		return false

	if TimeManager.is_resolving_turn:
		return false

	if is_ui_locked():
		clear_mouse_auto_path()
		return false

	# 敵クリックによる自動移動中は、敵の最新位置を追いかける。
	# 敵が移動したらルートを再計算し、途中で射程に入ったら移動を止めて1回だけ攻撃する。
	if is_mouse_auto_attack_kind(mouse_auto_target_kind):
		if try_finish_mouse_auto_attack_once():
			return true

		if not refresh_mouse_auto_attack_path_if_needed():
			return true

	# NPC / チェスト / クエストボードクリックによる自動移動中も、
	# 対象本体の最新位置を追いかける。
	# 隣接したら1回だけインタラクトして予約を消す。
	if is_mouse_auto_interact_kind(mouse_auto_target_kind):
		if try_finish_mouse_auto_interact_once():
			return true

		if not refresh_mouse_auto_interact_path_if_needed():
			return true

	var player_tile: Vector2i = get_player_tile_coords()

	while not mouse_auto_path.is_empty() and mouse_auto_path[0] == player_tile:
		mouse_auto_path.remove_at(0)

	if mouse_auto_path.is_empty():
		return finish_mouse_auto_target_if_needed()

	var next_tile: Vector2i = mouse_auto_path[0]
	var diff: Vector2i = next_tile - player_tile
	var distance: int = abs(diff.x) + abs(diff.y)

	if distance != 1:
		clear_mouse_auto_path()
		return false

	if not is_mouse_path_step_still_valid(next_tile):
		# 攻撃予約中は、敵や他Unitの移動でルートが塞がれても即キャンセルせず、
		# 敵の最新位置に対してルートを作り直す。
		if is_mouse_auto_attack_kind(mouse_auto_target_kind):
			if rebuild_mouse_auto_attack_path():
				return true

		# NPC / チェスト / クエストボード予約中も、対象の最新位置へ再ルートする。
		if is_mouse_auto_interact_kind(mouse_auto_target_kind):
			if rebuild_mouse_auto_interact_path():
				return true

		clear_mouse_auto_path()
		if unit.has_method("notify_hud_log"):
			unit.notify_hud_log("移動ルートがふさがれた")
		return true

	var dir: Vector2 = Vector2(float(diff.x), float(diff.y))
	var acted: bool = try_move_in_direction(dir)

	if acted:
		mouse_auto_path.remove_at(0)
		return true

	clear_mouse_auto_path()
	return true

func try_finish_mouse_auto_attack_once() -> bool:
	# 敵クリック/右クリックメニュー攻撃による自動移動中、
	# 攻撃可能位置に入ったら1回だけ攻撃して予約を消す。
	var clicked_unit = get_mouse_auto_attack_target_unit()
	if clicked_unit == null:
		clear_mouse_auto_path()
		return false

	mouse_auto_target_tile = get_unit_tile_coords_for_mouse(clicked_unit)
	var require_hostile: bool = mouse_auto_attack_requires_hostile()

	if not is_attack_target_in_current_range(clicked_unit, require_hostile):
		return false

	face_toward_tile_if_possible(mouse_auto_target_tile)
	var acted: bool = CombatManager.perform_attack(unit, clicked_unit, require_hostile)
	clear_mouse_auto_path()

	if acted:
		_advance_player_turn_after_action()
	elif unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log("攻撃に失敗した")

	return true


func is_mouse_auto_attack_kind(target_kind: StringName) -> bool:
	return target_kind == &"attack_unit" or target_kind == &"force_attack_unit"


func mouse_auto_attack_requires_hostile() -> bool:
	return mouse_auto_target_kind != &"force_attack_unit"


func get_mouse_auto_attack_target_unit():
	if not is_mouse_auto_attack_kind(mouse_auto_target_kind):
		return null

	if mouse_auto_target_unit == null:
		return null

	if not is_instance_valid(mouse_auto_target_unit):
		return null

	if mouse_auto_target_unit == unit:
		return null

	if mouse_auto_attack_requires_hostile():
		if not Targeting.is_hostile(unit, mouse_auto_target_unit):
			return null

	if mouse_auto_target_unit.has_node("Stats"):
		var target_stats = mouse_auto_target_unit.get_node("Stats")
		if target_stats != null and "hp" in target_stats and int(target_stats.hp) <= 0:
			return null

	return mouse_auto_target_unit


func refresh_mouse_auto_attack_path_if_needed() -> bool:
	var target_unit = get_mouse_auto_attack_target_unit()
	if target_unit == null:
		clear_mouse_auto_path()
		return false

	var current_target_tile: Vector2i = get_unit_tile_coords_for_mouse(target_unit)

	# 対象が動いていない、かつまだルートが残っているならそのまま進む。
	if current_target_tile == mouse_auto_target_tile and not mouse_auto_path.is_empty():
		return true

	mouse_auto_target_tile = current_target_tile

	# すでに射程内なら次の process 内で攻撃できる。
	if is_attack_target_in_current_range(target_unit, mouse_auto_attack_requires_hostile()):
		mouse_auto_path.clear()
		return true

	return rebuild_mouse_auto_attack_path()


func rebuild_mouse_auto_attack_path() -> bool:
	var target_unit = get_mouse_auto_attack_target_unit()
	if target_unit == null:
		clear_mouse_auto_path()
		return false

	var target_kind: StringName = mouse_auto_target_kind
	mouse_auto_target_tile = get_unit_tile_coords_for_mouse(target_unit)

	if is_attack_target_in_current_range(target_unit, mouse_auto_attack_requires_hostile()):
		mouse_auto_path.clear()
		return true

	var start_tile: Vector2i = get_player_tile_coords()
	var path: Array[Vector2i] = find_mouse_path_to_attack_position(start_tile, mouse_auto_target_tile)

	if path.is_empty():
		clear_mouse_auto_path()
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("攻撃できる位置まで移動できない")
		return false

	mouse_auto_path = path
	mouse_auto_target_kind = target_kind
	mouse_auto_target_unit = target_unit
	return true


func is_mouse_auto_interact_kind(target_kind: StringName) -> bool:
	return target_kind == &"unit" or target_kind == &"chest" or target_kind == &"quest_board"


func get_mouse_auto_interact_target_object():
	if not is_mouse_auto_interact_kind(mouse_auto_target_kind):
		return null

	if mouse_auto_target_object == null:
		return null

	if not is_instance_valid(mouse_auto_target_object):
		return null

	if mouse_auto_target_kind == &"unit":
		if mouse_auto_target_object == unit:
			return null

		# 非敵対Unitとしてクリックした対象が敵対化した場合は、
		# 誤爆防止のため会話予約をキャンセルする。
		if Targeting.is_hostile(unit, mouse_auto_target_object):
			return null

		if mouse_auto_target_object.has_node("Stats"):
			var target_stats = mouse_auto_target_object.get_node("Stats")
			if target_stats != null and "hp" in target_stats and int(target_stats.hp) <= 0:
				return null

	return mouse_auto_target_object


func get_mouse_auto_interact_object_tile(target_object, target_kind: StringName) -> Vector2i:
	if target_object == null:
		return Vector2i.ZERO

	if target_kind == &"unit":
		return get_unit_tile_coords_for_mouse(target_object)

	if "tile_coords" in target_object:
		return target_object.tile_coords

	var tile_size: int = get_unit_tile_size()
	return Vector2i(
		int(floor(target_object.global_position.x / float(tile_size))),
		int(floor(target_object.global_position.y / float(tile_size)))
	)


func try_finish_mouse_auto_interact_once() -> bool:
	var target_object = get_mouse_auto_interact_target_object()
	if target_object == null:
		clear_mouse_auto_path()
		return false

	mouse_auto_target_tile = get_mouse_auto_interact_object_tile(target_object, mouse_auto_target_kind)

	var player_tile: Vector2i = get_player_tile_coords()
	var distance: int = get_mouse_tile_distance(player_tile, mouse_auto_target_tile)
	if distance != 1:
		return false

	face_toward_tile_if_possible(mouse_auto_target_tile)
	var handled: bool = handle_mouse_auto_interact_object(target_object, mouse_auto_target_kind)
	clear_mouse_auto_path()
	return handled


func handle_mouse_auto_interact_object(target_object, target_kind: StringName) -> bool:
	if target_object == null:
		return false

	if target_kind == &"unit":
		if unit.has_method("try_interact_action"):
			unit.try_interact_action()
			return true
		return false

	if target_kind == &"chest":
		return handle_mouse_clicked_chest(target_object)

	if target_kind == &"quest_board":
		return handle_mouse_clicked_quest_board(target_object)

	return false


func refresh_mouse_auto_interact_path_if_needed() -> bool:
	var target_object = get_mouse_auto_interact_target_object()
	if target_object == null:
		clear_mouse_auto_path()
		return false

	var current_target_tile: Vector2i = get_mouse_auto_interact_object_tile(target_object, mouse_auto_target_kind)

	# 対象が動いていない、かつまだルートが残っているならそのまま進む。
	if current_target_tile == mouse_auto_target_tile and not mouse_auto_path.is_empty():
		return true

	mouse_auto_target_tile = current_target_tile

	var player_tile: Vector2i = get_player_tile_coords()
	if get_mouse_tile_distance(player_tile, mouse_auto_target_tile) == 1:
		mouse_auto_path.clear()
		return true

	return rebuild_mouse_auto_interact_path()


func rebuild_mouse_auto_interact_path() -> bool:
	var target_object = get_mouse_auto_interact_target_object()
	if target_object == null:
		clear_mouse_auto_path()
		return false

	mouse_auto_target_tile = get_mouse_auto_interact_object_tile(target_object, mouse_auto_target_kind)

	var player_tile: Vector2i = get_player_tile_coords()
	if get_mouse_tile_distance(player_tile, mouse_auto_target_tile) == 1:
		mouse_auto_path.clear()
		return true

	var path: Array[Vector2i] = find_mouse_path_to_adjacent_tile(player_tile, mouse_auto_target_tile)
	if path.is_empty():
		clear_mouse_auto_path()
		if unit != null and unit.has_method("notify_hud_log"):
			unit.notify_hud_log("対象の近くまで移動できない")
		return false

	mouse_auto_path = path
	return true


func get_mouse_tile_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func finish_mouse_auto_target_if_needed() -> bool:
	if mouse_auto_target_kind == &"none":
		clear_mouse_auto_path()
		return false

	if is_mouse_auto_attack_kind(mouse_auto_target_kind):
		var attack_handled: bool = try_finish_mouse_auto_attack_once()
		if not attack_handled:
			clear_mouse_auto_path()
		return attack_handled

	if is_mouse_auto_interact_kind(mouse_auto_target_kind):
		var interact_handled: bool = try_finish_mouse_auto_interact_once()
		if not interact_handled:
			clear_mouse_auto_path()
		return interact_handled

	clear_mouse_auto_path()
	return false

func is_mouse_path_step_still_valid(tile: Vector2i) -> bool:
	if Targeting.get_unit_on_tile(units_node, tile, unit) != null:
		return false

	if get_chest_on_tile(tile) != null:
		return false

	if get_quest_board_on_tile(tile) != null:
		return false

	return is_tile_walkable_for_mouse_path(tile)


func find_mouse_path(start_tile: Vector2i, goal_tile: Vector2i) -> Array[Vector2i]:
	var empty_path: Array[Vector2i] = []

	if start_tile == goal_tile:
		return empty_path

	if not is_tile_walkable_for_mouse_path(goal_tile):
		return empty_path

	if Targeting.get_unit_on_tile(units_node, goal_tile, unit) != null:
		return empty_path

	if get_chest_on_tile(goal_tile) != null:
		return empty_path

	if get_quest_board_on_tile(goal_tile) != null:
		return empty_path

	return find_mouse_path_to_any_goal(start_tile, [goal_tile])


func find_mouse_path_to_attack_position(start_tile: Vector2i, target_tile: Vector2i) -> Array[Vector2i]:
	var goals: Array[Vector2i] = get_attack_position_candidates(target_tile)
	return find_mouse_path_to_any_goal(start_tile, goals)


func get_attack_position_candidates(target_tile: Vector2i) -> Array[Vector2i]:
	var goals: Array[Vector2i] = []
	var min_range: int = get_mouse_attack_min_range()
	var max_range: int = get_mouse_attack_max_range()
	var start_tile: Vector2i = get_player_tile_coords()

	for y in range(-max_range, max_range + 1):
		for x in range(-max_range, max_range + 1):
			var offset: Vector2i = Vector2i(x, y)
			var distance: int = abs(offset.x) + abs(offset.y)

			if distance < min_range or distance > max_range:
				continue

			var candidate: Vector2i = target_tile + offset

			if candidate == target_tile:
				continue

			if candidate == start_tile:
				goals.append(candidate)
				continue

			if not is_tile_walkable_for_mouse_path(candidate):
				continue

			if Targeting.get_unit_on_tile(units_node, candidate, unit) != null:
				continue

			if get_chest_on_tile(candidate) != null:
				continue

			if get_quest_board_on_tile(candidate) != null:
				continue

			goals.append(candidate)

	goals.sort_custom(Callable(self, "_sort_attack_position_candidates"))
	return goals


func _sort_attack_position_candidates(a: Vector2i, b: Vector2i) -> bool:
	var start_tile: Vector2i = get_player_tile_coords()
	var da: int = get_mouse_tile_distance(start_tile, a)
	var db: int = get_mouse_tile_distance(start_tile, b)

	if da != db:
		return da < db

	if a.y != b.y:
		return a.y < b.y

	return a.x < b.x


func is_attack_target_in_current_range(target_unit, require_hostile: bool = true) -> bool:
	if target_unit == null:
		return false

	var source_tile: Vector2i = get_player_tile_coords()
	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(target_unit)

	if not is_target_tile_in_attack_range_from_tile(source_tile, target_tile):
		return false

	# CombatManager.can_attack() がある場合は、向きを合わせた上で最終確認する。
	# 遠距離前方攻撃などの既存ルールを尊重するため。
	face_toward_tile_if_possible(target_tile)

	if CombatManager.has_method("can_attack"):
		return CombatManager.can_attack(unit, target_unit, require_hostile)

	return true


func is_target_tile_in_attack_range_from_tile(source_tile: Vector2i, target_tile: Vector2i) -> bool:
	var diff: Vector2i = target_tile - source_tile
	var distance: int = abs(diff.x) + abs(diff.y)
	var min_range: int = get_mouse_attack_min_range()
	var max_range: int = get_mouse_attack_max_range()

	if distance < min_range:
		return false

	if distance > max_range:
		return false

	return true


func get_mouse_attack_min_range() -> int:
	if unit != null and unit.has_method("get_attack_min_range"):
		return max(1, int(unit.get_attack_min_range()))

	return 1


func get_mouse_attack_max_range() -> int:
	if unit != null and unit.has_method("get_attack_max_range"):
		return max(1, int(unit.get_attack_max_range()))

	return 1


func face_toward_tile_if_possible(target_tile: Vector2i) -> void:
	var player_tile: Vector2i = get_player_tile_coords()
	var diff: Vector2i = target_tile - player_tile

	if diff == Vector2i.ZERO:
		return

	if abs(diff.x) >= abs(diff.y):
		if diff.x > 0:
			face_direction_only(Vector2.RIGHT)
		elif diff.x < 0:
			face_direction_only(Vector2.LEFT)
	else:
		if diff.y > 0:
			face_direction_only(Vector2.DOWN)
		elif diff.y < 0:
			face_direction_only(Vector2.UP)


func get_unit_tile_coords_for_mouse(target_unit) -> Vector2i:
	if target_unit == null:
		return Vector2i.ZERO

	if target_unit.has_method("get_current_tile_coords"):
		return target_unit.get_current_tile_coords()

	if target_unit.has_method("get_occupied_tile_coords"):
		return target_unit.get_occupied_tile_coords()

	if "tile_coords" in target_unit:
		return target_unit.tile_coords

	var tile_size: int = get_unit_tile_size()
	return Vector2i(
		int(floor(target_unit.global_position.x / float(tile_size))),
		int(floor(target_unit.global_position.y / float(tile_size)))
	)


func find_mouse_path_to_adjacent_tile(start_tile: Vector2i, target_tile: Vector2i) -> Array[Vector2i]:
	var goals: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

	for dir in dirs:
		var candidate: Vector2i = target_tile + dir
		if candidate == start_tile:
			var empty_path: Array[Vector2i] = []
			return empty_path

		if not is_tile_walkable_for_mouse_path(candidate):
			continue

		if Targeting.get_unit_on_tile(units_node, candidate, unit) != null:
			continue

		if get_chest_on_tile(candidate) != null:
			continue

		if get_quest_board_on_tile(candidate) != null:
			continue

		goals.append(candidate)

	return find_mouse_path_to_any_goal(start_tile, goals)



func find_mouse_path_to_any_goal(start_tile: Vector2i, goals: Array[Vector2i]) -> Array[Vector2i]:
	var empty_path: Array[Vector2i] = []

	if goals.is_empty():
		return empty_path

	var goal_lookup: Dictionary = {}
	for goal in goals:
		goal_lookup[goal] = true

	if goal_lookup.has(start_tile):
		return empty_path

	var search_rect: Rect2i = get_mouse_path_search_rect(start_tile, goals)
	var open_queue: Array[Vector2i] = [start_tile]
	var queue_index: int = 0
	var came_from: Dictionary = {}
	var visited: Dictionary = {
		start_tile: true
	}
	var searched_count: int = 0
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.DOWN,
		Vector2i.UP
	]

	while queue_index < open_queue.size():
		searched_count += 1
		if searched_count > mouse_auto_move_max_search_tiles:
			break

		var current: Vector2i = open_queue[queue_index]
		queue_index += 1

		for direction in directions:
			var neighbor: Vector2i = current + direction

			if not search_rect.has_point(neighbor):
				continue

			if visited.has(neighbor):
				continue

			if not is_mouse_path_tile_passable(neighbor, start_tile):
				continue

			visited[neighbor] = true
			came_from[neighbor] = current

			if goal_lookup.has(neighbor):
				return reconstruct_mouse_path(came_from, neighbor, start_tile)

			open_queue.append(neighbor)

	return empty_path

func get_mouse_path_search_rect(start_tile: Vector2i, goals: Array[Vector2i]) -> Rect2i:
	var ground_layer = find_ground_layer()

	if ground_layer != null and ground_layer.has_method("get_used_rect"):
		var used_rect: Rect2i = ground_layer.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			return grow_rect2i(used_rect, mouse_auto_move_search_margin)

	# Fallback: if the map cannot provide its used rect, build a large enough rect
	# around start and goals. This is only a fallback.
	var min_x: int = start_tile.x
	var max_x: int = start_tile.x
	var min_y: int = start_tile.y
	var max_y: int = start_tile.y

	for goal in goals:
		min_x = mini(min_x, goal.x)
		max_x = maxi(max_x, goal.x)
		min_y = mini(min_y, goal.y)
		max_y = maxi(max_y, goal.y)

	var fallback_margin: int = max(mouse_auto_move_search_margin, 64)
	return Rect2i(
		Vector2i(min_x - fallback_margin, min_y - fallback_margin),
		Vector2i((max_x - min_x) + fallback_margin * 2 + 1, (max_y - min_y) + fallback_margin * 2 + 1)
	)

func grow_rect2i(rect: Rect2i, amount: int) -> Rect2i:
	amount = max(0, amount)
	return Rect2i(
		Vector2i(rect.position.x - amount, rect.position.y - amount),
		Vector2i(rect.size.x + amount * 2, rect.size.y + amount * 2)
	)

func is_mouse_path_tile_passable(tile: Vector2i, start_tile: Vector2i) -> bool:
	if tile == start_tile:
		return true

	if not is_tile_walkable_for_mouse_path(tile):
		return false

	if Targeting.get_unit_on_tile(units_node, tile, unit) != null:
		return false

	if get_chest_on_tile(tile) != null:
		return false

	if get_quest_board_on_tile(tile) != null:
		return false

	return true
func reconstruct_mouse_path(came_from: Dictionary, current: Vector2i, start_tile: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]

	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)

	if not path.is_empty() and path[0] == start_tile:
		path.remove_at(0)

	return path


func is_tile_walkable_for_mouse_path(tile: Vector2i) -> bool:
	var ground_layer = find_ground_layer()
	if ground_layer == null:
		return false

	if ground_layer.get_cell_source_id(tile) == -1:
		return false

	var target_pos: Vector2 = ground_layer.to_global(ground_layer.map_to_local(tile))
	var shape_node: CollisionShape2D = unit.get_node_or_null("CollisionShape2D")
	if shape_node == null or shape_node.shape == null:
		return true

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = Transform2D(0, target_pos)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	if unit is CollisionObject2D:
		query.exclude = [(unit as CollisionObject2D).get_rid()]

	var result: Array = unit.get_world_2d().direct_space_state.intersect_shape(query)
	return result.is_empty()


func get_mouse_tile_coords() -> Vector2i:
	var ground_layer = find_ground_layer()

	if ground_layer != null:
		var mouse_global: Vector2 = unit.get_global_mouse_position()
		var mouse_local: Vector2 = ground_layer.to_local(mouse_global)
		return ground_layer.local_to_map(mouse_local)

	var tile_size: int = get_unit_tile_size()
	var mouse_position: Vector2 = unit.get_global_mouse_position()

	return Vector2i(
		int(floor(mouse_position.x / float(tile_size))),
		int(floor(mouse_position.y / float(tile_size)))
	)


func get_player_tile_coords() -> Vector2i:
	if unit.has_method("get_current_tile_coords"):
		return unit.get_current_tile_coords()

	if unit.has_method("get_occupied_tile_coords"):
		return unit.get_occupied_tile_coords()

	var tile_size: int = get_unit_tile_size()

	return Vector2i(
		int(floor(unit.global_position.x / float(tile_size))),
		int(floor(unit.global_position.y / float(tile_size)))
	)


func get_unit_tile_size() -> int:
	if unit == null:
		return 32

	if "tile_size" in unit:
		return max(1, int(unit.tile_size))

	return 32


func find_ground_layer():
	var node: Node = unit

	while node != null:
		var ground_layer = node.get_node_or_null("GroundLayer")
		if ground_layer != null:
			return ground_layer

		node = node.get_parent()

	return null


func get_map_root() -> Node:
	var ground_layer = find_ground_layer()
	if ground_layer != null:
		return ground_layer.get_parent()

	var node: Node = unit
	while node != null:
		if node.has_node("Units"):
			return node
		node = node.get_parent()

	return null


func get_chest_on_tile(tile: Vector2i):
	var map_root: Node = get_map_root()
	if map_root == null:
		return null

	var chests_node: Node = map_root.get_node_or_null("Chests")
	if chests_node == null:
		return null

	for child in chests_node.get_children():
		if child == null:
			continue

		if not ("tile_coords" in child):
			continue

		if child.tile_coords == tile:
			return child

	return null


func get_quest_board_on_tile(tile: Vector2i):
	var boards: Array = get_tree().get_nodes_in_group("quest_boards")

	for board in boards:
		if board == null:
			continue

		if not ("tile_coords" in board):
			continue

		if board.tile_coords == tile:
			return board

	return null



# =========================
# Mouse Visual Feedback / Context Menu
# =========================
# ルート表示・クリック可能対象のホバー強調・右クリックメニュー。
# 実行処理自体は既存の左クリック処理や既存アクションに流す。

func ensure_mouse_visual_nodes() -> void:
	if unit == null:
		return

	var map_root: Node = get_map_root()
	if map_root == null:
		return

	if mouse_visual_root != null and is_instance_valid(mouse_visual_root):
		return

	mouse_visual_root = Node2D.new()
	mouse_visual_root.name = "MouseVisualFeedback"
	mouse_visual_root.z_index = 500
	map_root.add_child(mouse_visual_root)

	mouse_route_line = Line2D.new()
	mouse_route_line.name = "RoutePreviewLine"
	mouse_route_line.width = 3.0
	mouse_route_line.default_color = mouse_route_preview_color
	mouse_route_line.visible = false
	mouse_visual_root.add_child(mouse_route_line)

	mouse_hover_line = Line2D.new()
	mouse_hover_line.name = "HoverTileHighlight"
	mouse_hover_line.width = 2.0
	mouse_hover_line.default_color = mouse_hover_move_color
	mouse_hover_line.closed = true
	mouse_hover_line.visible = false
	mouse_visual_root.add_child(mouse_hover_line)


func ensure_mouse_context_menu() -> void:
	if mouse_context_menu != null and is_instance_valid(mouse_context_menu):
		return

	mouse_context_menu = PopupMenu.new()
	mouse_context_menu.name = "MouseContextMenu"
	mouse_context_menu.hide_on_item_selection = true
	mouse_context_menu.hide_on_checkable_item_selection = true
	mouse_context_menu.id_pressed.connect(_on_mouse_context_menu_id_pressed)
	get_tree().root.add_child(mouse_context_menu)


func update_mouse_visual_feedback() -> void:
	ensure_mouse_visual_nodes()

	if mouse_visual_root == null or not is_instance_valid(mouse_visual_root):
		return

	if is_ui_locked() or unit == null or keyboard_target_mode:
		hide_mouse_route_preview()
		hide_mouse_hover_highlight()
		return

	update_mouse_route_preview()
	update_mouse_hover_highlight()


func update_mouse_route_preview() -> void:
	if mouse_route_line == null:
		return

	if not show_mouse_route_preview:
		hide_mouse_route_preview()
		return

	if mouse_auto_path.is_empty():
		hide_mouse_route_preview()
		return

	var points: PackedVector2Array = PackedVector2Array()
	points.append(tile_to_mouse_visual_local(get_player_tile_coords()))

	for tile in mouse_auto_path:
		points.append(tile_to_mouse_visual_local(tile))

	mouse_route_line.points = points
	mouse_route_line.default_color = mouse_route_preview_color
	mouse_route_line.visible = points.size() >= 2


func hide_mouse_route_preview() -> void:
	if mouse_route_line == null:
		return

	mouse_route_line.visible = false
	mouse_route_line.clear_points()


func update_mouse_hover_highlight() -> void:
	if mouse_hover_line == null:
		return

	if not show_mouse_hover_highlight or not enable_mouse_hover_cursor:
		hide_mouse_hover_highlight()
		return

	var tile: Vector2i = get_mouse_tile_coords()
	var color: Color = get_mouse_hover_color_for_tile(tile)

	set_mouse_hover_tile(tile, color)


func hide_mouse_hover_highlight() -> void:
	if mouse_hover_line == null:
		return

	mouse_hover_line.visible = false
	mouse_hover_line.clear_points()


func set_mouse_hover_tile(tile: Vector2i, color: Color) -> void:
	if mouse_hover_line == null:
		return

	var tile_size: float = float(get_unit_tile_size())
	var center: Vector2 = tile_to_mouse_visual_local(tile)
	var half: float = tile_size * 0.5

	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half)
	])

	mouse_hover_line.points = points
	mouse_hover_line.default_color = color
	mouse_hover_line.visible = true


func ensure_keyboard_target_visual_nodes() -> void:
	if unit == null:
		return

	if keyboard_target_visual_root != null and is_instance_valid(keyboard_target_visual_root):
		return

	var parent_node: Node = find_ground_layer()
	if parent_node == null:
		parent_node = get_map_root()

	if parent_node == null:
		return

	# 重要:
	# top_level の Node2D にワールド座標を直接描く方式だと、
	# カメラ/TileMapLayer/親Transformの組み合わせによって画面外に描かれることがある。
	# そのため、攻撃範囲表示は GroundLayer の子に置き、
	# GroundLayer.map_to_local(tile) の座標で描く。
	keyboard_target_visual_root = Node2D.new()
	keyboard_target_visual_root.name = "KeyboardTargetHighlights"
	keyboard_target_visual_root.z_index = 100000
	keyboard_target_visual_root.z_as_relative = false
	parent_node.add_child(keyboard_target_visual_root)

func update_keyboard_target_visual_feedback() -> void:
	ensure_keyboard_target_visual_nodes()

	if keyboard_target_visual_root == null or not is_instance_valid(keyboard_target_visual_root):
		return

	if not show_keyboard_target_highlight or not keyboard_target_mode:
		clear_keyboard_target_visuals()
		return

	clear_keyboard_target_visuals()

	# 先に攻撃可能範囲を薄く表示する。
	# その上に候補枠、最後にInventory風の選択カーソルを描く。
	if show_keyboard_attack_range_highlight:
		var range_tiles: Array[Vector2i] = get_keyboard_attack_range_tiles()
		for range_tile in range_tiles:
			_add_keyboard_target_tile_fill(range_tile, keyboard_attack_range_fill_color)
			_add_keyboard_target_tile_highlight(range_tile, keyboard_attack_range_border_color, keyboard_attack_range_border_width)

	var selected_tile: Vector2i = Vector2i(999999, 999999)

	for i in range(keyboard_target_candidates.size()):
		var target = keyboard_target_candidates[i]
		if target == null or not is_instance_valid(target):
			continue

		var tile: Vector2i = get_unit_tile_coords_for_mouse(target)

		if i == keyboard_target_index:
			selected_tile = tile
			if keyboard_target_selected_fill_color.a > 0.0:
				_add_keyboard_target_tile_fill(tile, keyboard_target_selected_fill_color)
			continue

		if keyboard_target_candidate_show_fill:
			_add_keyboard_target_tile_fill(tile, keyboard_target_candidate_fill_color)

		_add_keyboard_target_tile_highlight(tile, keyboard_target_candidate_color, keyboard_target_candidate_width)

	# Inventoryのカーソルと同じ感覚で、選択中のUnitだけ黄色い四角枠を最前面に描く。
	if selected_tile != Vector2i(999999, 999999):
		_add_keyboard_target_inventory_cursor(selected_tile)


func clear_keyboard_target_visuals() -> void:
	if keyboard_target_visual_root == null or not is_instance_valid(keyboard_target_visual_root):
		return

	for child in keyboard_target_visual_root.get_children():
		child.queue_free()


func get_keyboard_attack_range_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if unit == null:
		return result

	var origin_tile: Vector2i = get_player_tile_coords()
	var min_range: int = 1
	var max_range: int = 1

	if unit.has_method("get_attack_min_range"):
		min_range = max(0, int(unit.get_attack_min_range()))

	if unit.has_method("get_attack_max_range"):
		max_range = max(min_range, int(unit.get_attack_max_range()))

	for y in range(-max_range, max_range + 1):
		for x in range(-max_range, max_range + 1):
			var offset: Vector2i = Vector2i(x, y)
			var distance: int = abs(offset.x) + abs(offset.y)

			if distance < min_range or distance > max_range:
				continue

			var tile: Vector2i = origin_tile + offset
			if not is_keyboard_attack_range_tile_visible(tile):
				continue

			result.append(tile)

	return result


func is_keyboard_attack_range_tile_visible(tile: Vector2i) -> bool:
	# 現在の攻撃判定は距離基準なので、ここでは最低限「地面があるマス」だけを表示する。
	# 将来、壁や射線で攻撃不可にする場合は CombatManager 側の判定に合わせてここも拡張する。
	if unit == null:
		return false

	if unit.ground_layer == null:
		return true

	return unit.ground_layer.get_cell_source_id(tile) != -1


func _add_keyboard_target_inventory_cursor(tile: Vector2i) -> void:
	# Inventoryスロット選択のような「黄色い四角カーソル」。
	# 黒い太枠を下に描いてから黄色枠を重ねるので、背景が明るくても見失いにくい。
	_add_keyboard_target_tile_highlight_with_inset(
		tile,
		keyboard_target_cursor_shadow_color,
		keyboard_target_cursor_shadow_width,
		keyboard_target_cursor_inset
	)
	_add_keyboard_target_tile_highlight_with_inset(
		tile,
		keyboard_target_cursor_color,
		keyboard_target_cursor_width,
		keyboard_target_cursor_inset
	)


func _add_keyboard_target_tile_fill(tile: Vector2i, color: Color) -> void:
	if keyboard_target_visual_root == null or not is_instance_valid(keyboard_target_visual_root):
		return

	var polygon: Polygon2D = Polygon2D.new()
	polygon.color = color
	polygon.z_index = 5000
	polygon.z_as_relative = false

	var tile_size: float = float(get_unit_tile_size())
	var center: Vector2 = tile_to_keyboard_target_visual_local(tile)
	var half: float = tile_size * 0.5

	polygon.polygon = PackedVector2Array([
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half)
	])

	keyboard_target_visual_root.add_child(polygon)


func _add_keyboard_target_tile_highlight(tile: Vector2i, color: Color, width: float) -> void:
	if keyboard_target_visual_root == null or not is_instance_valid(keyboard_target_visual_root):
		return

	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.closed = true
	line.z_index = 5010
	line.z_as_relative = false

	var tile_size: float = float(get_unit_tile_size())
	var center: Vector2 = tile_to_keyboard_target_visual_local(tile)
	var half: float = tile_size * 0.5

	var top_left: Vector2 = center + Vector2(-half, -half)
	var top_right: Vector2 = center + Vector2(half, -half)
	var bottom_right: Vector2 = center + Vector2(half, half)
	var bottom_left: Vector2 = center + Vector2(-half, half)

	line.points = PackedVector2Array([
		top_left,
		top_right,
		bottom_right,
		bottom_left,
		top_left
	])

	keyboard_target_visual_root.add_child(line)


func _add_keyboard_target_tile_highlight_with_inset(tile: Vector2i, color: Color, width: float, inset: float) -> void:
	if keyboard_target_visual_root == null or not is_instance_valid(keyboard_target_visual_root):
		return

	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.closed = true
	line.z_index = 5030
	line.z_as_relative = false

	var tile_size: float = float(get_unit_tile_size())
	var center: Vector2 = tile_to_keyboard_target_visual_local(tile)
	var half: float = max(1.0, tile_size * 0.5 - max(0.0, inset))

	var top_left: Vector2 = center + Vector2(-half, -half)
	var top_right: Vector2 = center + Vector2(half, -half)
	var bottom_right: Vector2 = center + Vector2(half, half)
	var bottom_left: Vector2 = center + Vector2(-half, half)

	line.points = PackedVector2Array([
		top_left,
		top_right,
		bottom_right,
		bottom_left,
		top_left
	])

	keyboard_target_visual_root.add_child(line)


func get_mouse_hover_color_for_tile(tile: Vector2i) -> Color:
	if units_node != null:
		var hovered_unit = Targeting.get_unit_on_tile(units_node, tile, unit)
		if hovered_unit != null:
			if Targeting.is_hostile(unit, hovered_unit):
				return mouse_hover_enemy_color
			return mouse_hover_interact_color

	if get_chest_on_tile(tile) != null:
		return mouse_hover_interact_color

	if get_quest_board_on_tile(tile) != null:
		return mouse_hover_interact_color

	if is_tile_walkable_for_mouse_path(tile):
		return mouse_hover_move_color

	return mouse_hover_blocked_color


func tile_to_mouse_visual_local(tile: Vector2i) -> Vector2:
	var ground_layer = find_ground_layer()
	var global_pos: Vector2

	if ground_layer != null:
		global_pos = ground_layer.to_global(ground_layer.map_to_local(tile))
	else:
		var tile_size: int = get_unit_tile_size()
		global_pos = Vector2(
			(float(tile.x) + 0.5) * float(tile_size),
			(float(tile.y) + 0.5) * float(tile_size)
		)

	if mouse_visual_root != null and is_instance_valid(mouse_visual_root):
		return mouse_visual_root.to_local(global_pos)

	return global_pos


func tile_to_keyboard_target_visual_local(tile: Vector2i) -> Vector2:
	var ground_layer = find_ground_layer()

	if keyboard_target_visual_root != null and is_instance_valid(keyboard_target_visual_root):
		# Root が GroundLayer の子なら、TileMapLayer のローカル座標をそのまま使う。
		# これが一番ズレにくい。
		if ground_layer != null and keyboard_target_visual_root.get_parent() == ground_layer:
			return ground_layer.map_to_local(tile)

		# GroundLayer の子にできなかった場合だけ、グローバル座標から変換する。
		if ground_layer != null:
			var global_pos: Vector2 = ground_layer.to_global(ground_layer.map_to_local(tile))
			return keyboard_target_visual_root.to_local(global_pos)

	var tile_size: int = get_unit_tile_size()
	return Vector2(
		(float(tile.x) + 0.5) * float(tile_size),
		(float(tile.y) + 0.5) * float(tile_size)
	)

func show_mouse_context_menu_for_current_tile() -> void:
	ensure_mouse_context_menu()

	if mouse_context_menu == null:
		return

	var clicked_tile: Vector2i = get_mouse_tile_coords()
	prepare_mouse_context_for_tile(clicked_tile)

	mouse_context_menu.clear()

	if mouse_context_target_kind == &"enemy":
		mouse_context_menu.add_item("攻撃", 1)
		mouse_context_menu.add_item("調べる", 2)
	elif mouse_context_target_kind == &"unit":
		mouse_context_menu.add_item("話す", 3)
		mouse_context_menu.add_item("攻撃", 1)
		mouse_context_menu.add_item("調べる", 2)
	elif mouse_context_target_kind == &"chest":
		mouse_context_menu.add_item("開く", 4)
		mouse_context_menu.add_item("調べる", 2)
	elif mouse_context_target_kind == &"quest_board":
		mouse_context_menu.add_item("開く", 5)
		mouse_context_menu.add_item("調べる", 2)
	else:
		mouse_context_menu.add_item("調べる", 2)

	mouse_context_menu.add_separator()
	mouse_context_menu.add_item("キャンセル", 0)
	mouse_context_menu.position = get_viewport().get_mouse_position()
	mouse_context_menu.popup()


func prepare_mouse_context_for_tile(clicked_tile: Vector2i) -> void:
	mouse_context_target_kind = &"tile"
	mouse_context_target_tile = clicked_tile
	mouse_context_target_unit = null
	mouse_context_target_object = null

	var clicked_unit = Targeting.get_unit_on_tile(units_node, clicked_tile, unit)
	if clicked_unit != null:
		mouse_context_target_unit = clicked_unit
		mouse_context_target_tile = clicked_tile
		if Targeting.is_hostile(unit, clicked_unit):
			mouse_context_target_kind = &"enemy"
		else:
			mouse_context_target_kind = &"unit"
		return

	var chest = get_chest_on_tile(clicked_tile)
	if chest != null:
		mouse_context_target_kind = &"chest"
		mouse_context_target_object = chest
		return

	var quest_board = get_quest_board_on_tile(clicked_tile)
	if quest_board != null:
		mouse_context_target_kind = &"quest_board"
		mouse_context_target_object = quest_board
		return


func _on_mouse_context_menu_id_pressed(id: int) -> void:
	if id == 0:
		return

	if id == 1:
		execute_mouse_context_attack()
		return

	if id == 2:
		execute_mouse_context_examine()
		return

	if id == 3:
		execute_mouse_context_talk()
		return

	if id == 4:
		execute_mouse_context_open_chest()
		return

	if id == 5:
		execute_mouse_context_open_quest_board()
		return


func execute_mouse_context_attack() -> void:
	if mouse_context_target_unit == null:
		return

	if not is_instance_valid(mouse_context_target_unit):
		return

	clear_mouse_auto_navigation()
	start_mouse_context_force_attack(mouse_context_target_unit)


func start_mouse_context_force_attack(target_unit) -> void:
	if target_unit == null:
		return

	if not is_instance_valid(target_unit):
		return

	if _is_player_action_blocked():
		return

	if not is_attack_target_in_current_range(target_unit, false):
		start_mouse_auto_path_to_force_attack_target(target_unit)
		return

	var target_tile: Vector2i = get_unit_tile_coords_for_mouse(target_unit)
	face_toward_tile_if_possible(target_tile)

	var acted: bool = CombatManager.perform_attack(unit, target_unit, false)
	if acted:
		_advance_player_turn_after_action()
	elif unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log("攻撃に失敗した")


func execute_mouse_context_talk() -> void:
	if mouse_context_target_unit == null:
		return

	if not is_instance_valid(mouse_context_target_unit):
		return

	clear_mouse_auto_navigation()
	start_mouse_auto_path_to_interact_target(mouse_context_target_unit, &"unit")


func execute_mouse_context_open_chest() -> void:
	if mouse_context_target_object == null:
		return

	if not is_instance_valid(mouse_context_target_object):
		return

	clear_mouse_auto_navigation()
	start_mouse_auto_path_to_interact_target(mouse_context_target_object, &"chest")


func execute_mouse_context_open_quest_board() -> void:
	if mouse_context_target_object == null:
		return

	if not is_instance_valid(mouse_context_target_object):
		return

	clear_mouse_auto_navigation()
	start_mouse_auto_path_to_interact_target(mouse_context_target_object, &"quest_board")


func execute_mouse_context_examine() -> void:
	var message: String = build_mouse_context_examine_text()
	if unit != null and unit.has_method("notify_hud_log"):
		unit.notify_hud_log(message)


func build_mouse_context_examine_text() -> String:
	if mouse_context_target_kind == &"enemy" or mouse_context_target_kind == &"unit":
		if mouse_context_target_unit != null and is_instance_valid(mouse_context_target_unit):
			return "%s を調べた" % String(mouse_context_target_unit.name)

	if mouse_context_target_kind == &"chest":
		return "チェストを調べた"

	if mouse_context_target_kind == &"quest_board":
		return "クエストボードを調べた"

	return "周囲を調べた"


func notify_hud() -> void:
	var node: Node = unit

	while node != null:
		if node.has_method("refresh_hud"):
			node.refresh_hud()

		if node.has_method("force_sync_hallucination_visuals"):
			node.force_sync_hallucination_visuals()
			return

		node = node.get_parent()


func get_input_direction() -> Vector2:
	if Input.is_action_pressed("RIGHT"):
		return Vector2.RIGHT
	elif Input.is_action_pressed("LEFT"):
		return Vector2.LEFT
	elif Input.is_action_pressed("DOWN"):
		return Vector2.DOWN
	elif Input.is_action_pressed("UP"):
		return Vector2.UP

	return Vector2.ZERO


func toggle_inventory_ui() -> void:
	var node: Node = unit

	while node != null:
		if node.has_method("toggle_inventory_ui"):
			node.toggle_inventory_ui()
			return

		node = node.get_parent()


func toggle_status_ui() -> void:
	var node: Node = unit

	while node != null:
		if node.has_method("toggle_status_ui"):
			node.toggle_status_ui()
			return

		node = node.get_parent()


func is_trade_ui_open() -> bool:
	var node: Node = unit

	while node != null:
		if node.has_method("is_trade_ui_open"):
			return node.is_trade_ui_open()

		node = node.get_parent()

	return false


func is_dialog_open() -> bool:
	var node: Node = unit

	while node != null:
		if node.has_method("is_dialog_open"):
			return node.is_dialog_open()

		node = node.get_parent()

	return false


func is_status_open() -> bool:
	var node: Node = unit

	while node != null:
		if node.has_method("is_status_open"):
			return node.is_status_open()

		node = node.get_parent()

	return false
