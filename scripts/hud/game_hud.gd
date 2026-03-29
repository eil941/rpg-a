extends Control

@onready var day_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/TimeLabel
@onready var weather_label: Label = $CanvasLayer/TimeArea/PanelContainer/VBoxContainer/WeatherLabel

@onready var player_name_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/NameLabel
@onready var hp_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/HPLabel
@onready var hp_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/HPBar
@onready var mp_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/MPLabel
@onready var mp_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/MPBar
@onready var stamina_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/StaminaLabel
@onready var stamina_bar: ProgressBar = $CanvasLayer/UnitStatusArea/HBoxContainer/PlayerStatusCard/PanelContainer/VBoxContainer/StaminaBar

@onready var dummy_label: Label = $CanvasLayer/UnitStatusArea/HBoxContainer/AllyStatusCardDummy/PanelContainer/VBoxContainer/DummyLabel
@onready var minimap_label: Label = $CanvasLayer/MiniMapArea/PanelContainer/MiniMapLabel

@onready var log_title_label: Label = $CanvasLayer/LogArea/PanelContainer/VBoxContainer/LogTitleLabel
@onready var log_label: Label = $CanvasLayer/LogArea/PanelContainer/VBoxContainer/LogLabel

var current_day: int = 1
var current_time_text: String = "08:30"
var current_weather_text: String = "Sunny"

var player_name: String = "Player"
var current_hp: int = 100
var max_hp: int = 100
var current_mp: int = 0
var max_mp: int = 0
var current_stamina: int = 0
var max_stamina: int = 0

var log_lines: Array[String] = []
var max_log_lines: int = 4


func _ready() -> void:
	initialize_hud()


func initialize_hud() -> void:
	log_title_label.text = "Log"
	dummy_label.text = "Ally Slot"
	minimap_label.text = "Mini Map"

	update_time_area()
	update_player_status_area()
	update_log_display()


func update_time_area() -> void:
	day_label.text = "Day %d" % current_day
	time_label.text = current_time_text
	weather_label.text = current_weather_text


func update_player_status_area() -> void:
	player_name_label.text = player_name

	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

	mp_label.text = "MP: %d / %d" % [current_mp, max_mp]
	mp_bar.max_value = max_mp
	mp_bar.value = current_mp

	stamina_label.text = "STM: %d / %d" % [current_stamina, max_stamina]
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina


func add_log(text: String) -> void:
	log_lines.append(text)

	while log_lines.size() > max_log_lines:
		log_lines.pop_front()

	update_log_display()


func update_log_display() -> void:
	log_label.text = "\n".join(log_lines)


func set_time_info(p_day: int, p_time_text: String, p_weather_text: String) -> void:
	current_day = p_day
	current_time_text = p_time_text
	current_weather_text = p_weather_text
	update_time_area()


func set_player_status(
	p_name: String,
	p_hp: int,
	p_max_hp: int,
	p_mp: int,
	p_max_mp: int,
	p_stamina: int,
	p_max_stamina: int
) -> void:
	player_name = p_name
	current_hp = p_hp
	max_hp = p_max_hp
	current_mp = p_mp
	max_mp = p_max_mp
	current_stamina = p_stamina
	max_stamina = p_max_stamina
	update_player_status_area()
