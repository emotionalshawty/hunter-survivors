extends Weapon

class_name ShotgunWeapon

const BASE_FIRE_INTERVAL: float = 0.85
const BASE_DAMAGE: float = 0.95
const DAMAGE_PER_LEVEL: float = 0.18
const BASE_PELLETS: int = 5
const SPREAD_STEP: float = 0.18
const SPREAD_PER_LEVEL: float = 0.08
const PELLET_SPEED: float = 620.0
const PELLET_LIFETIME: float = 0.85
const TARGET_RANGE: float = 600.0


func get_id() -> String:
	return "shotgun"


func get_display_name() -> String:
	return "Shotgun"


func get_level_description() -> String:
	return "+1 pellet, tighter spread"


func tick(delta: float, rt: WeaponRuntime) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target: Node2D = rt.find_nearest_enemy(rt.player.global_position, TARGET_RANGE)
	if target == null:
		return
	var direction: Vector2 = (target.global_position - rt.player.global_position).normalized()

	var pellets: int = BASE_PELLETS + (level - 1)
	var spread: float = SPREAD_STEP * maxf(0.5, 1.0 - SPREAD_PER_LEVEL * float(level - 1))
	for i in pellets:
		var centered: float = float(i) - float(pellets - 1) * 0.5
		var angle: float = centered * spread
		var pellet: Area2D = rt.spawn_projectile()
		if pellet == null:
			continue
		pellet.direction = direction.rotated(angle).normalized()
		pellet.damage = rt.stats.apply_damage(BASE_DAMAGE * (1.0 + DAMAGE_PER_LEVEL * float(level - 1)))
		pellet.speed = PELLET_SPEED
		pellet.lifetime = PELLET_LIFETIME
		pellet.pierce_count = 1 + rt.stats.pierce_bonus
		pellet.scale = Vector2(0.9, 0.9)
		pellet.global_position = rt.player.global_position
		if pellet.has_method("reset_for_acquire"):
			pellet.reset_for_acquire()

	if rt.effects != null and rt.effects.has_method("spawn_muzzle_flash"):
		rt.effects.spawn_muzzle_flash(rt.player.global_position, direction)

	cooldown = rt.stats.get_fire_interval(BASE_FIRE_INTERVAL)
