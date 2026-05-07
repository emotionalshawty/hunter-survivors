extends Area2D

@export var speed: float = 560.0
@export var damage: float = 1.0
@export var lifetime: float = 2.0
@export var pierce_count: int = 1

# Explosive (rockets) — does AoE damage in radius on impact or expiry.
@export var explode_on_hit: bool = false
@export var explode_radius: float = 0.0
@export var explode_damage: float = 0.0

# Boomerang — flips direction toward player after a delay, allowing a second pass.
@export var boomerang_returns: bool = false
@export var boomerang_return_time: float = 0.7

# Orbit — projectile orbits an owner node at a fixed radius. Lifetime ignored.
@export var orbit_active: bool = false
@export var orbit_radius: float = 78.0
@export var orbit_angle: float = 0.0
@export var orbit_angular_speed: float = 2.4
@export var orbit_damage_interval: float = 0.18

var direction: Vector2 = Vector2.ZERO
var orbit_owner: Node2D = null

var _remaining_pierce: int = 1
var _hit_targets: Dictionary = {}
var _initial_lifetime: float = 0.0
var _has_returned: bool = false
var _orbit_damage_cooldowns: Dictionary = {}


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	reset_for_acquire()


func reset_for_acquire() -> void:
	rotation = direction.angle() + PI * 0.5
	_remaining_pierce = max(1, pierce_count)
	_hit_targets.clear()
	_initial_lifetime = lifetime
	_has_returned = false
	_orbit_damage_cooldowns.clear()


func _process(delta: float) -> void:
	if orbit_active:
		_process_orbit(delta)
		return

	position += direction * speed * delta
	rotation += delta * 10.0
	lifetime -= delta

	if boomerang_returns and not _has_returned and (_initial_lifetime - lifetime) >= boomerang_return_time:
		_flip_toward_player()

	if lifetime <= 0.0:
		if explode_on_hit and explode_radius > 0.0:
			_apply_explosion()
		_release()


func _process_orbit(delta: float) -> void:
	if orbit_owner == null or not is_instance_valid(orbit_owner):
		_release()
		return
	orbit_angle += orbit_angular_speed * delta
	global_position = orbit_owner.global_position + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius
	rotation += delta * 6.0
	# Cooldown ageing for orbit damage targets.
	if not _orbit_damage_cooldowns.is_empty():
		var expired: Array = []
		for target_id in _orbit_damage_cooldowns.keys():
			_orbit_damage_cooldowns[target_id] -= delta
			if _orbit_damage_cooldowns[target_id] <= 0.0:
				expired.append(target_id)
		for target_id in expired:
			_orbit_damage_cooldowns.erase(target_id)


func _on_body_entered(body: Node) -> void:
	if body.has_method("can_be_hit_by_projectile") and not body.can_be_hit_by_projectile():
		return

	var body_id: int = body.get_instance_id()

	if orbit_active:
		# Orbit drones tick-damage on contact instead of single-pierce.
		if _orbit_damage_cooldowns.has(body_id):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position, "orbit")
			_orbit_damage_cooldowns[body_id] = orbit_damage_interval
		return

	if _hit_targets.has(body_id):
		return
	_hit_targets[body_id] = true

	if body.has_method("take_damage"):
		body.take_damage(damage, global_position, "projectile")
		_remaining_pierce -= 1
		if _remaining_pierce <= 0:
			if explode_on_hit and explode_radius > 0.0:
				_apply_explosion()
			_release()


func _flip_toward_player() -> void:
	_has_returned = true
	_hit_targets.clear()
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		direction = -direction
	else:
		var p: Node = players[0]
		if p is Node2D:
			direction = ((p as Node2D).global_position - global_position).normalized()
		else:
			direction = -direction
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	rotation = direction.angle() + PI * 0.5


func _apply_explosion() -> void:
	if explode_radius <= 0.0 or explode_damage <= 0.0:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var radius_sq: float = explode_radius * explode_radius
	for enemy in enemies:
		if not (enemy is Node2D):
			continue
		var n: Node2D = enemy
		if n.global_position.distance_squared_to(global_position) > radius_sq:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(explode_damage, global_position, "explosion")


func _release() -> void:
	if has_meta("pool"):
		var pool: Variant = get_meta("pool")
		if pool != null and pool.has_method("release"):
			pool.release(self)
			return
	queue_free()
