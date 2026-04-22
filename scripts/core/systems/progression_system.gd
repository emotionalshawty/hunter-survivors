extends RefCounted

class_name ProgressionSystem

const BASE_LEVEL: int = 1
const BASE_XP_TO_LEVEL: int = 6


static func apply_loaded_profile(data: Dictionary, current_level: int, fallback_username: String) -> Dictionary:
	return {
		"total_coins": int(data.get("total_coins", 0)),
		"highest_level": max(current_level, int(data.get("highest_level", 1))),
		"lifetime_deaths": int(data.get("lifetime_deaths", 0)),
		"best_score": int(data.get("best_score", 0)),
		"total_xp_collected": int(data.get("total_xp_collected", 0)),
		"username": str(data.get("username", fallback_username)).strip_edges()
	}


static func make_save_payload(level: int, experience: int, experience_to_level: int, player_health: float, player_max_health: float, projectile_damage_multiplier: float, move_speed: float, best_score: int, total_xp_collected: int, lifetime_deaths: int, extra_data: Dictionary) -> Dictionary:
	var payload := {
		"current_level": level,
		"current_xp": experience,
		"current_xp_to_level": experience_to_level,
		"current_health": player_health,
		"max_health": player_max_health,
		"projectile_damage_multiplier": projectile_damage_multiplier,
		"move_speed": move_speed,
		"best_score": best_score,
		"total_xp_collected": total_xp_collected,
		"lifetime_deaths": lifetime_deaths
	}
	for key in extra_data.keys():
		payload[key] = extra_data[key]
	return payload
