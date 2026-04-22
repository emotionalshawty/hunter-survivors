extends "res://scripts/entities/enemy.gd"

const INVULNERABLE_DURATION: float = 1.5
const VULNERABLE_DURATION_MIN: float = 2.2
const VULNERABLE_DURATION_MAX: float = 3.2

const BODY_BASE_COLOR := Color(0.66, 0.75, 0.96, 1.0)
const EYE_BASE_COLOR := Color(1.0, 0.94, 0.69, 1.0)

var _invulnerable: bool = false
var _phase_timer: float = 0.0

@onready var _body: Polygon2D = $Body
@onready var _eye: Polygon2D = $Eye


func _ready() -> void:
	super._ready()
	set_process(true)
	_phase_timer = randf_range(VULNERABLE_DURATION_MIN * 0.5, VULNERABLE_DURATION_MAX)
	_apply_visual_state()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_toggle_phase()


func _process(_delta: float) -> void:
	if not _invulnerable:
		if modulate != Color(1, 1, 1, 1):
			modulate = Color(1, 1, 1, 1)
		return

	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.02)
	modulate = Color(0.72 + pulse * 0.16, 0.84 + pulse * 0.1, 1.0, 0.42 + pulse * 0.2)
	queue_redraw()


func can_be_hit_by_projectile() -> bool:
	return not _invulnerable


func _can_receive_damage(_amount: float, _source_position: Vector2, _damage_kind: String) -> bool:
	return not _invulnerable


func _draw() -> void:
	super._draw()
	if not _invulnerable:
		return
	var ring_color := Color(0.56, 0.88, 1.0, 0.58)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 28, ring_color, 2.0, true)


func _toggle_phase() -> void:
	_invulnerable = not _invulnerable
	_phase_timer = INVULNERABLE_DURATION if _invulnerable else randf_range(VULNERABLE_DURATION_MIN, VULNERABLE_DURATION_MAX)
	_apply_visual_state()
	queue_redraw()


func _apply_visual_state() -> void:
	if _body != null:
		_body.color = BODY_BASE_COLOR
	if _eye != null:
		_eye.color = EYE_BASE_COLOR
	if not _invulnerable:
		modulate = Color(1, 1, 1, 1)
