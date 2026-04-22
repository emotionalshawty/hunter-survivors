extends Node2D

const MAIN_COLOR := Color(0.55, 0.9, 1.0, 0.95)
const GLOW_COLOR := Color(0.75, 0.97, 1.0, 0.35)
const SEGMENTS_PER_BOLT: int = 10
const JITTER: float = 9.0

var _active: bool = false
var _path_global: Array[Vector2] = []
var _time: float = 0.0


func _ready() -> void:
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	queue_redraw()


func set_chain_points(path_points: Array[Vector2], enabled: bool) -> void:
	_path_global = path_points.duplicate()
	_active = enabled
	visible = enabled
	if enabled:
		queue_redraw()


func set_target_global_position(target_global: Vector2, enabled: bool) -> void:
	if enabled:
		set_chain_points([Vector2.ZERO, target_global], true)
		return
	set_chain_points([], false)


func set_active(enabled: bool) -> void:
	_active = enabled
	visible = enabled
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	if _path_global.size() < 2:
		return

	for segment_index in range(_path_global.size() - 1):
		_draw_bolt_segment(to_local(_path_global[segment_index]), to_local(_path_global[segment_index + 1]), float(segment_index))


func _draw_bolt_segment(start_local: Vector2, end_local: Vector2, segment_index: float) -> void:
	var segment_delta: Vector2 = end_local - start_local
	if segment_delta.length() <= 1.0:
		return

	var perp: Vector2 = Vector2(-segment_delta.y, segment_delta.x).normalized()
	var points := PackedVector2Array()
	points.append(start_local)
	for i in range(1, SEGMENTS_PER_BOLT):
		var t: float = float(i) / float(SEGMENTS_PER_BOLT)
		var p: Vector2 = start_local.lerp(end_local, t)
		var wave: float = sin((_time * 18.0) + (segment_index * 2.7) + (t * 22.0))
		var taper: float = 1.0 - absf(t - 0.5) * 1.6
		points.append(p + (perp * wave * JITTER * taper))
	points.append(end_local)

	draw_polyline(points, GLOW_COLOR, 6.0, true)
	draw_polyline(points, MAIN_COLOR, 2.0, true)
