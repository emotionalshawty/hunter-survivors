extends Area2D

@export var speed: float = 560.0
@export var damage: float = 1.0
@export var lifetime: float = 2.0
@export var pierce_count: int = 1

var direction: Vector2 = Vector2.ZERO
var _remaining_pierce: int = 1
var _hit_targets: Dictionary = {}


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	reset_for_acquire()


func reset_for_acquire() -> void:
	rotation = direction.angle() + PI * 0.5
	_remaining_pierce = max(1, pierce_count)
	_hit_targets.clear()


func _process(delta: float) -> void:
	position += direction * speed * delta
	rotation += delta * 10.0
	lifetime -= delta
	if lifetime <= 0.0:
		_release()


func _on_body_entered(body: Node) -> void:
	if body.has_method("can_be_hit_by_projectile") and not body.can_be_hit_by_projectile():
		return

	var body_id: int = body.get_instance_id()
	if _hit_targets.has(body_id):
		return
	_hit_targets[body_id] = true
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position, "projectile")
		_remaining_pierce -= 1
		if _remaining_pierce <= 0:
			_release()


func _release() -> void:
	if has_meta("pool"):
		var pool: Variant = get_meta("pool")
		if pool != null and pool.has_method("release"):
			pool.release(self)
			return
	queue_free()
