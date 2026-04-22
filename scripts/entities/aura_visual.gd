extends Node2D

const BASE_COLOR := Color(1.0, 0.9, 0.22, 0.22)
const EDGE_COLOR := Color(1.0, 0.95, 0.45, 0.85)

var _radius: float = 95.0
var _enabled: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	visible = false
	set_process(true)


func _process(delta: float) -> void:
	if not _enabled:
		return
	_pulse_time += delta
	queue_redraw()


func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value
	if value:
		queue_redraw()


func set_radius(value: float) -> void:
	_radius = max(8.0, value)
	if _enabled:
		queue_redraw()


func _draw() -> void:
	if not _enabled:
		return

	var pulse := 4.0 + sin(_pulse_time * 4.0) * 2.0
	draw_circle(Vector2.ZERO, _radius - pulse, BASE_COLOR)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, EDGE_COLOR, 3.0, true)
