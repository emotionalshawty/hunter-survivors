extends CharacterBody2D

signal shoot_requested(origin: Vector2, direction: Vector2)

@export var speed: float = 260.0
@export var fire_interval: float = 0.65

var _fire_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle() + PI * 0.5
	move_and_slide()

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		var direction := _get_attack_direction()
		if direction != Vector2.ZERO:
			shoot_requested.emit(global_position, direction)
			_fire_cooldown = fire_interval


func _get_attack_direction() -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.ZERO

	var closest_enemy: Node2D = null
	var best_distance := INF

	for enemy in enemies:
		if not enemy is Node2D:
			continue
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			closest_enemy = enemy

	if closest_enemy == null:
		return Vector2.ZERO

	return (closest_enemy.global_position - global_position).normalized()
