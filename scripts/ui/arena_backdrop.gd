extends Node2D

const BG_COLOR := Color(0.04, 0.09, 0.11, 1.0)
const GRID_COLOR := Color(0.16, 0.42, 0.42, 0.34)
const ACCENT_CYAN := Color(0.36, 0.96, 0.89, 0.95)
const ACCENT_ORANGE := Color(1.0, 0.43, 0.29, 0.9)
const ACCENT_GOLD := Color(1.0, 0.83, 0.38, 0.9)
const SHADOW_COLOR := Color(0.02, 0.04, 0.05, 0.68)

var _time: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := get_viewport_rect()
	var size := rect.size
	var center := size * 0.5

	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR, true)
	_draw_grid(size)
	_draw_scanlines(size)
	_draw_rings(center)
	_draw_accent_bars(size)
	_draw_target_frame(size)


func _draw_grid(size: Vector2) -> void:
	var spacing := 48.0
	var offset := fmod(_time * 18.0, spacing)
	var x := -spacing
	while x <= size.x + spacing:
		draw_line(Vector2(x + offset, 0.0), Vector2(x + offset + 120.0, size.y), GRID_COLOR, 1.0)
		x += spacing

	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(GRID_COLOR, 0.16), 1.0)
		y += spacing


func _draw_scanlines(size: Vector2) -> void:
	var band_y := fmod(_time * 90.0, size.y + 180.0) - 90.0
	draw_rect(Rect2(Vector2(-40.0, band_y), Vector2(size.x + 80.0, 56.0)), Color(ACCENT_CYAN, 0.05), true)
	draw_rect(Rect2(Vector2(-40.0, band_y + 20.0), Vector2(size.x + 80.0, 10.0)), Color(ACCENT_GOLD, 0.08), true)


func _draw_rings(center: Vector2) -> void:
	for radius in [110.0, 170.0, 250.0, 360.0]:
		draw_arc(center, radius, -PI * 0.1, PI * 1.25, 72, Color(ACCENT_CYAN, 0.2), 2.0)

	var pulse := 32.0 + sin(_time * 1.7) * 8.0
	draw_arc(center + Vector2(-220.0, -120.0), 84.0 + pulse, PI * 0.05, PI * 0.8, 48, Color(ACCENT_ORANGE, 0.34), 3.0)
	draw_arc(center + Vector2(260.0, 140.0), 74.0 + pulse * 0.7, PI * 1.1, PI * 1.9, 48, Color(ACCENT_GOLD, 0.28), 3.0)


func _draw_accent_bars(size: Vector2) -> void:
	var top_bar := PackedVector2Array([
		Vector2(42.0, 30.0),
		Vector2(246.0, 30.0),
		Vector2(214.0, 56.0),
		Vector2(10.0, 56.0)
	])
	draw_colored_polygon(top_bar, Color(ACCENT_ORANGE, 0.95))

	var cyan_bar := PackedVector2Array([
		Vector2(size.x - 290.0, size.y - 78.0),
		Vector2(size.x - 32.0, size.y - 78.0),
		Vector2(size.x - 4.0, size.y - 44.0),
		Vector2(size.x - 262.0, size.y - 44.0)
	])
	draw_colored_polygon(cyan_bar, Color(ACCENT_CYAN, 0.85))

	var shadow_bar := PackedVector2Array([
		Vector2(size.x - 240.0, 36.0),
		Vector2(size.x - 68.0, 36.0),
		Vector2(size.x - 20.0, 88.0),
		Vector2(size.x - 192.0, 88.0)
	])
	draw_colored_polygon(shadow_bar, SHADOW_COLOR)


func _draw_target_frame(size: Vector2) -> void:
	var rect := Rect2(Vector2(24.0, 24.0), size - Vector2(48.0, 48.0))
	var corners := [
		[rect.position, rect.position + Vector2(70.0, 0.0), rect.position + Vector2(0.0, 70.0)],
		[Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - 70.0, rect.position.y), Vector2(rect.end.x, rect.position.y + 70.0)],
		[Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + 70.0, rect.end.y), Vector2(rect.position.x, rect.end.y - 70.0)],
		[rect.end, rect.end - Vector2(70.0, 0.0), rect.end - Vector2(0.0, 70.0)]
	]

	for corner in corners:
		draw_line(corner[0], corner[1], Color(ACCENT_CYAN, 0.6), 3.0)
		draw_line(corner[0], corner[2], Color(ACCENT_CYAN, 0.6), 3.0)