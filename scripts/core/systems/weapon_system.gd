extends RefCounted

class_name WeaponSystem

const MODE_NORMAL: int = 0
const MODE_SNIPER: int = 1
const MODE_SHOTGUN: int = 2
const MODE_CHAIN_LIGHTNING: int = 3

const BASE_FIRE_INTERVAL: float = 0.39
const DAMAGE_UPGRADE_STEP: float = 0.25
const SNIPER_FIRE_INTERVAL: float = 0.69
const SNIPER_DAMAGE_MULTIPLIER: float = 7.0
const SHOTGUN_FIRE_INTERVAL: float = 0.432
const SHOTGUN_PELLET_COUNT: int = 5
const SHOTGUN_SPREAD_STEP: float = 0.16
const SHOTGUN_DAMAGE_MULTIPLIER: float = 0.65
const CHAIN_MIN_TARGETS: int = 3
const CHAIN_MAX_TARGETS: int = 5
const CHAIN_FIRST_TARGET_RANGE: float = 280.0
const CHAIN_BOUNCE_RANGE: float = 150.0
const CHAIN_DAMAGE_FALLOFF: float = 0.50
const CHAIN_BEAM_DPS: float = 3.8

const AURA_RADIUS: float = 95.0
const AURA_DPS: float = 3.84

var projectile_damage_multiplier: float = 1.0
var weapon_mode: int = MODE_NORMAL
var aura_active: bool = false
var _chain_beam_has_target: bool = false
var _chain_beam_endpoint: Vector2 = Vector2.ZERO
var _chain_beam_points: Array[Vector2] = []


func reset(player: CharacterBody2D) -> void:
	projectile_damage_multiplier = 1.0
	weapon_mode = MODE_NORMAL
	aura_active = false
	_chain_beam_has_target = false
	_chain_beam_endpoint = Vector2.ZERO
	_chain_beam_points.clear()
	player.fire_interval = BASE_FIRE_INTERVAL


func apply_damage_upgrade() -> void:
	projectile_damage_multiplier += DAMAGE_UPGRADE_STEP


func choose_sniper(player: CharacterBody2D) -> void:
	weapon_mode = MODE_SNIPER
	player.fire_interval = SNIPER_FIRE_INTERVAL


func choose_shotgun(player: CharacterBody2D) -> void:
	weapon_mode = MODE_SHOTGUN
	player.fire_interval = SHOTGUN_FIRE_INTERVAL


func choose_chain_lightning(player: CharacterBody2D) -> void:
	weapon_mode = MODE_CHAIN_LIGHTNING
	player.fire_interval = 0.15


func choose_aura() -> void:
	aura_active = true


func is_aura_active() -> bool:
	return aura_active


func get_aura_radius() -> float:
	return AURA_RADIUS


func has_chain_beam_target() -> bool:
	return _chain_beam_has_target


func get_chain_beam_endpoint() -> Vector2:
	return _chain_beam_endpoint


func has_chain_beam_points() -> bool:
	return _chain_beam_points.size() >= 2


func get_chain_beam_points() -> Array[Vector2]:
	return _chain_beam_points


func spawn_projectiles(projectile_scene: PackedScene, projectiles: Node2D, enemies: Node2D, origin: Vector2, direction: Vector2) -> void:
	match weapon_mode:
		MODE_SNIPER:
			var sniper_projectile: Area2D = projectile_scene.instantiate()
			sniper_projectile.direction = direction
			sniper_projectile.damage *= projectile_damage_multiplier * SNIPER_DAMAGE_MULTIPLIER
			sniper_projectile.scale = Vector2(1.9, 1.9)
			sniper_projectile.lifetime = 3.0
			sniper_projectile.speed = 920.0
			sniper_projectile.pierce_count = 100
			sniper_projectile.global_position = origin
			projectiles.add_child(sniper_projectile)
		MODE_SHOTGUN:
			for pellet_index in SHOTGUN_PELLET_COUNT:
				var pellet: Area2D = projectile_scene.instantiate()
				var centered_index: float = float(pellet_index) - float(SHOTGUN_PELLET_COUNT - 1) * 0.5
				var spread_angle: float = centered_index * SHOTGUN_SPREAD_STEP
				pellet.direction = direction.rotated(spread_angle).normalized()
				pellet.damage *= projectile_damage_multiplier * SHOTGUN_DAMAGE_MULTIPLIER
				pellet.scale = Vector2(0.9, 0.9)
				pellet.speed = 600.0
				pellet.lifetime = 0.9
				pellet.pierce_count = 1
				pellet.global_position = origin
				projectiles.add_child(pellet)
		MODE_CHAIN_LIGHTNING:
			# Continuous chain lightning is processed each physics frame.
			pass
		_:
			var projectile: Area2D = projectile_scene.instantiate()
			projectile.direction = direction
			projectile.damage *= projectile_damage_multiplier
			projectile.pierce_count = 1
			projectile.global_position = origin
			projectiles.add_child(projectile)


func apply_aura_damage(delta: float, spatial_hash: SpatialHash, player: CharacterBody2D) -> void:
	if not aura_active:
		return
	if spatial_hash == null:
		return
	var aura_damage: float = AURA_DPS * delta
	var nearby := spatial_hash.query_circle(player.global_position, AURA_RADIUS)
	for enemy in nearby:
		if not (enemy is CharacterBody2D):
			continue
		enemy.take_damage(aura_damage, player.global_position, "aura")


func process_chain_lightning_beam(delta: float, spatial_hash: SpatialHash, origin: Vector2) -> void:
	_chain_beam_has_target = false
	_chain_beam_endpoint = origin
	_chain_beam_points.clear()
	_chain_beam_points.append(origin)
	if weapon_mode != MODE_CHAIN_LIGHTNING:
		return
	if spatial_hash == null:
		return

	var used_targets: Dictionary = {}
	var primary_target := _find_nearest_chain_target(spatial_hash, origin, used_targets, CHAIN_FIRST_TARGET_RANGE)
	if primary_target == null:
		return

	_chain_beam_has_target = true
	var chain_damage: float = CHAIN_BEAM_DPS * projectile_damage_multiplier * delta
	var jumps: int = randi_range(CHAIN_MIN_TARGETS, CHAIN_MAX_TARGETS)
	var current_point: Vector2 = primary_target.global_position
	used_targets[primary_target.get_instance_id()] = true
	_chain_beam_points.append(current_point)
	primary_target.take_damage(chain_damage, origin, "chain")
	chain_damage *= CHAIN_DAMAGE_FALLOFF

	for _jump in max(0, jumps - 1):
		var target := _find_nearest_chain_target(spatial_hash, current_point, used_targets, CHAIN_BOUNCE_RANGE)
		if target == null:
			break
		used_targets[target.get_instance_id()] = true
		_chain_beam_points.append(target.global_position)
		target.take_damage(chain_damage, current_point, "chain")
		current_point = target.global_position
		chain_damage *= CHAIN_DAMAGE_FALLOFF

	_chain_beam_endpoint = current_point


func _find_nearest_chain_target(spatial_hash: SpatialHash, from_point: Vector2, used_targets: Dictionary, max_range: float) -> CharacterBody2D:
	var best_target: CharacterBody2D = null
	var best_distance_sq: float = max_range * max_range
	var candidates := spatial_hash.query_circle(from_point, max_range)

	for enemy in candidates:
		if not (enemy is CharacterBody2D):
			continue
		var target_id: int = enemy.get_instance_id()
		if used_targets.has(target_id):
			continue

		var distance_sq: float = from_point.distance_squared_to(enemy.global_position)
		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_target = enemy

	return best_target
