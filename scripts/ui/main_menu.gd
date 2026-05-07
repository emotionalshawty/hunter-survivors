extends Control

const LABEL_COLOR := Color(0.62, 0.86, 0.90, 1.0)
const VALUE_COLOR := Color(0.94, 0.98, 0.98, 1.0)
const ACCENT_CYAN := Color(0.36, 0.96, 0.89, 1.0)
const ACCENT_GOLD := Color(1.0, 0.83, 0.38, 1.0)

@onready var pilot_name_value: Label = $MainPanel/CenterContainer/MainContent/Columns/StatsPanel/Margin/VBox/PilotNameValue
@onready var stats_grid: GridContainer = $MainPanel/CenterContainer/MainContent/Columns/StatsPanel/Margin/VBox/StatsGrid
@onready var leaderboard_status: Label = $MainPanel/CenterContainer/MainContent/Columns/LeaderboardPanel/Margin/VBox/LeaderboardStatus
@onready var leaderboard_list: VBoxContainer = $MainPanel/CenterContainer/MainContent/Columns/LeaderboardPanel/Margin/VBox/LeaderboardList
@onready var play_button: Button = $MainPanel/CenterContainer/MainContent/Buttons/PlayButton
@onready var settings_button: Button = $MainPanel/CenterContainer/MainContent/Buttons/SettingsButton
@onready var sign_out_button: Button = $MainPanel/CenterContainer/MainContent/Buttons/SignOutButton
@onready var exit_button: Button = $MainPanel/CenterContainer/MainContent/Buttons/ExitButton
@onready var main_panel: Control = $MainPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var settings_back_button: Button = $SettingsPanel/CenterContainer/PanelContainer/Margin/VBox/BackButton
@onready var shake_checkbox: CheckBox = $SettingsPanel/CenterContainer/PanelContainer/Margin/VBox/Settings/ShakeCheckBox
@onready var post_processing_checkbox: CheckBox = $SettingsPanel/CenterContainer/PanelContainer/Margin/VBox/Settings/PostProcessCheckBox
@onready var fullscreen_checkbox: CheckBox = $SettingsPanel/CenterContainer/PanelContainer/Margin/VBox/Settings/FullscreenCheckBox

var _highlight_user_id: String = ""


func _ready() -> void:
	if not Database.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")
		return

	settings_panel.visible = false

	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	sign_out_button.pressed.connect(_on_sign_out_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)

	shake_checkbox.toggled.connect(Settings.set_screen_shake)
	post_processing_checkbox.toggled.connect(Settings.set_post_processing)
	fullscreen_checkbox.toggled.connect(Settings.set_fullscreen)
	_sync_settings_checkboxes()

	if Database.has_signal("leaderboard_loaded") and not Database.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		Database.leaderboard_loaded.connect(_on_leaderboard_loaded)
	if Database.has_signal("leaderboard_error") and not Database.leaderboard_error.is_connected(_on_leaderboard_error):
		Database.leaderboard_error.connect(_on_leaderboard_error)
	if Database.has_signal("player_data_loaded") and not Database.player_data_loaded.is_connected(_on_player_data_loaded):
		Database.player_data_loaded.connect(_on_player_data_loaded)

	_highlight_user_id = str(Database.current_user_id)

	# Show whatever is cached immediately, then re-fetch to capture any
	# stats earned since this client last loaded (e.g. after a finished run).
	_populate_pilot_stats(Database._last_loaded_data)
	if not Database.is_data_request_in_progress() and not _highlight_user_id.is_empty():
		Database.load_player_data(_highlight_user_id)

	_show_leaderboard_loading()
	Database.fetch_leaderboard(10)

	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if settings_panel.visible:
		_on_settings_back_pressed()
		accept_event()


# ---------------------------------------------------------
# BUTTON HANDLERS
# ---------------------------------------------------------
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	_sync_settings_checkboxes()
	settings_panel.visible = true
	settings_back_button.grab_focus()


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	play_button.grab_focus()


func _on_sign_out_pressed() -> void:
	Database.logout()
	get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


# ---------------------------------------------------------
# DATA UPDATES
# ---------------------------------------------------------
func _on_player_data_loaded(loaded_id: String, data: Dictionary) -> void:
	if loaded_id != Database.current_user_id:
		return
	_populate_pilot_stats(data)


func _populate_pilot_stats(data: Dictionary) -> void:
	var name_text: String = str(Database.current_username).strip_edges()
	if name_text.is_empty():
		name_text = str(data.get("username", "")).strip_edges()
	if name_text.is_empty():
		name_text = "anonymous"
	if pilot_name_value != null:
		pilot_name_value.text = name_text.to_upper()

	if stats_grid == null:
		return
	for child in stats_grid.get_children():
		child.queue_free()

	var best_score: int = int(data.get("best_score", 0))
	var highest_level: int = int(data.get("highest_level", 1))
	var lifetime_deaths: int = int(data.get("lifetime_deaths", 0))
	var total_coins: int = int(data.get("total_coins", 0))
	var total_xp: int = int(data.get("total_xp_collected", 0))
	var last_score: int = int(data.get("last_score", 0))

	_add_stat_row("BEST SCORE", str(best_score), ACCENT_GOLD)
	_add_stat_row("HIGHEST LEVEL", str(highest_level), ACCENT_CYAN)
	_add_stat_row("TOTAL CREDITS", str(total_coins), ACCENT_GOLD)
	_add_stat_row("TOTAL XP", str(total_xp), VALUE_COLOR)
	_add_stat_row("DEATHS", str(lifetime_deaths), VALUE_COLOR)
	_add_stat_row("LAST RUN", str(last_score), VALUE_COLOR)


func _add_stat_row(label_text: String, value_text: String, value_color: Color) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", value_color)
	value.add_theme_font_size_override("font_size", 18)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_child(value)


# ---------------------------------------------------------
# LEADERBOARD
# ---------------------------------------------------------
func _show_leaderboard_loading() -> void:
	if leaderboard_status != null:
		leaderboard_status.visible = true
		leaderboard_status.text = "Loading top operators..."
	if leaderboard_list != null:
		for child in leaderboard_list.get_children():
			child.queue_free()


func _on_leaderboard_loaded(entries: Array) -> void:
	if leaderboard_list == null:
		return
	for child in leaderboard_list.get_children():
		child.queue_free()

	if entries.is_empty():
		if leaderboard_status != null:
			leaderboard_status.visible = true
			leaderboard_status.text = "No leaderboard entries yet."
		return

	if leaderboard_status != null:
		leaderboard_status.visible = false

	var rank: int = 0
	for entry in entries:
		rank += 1
		_add_leaderboard_row(rank, str(entry.get("username", "anonymous")), int(entry.get("best_score", 0)), str(entry.get("user_id", "")) == _highlight_user_id)


func _on_leaderboard_error(message: String) -> void:
	if leaderboard_list != null:
		for child in leaderboard_list.get_children():
			child.queue_free()
	if leaderboard_status != null:
		leaderboard_status.visible = true
		leaderboard_status.text = "Leaderboard unavailable: %s" % message


func _add_leaderboard_row(rank: int, username: String, score: int, is_self: bool) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var rank_label := Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(36, 0)
	rank_label.add_theme_font_size_override("font_size", 13)
	rank_label.add_theme_color_override("font_color", ACCENT_GOLD if rank == 1 else LABEL_COLOR)

	var name_label := Label.new()
	name_label.text = username
	if is_self:
		name_label.text = "%s  (you)" % username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", ACCENT_CYAN if is_self else VALUE_COLOR)

	var score_label := Label.new()
	score_label.text = str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 13)
	score_label.add_theme_color_override("font_color", ACCENT_GOLD if rank == 1 else VALUE_COLOR)

	row.add_child(rank_label)
	row.add_child(name_label)
	row.add_child(score_label)
	leaderboard_list.add_child(row)


# ---------------------------------------------------------
# SETTINGS PANEL
# ---------------------------------------------------------
func _sync_settings_checkboxes() -> void:
	if shake_checkbox != null:
		shake_checkbox.button_pressed = Settings.screen_shake_enabled
	if post_processing_checkbox != null:
		post_processing_checkbox.button_pressed = Settings.post_processing_enabled
	if fullscreen_checkbox != null:
		fullscreen_checkbox.button_pressed = Settings.fullscreen
