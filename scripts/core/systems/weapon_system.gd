extends RefCounted

class_name WeaponSystem

const WeaponDataScript = preload("res://scripts/core/systems/weapon_data.gd")
const WeaponItemScript = preload("res://scripts/resources/weapon_item.gd")

const MODE_NORMAL: int = WeaponDataScript.MODE_NORMAL
const MODE_SNIPER: int = WeaponDataScript.MODE_SNIPER
const MODE_SHOTGUN: int = WeaponDataScript.MODE_SHOTGUN
const MODE_CHAIN_LIGHTNING: int = WeaponDataScript.MODE_CHAIN_LIGHTNING
const MODE_BURST: int = WeaponDataScript.MODE_BURST
const MODE_ROCKET: int = WeaponDataScript.MODE_ROCKET
const MODE_BOOMERANG: int = WeaponDataScript.MODE_BOOMERANG

const DAMAGE_UPGRADE_STEP: float = 0.25
const MAX_EQUIPPED_WEAPONS: int = 3

signal aura_changed(radius: float, active: bool)
signal chain_beam_changed(points: Array, active: bool)

var projectile_damage_multiplier: float = 1.0

var equipped_weapons: Array[WeaponItem] = []
var _weapon_cooldowns: Array[float] = []

var aura_active: bool = false
var orbit_active: bool = false
var _orbit_drones: Array[Area2D] = []

var _chain_beam_has_target: bool = false
var _chain_beam_endpoint: Vector2 = Vector2.ZERO
var _chain_beam_points: Array[Vector2] = []


func reset(_player: CharacterBody2D) -> void:
	projectile_damage_multiplier = 1.0
	equipped_weapons.clear()
	_weapon_cooldowns.clear()
	aura_active = false
	orbit_active = false
	_clear_orbit_drones()
	_chain_beam_has_target = false
	_chain_beam_endpoint = Vector2.ZERO
	_chain_beam_points.clear()
	_add_weapon_to_slot(WeaponItemScript.create_starter(MODE_NORMAL))
	aura_changed.emit(get_aura_radius(), false)
	chain_beam_changed.emit([], false)


func _clear_orbit_drones() -> void:
	for drone in _orbit_drones:
		if drone != null and is_instance_valid(drone):
			drone.queue_free()
	_orbit_drones.clear()


# Returns the displaced weapon if the cap was hit, otherwise null.
func equip_weapon(item: WeaponItem) -> WeaponItem:
	if item == null or has_weapon_mode(item.weapon_mode):
		return null
	return _add_weapon_to_slot(item)


func _add_weapon_to_slot(item: WeaponItem) -> WeaponItem:
	var displaced: WeaponItem = null
	if equipped_weapons.size() >= MAX_EQUIPPED_WEAPONS:
		displaced = equipped_weapons[0]
		equipped_weapons.pop_front()
		_weapon_cooldowns.pop_front()
	equipped_weapons.append(item)
	_weapon_cooldowns.append(0.05 * float(_weapon_cooldowns.size())) # slight stagger
	return displaced


func has_weapon_mode(mode: int) -> bool:
	for w in equipped_weapons:
		if w != null and w.weapon_mode == mode:
			return true
	return false


func get_equipped_modes() -> Array[int]:
	var out: Array[int] = []
	for w in equipped_weapons:
		if w != null:
			out.append(w.weapon_mode)
	return out


func is_active_full() -> bool:
	return equipped_weapons.size() >= MAX_EQUIPPED_WEAPONS


func get_weapon_mode() -> int:
	return MODE_NORMAL if equipped_weapons.is_empty() else equipped_weapons[0].weapon_mode


func apply_damage_upgrade() -> void:
	projectile_damage_multiplier += DAMAGE_UPGRADE_STEP


func choose_weapon_mode(mode: int, _player: CharacterBody2D) -> WeaponItem:
	return equip_weapon(WeaponItemScript.create_starter(mode))

func choose_sniper(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_SNIPER, player)

func choose_shotgun(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_SHOTGUN, player)

func choose_chain_lightning(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_CHAIN_LIGHTNING, player)

func choose_burst(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_BURST, player)

func choose_rocket(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_ROCKET, player)

func choose_boomerang(player: CharacterBody2D) -> WeaponItem:
	return choose_weapon_mode(MODE_BOOMERANG, player)


func choose_aura() -> void:
	aura_active = true
	aura_changed.emit(get_aura_radius(), true)


func choose_orbit(projectile_scene: PackedScene, projectiles_parent: Node2D, player: CharacterBody2D) -> void:
	if projectile_scene == null or projectiles_parent == null or player == null:
		return
	if orbit_active:
		_clear_orbit_drones()
	orbit_active = true
	var stats: Dictionary = WeaponDataScript.get_passive_stats(WeaponDataScript.PASSIVE_ORBIT)
	var drone_count: int = int(stats.get("drone_count", 3))
	var radius: float = float(stats.get("radius", 78.0))
	var angular_speed: float = float(stats.get("angular_speed", 2.4))
	var damage: float = float(stats.get("damage_per_tick", 0.7))
	var tick_interval: float = float(stats.get("tick_interval", 0.18))
	var drone_scale: float = float(stats.get("scale", 0.7))
	for i in drone_count:
		var drone: Area2D = projectile_scene.instantiate()
		drone.orbit_active = true
		drone.orbit_owner = player
		drone.orbit_radius = radius
		drone.orbit_angular_speed = angular_speed
		drone.orbit_angle = TAU * float(i) / float(drone_count)
		drone.orbit_damage_interval = tick_interval
		drone.damage = damage * projectile_damage_multiplier
		drone.lifetime = 999999.0
		drone.pierce_count = 99
		drone.scale = Vector2(drone_scale, drone_scale)
		drone.global_position = player.global_position + Vector2.RIGHT.rotated(drone.orbit_angle) * radius
		projectiles_parent.add_child(drone)
		_orbit_drones.append(drone)


func update_orbit_damage(_delta: float) -> void:
	if not orbit_active:
		return
	var stats: Dictionary = WeaponDataScript.get_passive_stats(WeaponDataScript.PASSIVE_ORBIT)
	var damage: float = float(stats.get("damage_per_tick", 0.7))
	for drone in _orbit_drones:
		if drone != null and is_instance_valid(drone):
			drone.damage = damage * projectile_damage_multiplier


func is_aura_active() -> bool:
	return aura_active

func is_orbit_active() -> bool:
	return orbit_active

func get_aura_radius() -> float:
	return float(WeaponDataScript.get_passive_stats(WeaponDataScript.PASSIVE_AURA).get("radius", 105.0))

func has_chain_beam_target() -> bool:
	return _chain_beam_has_target

func get_chain_beam_endpoint() -> Vector2:
	return _chain_beam_endpoint

func has_chain_beam_points() -> bool:
	return _chain_beam_points.size() >= 2

func get_chain_beam_points() -> Array[Vector2]:
	return _chain_beam_points


func tick_active_weapons(delta: float, player: CharacterBody2D, projectile_scene: PackedScene, projectiles_root: Node2D, enemies_root: Node2D) -> void:
	if player == null or projectile_scene == null or projectiles_root == null or equipped_weapons.is_empty():
		return
	var direction: Vector2 = _find_attack_direction(player, enemies_root)
	for i in equipped_weapons.size():
		_weapon_cooldowns[i] -= delta
		if _weapon_cooldowns[i] > 0.0:
			continue
		var weapon: WeaponItem = equipped_weapons[i]
		if weapon == null:
			continue
		if weapon.weapon_mode == MODE_CHAIN_LIGHTNING:
			_weapon_cooldowns[i] = 0.0
			continue
		if direction == Vector2.ZERO:
			_weapon_cooldowns[i] = 0.05
			continue
		_fire_weapon(weapon, projectile_scene, projectiles_root, player.global_position, direction)
		var stats: Dictionary = WeaponDataScript.get_mode_stats(weapon.weapon_mode)
		_weapon_cooldowns[i] = weapon.get_modified_fire_interval(float(stats.get("fire_interval", 0.4)))


func _find_attack_direction(player: CharacterBody2D, enemies_root: Node2D) -> Vector2:
	if enemies_root == null:
		return Vector2.ZERO
	var nearest: Node2D = null
	var best_sq: float = INF
	for e in enemies_root.get_children():
		if not (e is Node2D):
			continue
		var d: float = (e as Node2D).global_position.distance_squared_to(player.global_position)
		if d < best_sq:
			best_sq = d
			nearest = e
	if nearest == null:
		return Vector2.ZERO
	return (nearest.global_position - player.global_position).normalized()


func _fire_weapon(weapon: WeaponItem, projectile_scene: PackedScene, projectiles: Node2D, origin: Vector2, direction: Vector2) -> void:
	var stats: Dictionary = WeaponDataScript.get_mode_stats(weapon.weapon_mode)
	match weapon.weapon_mode:
		MODE_SHOTGUN:  _spawn_shotgun(projectile_scene, projectiles, weapon, stats, origin, direction)
		MODE_BURST:    _spawn_burst(projectile_scene, projectiles, weapon, stats, origin, direction)
		MODE_ROCKET:   _spawn_rocket(projectile_scene, projectiles, weapon, stats, origin, direction)
		MODE_BOOMERANG: _spawn_boomerang(projectile_scene, projectiles, weapon, stats, origin, direction)
		_:             _spawn_single(projectile_scene, projectiles, weapon, stats, origin, direction)


func _spawn_single(projectile_scene: PackedScene, projectiles: Node2D, weapon: WeaponItem, stats: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var p: Area2D = projectile_scene.instantiate()
	_configure_projectile(p, weapon, stats, direction)
	p.global_position = origin
	projectiles.add_child(p)


func _spawn_shotgun(projectile_scene: PackedScene, projectiles: Node2D, weapon: WeaponItem, stats: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var count: int = int(stats.get("pellet_count", 5))
	var spread: float = float(stats.get("spread_step", 0.16))
	for i in count:
		var pellet: Area2D = projectile_scene.instantiate()
		var centered: float = float(i) - float(count - 1) * 0.5
		_configure_projectile(pellet, weapon, stats, direction.rotated(centered * spread).normalized())
		pellet.global_position = origin
		projectiles.add_child(pellet)


func _spawn_burst(projectile_scene: PackedScene, projectiles: Node2D, weapon: WeaponItem, stats: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var count: int = int(stats.get("burst_count", 3))
	var spread: float = float(stats.get("burst_spread_step", 0.05))
	for i in count:
		var bullet: Area2D = projectile_scene.instantiate()
		var centered: float = float(i) - float(count - 1) * 0.5
		_configure_projectile(bullet, weapon, stats, direction.rotated(centered * spread).normalized())
		bullet.global_position = origin
		projectiles.add_child(bullet)


func _spawn_rocket(projectile_scene: PackedScene, projectiles: Node2D, weapon: WeaponItem, stats: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var rocket: Area2D = projectile_scene.instantiate()
	_configure_projectile(rocket, weapon, stats, direction)
	rocket.explode_on_hit = true
	rocket.explode_radius = float(stats.get("explode_radius", 80.0)) * weapon.area_radius_mult
	rocket.explode_damage = float(stats.get("explode_damage", 3.0)) * weapon.get_total_damage_multiplier(projectile_damage_multiplier)
	rocket.global_position = origin
	projectiles.add_child(rocket)


func _spawn_boomerang(projectile_scene: PackedScene, projectiles: Node2D, weapon: WeaponItem, stats: Dictionary, origin: Vector2, direction: Vector2) -> void:
	var boom: Area2D = projectile_scene.instantiate()
	_configure_projectile(boom, weapon, stats, direction)
	boom.boomerang_returns = true
	boom.lifetime = float(stats.get("lifetime", 1.6))
	boom.boomerang_return_time = float(stats.get("return_after", 0.55))
	boom.global_position = origin
	projectiles.add_child(boom)


func _configure_projectile(p: Area2D, weapon: WeaponItem, stats: Dictionary, direction: Vector2) -> void:
	p.direction = direction
	p.damage = float(stats.get("damage", 1.0)) * weapon.get_total_damage_multiplier(projectile_damage_multiplier)
	p.speed = weapon.get_modified_projectile_speed(float(stats.get("speed", 560.0)))
	p.lifetime = float(stats.get("lifetime", 2.0))
	p.pierce_count = weapon.get_modified_pierce(int(stats.get("pierce", 1)))
	p.scale = Vector2.ONE * float(stats.get("scale", 1.0))


func apply_aura_damage(delta: float, spatial_hash: SpatialHash, player: CharacterBody2D) -> void:
	if not aura_active or spatial_hash == null or player == null:
		return
	var stats: Dictionary = WeaponDataScript.get_passive_stats(WeaponDataScript.PASSIVE_AURA)
	var aura_damage: float = float(stats.get("dps", 5.0)) * projectile_damage_multiplier * delta
	var radius: float = float(stats.get("radius", 105.0))
	for enemy in spatial_hash.query_circle(player.global_position, radius):
		if enemy is CharacterBody2D:
			enemy.take_damage(aura_damage, player.global_position, "aura")


func process_chain_lightning_beam(delta: float, spatial_hash: SpatialHash, origin: Vector2) -> void:
	_chain_beam_has_target = false
	_chain_beam_endpoint = origin
	_chain_beam_points.clear()
	_chain_beam_points.append(origin)

	var chain_weapon: WeaponItem = _get_weapon_in_mode(MODE_CHAIN_LIGHTNING)
	if chain_weapon == null or spatial_hash == null:
		chain_beam_changed.emit([], false)
		return

	var stats: Dictionary = WeaponDataScript.get_mode_stats(MODE_CHAIN_LIGHTNING)
	var first_range: float = float(stats.get("first_target_range", 280.0))
	var bounce_range: float = float(stats.get("bounce_range", 175.0))
	var falloff: float = float(stats.get("damage_falloff", 0.55))
	var damage_mult: float = chain_weapon.get_total_damage_multiplier(projectile_damage_multiplier)

	var used_targets: Dictionary = {}
	var primary := _find_nearest_chain_target(spatial_hash, origin, used_targets, first_range)
	if primary == null:
		return

	_chain_beam_has_target = true
	var chain_damage: float = float(stats.get("dps", 5.5)) * damage_mult * delta
	var jumps: int = randi_range(int(stats.get("min_targets", 3)), int(stats.get("max_targets", 5)))
	var current_point: Vector2 = primary.global_position
	used_targets[primary.get_instance_id()] = true
	_chain_beam_points.append(current_point)
	primary.take_damage(chain_damage, origin, "chain")
	chain_damage *= falloff

	for _jump in max(0, jumps - 1):
		var target := _find_nearest_chain_target(spatial_hash, current_point, used_targets, bounce_range)
		if target == null:
			break
		used_targets[target.get_instance_id()] = true
		_chain_beam_points.append(target.global_position)
		target.take_damage(chain_damage, current_point, "chain")
		current_point = target.global_position
		chain_damage *= falloff

	_chain_beam_endpoint = current_point
	chain_beam_changed.emit(_chain_beam_points, _chain_beam_points.size() >= 2)


func _get_weapon_in_mode(mode: int) -> WeaponItem:
	for w in equipped_weapons:
		if w != null and w.weapon_mode == mode:
			return w
	return null


func _find_nearest_chain_target(spatial_hash: SpatialHash, from_point: Vector2, used_targets: Dictionary, max_range: float) -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_sq: float = max_range * max_range
	for e in spatial_hash.query_circle(from_point, max_range):
		if not (e is CharacterBody2D):
			continue
		var id: int = e.get_instance_id()
		if used_targets.has(id):
			continue
		var d: float = from_point.distance_squared_to((e as CharacterBody2D).global_position)
		if d < best_sq:
			best_sq = d
			best = e
	return best
