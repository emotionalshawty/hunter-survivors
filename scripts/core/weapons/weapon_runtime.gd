extends RefCounted

class_name WeaponRuntime

var player: CharacterBody2D
var projectiles_root: Node2D
var enemies_root: Node2D
var spatial_hash: SpatialHash
var projectile_pool: ProjectilePool
var effects: Node2D
var stats: PlayerStats


func find_nearest_enemy(from: Vector2, max_range: float = 1500.0) -> Node2D:
	if spatial_hash == null:
		return null
	var candidates: Array = spatial_hash.query_circle(from, max_range)
	var nearest: Node2D = null
	var best_sq: float = INF
	for e in candidates:
		if not (e is Node2D):
			continue
		var d: float = from.distance_squared_to((e as Node2D).global_position)
		if d < best_sq:
			best_sq = d
			nearest = e
	return nearest


func spawn_projectile() -> Area2D:
	if projectile_pool == null:
		return null
	return projectile_pool.acquire(projectiles_root)
