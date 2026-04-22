extends RefCounted

class_name SpawnSystem

const ENEMY_MIN_SPAWN_RADIUS: float = 500.0
const ENEMY_MAX_SPAWN_RADIUS: float = 760.0
const MIN_SPAWN_GAP: float = 70.0

var _basic_enemy_scene: PackedScene
var _brute_enemy_scene: PackedScene
var _dasher_enemy_scene: PackedScene
var _shield_bearer_enemy_scene: PackedScene
var _splitter_enemy_scene: PackedScene
var _ghost_enemy_scene: PackedScene


func _init(
	basic_enemy_scene: PackedScene,
	brute_enemy_scene: PackedScene,
	dasher_enemy_scene: PackedScene = null,
	shield_bearer_enemy_scene: PackedScene = null,
	splitter_enemy_scene: PackedScene = null,
	ghost_enemy_scene: PackedScene = null
) -> void:
	_basic_enemy_scene = basic_enemy_scene
	_brute_enemy_scene = brute_enemy_scene
	_dasher_enemy_scene = dasher_enemy_scene
	_shield_bearer_enemy_scene = shield_bearer_enemy_scene
	_splitter_enemy_scene = splitter_enemy_scene
	_ghost_enemy_scene = ghost_enemy_scene


func spawn_tick(level: int, player: CharacterBody2D, enemies_root: Node2D, on_enemy_defeated: Callable, enemy_speed_scale: float, enemy_health_scale: float, on_enemy_damaged: Callable = Callable()) -> void:
	var current_enemy_count := enemies_root.get_child_count()
	var enemy_cap := get_enemy_cap(level)
	if current_enemy_count >= enemy_cap:
		return

	var spawn_count := get_spawn_count(level, current_enemy_count, enemy_cap)
	var available_slots := enemy_cap - current_enemy_count
	spawn_count = min(spawn_count, available_slots)
	if spawn_count <= 0:
		return

	for _i in spawn_count:
		var enemy_scene := _pick_enemy_scene(level)
		if enemy_scene == null:
			continue

		var enemy: CharacterBody2D = enemy_scene.instantiate()
		if enemy.has_method("apply_spawn_scalars"):
			enemy.apply_spawn_scalars(enemy_speed_scale, enemy_health_scale)
		else:
			enemy.max_health *= enemy_health_scale
			enemy.move_speed *= enemy_speed_scale
		enemy.set_target(player)
		enemy.defeated.connect(on_enemy_defeated)
		if on_enemy_damaged.is_valid() and enemy.has_signal("damaged"):
			enemy.damaged.connect(on_enemy_damaged)
		enemy.global_position = _find_spawn_position(player.global_position, enemies_root)
		enemies_root.add_child(enemy)


func get_enemy_cap(level: int) -> int:
	return clampi(18 + level * 2, 18, 70)


func get_spawn_count(level: int, current_enemy_count: int, enemy_cap: int) -> int:
	var count: int = 1 + int(float(level) / 7.0)
	if current_enemy_count < int(float(enemy_cap) * 0.35):
		count += 1
	return clampi(count, 1, 4)


func compute_spawn_interval(level: int, current_enemy_count: int, base_interval: float) -> float:
	var cap: int = maxi(1, get_enemy_cap(level))
	var pressure := clampf(float(current_enemy_count) / float(cap), 0.0, 1.0)
	var target: float = maxf(0.32, base_interval - float(level) * 0.018 + pressure * 0.14)
	return target


func _pick_enemy_scene(level: int) -> PackedScene:
	var options: Array[Dictionary] = []
	_add_spawn_option(options, _basic_enemy_scene, 8.0)
	_add_spawn_option(options, _brute_enemy_scene, clampf(0.9 + float(level) * 0.22, 0.9, 4.2))
	if level >= 3:
		_add_spawn_option(options, _dasher_enemy_scene, clampf(0.7 + float(level - 2) * 0.20, 0.7, 3.8))
	if level >= 4:
		_add_spawn_option(options, _shield_bearer_enemy_scene, clampf(0.55 + float(level - 3) * 0.16, 0.55, 3.0))
	if level >= 5:
		_add_spawn_option(options, _splitter_enemy_scene, clampf(0.8 + float(level - 4) * 0.19, 0.8, 3.5))
	if level >= 7:
		_add_spawn_option(options, _ghost_enemy_scene, clampf(0.45 + float(level - 6) * 0.13, 0.45, 2.4))

	return _pick_weighted_scene(options)


func _add_spawn_option(options: Array[Dictionary], scene: PackedScene, weight: float) -> void:
	if scene == null or weight <= 0.0:
		return
	options.append({
		"scene": scene,
		"weight": weight,
	})


func _pick_weighted_scene(options: Array[Dictionary]) -> PackedScene:
	if options.is_empty():
		return _basic_enemy_scene

	var total_weight: float = 0.0
	for entry in options:
		total_weight += float(entry.get("weight", 0.0))
	if total_weight <= 0.0:
		return _basic_enemy_scene

	var roll: float = randf() * total_weight
	for entry in options:
		roll -= float(entry.get("weight", 0.0))
		if roll <= 0.0:
			return entry.get("scene", _basic_enemy_scene)

	return options.back().get("scene", _basic_enemy_scene)


func _find_spawn_position(player_position: Vector2, enemies_root: Node2D) -> Vector2:
	for _attempt in 8:
		var angle := randf() * TAU
		var distance := randf_range(ENEMY_MIN_SPAWN_RADIUS, ENEMY_MAX_SPAWN_RADIUS)
		var candidate := player_position + Vector2.RIGHT.rotated(angle) * distance
		if _is_position_clear(candidate, enemies_root):
			return candidate

	var fallback_angle := randf() * TAU
	return player_position + Vector2.RIGHT.rotated(fallback_angle) * ENEMY_MIN_SPAWN_RADIUS


func _is_position_clear(candidate: Vector2, enemies_root: Node2D) -> bool:
	for enemy in enemies_root.get_children():
		if not (enemy is CharacterBody2D):
			continue
		if enemy.global_position.distance_to(candidate) < MIN_SPAWN_GAP:
			return false
	return true
