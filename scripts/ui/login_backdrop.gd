extends Control

# Animated Marathon-style terminal backdrop for the login screen.
# Draws: grid, drifting scan-band, orbital rings, corner brackets,
#         top terminal ID bar, boot log, system clock.

const ACCENT_CYAN := Color(0.36, 0.96, 0.89, 0.9)
const ACCENT_ORANGE := Color(1.0, 0.48, 0.24, 0.9)
const GRID_COLOR := Color(0.22, 0.55, 0.58, 0.22)
const TEXT_DIM := Color(0.55, 0.78, 0.82, 0.72)

const BOOT_LOG: Array[String] = [
	"> NETWORK HANDSHAKE .... OK",
	"> BIOMETRIC PROFILE .... OK",
	"> LOCAL CACHE .......... READY",
	"> AWAITING OPERATOR INPUT",
]

var _time: float = 0.0
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var size := get_size()
	_draw_grid(size)
	_draw_scan_band(size)
	_draw_rings(size)
	_draw_corner_brackets(size)
	_draw_top_bar(size)
	_draw_boot_log(size)
	_draw_system_clock(size)


func _draw_grid(size: Vector2) -> void:
	var spacing: float = 56.0
	var offset: float = fmod(_time * 12.0, spacing)
	var y: float = -spacing
	while y <= size.y + spacing:
		draw_line(Vector2(0.0, y + offset), Vector2(size.x, y + offset), GRID_COLOR, 1.0)
		y += spacing
	var x: float = 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(GRID_COLOR.r, GRID_COLOR.g, GRID_COLOR.b, 0.14), 1.0)
		x += spacing


func _draw_scan_band(size: Vector2) -> void:
	var band_y: float = fmod(_time * 80.0, size.y + 180.0) - 90.0
	draw_rect(Rect2(Vector2(0.0, band_y), Vector2(size.x, 48.0)), Color(ACCENT_CYAN, 0.04), true)
	draw_rect(Rect2(Vector2(0.0, band_y + 18.0), Vector2(size.x, 6.0)), Color(ACCENT_ORANGE, 0.06), true)


func _draw_rings(size: Vector2) -> void:
	var pulse: float = 20.0 + sin(_time * 1.5) * 6.0
	draw_arc(Vector2(size.x * 0.14, size.y * 0.22), 190.0 + pulse, 0.0, TAU, 96, Color(ACCENT_ORANGE, 0.18), 2.0)
	draw_arc(Vector2(size.x * 0.86, size.y * 0.8), 240.0 + pulse * 0.8, 0.0, TAU, 96, Color(ACCENT_CYAN, 0.14), 2.0)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.5), 320.0 + pulse * 0.5, 0.0, TAU, 128, Color(ACCENT_CYAN, 0.06), 1.5)


func _draw_corner_brackets(size: Vector2) -> void:
	var inset: float = 40.0
	var length: float = 60.0
	_corner(Vector2(inset, inset), Vector2(length, 0.0), Vector2(0.0, length), ACCENT_ORANGE)
	_corner(Vector2(size.x - inset, inset), Vector2(-length, 0.0), Vector2(0.0, length), ACCENT_ORANGE)
	_corner(Vector2(inset, size.y - inset), Vector2(length, 0.0), Vector2(0.0, -length), ACCENT_ORANGE)
	_corner(Vector2(size.x - inset, size.y - inset), Vector2(-length, 0.0), Vector2(0.0, -length), ACCENT_ORANGE)


func _corner(origin: Vector2, h: Vector2, v: Vector2, color: Color) -> void:
	draw_line(origin, origin + h, color, 2.5)
	draw_line(origin, origin + v, color, 2.5)


func _draw_top_bar(size: Vector2) -> void:
	draw_rect(Rect2(Vector2(52.0, 22.0), Vector2(260.0, 20.0)), Color(ACCENT_ORANGE, 0.9), true)
	draw_string(_font, Vector2(60.0, 37.0), "TERMINAL ID · 0xA47E-9C", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.05, 0.04, 0.06, 1.0))

	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
	draw_rect(Rect2(Vector2(size.x - 240.0, 28.0), Vector2(8.0, 8.0)), Color(ACCENT_CYAN, 0.2 + 0.8 * pulse), true)
	draw_string(_font, Vector2(size.x - 224.0, 37.0), "SECURE CHANNEL · ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, ACCENT_CYAN)


func _draw_boot_log(size: Vector2) -> void:
	var base_y: float = size.y - 110.0
	for i in BOOT_LOG.size():
		var alpha: float = 0.35 + 0.35 * sin(_time * 1.5 + float(i) * 0.7)
		draw_string(_font, Vector2(52.0, base_y + float(i) * 18.0), BOOT_LOG[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, alpha))


func _draw_system_clock(size: Vector2) -> void:
	var t: int = int(_time)
	var clock: String = "SYS TIME · %02d:%02d:%02d" % [(t / 3600) % 24, (t / 60) % 60, t % 60]
	draw_string(_font, Vector2(size.x - 260.0, size.y - 42.0), clock, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, TEXT_DIM)
	draw_string(_font, Vector2(size.x - 260.0, size.y - 62.0), "OP · HUNTERSURV / HUV", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, 0.55))
