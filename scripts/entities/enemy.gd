extends CharacterBody2D

signal defeated(xp: int, world_position: Vector2)
signal damaged(world_position: Vector2, damage_kind: String)

const HEALTH_BAR_BG := Color(0.12, 0.09, 0.09, 0.85)
const HEALTH_BAR_FILL := Color(0.96, 0.25, 0.27, 0.95)
const HEALTH_BAR_BORDER := Color(0.98, 0.85, 0.72, 0.9)
const HEALTH_BAR_WIDTH: float = 24.0
const HEALTH_BAR_HEIGHT: float = 4.0
const HEALTH_BAR_Y_OFFSET: float = -24.0

@export var move_speed: float = 90.0
@export var max_health: float = 3.0
@export var contact_damage: float = 8.0
@export var xp_reward: int = 1
@export var separation_radius: float = 34.0
@export var separation_strength: float = 160.0
@export var max_separation_neighbors: int = 8

var _health: float
var _target: Node2D
var _spawn_speed_scale: float = 1.0
var _spawn_health_scale: float = 1.0

static var _cached_enemies: Array = []
static var _last_cache_frame: int = -1000
const CACHE_REFRESH_FRAMES: int = 6

func _ready() -> void:
	_health = max_health
	add_to_group("enemies")
	queue_redraw()


func set_target(target: Node2D) -> void:
	_target = target


func apply_spawn_scalars(speed_scale: float, health_scale: float) -> void:
	_spawn_speed_scale = maxf(0.01, speed_scale)
	_spawn_health_scale = maxf(0.01, health_scale)
	move_speed *= _spawn_speed_scale
	max_health *= _spawn_health_scale


func get_spawn_speed_scale() -> float:
	return _spawn_speed_scale


func get_spawn_health_scale() -> float:
	return _spawn_health_scale


func get_forward_vector() -> Vector2:
	return Vector2.UP.rotated(rotation).normalized()


func can_be_hit_by_projectile() -> bool:
	return true


func copy_defeat_connections_to(other_enemy: Node) -> void:
	if other_enemy == null or not other_enemy.has_signal("defeated"):
		return
	for connection in get_signal_connection_list("defeated"):
		var callback: Callable = connection.get("callable", Callable())
		if callback.is_valid():
			other_enemy.connect("defeated", callback)


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return

	var direction := (_target.global_position - global_position).normalized()
	var separation := _compute_separation_force()
	velocity = (direction * move_speed) + separation
	velocity = velocity.limit_length(move_speed * 1.2)
	rotation = direction.angle() + PI * 0.5
	move_and_slide()


func _compute_separation_force() -> Vector2:
	var enemies := _get_cached_enemies()
	var accumulated := Vector2.ZERO
	var neighbors := 0
	var min_distance_squared: float = separation_radius * separation_radius

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == self:
			continue
		if not (enemy is CharacterBody2D):
			continue

		var offset: Vector2 = global_position - enemy.global_position
		var distance_squared: float = offset.length_squared()
		if distance_squared <= 0.0001 or distance_squared > min_distance_squared:
			continue

		var distance := sqrt(distance_squared)
		var weight := (separation_radius - distance) / separation_radius
		accumulated += offset.normalized() * weight
		neighbors += 1
		if neighbors >= max_separation_neighbors:
			break

	if neighbors == 0:
		return Vector2.ZERO

	return (accumulated / float(neighbors)) * separation_strength


func _get_cached_enemies() -> Array:
	var current_frame: int = Engine.get_process_frames()
	if _cached_enemies.is_empty() or current_frame - _last_cache_frame >= CACHE_REFRESH_FRAMES:
		var group_enemies := get_tree().get_nodes_in_group("enemies")
		_cached_enemies = []
		for enemy in group_enemies:
			if is_instance_valid(enemy):
				_cached_enemies.append(enemy)
		_last_cache_frame = current_frame
	return _cached_enemies


func take_damage(amount: float, source_position: Vector2 = Vector2.INF, damage_kind: String = "generic") -> void:
	if amount <= 0.0:
		return
	if not _can_receive_damage(amount, source_position, damage_kind):
		return
	_health -= amount
	queue_redraw()
	if _health > 0.0:
		damaged.emit(global_position, damage_kind)
		return
	defeated.emit(xp_reward, global_position)
	queue_free()


func _can_receive_damage(_amount: float, _source_position: Vector2, _damage_kind: String) -> bool:
	return true


func _draw() -> void:
	if max_health <= 0.0:
		return

	var health_ratio: float = clampf(_health / max_health, 0.0, 1.0)
	var top_left := Vector2(-HEALTH_BAR_WIDTH * 0.5, HEALTH_BAR_Y_OFFSET)
	var bar_size := Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	var bar_rect := Rect2(top_left, bar_size)

	draw_rect(bar_rect, HEALTH_BAR_BG, true)
	if health_ratio > 0.0:
		var fill_rect := Rect2(top_left, Vector2(HEALTH_BAR_WIDTH * health_ratio, HEALTH_BAR_HEIGHT))
		draw_rect(fill_rect, HEALTH_BAR_FILL, true)
	draw_rect(bar_rect, HEALTH_BAR_BORDER, false, 1.0)
