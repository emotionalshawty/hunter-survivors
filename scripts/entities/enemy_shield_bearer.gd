extends "res://scripts/entities/enemy.gd"

const FRONT_BLOCK_DOT: float = 0.96
const BLOCK_FLASH_DURATION: float = 0.16
const SHIELD_ARC_RADIUS: float = 19.0
const SHIELD_HALF_ARC: float = 0.92

const BODY_BASE_COLOR := Color(0.19, 0.54, 0.66, 1.0)
const BODY_FLASH_COLOR := Color(0.44, 0.88, 0.98, 1.0)
const EYE_COLOR := Color(0.99, 0.83, 0.43, 1.0)

var _block_flash_timer: float = 0.0

@onready var _body: Polygon2D = $Body
@onready var _eye: Polygon2D = $Eye


func _ready() -> void:
	super._ready()
	set_process(true)
	if _body != null:
		_body.color = BODY_BASE_COLOR
	if _eye != null:
		_eye.color = EYE_COLOR


func _process(delta: float) -> void:
	if _block_flash_timer <= 0.0:
		if _body != null and _body.color != BODY_BASE_COLOR:
			_body.color = BODY_BASE_COLOR
		return

	_block_flash_timer = maxf(0.0, _block_flash_timer - delta)
	if _body != null:
		_body.color = BODY_FLASH_COLOR
	queue_redraw()


func _can_receive_damage(_amount: float, source_position: Vector2, damage_kind: String) -> bool:
	if damage_kind != "projectile":
		return true
	if source_position == Vector2.INF:
		return true

	var incoming: Vector2 = global_position - source_position
	if incoming.length_squared() <= 0.0001:
		return true
	incoming = incoming.normalized()

	if incoming.dot(get_forward_vector()) >= FRONT_BLOCK_DOT:
		_trigger_block_feedback()
		return false
	return true


func _draw() -> void:
	super._draw()
	var flash_factor: float = 0.0
	if _block_flash_timer > 0.0:
		flash_factor = _block_flash_timer / BLOCK_FLASH_DURATION
	var shield_color := Color(0.35, 0.93, 0.99, 0.42 + flash_factor * 0.4)
	var center_angle: float = -PI * 0.5
	draw_arc(Vector2.ZERO, SHIELD_ARC_RADIUS, center_angle - SHIELD_HALF_ARC, center_angle + SHIELD_HALF_ARC, 20, shield_color, 3.0, true)


func _trigger_block_feedback() -> void:
	_block_flash_timer = BLOCK_FLASH_DURATION
	queue_redraw()
