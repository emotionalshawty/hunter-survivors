extends RefCounted

class_name DifficultySystem

const BASE_SPAWN_INTERVAL: float = 1.25
const MIN_SPAWN_INTERVAL: float = 0.35

var enemy_spawn_interval: float = BASE_SPAWN_INTERVAL
var enemy_speed_scale: float = 1.0
var enemy_health_scale: float = 1.0


func reset() -> void:
	enemy_spawn_interval = BASE_SPAWN_INTERVAL
	enemy_speed_scale = 1.0
	enemy_health_scale = 1.0


func tick() -> void:
	enemy_spawn_interval = max(MIN_SPAWN_INTERVAL, enemy_spawn_interval - 0.06)
	enemy_speed_scale += 0.08
	enemy_health_scale += 0.12
