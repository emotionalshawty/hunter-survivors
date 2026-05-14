extends RefCounted

class_name DifficultySystem

const BASE_SPAWN_INTERVAL: float = 1.25
const MIN_SPAWN_INTERVAL: float = 0.35
const SPAWN_INTERVAL_STEP: float = 0.06
const SPEED_SCALE_STEP: float = 0.08
const HEALTH_SCALE_STEP: float = 0.12

var enemy_spawn_interval: float = BASE_SPAWN_INTERVAL
var enemy_speed_scale: float = 1.0
var enemy_health_scale: float = 1.0


func reset() -> void:
	enemy_spawn_interval = BASE_SPAWN_INTERVAL
	enemy_speed_scale = 1.0
	enemy_health_scale = 1.0


# Called each DifficultyTimer tick (~every 10 s). Ramps up all three scalars.
func tick() -> void:
	enemy_spawn_interval = max(MIN_SPAWN_INTERVAL, enemy_spawn_interval - SPAWN_INTERVAL_STEP)
	enemy_speed_scale += SPEED_SCALE_STEP
	enemy_health_scale += HEALTH_SCALE_STEP
