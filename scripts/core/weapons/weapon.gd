extends RefCounted

class_name Weapon

const DEFAULT_MAX_LEVEL: int = 5

var level: int = 1
var cooldown: float = 0.0


func get_id() -> String:
	return "weapon"


func get_display_name() -> String:
	return "Weapon"


func get_level_description() -> String:
	return ""


func get_max_level() -> int:
	return DEFAULT_MAX_LEVEL


func is_max_level() -> bool:
	return level >= get_max_level()


func can_evolve() -> bool:
	return false


func evolve_into_id() -> String:
	return ""


func reset() -> void:
	level = 1
	cooldown = 0.0


func level_up() -> void:
	if level < get_max_level():
		level += 1


func tick(_delta: float, _runtime: WeaponRuntime) -> void:
	pass
