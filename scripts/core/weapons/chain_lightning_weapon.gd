extends Weapon

class_name ChainLightningWeapon

signal beam_changed(points: Array, active: bool)

const BASE_DPS: float = 7.0
const DPS_PER_LEVEL: float = 1.6
const BASE_JUMPS: int = 3
const JUMPS_PER_LEVEL: int = 1
const FIRST_RANGE: float = 290.0
const FIRST_RANGE_PER_LEVEL: float = 14.0
const BOUNCE_RANGE: float = 160.0
const FALLOFF: float = 0.55

var _beam_points: Array = []


func get_id() -> String:
	return "chain_lightning"


func get_display_name() -> String:
	return "Chain Lightning"


func get_level_description() -> String:
	return "+1 jump, +DPS, longer first range"


func get_jumps() -> int:
	return BASE_JUMPS + JUMPS_PER_LEVEL * (level - 1)


func get_first_range() -> float:
	return FIRST_RANGE + FIRST_RANGE_PER_LEVEL * float(level - 1)


func reset() -> void:
	super.reset()
	_beam_points.clear()


func tick(delta: float, rt: WeaponRuntime) -> void:
	_beam_points.clear()
	_beam_points.append(rt.player.global_position)
	if rt.spatial_hash == null:
		beam_changed.emit(_beam_points, false)
		return

	var used: Dictionary = {}
	var primary: CharacterBody2D = _find_chain_target(rt.spatial_hash, rt.player.global_position, used, get_first_range())
	if primary == null:
		beam_changed.emit(_beam_points, false)
		return

	var dps: float = BASE_DPS + DPS_PER_LEVEL * float(level - 1)
	var damage: float = rt.stats.apply_damage(dps) * delta
	var current: Vector2 = primary.global_position
	used[primary.get_instance_id()] = true
	_beam_points.append(current)
	primary.take_damage(damage, rt.player.global_position, DamageKind.CHAIN)
	damage *= FALLOFF

	var max_extra: int = maxi(0, get_jumps() - 1)
	for _i in max_extra:
		var t: CharacterBody2D = _find_chain_target(rt.spatial_hash, current, used, BOUNCE_RANGE)
		if t == null:
			break
		used[t.get_instance_id()] = true
		_beam_points.append(t.global_position)
		t.take_damage(damage, current, DamageKind.CHAIN)
		current = t.global_position
		damage *= FALLOFF

	beam_changed.emit(_beam_points, _beam_points.size() >= 2)


func _find_chain_target(hash: SpatialHash, from_point: Vector2, used: Dictionary, max_range: float) -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_sq: float = max_range * max_range
	var candidates: Array = hash.query_circle(from_point, max_range)
	for e in candidates:
		if not (e is CharacterBody2D):
			continue
		var id: int = e.get_instance_id()
		if used.has(id):
			continue
		var d: float = from_point.distance_squared_to((e as CharacterBody2D).global_position)
		if d < best_sq:
			best_sq = d
			best = e
	return best
