extends Control

signal retry_pressed
signal sign_out_pressed
signal main_menu_pressed

const LABEL_COLOR := Color(0.62, 0.86, 0.90, 1.0)
const VALUE_COLOR := Color(0.94, 0.98, 0.98, 1.0)
const ACCENT_CYAN := Color(0.36, 0.96, 0.89, 1.0)
const ACCENT_ORANGE := Color(1.0, 0.48, 0.24, 1.0)
const ACCENT_GOLD := Color(1.0, 0.83, 0.38, 1.0)
const ROW_SEP := Color(0.22, 0.50, 0.56, 0.35)

@onready var subtitle_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/SubtitleLabel
@onready var new_record_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/NewRecordLabel
@onready var stats_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/StatsGrid
@onready var leaderboard_status: Label = $CenterContainer/PanelContainer/MarginContainer/VBox/LeaderboardStatus
@onready var leaderboard_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBox/LeaderboardList
@onready var retry_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/RetryButton
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/MainMenuButton
@onready var sign_out_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/SignOutButton

var _highlight_user_id: String = ""


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	sign_out_button.pressed.connect(func() -> void: sign_out_pressed.emit())
	if main_menu_button != null:
		main_menu_button.pressed.connect(func() -> void: main_menu_pressed.emit())
	if new_record_label != null:
		new_record_label.visible = false


func show_stats(data: Dictionary) -> void:
	_populate(data)
	_highlight_user_id = str(data.get("user_id", ""))
	set_leaderboard_loading()
	visible = true
	retry_button.grab_focus()


func set_leaderboard_loading() -> void:
	if leaderboard_status != null:
		leaderboard_status.visible = true
		leaderboard_status.text = "Loading leaderboard..."
	if leaderboard_list != null:
		for child in leaderboard_list.get_children():
			child.queue_free()


func set_leaderboard(entries: Array) -> void:
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


func set_leaderboard_error(message: String) -> void:
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
	rank_label.add_theme_font_size_override("font_size", 14)
	rank_label.add_theme_color_override("font_color", ACCENT_GOLD if rank == 1 else LABEL_COLOR)

	var name_label := Label.new()
	name_label.text = username
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", ACCENT_CYAN if is_self else VALUE_COLOR)
	if is_self:
		name_label.text = "%s  (you)" % username

	var score_label := Label.new()
	score_label.text = str(score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 14)
	score_label.add_theme_color_override("font_color", ACCENT_GOLD if rank == 1 else VALUE_COLOR)

	row.add_child(rank_label)
	row.add_child(name_label)
	row.add_child(score_label)
	leaderboard_list.add_child(row)


func _populate(data: Dictionary) -> void:
	for child in stats_grid.get_children():
		child.queue_free()

	var pilot: String = str(data.get("pilot", "anonymous"))
	if pilot.strip_edges().is_empty():
		pilot = "anonymous"
	subtitle_label.text = "PILOT %s · TRANSMISSION SEVERED" % pilot.to_upper()

	var is_new_best: bool = bool(data.get("is_new_best", false))
	new_record_label.visible = is_new_best

	var score: int = int(data.get("score", 0))
	var level: int = int(data.get("level", 1))
	var kills: int = int(data.get("kills", 0))
	var xp_gained: int = int(data.get("xp_gained", 0))
	var credits_earned: int = int(data.get("credits_earned", 0))
	var previous_best: int = int(data.get("previous_best", 0))
	var best_display: int = int(data.get("best_display", previous_best))
	var time_ms: int = int(data.get("time_ms", 0))

	var secs: int = int(time_ms / 1000)
	var time_str: String = "%02d:%02d" % [secs / 60, secs % 60]

	var score_color: Color = ACCENT_ORANGE if is_new_best else VALUE_COLOR
	var best_text: String = str(best_display)
	if is_new_best:
		var delta: int = score - previous_best
		best_text = "%d  (+%d)" % [best_display, max(0, delta)]

	_add_row("FINAL SCORE", str(score), score_color)
	_add_row("LEVEL REACHED", str(level), ACCENT_CYAN)
	_add_row("KILLS", str(kills), VALUE_COLOR)
	_add_row("SURVIVAL TIME", time_str, VALUE_COLOR)
	_add_row("XP GAINED", str(xp_gained), VALUE_COLOR)
	_add_row("CREDITS EARNED", str(credits_earned), ACCENT_GOLD)
	_add_row("BEST SCORE", best_text, ACCENT_CYAN)


func _add_row(label_text: String, value_text: String, value_color: Color) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", value_color)
	value.add_theme_font_size_override("font_size", 22)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_child(value)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			retry_pressed.emit()
			accept_event()
		elif event.keycode == KEY_ESCAPE:
			sign_out_pressed.emit()
			accept_event()
