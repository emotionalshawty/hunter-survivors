extends Camera2D



@export var trauma_power: float = 2.0
@export var max_offset: Vector2 = Vector2(18.0, 14.0)
@export var max_roll: float = 0.04
@export var decay_rate: float = 1.8

var _trauma: float = 0.0


func _ready() -> void:
	add_to_group("camera_shake")


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	_trauma = maxf(_trauma - decay_rate * delta, 0.0)
	var shake := pow(_trauma, trauma_power)
	offset = Vector2(
		max_offset.x * shake * randf_range(-1.0, 1.0),
		max_offset.y * shake * randf_range(-1.0, 1.0)
	)
	rotation = max_roll * shake * randf_range(-1.0, 1.0)
