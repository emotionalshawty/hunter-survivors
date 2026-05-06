extends Weapon

class_name BasicShotWeapon

const BASE_FIRE_INTERVAL: float = 0.55
const FIRE_INTERVAL_PER_LEVEL: float = 0.05
const BASE_DAMAGE: float = 1.0
const DAMAGE_PER_LEVEL: float = 0.25
const PROJECTILE_SPEED: float = 600.0
const PROJECTILE_LIFETIME: float = 1.6
const TARGET_RANGE: float = 900.0


func get_id() -> String:
	return "basic"


func get_display_name() -> String:
	return "Auto Pistol"


func get_level_description() -> String:
	return "+25% damage, faster cadence"


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
	projectile.pierce_count = 1 + rt.stats.pierce_bonus
	projectile.scale = Vector2.ONE
	projectile.global_position = rt.player.global_position
	if projectile.has_method("reset_for_acquire"):
		projectile.reset_for_acquire()
	if rt.effects != null and rt.effects.has_method("spawn_muzzle_flash"):
		rt.effects.spawn_muzzle_flash(rt.player.global_position, direction)

	var base_interval: float = max(0.1, BASE_FIRE_INTERVAL - FIRE_INTERVAL_PER_LEVEL * float(level - 1))
	cooldown = rt.stats.get_fire_interval(base_interval)
