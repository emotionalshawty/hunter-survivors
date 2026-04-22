extends Area2D

@export var speed: float = 560.0
@export var damage: float = 1.0
@export var lifetime: float = 2.0
@export var pierce_count: int = 1

var direction: Vector2 = Vector2.ZERO
var _remaining_pierce: int = 1
var _hit_targets: Dictionary = {}

func _ready() -> void:
	rotation = direction.angle() + PI * 0.5
	_remaining_pierce = max(1, pierce_count)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position += direction * speed * delta
	rotation += delta * 10.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("can_be_hit_by_projectile") and not body.can_be_hit_by_projectile():
		return

	var body_id := body.get_instance_id()
	if _hit_targets.has(body_id):
		return
	_hit_targets[body_id] = true
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position, "projectile")
		_remaining_pierce -= 1
		if _remaining_pierce <= 0:
			queue_free()
