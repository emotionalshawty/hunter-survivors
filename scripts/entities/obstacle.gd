extends StaticBody2D

enum ShapeType { BLOCK, HEX, CRYSTAL }

const FILL   := Color(0.03, 0.07, 0.11, 0.88)
const EDGE   := Color(0.36, 0.96, 0.89, 0.65)
const DIM    := Color(0.36, 0.96, 0.89, 0.18)
const ORANGE := Color(1.0, 0.45, 0.25, 0.45)

var shape_type: ShapeType = ShapeType.BLOCK
var half_size: float = 26.0


func setup(type: ShapeType, sz: float) -> void:
	shape_type = type
	half_size = sz
	_build_collision()
	queue_redraw()


func _build_collision() -> void:
	var col := CollisionShape2D.new()
	match shape_type:
		ShapeType.BLOCK:
			var r := RectangleShape2D.new()
			r.size = Vector2(half_size * 2.0, half_size * 2.0)
			col.shape = r
		ShapeType.HEX, ShapeType.CRYSTAL:
			var poly := ConvexPolygonShape2D.new()
			poly.points = _verts()
			col.shape = poly
	add_child(col)


func _verts() -> PackedVector2Array:
	var pts := PackedVector2Array()
	if shape_type == ShapeType.HEX:
		for i in 6:
			var a := (PI / 3.0) * i - PI / 6.0
			pts.append(Vector2(cos(a), sin(a)) * half_size)
	else: # CRYSTAL — tall diamond
		pts = PackedVector2Array([
			Vector2(0.0, -half_size * 1.4),
			Vector2(half_size * 0.75, -half_size * 0.25),
			Vector2(half_size * 0.55, half_size * 0.9),
			Vector2(0.0, half_size * 1.4),
			Vector2(-half_size * 0.55, half_size * 0.9),
			Vector2(-half_size * 0.75, -half_size * 0.25),
		])
	return pts


func _draw() -> void:
	match shape_type:
		ShapeType.BLOCK:   _draw_block()
		ShapeType.HEX:     _draw_poly(_verts())
		ShapeType.CRYSTAL: _draw_poly(_verts())


func _draw_block() -> void:
	var h := half_size
	var rect := Rect2(Vector2(-h, -h), Vector2(h * 2.0, h * 2.0))
	draw_rect(rect, FILL, true)
	draw_rect(rect, EDGE, false, 1.5)
	var m := 5.0
	var c := 8.0
	# corner crosshair marks
	_draw_crosshair(Vector2(-h + m, -h + m), c)
	_draw_crosshair(Vector2( h - m, -h + m), c)
	_draw_crosshair(Vector2( h - m,  h - m), c)
	_draw_crosshair(Vector2(-h + m,  h - m), c)
	# center cross
	draw_line(Vector2(-h * 0.3, 0.0), Vector2(h * 0.3, 0.0), DIM, 0.5)
	draw_line(Vector2(0.0, -h * 0.3), Vector2(0.0, h * 0.3), DIM, 0.5)


func _draw_crosshair(pos: Vector2, size: float) -> void:
	draw_line(pos + Vector2(-size, 0.0), pos + Vector2(size, 0.0), DIM, 1.0)
	draw_line(pos + Vector2(0.0, -size), pos + Vector2(0.0, size), DIM, 1.0)


func _draw_poly(pts: PackedVector2Array) -> void:
	draw_colored_polygon(pts, FILL)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, EDGE, 1.5)
	# center dot
	draw_circle(Vector2.ZERO, 2.5, Color(ORANGE, 0.9))
	# inner ring
	draw_arc(Vector2.ZERO, half_size * 0.45, 0.0, TAU, 24, DIM, 0.5)
