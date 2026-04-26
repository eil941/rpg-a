extends Node

@onready var current_map_container: Node = $CurrentMapContainer
@onready var game_hud = $GameHUD
@onready var inventory_ui = $InventoryUI
@onready var status_ui = $StatusUI

var current_map: Node = null
var trade_return_context: Dictionary = {}

var hud_refresh_interval: float = 0.2
var hud_refresh_timer: float = 0.0

# =========================================================
# blind / hallucination visual settings
# =========================================================
@export var blind_radius_px: float = 56.0
@export var blind_edge_softness_px: float = 10.0

var blind_overlay_layer: CanvasLayer = null
var blind_overlay_rect: ColorRect = null

var hallucination_active: bool = false
var hallucination_original_entries: Array[Dictionary] = []
var hallucination_texture_pool: Array[Texture2D] = []
var hallucination_frames_pool: Array[SpriteFrames] = []

# 幻覚中はこの remap を固定で使い続ける
var hallucination_texture_remap: Dictionary = {}
var hallucination_frames_remap: Dictionary = {}

var hallucination_seed: int = 0

var last_hunger_condition_key: String = "__unset__"
var last_stamina_condition_key: String = "__unset__"


func _ready() -> void:
	_setup_blind_overlay()

	load_map_by_path("res://scenes/field_map.tscn")
	refresh_hud()

	if status_ui != null:
		if status_ui.has_method("close_ui"):
			status_ui.close_ui()
		else:
			status_ui.visible = false

	_update_world_status_visuals(0.0)


func _process(delta: float) -> void:
	_update_world_status_visuals(delta)

	hud_refresh_timer += delta
	if hud_refresh_timer < hud_refresh_interval:
		return

	hud_refresh_timer = 0.0
	update_hud_time()
	update_hud_player_status()
	update_hud_effects()


func load_map_by_path(scene_path: String) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("GameAndHud: シーンを読み込めません: " + scene_path)
		return

	load_map(scene)


func load_map(map_scene: PackedScene) -> void:
	if hallucination_active:
		_restore_hallucination_visuals()
		_force_restore_remaining_hallucination_nodes()
		_clear_hallucination_cache()
		hallucination_active = false

	if current_map != null:
		current_map.queue_free()
		current_map = null

	current_map = map_scene.instantiate()
	current_map_container.add_child(current_map)

	_configure_blind_overlay_layer()
	_resize_blind_overlay_to_viewport()

	refresh_hud()
	_update_world_status_visuals(0.0)

	if _player_has_status(&"hallucination"):
		_activate_hallucination()




func _has_game_hud_method(method_name: String) -> bool:
	if game_hud == null:
		return false
	return game_hud.has_method(method_name)


func _get_player_with_stats():
	var player = find_player()
	if player == null:
		return null
	if player.stats == null:
		return null
	return player


func _get_stats_int(stats, property_name: String) -> int:
	if not _stats_has_property(stats, property_name):
		return 0
	return int(stats.get(property_name))


func _is_dialog_open_via_manager() -> bool:
	if DialogueManager == null:
		return false
	if not DialogueManager.has_method("is_dialog_open"):
		return false
	return DialogueManager.is_dialog_open()

func refresh_hud() -> void:
	update_hud_time()
	update_hud_player_status()
	update_hud_effects()


func update_hud_time() -> void:
	if not _has_game_hud_method("set_time_info"):
		return

	game_hud.set_time_info(
		TimeManager.get_day(),
		TimeManager.get_time_string(),
		TimeManager.get_time_of_day()
	)


func update_hud_player_status() -> void:
	if not _has_game_hud_method("set_player_status"):
		return

	var player = _get_player_with_stats()
	if player == null:
		return

	var total_max_hp: int = int(player.stats.max_hp)
	if player.has_method("get_total_max_hp"):
		total_max_hp = int(player.get_total_max_hp())

	var current_mp: int = _get_stats_int(player.stats, "mp")
	var total_max_mp: int = _get_stats_int(player.stats, "max_mp")
	var current_stamina: int = _get_stats_int(player.stats, "stamina")
	var total_max_stamina: int = _get_stats_int(player.stats, "max_stamina")

	game_hud.set_player_status(
		player.name,
		int(player.stats.hp),
		total_max_hp,
		current_mp,
		total_max_mp,
		current_stamina,
		total_max_stamina
	)


func update_hud_effects() -> void:
	if not _has_game_hud_method("set_effect_entries"):
		return

	var player = find_player()
	if player == null:
		game_hud.set_effect_entries([])
		return

	var entries: Array[Dictionary] = _build_player_effect_entries(player)
	game_hud.set_effect_entries(entries)


func _build_player_effect_entries(player) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if player == null:
		return result

	if not ("active_effect_runtimes" in player):
		return result

	var player_speed: float = 1.0
	if player.has_method("get_total_speed"):
		player_speed = max(1.0, float(player.get_total_speed()))
	elif player.stats != null:
		player_speed = max(1.0, float(player.stats.speed))

	var runtimes: Array = player.active_effect_runtimes
	for runtime_value in runtimes:
		if runtime_value == null:
			continue

		var entry: Dictionary = _build_effect_entry(runtime_value, player_speed)
		if entry.is_empty():
			continue

		result.append(entry)

	_append_hunger_condition_entry(player, result)
	_append_stamina_condition_entry(player, result)

	return result



func _append_hunger_condition_entry(player, out_entries: Array[Dictionary]) -> void:
	if player == null or player.stats == null:
		return
	if not player.stats.has_method("get_hunger_condition_key"):
		return

	var key: String = player.stats.get_hunger_condition_key()

	if last_hunger_condition_key == "__unset__":
		last_hunger_condition_key = key
	elif key != last_hunger_condition_key:
		_log_hunger_condition_change(key)
		last_hunger_condition_key = key

	var entry: Dictionary = _build_hunger_condition_entry(key)
	if not entry.is_empty():
		out_entries.append(entry)


func _append_stamina_condition_entry(player, out_entries: Array[Dictionary]) -> void:
	if player == null or player.stats == null:
		return
	if not player.stats.has_method("get_stamina_condition_key"):
		return

	var key: String = player.stats.get_stamina_condition_key()

	if last_stamina_condition_key == "__unset__":
		last_stamina_condition_key = key
	elif key != last_stamina_condition_key:
		_log_stamina_condition_change(key)
		last_stamina_condition_key = key

	var entry: Dictionary = _build_stamina_condition_entry(key)
	if not entry.is_empty():
		out_entries.append(entry)


func _build_hunger_condition_entry(key: String) -> Dictionary:
	match key:
		"full":
			return {
				"name": "満腹",
				"icon_text": "満",
				"description": "十分に満たされている",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "空腹状態",
				"kind": "status",
				"hover_key": "condition:full"
			}
		"hungry":
			return {
				"name": "空腹",
				"icon_text": "空",
				"description": "空腹を感じている",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "空腹状態",
				"kind": "status",
				"hover_key": "condition:hungry"
			}
		"starving":
			return {
				"name": "飢餓",
				"icon_text": "飢",
				"description": "かなり飢えている",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "空腹状態",
				"kind": "status",
				"hover_key": "condition:starving"
			}
		"starving_dead":
			return {
				"name": "餓死",
				"icon_text": "死",
				"description": "餓死状態。継続ダメージを受ける",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "空腹状態",
				"kind": "status",
				"hover_key": "condition:starving_dead"
			}
		_:
			return {}


func _build_stamina_condition_entry(key: String) -> Dictionary:
	match key:
		"fatigue":
			return {
				"name": "疲労",
				"icon_text": "疲",
				"description": "スタミナが減っている",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "スタミナ状態",
				"kind": "status",
				"hover_key": "condition:fatigue"
			}
		"overwork":
			return {
				"name": "過労",
				"icon_text": "労",
				"description": "スタミナが限界に近い",
				"remaining_time_text": "",
				"remaining_turn_text": "",
				"type_text": "スタミナ状態",
				"kind": "status",
				"hover_key": "condition:overwork"
			}
		_:
			return {}


func _log_hunger_condition_change(key: String) -> void:
	match key:
		"full":
			add_hud_log("満腹になった")
		"hungry":
			add_hud_log("空腹になった")
		"starving":
			add_hud_log("飢餓状態になった")
		"starving_dead":
			add_hud_log("餓死状態になった")
		"":
			add_hud_log("空腹状態が落ち着いた")


func _log_stamina_condition_change(key: String) -> void:
	match key:
		"fatigue":
			add_hud_log("疲労状態になった")
		"overwork":
			add_hud_log("過労状態になった")
		"":
			add_hud_log("スタミナ状態が回復した")

func _build_effect_entry(runtime, player_speed: float) -> Dictionary:
	if runtime == null:
		return {}

	var entry: Dictionary = {
		"name": "効果",
		"icon_text": "？",
		"description": "",
		"remaining_time_text": "",
		"remaining_turn_text": "",
		"type_text": "",
		"kind": "status",
		"hover_key": ""
	}

	var remaining_seconds: float = max(0.0, float(runtime.remaining_duration))
	entry["remaining_time_text"] = _format_remaining_time_text(remaining_seconds)
	entry["remaining_turn_text"] = _format_remaining_turn_text(remaining_seconds, player_speed)

	if runtime.effect_type == ItemEffectData.EffectType.APPLY_STATUS:
		var status_id: String = String(runtime.status_id)
		entry["name"] = _get_status_display_name(status_id)
		entry["icon_text"] = _get_status_icon_text(status_id)
		entry["description"] = _get_status_description(status_id, int(runtime.status_power))
		entry["type_text"] = "状態異常"
		entry["kind"] = "status"
		entry["hover_key"] = "status:%s" % status_id
		return entry

	if runtime.effect_type == ItemEffectData.EffectType.APPLY_MODIFIER:
		var stat_name: String = String(runtime.stat_name)
		var is_debuff: bool = runtime.modifier_kind == ItemEffectData.ModifierKind.DEBUFF
		var kind: String = "buff"
		var type_text: String = "バフ"
		var debuff_flag: String = "0"

		if is_debuff:
			kind = "debuff"
			type_text = "デバフ"
			debuff_flag = "1"

		entry["name"] = _get_modifier_display_name(stat_name, is_debuff)
		entry["icon_text"] = _get_modifier_icon_text(stat_name, is_debuff)
		entry["description"] = _build_modifier_description(runtime, stat_name, is_debuff)
		entry["type_text"] = type_text
		entry["kind"] = kind
		entry["hover_key"] = "modifier:%s:%s" % [stat_name, debuff_flag]
		return entry

	return {}


func _build_modifier_description(runtime, stat_name: String, is_debuff: bool) -> String:
	var stat_text: String = _get_stat_display_name(stat_name)
	var parts: Array[String] = []

	if int(runtime.stat_flat) != 0:
		if is_debuff:
			parts.append("%s %d" % [stat_text, -abs(int(runtime.stat_flat))])
		else:
			parts.append("%s +%d" % [stat_text, abs(int(runtime.stat_flat))])

	if absf(float(runtime.stat_percent)) > 0.0001:
		var percent_text: String = str(int(round(absf(float(runtime.stat_percent)) * 100.0))) + "%"
		if is_debuff:
			parts.append("%s -%s" % [stat_text, percent_text])
		else:
			parts.append("%s +%s" % [stat_text, percent_text])

	if parts.is_empty():
		if is_debuff:
			return stat_text + "を一時的に低下させる"
		return stat_text + "を一時的に上昇させる"

	return " / ".join(parts)


func _format_remaining_time_text(seconds: float) -> String:
	if seconds <= 0.0:
		return "0秒"

	var total_seconds: int = int(ceil(seconds))

	if total_seconds < 60:
		return "%d秒" % total_seconds

	if total_seconds < 3600:
		var minutes: int = total_seconds / 60
		var remain_seconds: int = total_seconds % 60
		return "%d分%d秒" % [minutes, remain_seconds]

	if total_seconds < 86400:
		var hours: int = total_seconds / 3600
		var minutes2: int = (total_seconds % 3600) / 60
		return "%d時間%d分" % [hours, minutes2]

	var days: int = total_seconds / 86400
	var hours2: int = (total_seconds % 86400) / 3600
	return "%d日%d時間" % [days, hours2]


func _format_remaining_turn_text(seconds: float, player_speed: float) -> String:
	if seconds <= 0.0:
		return "約0ターン"

	if player_speed <= 0.0:
		return ""

	var seconds_per_turn: float = 86400.0 / player_speed
	if seconds_per_turn <= 0.0:
		return ""

	var estimated_turns: int = int(ceil(seconds / seconds_per_turn))
	return "約%dターン" % estimated_turns


func _get_status_display_name(status_id: String) -> String:
	match status_id:
		"poison":
			return "毒"
		"paralysis":
			return "麻痺"
		"sleep":
			return "睡眠"
		"burning", "burn":
			return "炎上"
		"frostbite", "freeze":
			return "凍傷"
		"confusion":
			return "混乱"
		"blind":
			return "盲目"
		"hallucination":
			return "幻覚"
		"curse":
			return "呪い"
		_:
			return status_id


func _get_status_icon_text(status_id: String) -> String:
	match status_id:
		"poison":
			return "毒"
		"paralysis":
			return "麻"
		"sleep":
			return "眠"
		"burning", "burn":
			return "炎"
		"frostbite", "freeze":
			return "凍"
		"confusion":
			return "乱"
		"blind":
			return "盲"
		"hallucination":
			return "幻"
		"curse":
			return "呪"
		_:
			return "異"


func _get_status_description(status_id: String, status_power: int) -> String:
	match status_id:
		"poison":
			return "継続ダメージを受ける。威力: %d" % max(1, status_power)
		"paralysis":
			return "行動できない"
		"sleep":
			return "眠って行動できない"
		"burning", "burn":
			return "燃焼ダメージを受ける。威力: %d" % max(1, status_power)
		"frostbite", "freeze":
			return "凍傷ダメージを受ける。威力: %d" % max(1, status_power)
		"confusion":
			return "移動が乱れる"
		"blind":
			return "画面中央のごく一部しか見えない"
		"hallucination":
			return "unit / item / object の見た目が乱れる"
		"curse":
			return "不吉な影響を受けている"
		_:
			return ""


func _get_modifier_display_name(stat_name: String, is_debuff: bool) -> String:
	var stat_text: String = _get_stat_display_name(stat_name)
	if is_debuff:
		return stat_text + "低下"
	return stat_text + "上昇"


func _get_modifier_icon_text(stat_name: String, is_debuff: bool) -> String:
	var arrow: String = "↑"
	if is_debuff:
		arrow = "↓"

	match stat_name:
		"attack":
			return "攻" + arrow
		"defense":
			return "防" + arrow
		"speed":
			return "速" + arrow
		"accuracy":
			return "命" + arrow
		"evasion":
			return "避" + arrow
		"crit_rate":
			return "会" + arrow
		_:
			return "強" + arrow


func _get_stat_display_name(stat_name: String) -> String:
	match stat_name:
		"attack":
			return "攻撃"
		"defense":
			return "防御"
		"speed":
			return "速度"
		"accuracy":
			return "命中"
		"evasion":
			return "回避"
		"crit_rate":
			return "会心"
		_:
			return stat_name


func _stats_has_property(stats, property_name: String) -> bool:
	if stats == null:
		return false

	for info in stats.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false


func _object_has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false

	for info in obj.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true

	return false


func add_hud_log(text: String) -> void:
	if not _has_game_hud_method("add_log"):
		return

	game_hud.add_log(text)


# =========================================================
# blind / hallucination visuals
# =========================================================

func _update_world_status_visuals(delta: float) -> void:
	_update_blind_overlay()
	_update_hallucination_visuals(delta)


func _player_has_status(status_id: StringName) -> bool:
	var player = find_player()
	if player == null:
		return false

	if player.has_method("has_status_effect"):
		return bool(player.has_status_effect(status_id))

	if not ("active_effect_runtimes" in player):
		return false

	for runtime in player.active_effect_runtimes:
		if runtime == null:
			continue
		if runtime.effect_type != ItemEffectData.EffectType.APPLY_STATUS:
			continue
		if StringName(runtime.status_id) == status_id:
			return true

	return false


func force_sync_hallucination_visuals() -> void:
	var should_be_active: bool = _player_has_status(&"hallucination")

	if should_be_active:
		if not hallucination_active:
			_activate_hallucination()
		else:
			_reapply_hallucination_visuals()
	else:
		if hallucination_active:
			_deactivate_hallucination()


func _is_hallucination_excluded_node(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if _object_has_property(current, "is_player_unit") and current.get("is_player_unit") == true:
			return true
		current = current.get_parent()
	return false


func _setup_blind_overlay() -> void:
	if blind_overlay_layer != null:
		return

	blind_overlay_layer = CanvasLayer.new()
	blind_overlay_layer.name = "BlindOverlayLayer"
	add_child(blind_overlay_layer)

	blind_overlay_rect = ColorRect.new()
	blind_overlay_rect.name = "BlindOverlay"
	blind_overlay_rect.color = Color.WHITE
	blind_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blind_overlay_rect.material = _create_blind_overlay_material()
	blind_overlay_rect.visible = false
	blind_overlay_layer.add_child(blind_overlay_rect)

	_configure_blind_overlay_layer()
	_resize_blind_overlay_to_viewport()


func _configure_blind_overlay_layer() -> void:
	if blind_overlay_layer == null:
		return

	var min_ui_layer: int = _find_min_ui_canvas_layer()
	if min_ui_layer < 999999:
		blind_overlay_layer.layer = min_ui_layer - 1
	else:
		blind_overlay_layer.layer = 0


func _find_min_ui_canvas_layer() -> int:
	var min_layer: int = 999999

	var ui_roots: Array[Node] = []
	if game_hud != null:
		ui_roots.append(game_hud)
	if inventory_ui != null:
		ui_roots.append(inventory_ui)
	if status_ui != null:
		ui_roots.append(status_ui)

	for root in ui_roots:
		var found_layers: Array[CanvasLayer] = []
		_collect_canvas_layers(root, found_layers)

		for layer_node in found_layers:
			if layer_node == null:
				continue
			min_layer = min(min_layer, int(layer_node.layer))

	return min_layer


func _collect_canvas_layers(node: Node, out_layers: Array[CanvasLayer]) -> void:
	if node == null:
		return

	if node is CanvasLayer:
		out_layers.append(node as CanvasLayer)

	for child in node.get_children():
		if child == null:
			continue
		_collect_canvas_layers(child, out_layers)


func _resize_blind_overlay_to_viewport() -> void:
	if blind_overlay_rect == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	blind_overlay_rect.position = Vector2.ZERO
	blind_overlay_rect.size = viewport_size


func _reorder_blind_overlay() -> void:
	pass


func _create_blind_overlay_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 hole_center_px = vec2(640.0, 360.0);
uniform float hole_radius_px = 56.0;
uniform float edge_softness_px = 10.0;

void fragment() {
	vec2 screen_px = UV * viewport_size;
	float dist = distance(screen_px, hole_center_px);
	float alpha = smoothstep(hole_radius_px, hole_radius_px + max(edge_softness_px, 0.001), dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _update_blind_overlay() -> void:
	if blind_overlay_rect == null:
		return

	_resize_blind_overlay_to_viewport()

	var blind_active: bool = _player_has_status(&"blind")
	blind_overlay_rect.visible = blind_active

	if not blind_active:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var center_px: Vector2 = viewport_size * 0.5

	var material: ShaderMaterial = blind_overlay_rect.material as ShaderMaterial
	if material == null:
		return

	material.set_shader_parameter("viewport_size", viewport_size)
	material.set_shader_parameter("hole_center_px", center_px)
	material.set_shader_parameter("hole_radius_px", blind_radius_px)
	material.set_shader_parameter("edge_softness_px", blind_edge_softness_px)


func _update_hallucination_visuals(_delta: float) -> void:
	var should_be_active: bool = _player_has_status(&"hallucination")

	if should_be_active and not hallucination_active:
		_activate_hallucination()
	elif not should_be_active and hallucination_active:
		_deactivate_hallucination()

	if not hallucination_active:
		return

	_reapply_hallucination_visuals()


func _activate_hallucination() -> void:
	hallucination_active = true
	hallucination_seed = randi()

	_capture_hallucination_visuals()
	_build_hallucination_remap_tables()
	_apply_hallucination_visuals_once()
	_refresh_inventory_hallucination_if_possible()


func _deactivate_hallucination() -> void:
	hallucination_active = false
	_restore_hallucination_visuals()
	_force_restore_remaining_hallucination_nodes()
	_clear_hallucination_cache()
	_refresh_inventory_hallucination_if_possible()


func _clear_hallucination_cache() -> void:
	hallucination_original_entries.clear()
	hallucination_texture_pool.clear()
	hallucination_frames_pool.clear()
	hallucination_texture_remap.clear()
	hallucination_frames_remap.clear()
	hallucination_seed = 0


func _capture_hallucination_visuals() -> void:
	_clear_hallucination_cache()

	if current_map != null:
		var sprite_nodes: Array[Sprite2D] = []
		var animated_nodes: Array[AnimatedSprite2D] = []
		_collect_world_visual_nodes(current_map, sprite_nodes, animated_nodes)

		for sprite in sprite_nodes:
			if sprite == null:
				continue
			if _is_hallucination_excluded_node(sprite):
				continue

			var original_texture: Texture2D = sprite.texture
			hallucination_original_entries.append({
				"type": "sprite",
				"node": sprite,
				"texture": original_texture,
				"offset": sprite.offset,
				"centered": sprite.centered
			})

			if original_texture != null and not hallucination_texture_pool.has(original_texture):
				hallucination_texture_pool.append(original_texture)

		for animated in animated_nodes:
			if animated == null:
				continue
			if _is_hallucination_excluded_node(animated):
				continue

			var original_frames: SpriteFrames = animated.sprite_frames
			var original_animation: StringName = animated.animation
			var original_frame: int = animated.frame
			var original_speed_scale: float = animated.speed_scale

			hallucination_original_entries.append({
				"type": "animated",
				"node": animated,
				"frames": original_frames,
				"animation": original_animation,
				"frame": original_frame,
				"speed_scale": original_speed_scale,
				"offset": animated.offset,
				"centered": animated.centered
			})

			if original_frames != null and not hallucination_frames_pool.has(original_frames):
				hallucination_frames_pool.append(original_frames)

	_collect_item_database_icons_for_hallucination()


func _collect_item_database_icons_for_hallucination() -> void:
	if ItemDatabase == null:
		return

	var resources_dict: Dictionary = ItemDatabase.ITEM_RESOURCES
	for item_id in resources_dict.keys():
		var item_res = resources_dict[item_id]
		if item_res == null:
			continue
		if not _object_has_property(item_res, "icon"):
			continue

		var icon_tex: Texture2D = item_res.icon
		if icon_tex != null and not hallucination_texture_pool.has(icon_tex):
			hallucination_texture_pool.append(icon_tex)


func _collect_world_visual_nodes(node: Node, sprite_nodes: Array[Sprite2D], animated_nodes: Array[AnimatedSprite2D]) -> void:
	if node == null:
		return

	if node is Sprite2D:
		sprite_nodes.append(node)

	if node is AnimatedSprite2D:
		animated_nodes.append(node)

	for child in node.get_children():
		if child == null:
			continue
		_collect_world_visual_nodes(child, sprite_nodes, animated_nodes)


func _build_hallucination_remap_tables() -> void:
	hallucination_texture_remap.clear()
	hallucination_frames_remap.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = hallucination_seed

	for original_texture in hallucination_texture_pool:
		if original_texture == null:
			continue

		var candidates: Array = hallucination_texture_pool.duplicate()
		candidates.erase(original_texture)

		if candidates.is_empty():
			hallucination_texture_remap[original_texture] = original_texture
			continue

		var picked_index: int = rng.randi_range(0, candidates.size() - 1)
		hallucination_texture_remap[original_texture] = candidates[picked_index]

	for original_frames in hallucination_frames_pool:
		if original_frames == null:
			continue

		var frames_candidates: Array = hallucination_frames_pool.duplicate()
		frames_candidates.erase(original_frames)

		if frames_candidates.is_empty():
			hallucination_frames_remap[original_frames] = original_frames
			continue

		var picked_frames_index: int = rng.randi_range(0, frames_candidates.size() - 1)
		hallucination_frames_remap[original_frames] = frames_candidates[picked_frames_index]


func _get_frame_texture_safe(frames: SpriteFrames, animation_name: StringName, frame_index: int) -> Texture2D:
	if frames == null:
		return null

	var anim_name: StringName = animation_name
	if not frames.has_animation(anim_name):
		var names: PackedStringArray = frames.get_animation_names()
		if names.is_empty():
			return null
		anim_name = StringName(names[0])

	var frame_count: int = frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return null

	var safe_frame: int = clamp(frame_index, 0, frame_count - 1)
	return frames.get_frame_texture(anim_name, safe_frame)


func _get_default_image_anchor(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO

	return Vector2(
		texture.get_width() * 0.5,
		texture.get_height()
	)


func _image_anchor_to_local(
	anchor_image: Vector2,
	texture: Texture2D,
	centered: bool,
	offset: Vector2
) -> Vector2:
	if texture == null:
		return offset

	if centered:
		return offset + anchor_image - texture.get_size() * 0.5

	return offset + anchor_image


func _calc_offset_from_desired_anchor_local(
	desired_anchor_local: Vector2,
	anchor_image: Vector2,
	texture: Texture2D,
	centered: bool
) -> Vector2:
	if texture == null:
		return Vector2.ZERO

	if centered:
		return desired_anchor_local - anchor_image + texture.get_size() * 0.5

	return desired_anchor_local - anchor_image


func _apply_hallucination_visuals_once() -> void:
	_reapply_hallucination_visuals()


func _reapply_hallucination_visuals() -> void:
	for entry in hallucination_original_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var entry_type: String = String(entry.get("type", ""))
		var node = entry.get("node", null)

		if node == null or not is_instance_valid(node):
			continue
		if _is_hallucination_excluded_node(node):
			continue

		if entry_type == "sprite":
			if not (node is Sprite2D):
				continue

			var sprite: Sprite2D = node
			var original_texture: Texture2D = entry.get("texture", null)
			var base_offset: Vector2 = entry.get("offset", Vector2.ZERO)
			var centered_sprite: bool = bool(entry.get("centered", true))
			var hallucinated_texture: Texture2D = get_hallucinated_texture(original_texture)

			var original_anchor_image: Vector2 = _get_default_image_anchor(original_texture)
			var desired_anchor_local: Vector2 = _image_anchor_to_local(
				original_anchor_image,
				original_texture,
				centered_sprite,
				base_offset
			)

			var target_anchor_image: Vector2 = _get_default_image_anchor(hallucinated_texture)

			if sprite.texture != hallucinated_texture:
				sprite.texture = hallucinated_texture

			sprite.offset = _calc_offset_from_desired_anchor_local(
				desired_anchor_local,
				target_anchor_image,
				hallucinated_texture,
				centered_sprite
			)
			continue

		if entry_type == "animated":
			if not (node is AnimatedSprite2D):
				continue

			var animated: AnimatedSprite2D = node
			var original_frames: SpriteFrames = entry.get("frames", null)
			var original_animation: StringName = entry.get("animation", &"")
			var original_frame: int = int(entry.get("frame", 0))
			var base_offset_animated: Vector2 = entry.get("offset", Vector2.ZERO)
			var centered_animated: bool = bool(entry.get("centered", true))

			if original_frames == null:
				continue

			var swapped_frames: SpriteFrames = original_frames
			if hallucination_frames_remap.has(original_frames):
				swapped_frames = hallucination_frames_remap[original_frames]

			var current_anim: StringName = animated.animation
			var current_frame: int = animated.frame
			var was_playing: bool = animated.is_playing()

			var original_texture_for_anchor: Texture2D = _get_frame_texture_safe(
				original_frames,
				original_animation,
				original_frame
			)

			var original_anchor_image_frames: Vector2 = _get_default_image_anchor(original_texture_for_anchor)
			var desired_anchor_local_animated: Vector2 = _image_anchor_to_local(
				original_anchor_image_frames,
				original_texture_for_anchor,
				centered_animated,
				base_offset_animated
			)

			if animated.sprite_frames != swapped_frames:
				animated.sprite_frames = swapped_frames

			var target_anim: StringName = current_anim
			if swapped_frames != null:
				var animation_names: PackedStringArray = swapped_frames.get_animation_names()
				if animation_names.size() > 0:
					if not swapped_frames.has_animation(current_anim):
						target_anim = StringName(animation_names[0])

					if was_playing:
						animated.play(target_anim)
					else:
						animated.animation = target_anim

					var frame_count: int = swapped_frames.get_frame_count(target_anim)
					if frame_count > 0:
						current_frame = clamp(current_frame, 0, frame_count - 1)
						animated.frame = current_frame

			var hallucinated_texture_for_anchor: Texture2D = _get_frame_texture_safe(
				swapped_frames,
				target_anim,
				current_frame
			)

			var target_anchor_image_frames: Vector2 = _get_default_image_anchor(hallucinated_texture_for_anchor)
			animated.offset = _calc_offset_from_desired_anchor_local(
				desired_anchor_local_animated,
				target_anchor_image_frames,
				hallucinated_texture_for_anchor,
				centered_animated
			)


func _restore_hallucination_visuals() -> void:
	for entry in hallucination_original_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var entry_type: String = String(entry.get("type", ""))
		var node = entry.get("node", null)

		if node == null or not is_instance_valid(node):
			continue
		if _is_hallucination_excluded_node(node):
			continue

		if entry_type == "sprite":
			if node is Sprite2D:
				var sprite: Sprite2D = node
				sprite.texture = entry.get("texture", null)
				sprite.offset = entry.get("offset", Vector2.ZERO)
			continue

		if entry_type == "animated":
			if node is AnimatedSprite2D:
				var animated: AnimatedSprite2D = node
				var original_frames: SpriteFrames = entry.get("frames", null)
				var original_animation: StringName = entry.get("animation", &"")
				var original_frame: int = int(entry.get("frame", 0))
				var original_speed_scale: float = float(entry.get("speed_scale", 1.0))

				var was_visible: bool = animated.visible
				animated.visible = false

				animated.sprite_frames = original_frames
				animated.speed_scale = original_speed_scale
				animated.offset = entry.get("offset", Vector2.ZERO)

				if original_frames != null:
					if original_frames.has_animation(original_animation):
						animated.play(original_animation)
						var frame_count: int = original_frames.get_frame_count(original_animation)
						if frame_count > 0:
							animated.frame = clamp(original_frame, 0, frame_count - 1)
					else:
						var names: PackedStringArray = original_frames.get_animation_names()
						if names.size() > 0:
							var fallback_anim: StringName = StringName(names[0])
							animated.play(fallback_anim)
							var fallback_count: int = original_frames.get_frame_count(fallback_anim)
							if fallback_count > 0:
								animated.frame = clamp(original_frame, 0, fallback_count - 1)

				animated.visible = was_visible


func _force_restore_remaining_hallucination_nodes() -> void:
	if current_map == null:
		return

	var reverse_texture_remap: Dictionary = {}
	for original_texture in hallucination_texture_remap.keys():
		var remapped_texture: Texture2D = hallucination_texture_remap[original_texture]
		if remapped_texture != null:
			reverse_texture_remap[remapped_texture] = original_texture

	var reverse_frames_remap: Dictionary = {}
	for original_frames in hallucination_frames_remap.keys():
		var remapped_frames: SpriteFrames = hallucination_frames_remap[original_frames]
		if remapped_frames != null:
			reverse_frames_remap[remapped_frames] = original_frames

	var sprite_nodes: Array[Sprite2D] = []
	var animated_nodes: Array[AnimatedSprite2D] = []
	_collect_world_visual_nodes(current_map, sprite_nodes, animated_nodes)

	for sprite in sprite_nodes:
		if sprite == null:
			continue
		if _is_hallucination_excluded_node(sprite):
			continue

		var current_texture: Texture2D = sprite.texture
		if current_texture != null and reverse_texture_remap.has(current_texture):
			sprite.texture = reverse_texture_remap[current_texture]

	for animated in animated_nodes:
		if animated == null:
			continue
		if _is_hallucination_excluded_node(animated):
			continue

		var current_frames: SpriteFrames = animated.sprite_frames
		if current_frames != null and reverse_frames_remap.has(current_frames):
			var restored_frames: SpriteFrames = reverse_frames_remap[current_frames]
			var current_anim: StringName = animated.animation
			var current_frame: int = animated.frame
			var was_playing: bool = animated.is_playing()
			var was_visible: bool = animated.visible

			animated.visible = false
			animated.sprite_frames = restored_frames

			if restored_frames != null:
				if not restored_frames.has_animation(current_anim):
					var names: PackedStringArray = restored_frames.get_animation_names()
					if names.size() > 0:
						current_anim = StringName(names[0])

				if restored_frames.has_animation(current_anim):
					if was_playing:
						animated.play(current_anim)
					else:
						animated.animation = current_anim

					var frame_count: int = restored_frames.get_frame_count(current_anim)
					if frame_count > 0:
						animated.frame = clamp(current_frame, 0, frame_count - 1)

			animated.visible = was_visible


func _refresh_inventory_hallucination_if_possible() -> void:
	if inventory_ui == null:
		return

	if inventory_ui.has_method("refresh_inventory"):
		inventory_ui.refresh_inventory()
		return

	if inventory_ui.has_method("refresh_all_slots"):
		inventory_ui.refresh_all_slots()
		return

	if inventory_ui.has_method("rebuild_slots"):
		inventory_ui.rebuild_slots()
		return

	if inventory_ui.has_method("redraw"):
		inventory_ui.redraw()


func get_hallucinated_texture(original_texture: Texture2D) -> Texture2D:
	if not hallucination_active:
		return original_texture

	if original_texture == null:
		return null

	if hallucination_texture_remap.has(original_texture):
		return hallucination_texture_remap[original_texture]

	return original_texture


func find_player():
	if current_map == null:
		return null

	var units_node = current_map.get_node_or_null("Units")
	if units_node == null:
		return null

	for child in units_node.get_children():
		if child == null:
			continue
		if child.get("is_player_unit"):
			return child

	return null


func toggle_inventory_ui() -> void:
	if inventory_ui == null:
		print("inventory_ui is null")
		return

	if is_status_open():
		return

	if _is_dialog_open_via_manager():
		return

	if inventory_ui.has_method("is_trade_mode_open"):
		if inventory_ui.is_trade_mode_open():
			return

	var player = find_player()
	if player == null:
		print("player is null")
		return

	if player.inventory == null:
		print("player.inventory is null")
		return

	print("OPEN INVENTORY", player.inventory.get_all_items())
	inventory_ui.toggle_with_inventory(player.inventory)


func is_inventory_open() -> bool:
	if inventory_ui == null:
		return false

	return inventory_ui.visible


func open_trade_ui(player_unit, merchant_unit, return_context: Dictionary = {}) -> void:
	if inventory_ui == null:
		push_error("InventoryUI が見つかりません")
		return

	if is_status_open():
		return

	if player_unit == null:
		push_error("open_trade_ui: player_unit is null")
		return

	if merchant_unit == null:
		push_error("open_trade_ui: merchant_unit is null")
		return

	if player_unit.inventory == null:
		push_error("open_trade_ui: player_unit.inventory is null")
		return

	if merchant_unit.inventory == null:
		push_error("open_trade_ui: merchant_unit.inventory is null")
		return

	trade_return_context = return_context.duplicate(true)

	if DialogueManager != null and DialogueManager.has_method("close_dialog"):
		DialogueManager.close_dialog()

	if inventory_ui.has_method("open_trade_mode"):
		inventory_ui.open_trade_mode(
			player_unit.inventory,
			player_unit,
			merchant_unit.inventory,
			merchant_unit
		)
	else:
		push_error("InventoryUI に open_trade_mode() がありません")


func close_trade_ui() -> void:
	if inventory_ui == null:
		return

	if inventory_ui.has_method("is_trade_mode_open"):
		if not inventory_ui.is_trade_mode_open():
			return

	if inventory_ui.has_method("close_inventory"):
		inventory_ui.close_inventory()


func is_trade_ui_open() -> bool:
	if inventory_ui == null:
		return false

	if inventory_ui.has_method("is_trade_mode_open"):
		return inventory_ui.is_trade_mode_open()

	return false


func on_trade_ui_closed() -> void:
	if DialogueManager == null:
		return

	if trade_return_context.is_empty():
		return

	if DialogueManager.has_method("reopen_dialog_from_context"):
		DialogueManager.reopen_dialog_from_context(trade_return_context)

	trade_return_context = {}


func toggle_status_ui() -> void:
	if status_ui == null:
		push_error("StatusUI が見つかりません")
		return

	if is_trade_ui_open():
		return

	if _is_dialog_open_via_manager():
		return

	if is_inventory_open():
		return

	if is_status_open():
		close_status_ui()
		return

	open_status_ui()


func open_status_ui() -> void:
	if status_ui == null:
		return

	if is_trade_ui_open():
		return

	if is_inventory_open():
		return

	if _is_dialog_open_via_manager():
		return

	var player = find_player()
	if player == null:
		return

	if game_hud != null:
		game_hud.visible = false

	if status_ui.has_method("open_for_unit"):
		status_ui.open_for_unit(player)
	else:
		status_ui.visible = true


func close_status_ui() -> void:
	if status_ui == null:
		return

	if status_ui.has_method("close_ui"):
		status_ui.close_ui()
	else:
		status_ui.visible = false

	if game_hud != null:
		game_hud.visible = true


func is_status_open() -> bool:
	if status_ui == null:
		return false

	if status_ui.has_method("is_open"):
		return status_ui.is_open()

	return status_ui.visible
