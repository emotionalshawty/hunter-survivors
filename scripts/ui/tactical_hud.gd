extends Control

const ACCENT_CYAN  := Color(0.36, 0.96, 0.89, 1.0)
const ACCENT_ORANGE := Color(1.0, 0.48, 0.24, 1.0)
const ACCENT_GOLD  := Color(1.0, 0.83, 0.38, 1.0)
const TEXT_DIM     := Color(0.62, 0.86, 0.90, 1.0)
const TEXT_BRIGHT  := Color(0.94, 0.98, 0.98, 1.0)
const BAR_BG       := Color(0.05, 0.10, 0.13, 0.85)
const BAR_BORDER   := Color(0.22, 0.50, 0.56, 0.45)
const HEALTH_FILL  := Color(1.0, 0.34, 0.28, 1.0)
const HEALTH_WARN  := Color(1.0, 0.72, 0.22, 1.0)
const HEALTH_CRIT  := Color(1.0, 0.18, 0.18, 1.0)

const HEALTH_SEGMENTS: int = 20
const XP_SEGMENTS:     int = 16

const ROW_PILOT_Y:   float = 0.0    # pilot + status row top
const SEP1_Y:        float = 26.0   # first separator
const VITALS_Y:      float = 36.0   # health label + bar section top
const LEVEL_Y:       float = 76.0   # level label + xp bar section top
const SEP2_Y:        float = 112.0  # second separator
const STATS_Y:       float = 118.0  # stats row top
const PILOT_FONT:    int   = 13
const LABEL_FONT:    int   = 10
const HP_FONT:       int   = 12
const LEVEL_FONT:    int   = 14
const XP_FONT:       int   = 11
const STAT_VAL_FONT: int   = 16
const STAT_LBL_FONT: int   = 10

var pilot_name: String = "anonymous"
var current_health: float = 100.0
var max_health:     float = 100.0
var level: int = 1
var experience: int = 0
var experience_to_level: int = 6
var run_score:  int = 0
var best_score: int = 1
var credits:    int = 0
var status_text:  String = "ONLINE"
var status_color: Color  = ACCENT_CYAN
var game_over:   bool   = false

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
	pilot_name = new_name;  queue_redraw()

func set_health(current: float, maximum: float) -> void:
	current_health = current;  max_health = maximum;  queue_redraw()

func set_level(lvl: int, xp: int, xp_to_level: int) -> void:
	level = lvl;  experience = xp;  experience_to_level = xp_to_level;  queue_redraw()

func set_stats(run: int, best: int, credits_total: int) -> void:
	run_score = run;  best_score = best;  credits = credits_total;  queue_redraw()

func set_status(text: String, color: Color = ACCENT_CYAN) -> void:
	status_text = text;  status_color = color;  queue_redraw()

func show_game_over() -> void:
	game_over = true
	set_status("TERMINATED", Color(1.0, 0.25, 0.25, 1.0))


func _draw() -> void:
	var w := get_size().x

	# --- Row 1: pilot / status ---
	_text(Vector2(0.0, ROW_PILOT_Y + LABEL_FONT), "PILOT", LABEL_FONT, TEXT_DIM)
	_text(Vector2(46.0, ROW_PILOT_Y + PILOT_FONT), pilot_name.to_upper(), PILOT_FONT, TEXT_BRIGHT)

	var blink := 0.5 + 0.5 * sin(_time * 3.2)
	var dot_x := w - 108.0
	draw_rect(Rect2(Vector2(dot_x, ROW_PILOT_Y + 2.0), Vector2(7.0, 7.0)),
		Color(status_color, blink * 0.85 + 0.15), true)
	_text(Vector2(dot_x + 12.0, ROW_PILOT_Y + LABEL_FONT),
		status_text, LABEL_FONT, status_color)

	# --- Separator 1 ---
	_separator(w, SEP1_Y, ACCENT_ORANGE)

	# --- Health ---
	_text(Vector2(0.0, VITALS_Y + LABEL_FONT), "VITALS", LABEL_FONT, TEXT_DIM)
	var hp_text := "%d / %d" % [int(max(0.0, current_health)), int(max_health)]
	_text_right(Vector2(w, VITALS_Y + HP_FONT), hp_text, HP_FONT, TEXT_BRIGHT)

	var ratio := 0.0 if max_health <= 0.0 else clampf(current_health / max_health, 0.0, 1.0)
	var hp_color := HEALTH_CRIT if ratio <= 0.2 else (HEALTH_WARN if ratio <= 0.45 else HEALTH_FILL)
	_segbar(Rect2(Vector2(0.0, VITALS_Y + 16.0), Vector2(w, 9.0)), ratio, HEALTH_SEGMENTS, hp_color)

	# --- Level / XP ---
	_text(Vector2(0.0, LEVEL_Y + LEVEL_FONT), "LVL %d" % level, LEVEL_FONT, ACCENT_CYAN)
	var xp_text := "%d / %d XP" % [experience, experience_to_level]
	_text_right(Vector2(w, LEVEL_Y + XP_FONT), xp_text, XP_FONT, TEXT_BRIGHT)

	var xp_ratio := 0.0 if experience_to_level <= 0 else \
		clampf(float(experience) / float(experience_to_level), 0.0, 1.0)
	_segbar(Rect2(Vector2(0.0, LEVEL_Y + 20.0), Vector2(w, 7.0)), xp_ratio, XP_SEGMENTS, ACCENT_CYAN)

	# --- Separator 2 ---
	_separator(w, SEP2_Y, Color(ACCENT_CYAN, 0.45))

	# --- Stats row ---
	var col := w / 3.0
	_stat_col(Vector2(0.0,       STATS_Y), col, "RUN",     str(run_score),  ACCENT_GOLD)
	_stat_col(Vector2(col,       STATS_Y), col, "BEST",    str(best_score), ACCENT_CYAN)
	_stat_col(Vector2(col * 2.0, STATS_Y), col, "CREDITS", str(credits),    ACCENT_ORANGE)


func _separator(w: float, y: float, color: Color) -> void:
	draw_line(Vector2(12.0, y), Vector2(w - 12.0, y), Color(color, 0.55), 1.0)
	_bracket(Vector2(0.0, y - 4.0), Vector2(10.0, 0.0), Vector2(0.0, 8.0), color)
	_bracket(Vector2(w,   y - 4.0), Vector2(-10.0, 0.0), Vector2(0.0, 8.0), color)


func _bracket(o: Vector2, h: Vector2, v: Vector2, color: Color) -> void:
	draw_line(o, o + h, color, 1.5)
	draw_line(o, o + v, color, 1.5)
	draw_line(o + v, o + v + h, color, 1.5)


func _stat_col(pos: Vector2, _col_w: float, label: String, value: String, val_color: Color) -> void:
	_text(pos + Vector2(0.0, STAT_LBL_FONT),                   label, STAT_LBL_FONT, TEXT_DIM)
	_text(pos + Vector2(0.0, STAT_LBL_FONT + 6 + STAT_VAL_FONT), value, STAT_VAL_FONT, val_color)


func _segbar(rect: Rect2, fill: float, segments: int, color: Color) -> void:
	var gap    := 2.0
	var seg_w  := (rect.size.x - gap * float(segments - 1)) / float(segments)
	var filled := int(round(fill * float(segments)))
	for i in segments:
		var x := rect.position.x + float(i) * (seg_w + gap)
		var r  := Rect2(Vector2(x, rect.position.y), Vector2(seg_w, rect.size.y))
		if i < filled:
			var pulse := 0.0
			if i == filled - 1:
				pulse = 0.5 + 0.5 * sin(_time * 6.0)
			draw_rect(r, color.lerp(Color(1.0, 1.0, 1.0, 1.0), pulse * 0.25), true)
			draw_rect(r, Color(color, 0.5), false, 1.0)
		else:
			draw_rect(r, BAR_BG, true)
			draw_rect(r, BAR_BORDER, false, 1.0)


func _text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _text_right(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(_font, Vector2(pos.x - tw, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
