extends Weapon

class_name SniperWeapon

const BASE_FIRE_INTERVAL: float = 1.4
const FIRE_INTERVAL_PER_LEVEL: float = 0.12
const BASE_DAMAGE: float = 5.5
const DAMAGE_PER_LEVEL: float = 0.45
const PROJECTILE_SPEED: float = 1100.0
const PROJECTILE_LIFETIME: float = 2.5
const BASE_PIERCE: int = 4
const TARGET_RANGE: float = 1200.0


func get_id() -> String:
	return "sniper"


func get_display_name() -> String:
	return "Railgun"


func get_level_description() -> String:
	return "+45% damage, +1 pierce, faster reload"


func tick(delta: float, rt: WeaponRuntime) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target: Node2D = rt.find_nearest_enemy(rt.player.global_position, TARGET_RANGE)
	if target == null:
		return
	var direction: Vector2 = (target.global_position - rt.player.global_position).normalized()

	var projectile: Area2D = rt.spawn_projectile()
	if projectile == null:
		return
	projectile.direction = direction
	projectile.damage = rt.stats.apply_damage(BASE_DAMAGE * (1.0 + DAMAGE_PER_LEVEL * float(level - 1)))
	projectile.speed = PROJECTILE_SPEED
	projectile.lifetime = PROJECTILE_LIFETIME
	projectile.pierce_count = BASE_PIERCE + (level - 1) + rt.stats.pierce_bonus
	projectile.scale = Vector2(1.7, 1.7)
	projectile.global_position = rt.player.global_position
	if projectile.has_method("reset_for_acquire"):
		projectile.reset_for_acquire()
	if rt.effects != null and rt.effects.has_method("spawn_muzzle_flash"):
		rt.effects.spawn_muzzle_flash(rt.player.global_position, direction)

	var base_interval: float = maxf(0.5, BASE_FIRE_INTERVAL - FIRE_INTERVAL_PER_LEVEL * float(level - 1))
	cooldown = rt.stats.get_fire_interval(base_interval)
