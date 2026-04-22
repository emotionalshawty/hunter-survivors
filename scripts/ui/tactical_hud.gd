extends Control

# Marathon-style tactical HUD with segmented bars, corner brackets, mono-ish readouts.
# Driven by setter methods; uses custom _draw() for everything.

const ACCENT_CYAN := Color(0.36, 0.96, 0.89, 1.0)
const ACCENT_ORANGE := Color(1.0, 0.48, 0.24, 1.0)
const ACCENT_GOLD := Color(1.0, 0.83, 0.38, 1.0)
const TEXT_DIM := Color(0.62, 0.86, 0.90, 1.0)
const TEXT_BRIGHT := Color(0.94, 0.98, 0.98, 1.0)
const BAR_DIM := Color(0.05, 0.10, 0.13, 0.85)
const BAR_DIM_BORDER := Color(0.22, 0.50, 0.56, 0.45)
const HEALTH_FILL := Color(1.0, 0.34, 0.28, 1.0)
const HEALTH_WARN := Color(1.0, 0.72, 0.22, 1.0)
const HEALTH_CRIT := Color(1.0, 0.18, 0.18, 1.0)

const HEALTH_SEGMENTS: int = 20
const XP_SEGMENTS: int = 16

var pilot_name: String = "anonymous"
var current_health: float = 100.0
var max_health: float = 100.0
var level: int = 1
var experience: int = 0
var experience_to_level: int = 6
var run_score: int = 0
var best_score: int = 1
var credits: int = 0
var status_text: String = "ONLINE"
var status_color: Color = ACCENT_CYAN
var game_over: bool = false

var _font: Font
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func set_pilot(new_name: String) -> void:
	pilot_name = new_name
	queue_redraw()


func set_health(current: float, maximum: float) -> void:
	current_health = current
	max_health = maximum
	queue_redraw()


func set_level(lvl: int, xp: int, xp_to_level: int) -> void:
	level = lvl
	experience = xp
	experience_to_level = xp_to_level
	queue_redraw()


func set_stats(run: int, best: int, credits_total: int) -> void:
	run_score = run
	best_score = best
	credits = credits_total
	queue_redraw()


func set_status(text: String, color: Color = ACCENT_CYAN) -> void:
	status_text = text
	status_color = color
	queue_redraw()


func show_game_over() -> void:
	game_over = true
	set_status("TERMINATED", Color(1.0, 0.25, 0.25, 1.0))
	queue_redraw()


func _draw() -> void:
	var size := get_size()
	_draw_top_row(size)
	_draw_separator(size, 30.0, ACCENT_ORANGE)
	_draw_vitals_block(size, 42.0)
	_draw_level_block(size, 82.0)
	_draw_separator(size, 118.0, Color(ACCENT_CYAN, 0.45))
	_draw_stats_row(size, 126.0)


func _draw_top_row(size: Vector2) -> void:
	_draw_text(Vector2(0.0, 14.0), "PILOT", 11, TEXT_DIM)
	_draw_text(Vector2(42.0, 14.0), pilot_name.to_upper(), 14, TEXT_BRIGHT)

	var blink: float = 0.5 + 0.5 * sin(_time * 3.2)
	var dot_pos := Vector2(size.x - 118.0, 6.0)
	draw_rect(Rect2(dot_pos, Vector2(7.0, 7.0)), Color(status_color, blink * 0.85 + 0.15), true)
	_draw_text(dot_pos + Vector2(13.0, 7.0), status_text, 11, status_color)


func _draw_separator(size: Vector2, y: float, color: Color) -> void:
	draw_line(Vector2(12.0, y), Vector2(size.x - 12.0, y), Color(color, 0.55), 1.0)
	_draw_bracket(Vector2(0.0, y - 4.0), Vector2(10.0, 0.0), Vector2(0.0, 8.0), color)
	_draw_bracket(Vector2(size.x, y - 4.0), Vector2(-10.0, 0.0), Vector2(0.0, 8.0), color)


func _draw_bracket(origin: Vector2, h: Vector2, v: Vector2, color: Color) -> void:
	draw_line(origin, origin + h, color, 1.5)
	draw_line(origin, origin + v, color, 1.5)
	draw_line(origin + v, origin + v + h, color, 1.5)


func _draw_vitals_block(size: Vector2, y: float) -> void:
	_draw_text(Vector2(0.0, y), "VITALS", 11, TEXT_DIM)
	var hp_text := "%d / %d" % [int(max(0.0, current_health)), int(max_health)]
	_draw_text_right(Vector2(size.x, y), hp_text, 12, TEXT_BRIGHT)

	var ratio: float = 0.0
	if max_health > 0.0:
		ratio = clampf(current_health / max_health, 0.0, 1.0)
	var color := HEALTH_FILL
	if ratio <= 0.2:
		color = HEALTH_CRIT
	elif ratio <= 0.45:
		color = HEALTH_WARN

	_draw_segmented_bar(Rect2(Vector2(0.0, y + 8.0), Vector2(size.x, 9.0)), ratio, HEALTH_SEGMENTS, color)


func _draw_level_block(size: Vector2, y: float) -> void:
	_draw_text(Vector2(0.0, y), "LVL %d" % level, 14, ACCENT_CYAN)
	var xp_text := "%d / %d XP" % [experience, experience_to_level]
	_draw_text_right(Vector2(size.x, y), xp_text, 11, TEXT_BRIGHT)

	var ratio: float = 0.0
	if experience_to_level > 0:
		ratio = clampf(float(experience) / float(experience_to_level), 0.0, 1.0)
	_draw_segmented_bar(Rect2(Vector2(0.0, y + 10.0), Vector2(size.x, 7.0)), ratio, XP_SEGMENTS, ACCENT_CYAN)


func _draw_stats_row(size: Vector2, y: float) -> void:
	var col_w: float = size.x / 3.0
	_draw_stat_column(Vector2(0.0, y), col_w, "RUN", str(run_score), ACCENT_GOLD)
	_draw_stat_column(Vector2(col_w, y), col_w, "BEST", str(best_score), ACCENT_CYAN)
	_draw_stat_column(Vector2(col_w * 2.0, y), col_w, "CREDITS", str(credits), ACCENT_ORANGE)


func _draw_stat_column(pos: Vector2, _width: float, label: String, value: String, value_color: Color) -> void:
	_draw_text(pos + Vector2(0.0, 10.0), label, 10, TEXT_DIM)
	_draw_text(pos + Vector2(0.0, 28.0), value, 18, value_color)


func _draw_segmented_bar(rect: Rect2, fill: float, segments: int, color: Color) -> void:
	var gap: float = 2.0
	var seg_w: float = (rect.size.x - gap * float(segments - 1)) / float(segments)
	var filled: int = int(round(fill * float(segments)))
	for i in segments:
		var x: float = rect.position.x + float(i) * (seg_w + gap)
		var r := Rect2(Vector2(x, rect.position.y), Vector2(seg_w, rect.size.y))
		if i < filled:
			var pulse: float = 0.0
			if i == filled - 1:
				pulse = 0.5 + 0.5 * sin(_time * 6.0)
			draw_rect(r, color.lerp(Color(1.0, 1.0, 1.0, 1.0), pulse * 0.25), true)
			draw_rect(r, Color(color, 0.5), false, 1.0)
		else:
			draw_rect(r, BAR_DIM, true)
			draw_rect(r, BAR_DIM_BORDER, false, 1.0)


func _draw_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(_font, pos + Vector2(0.0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_text_right(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(_font, Vector2(pos.x - text_size.x, pos.y + font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
