extends "res://scripts/entities/enemy.gd"

const STATE_IDLE: int = 0
const STATE_TELEGRAPH: int = 1
const STATE_DASH: int = 2
const STATE_RECOVER: int = 3

const BODY_BASE_COLOR := Color(0.98, 0.42, 0.26, 1.0)
const BODY_CHARGE_COLOR := Color(1.0, 0.94, 0.55, 1.0)
const EYE_BASE_COLOR := Color(1.0, 0.86, 0.46, 1.0)
const EYE_CHARGE_COLOR := Color(1.0, 0.99, 0.85, 1.0)

@export var idle_wait_min: float = 1.1
@export var idle_wait_max: float = 1.9
@export var telegraph_duration: float = 0.42
@export var dash_duration: float = 0.28
@export var recover_duration: float = 0.42
@export var dash_speed: float = 620.0

var _state: int = STATE_IDLE
var _state_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.RIGHT

@onready var _body: Polygon2D = $Body
@onready var _eye: Polygon2D = $Eye


func _ready() -> void:
	super._ready()
	_enter_idle_state()
	_apply_base_colors()


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return

	var to_target: Vector2 = (_target.global_position - global_position).normalized()
	_state_timer -= delta

	match _state:
		STATE_IDLE:
			velocity = _compute_separation_force() * 0.55
			rotation = to_target.angle() + PI * 0.5
			move_and_slide()
			if _state_timer <= 0.0:
				_enter_telegraph_state(to_target)
		STATE_TELEGRAPH:
			velocity = Vector2.ZERO
			rotation = to_target.angle() + PI * 0.5
			move_and_slide()
			if _state_timer <= 0.0:
				_enter_dash_state(to_target)
		STATE_DASH:
			velocity = (_dash_direction * dash_speed) + (_compute_separation_force() * 0.25)
			rotation = _dash_direction.angle() + PI * 0.5
			move_and_slide()
			if _state_timer <= 0.0:
				_enter_recover_state()
		STATE_RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, dash_speed * delta * 3.8)
			move_and_slide()
			if _state_timer <= 0.0:
				_enter_idle_state()

	_update_visual_state()


func _enter_idle_state() -> void:
	_state = STATE_IDLE
	_state_timer = randf_range(idle_wait_min, idle_wait_max)


func _enter_telegraph_state(to_target: Vector2) -> void:
	_state = STATE_TELEGRAPH
	_state_timer = telegraph_duration
	_dash_direction = to_target


func _enter_dash_state(to_target: Vector2) -> void:
	_state = STATE_DASH
	_state_timer = dash_duration
	if to_target.length_squared() > 0.001:
		_dash_direction = to_target


func _enter_recover_state() -> void:
	_state = STATE_RECOVER
	_state_timer = recover_duration


func _update_visual_state() -> void:
	if _body == null or _eye == null:
		return
	if _state == STATE_TELEGRAPH:
		var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.032)
		_body.color = BODY_BASE_COLOR.lerp(BODY_CHARGE_COLOR, 0.55 + pulse * 0.45)
		_eye.color = EYE_BASE_COLOR.lerp(EYE_CHARGE_COLOR, 0.55 + pulse * 0.45)
		return
	if _state == STATE_DASH:
		_body.color = BODY_CHARGE_COLOR
		_eye.color = EYE_CHARGE_COLOR
		return
	_apply_base_colors()


func _apply_base_colors() -> void:
	if _body != null:
		_body.color = BODY_BASE_COLOR
	if _eye != null:
		_eye.color = EYE_BASE_COLOR
