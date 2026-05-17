extends Node2D


const HIT_COLOR := Color(1.0, 0.85, 0.45, 1.0)
const DEATH_COLOR := Color(1.0, 0.55, 0.22, 1.0)
const DEATH_EMBER_COLOR := Color(0.35, 0.88, 1.0, 1.0)
const MUZZLE_COLOR := Color(1.0, 0.92, 0.55, 1.0)
const PICKUP_COLOR := Color(0.45, 0.95, 1.0, 1.0)


func spawn_hit(pos: Vector2, tint: Color = HIT_COLOR) -> void:
	_burst(pos, tint, 7, 0.28, 200.0, 320.0, 1.4, 2.6, 120.0, 180.0)


func spawn_death(pos: Vector2, tint: Color = DEATH_COLOR) -> void:
	_burst(pos, tint, 20, 0.55, 240.0, 430.0, 1.8, 3.4, 90.0, 160.0)
	_burst(pos, DEATH_EMBER_COLOR, 9, 0.75, 80.0, 180.0, 1.0, 2.0, 30.0, 60.0)


func spawn_muzzle_flash(pos: Vector2, direction: Vector2, tint: Color = MUZZLE_COLOR) -> void:
	var p := CPUParticles2D.new()
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 5
	p.lifetime = 0.16
	p.direction = direction
	p.spread = 18.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 320.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.6
	p.color = tint
	p.gravity = Vector2.ZERO
	p.damping_min = 220.0
	p.damping_max = 320.0
	p.emitting = true
	add_child(p)
	_queue_free_after(p, 0.5)


func spawn_pickup_absorb(pos: Vector2, tint: Color = PICKUP_COLOR) -> void:
	_burst(pos, tint, 5, 0.35, 80.0, 140.0, 1.0, 1.8, 60.0, 100.0)


func spawn_player_hit(pos: Vector2) -> void:
	_burst(pos, Color(1.0, 0.35, 0.35, 1.0), 11, 0.35, 120.0, 260.0, 1.4, 2.6, 80.0, 140.0)


func _burst(
	pos: Vector2,
	tint: Color,
	amount: int,
	lifetime: float,
	vel_min: float,
	vel_max: float,
	scale_min: float,
	scale_max: float,
	damp_min: float,
	damp_max: float
) -> void:
	var p := CPUParticles2D.new()
	p.global_position = pos
	p.one_shot = true
	p.explosiveness = 0.98
	p.amount = amount
	p.lifetime = lifetime
	p.spread = 180.0
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.color = tint
	p.gravity = Vector2.ZERO
	p.damping_min = damp_min
	p.damping_max = damp_max
	p.emitting = true
	add_child(p)
	_queue_free_after(p, lifetime + 0.25)


func _queue_free_after(node: Node, seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(node):
			node.queue_free()
	)
