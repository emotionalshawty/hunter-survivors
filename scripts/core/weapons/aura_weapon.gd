extends Weapon

class_name AuraWeapon

signal aura_changed(radius: float, active: bool)

const BASE_DPS: float = 7.0
const DPS_PER_LEVEL: float = 2.4
const BASE_RADIUS: float = 95.0
const RADIUS_PER_LEVEL: float = 16.0


func get_id() -> String:
	return "aura"


func get_display_name() -> String:
	return "Plasma Aura"


func get_level_description() -> String:
	return "+radius, +DPS"


func get_radius() -> float:
	return BASE_RADIUS + RADIUS_PER_LEVEL * float(level - 1)


func tick(delta: float, rt: WeaponRuntime) -> void:
	if rt.spatial_hash == null:
		aura_changed.emit(get_radius(), false)
		return
	var radius: float = get_radius()
	aura_changed.emit(radius, true)

	var dps: float = BASE_DPS + DPS_PER_LEVEL * float(level - 1)
	# FIX: aura damage now respects damage_multiplier and crit chance.
	var damage: float = rt.stats.apply_damage(dps) * delta
	var nearby: Array = rt.spatial_hash.query_circle(rt.player.global_position, radius)
	for e in nearby:
		if not (e is CharacterBody2D):
			continue
		(e as CharacterBody2D).take_damage(damage, rt.player.global_position, DamageKind.AURA)
