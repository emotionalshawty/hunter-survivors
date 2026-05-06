extends RefCounted

class_name PlayerStats

var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var pierce_bonus: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0


func reset() -> void:
	damage_multiplier = 1.0
	fire_rate_multiplier = 1.0
	pierce_bonus = 0
	crit_chance = 0.0
	crit_multiplier = 2.0


func apply_damage(base: float) -> float:
	var dmg: float = base * damage_multiplier
	if crit_chance > 0.0 and randf() < crit_chance:
		dmg *= crit_multiplier
	return dmg


func get_fire_interval(base_interval: float) -> float:
	if fire_rate_multiplier <= 0.0:
		return base_interval
	return base_interval / fire_rate_multiplier
