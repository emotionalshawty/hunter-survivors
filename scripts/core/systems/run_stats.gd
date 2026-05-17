extends RefCounted

class_name RunStats

const BASE_XP_TO_LEVEL: int = 6
const XP_SCALE: float = 1.35

var score: int = 0
var level: int = 1
var experience: int = 0
var experience_to_level: int = BASE_XP_TO_LEVEL
var player_max_health: float = 100.0
var player_health: float = 100.0
var run_kills: int = 0
var run_xp_gained: int = 0
var _run_start_ticks_ms: int = 0

var total_coins: int = 0
var highest_level: int = 1
var lifetime_deaths: int = 0
var best_score: int = 0
var total_xp_collected: int = 0


func reset(start_health: float) -> void:
	score = 0
	level = 1
	experience = 0
	experience_to_level = BASE_XP_TO_LEVEL
	player_max_health = start_health
	player_health = start_health
	run_kills = 0
	run_xp_gained = 0
	_run_start_ticks_ms = Time.get_ticks_msec()


# Carga stats desde firebase
func apply_loaded_profile(data: Dictionary, fallback_username: String) -> String:
	total_coins = int(data.get("total_coins", 0))
	highest_level = max(highest_level, int(data.get("highest_level", 1)))
	lifetime_deaths = int(data.get("lifetime_deaths", 0))
	best_score = int(data.get("best_score", 0))
	total_xp_collected = int(data.get("total_xp_collected", 0))
	return str(data.get("username", fallback_username)).strip_edges()



func on_pickup_collected(xp: int, coins: int) -> Array[int]:
	score += coins
	experience += xp
	run_xp_gained += xp
	var new_levels: Array[int] = []
	while experience >= experience_to_level:
		experience -= experience_to_level
		level += 1
		highest_level = max(highest_level, level)
		experience_to_level = int(round(experience_to_level * XP_SCALE))
		new_levels.append(level)
	return new_levels


func on_enemy_killed() -> void:
	run_kills += 1


func get_run_time_ms() -> int:
	return Time.get_ticks_msec() - _run_start_ticks_ms


# Commits the run to lifetime stats and returns the game over stats 
func finalize_run(pilot_name: String, user_id: String) -> Dictionary:
	var run_score := score
	var is_new_best := run_score > best_score
	var previous_best := best_score

	total_coins += run_score
	highest_level = max(highest_level, level)
	lifetime_deaths += 1
	best_score = max(best_score, run_score)
	total_xp_collected += run_xp_gained

	return {
		"pilot": pilot_name,
		"user_id": user_id,
		"score": run_score,
		"level": level,
		"kills": run_kills,
		"xp_gained": run_xp_gained,
		"credits_earned": run_score,
		"time_ms": get_run_time_ms(),
		"previous_best": previous_best,
		"best_display": best_score,
		"is_new_best": is_new_best,
	}


func make_save_payload(move_speed: float, projectile_damage_multiplier: float, extra_data: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = {
		"current_level": level,
		"current_xp": experience,
		"current_xp_to_level": experience_to_level,
		"current_health": player_health,
		"max_health": player_max_health,
		"projectile_damage_multiplier": projectile_damage_multiplier,
		"move_speed": move_speed,
		"best_score": best_score,
		"total_xp_collected": total_xp_collected,
		"lifetime_deaths": lifetime_deaths,
	}
	for key in extra_data:
		payload[key] = extra_data[key]
	return payload
