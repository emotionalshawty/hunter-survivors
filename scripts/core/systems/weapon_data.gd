extends RefCounted

class_name WeaponData

# Single source of truth for weapon balance numbers.
# Stats are looked up at fire-time so runtime can re-tune without code changes.

# --- Active weapons (main fire mode) ---
const MODE_NORMAL: int = 0
const MODE_SNIPER: int = 1
const MODE_SHOTGUN: int = 2
const MODE_CHAIN_LIGHTNING: int = 3
const MODE_BURST: int = 4
const MODE_ROCKET: int = 5
const MODE_BOOMERANG: int = 6

# --- Passive weapons (additive to main fire) ---
const PASSIVE_AURA: String = "aura"
const PASSIVE_ORBIT: String = "orbit"

# Base stats per active mode.
# Tuned against enemy curve: base enemy 3.0 HP, scales +12% HP every 10s,
# spawn cap 18 + level*2 (max 70). Player base contact: ~84 DPS taken when surrounded.
const BASE_STATS: Dictionary = {
	MODE_NORMAL: {
		"name": "Pistol",
		"fire_interval": 0.36,
		"damage": 1.0,
		"speed": 560.0,
		"lifetime": 2.0,
		"pierce": 1,
		"scale": 1.0,
	},
	MODE_SNIPER: {
		"name": "Sniper",
		"fire_interval": 0.78,
		"damage": 5.5,
		"speed": 920.0,
		"lifetime": 2.4,
		"pierce": 4,
		"scale": 1.7,
	},
	MODE_SHOTGUN: {
		"name": "Shotgun",
		"fire_interval": 0.50,
		"damage": 0.7,
		"speed": 600.0,
		"lifetime": 0.85,
		"pierce": 2,
		"scale": 0.9,
		"pellet_count": 5,
		"spread_step": 0.16,
	},
	MODE_CHAIN_LIGHTNING: {
		"name": "Chain Lightning",
		"fire_interval": 0.15,
		"dps": 5.5,
		"first_target_range": 280.0,
		"bounce_range": 175.0,
		"min_targets": 3,
		"max_targets": 5,
		"damage_falloff": 0.55,
	},
	MODE_BURST: {
		"name": "Burst Rifle",
		"fire_interval": 0.55,
		"damage": 0.95,
		"speed": 720.0,
		"lifetime": 1.4,
		"pierce": 1,
		"scale": 0.85,
		"burst_count": 3,
		"burst_spread_step": 0.05,
	},
	MODE_ROCKET: {
		"name": "Rocket Launcher",
		"fire_interval": 1.10,
		"damage": 4.0,
		"speed": 380.0,
		"lifetime": 2.4,
		"pierce": 1,
		"scale": 1.4,
		"explode_radius": 80.0,
		"explode_damage": 3.0,
	},
	MODE_BOOMERANG: {
		"name": "Boomerang",
		"fire_interval": 0.62,
		"damage": 1.4,
		"speed": 520.0,
		"lifetime": 1.6,
		"pierce": 99,
		"scale": 1.0,
		"return_after": 0.55,
	},
}

const PASSIVE_STATS: Dictionary = {
	PASSIVE_AURA: {
		"name": "Aura",
		"radius": 105.0,
		"dps": 5.0,
	},
	PASSIVE_ORBIT: {
		"name": "Orbital Drones",
		"drone_count": 3,
		"radius": 78.0,
		"angular_speed": 2.4,
		"damage_per_tick": 0.7,
		"tick_interval": 0.18,
		"scale": 0.7,
	},
}


static func get_mode_stats(weapon_mode: int) -> Dictionary:
	return BASE_STATS.get(weapon_mode, BASE_STATS[MODE_NORMAL])


static func get_passive_stats(passive_id: String) -> Dictionary:
	return PASSIVE_STATS.get(passive_id, {})


static func get_mode_name(weapon_mode: int) -> String:
	var stats: Dictionary = BASE_STATS.get(weapon_mode, {})
	return str(stats.get("name", "Unknown"))


static func get_passive_name(passive_id: String) -> String:
	var stats: Dictionary = PASSIVE_STATS.get(passive_id, {})
	return str(stats.get("name", "Unknown"))


static func get_all_active_modes() -> Array[int]:
	var result: Array[int] = []
	for key in BASE_STATS.keys():
		result.append(int(key))
	return result


static func get_all_passive_ids() -> Array[String]:
	var result: Array[String] = []
	for key in PASSIVE_STATS.keys():
		result.append(str(key))
	return result
