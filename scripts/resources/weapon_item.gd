extends Resource

class_name WeaponItem



const RARITY_COMMON: String = "common"
const RARITY_RARE: String = "rare"
const RARITY_EPIC: String = "epic"
const RARITY_LEGENDARY: String = "legendary"

const RARITIES: Array[String] = [RARITY_COMMON, RARITY_RARE, RARITY_EPIC, RARITY_LEGENDARY]

var item_id: String = ""
var owner_id: String = ""
var weapon_mode: int = 0
var rarity: String = RARITY_COMMON

# Progression (lives on the item, not the player)
var weapon_xp: int = 0
var weapon_level: int = 1

var tradeable: bool = false
var obtained_at_unix: int = 0

# Stat modifiers, applied on top of WeaponData.BASE_STATS
var damage_mult_bonus: float = 0.0       # +0.15 = +15% damage
var fire_rate_mult: float = 1.0           # 0.9 = 10% faster (interval *= this)
var pierce_bonus: int = 0
var projectile_speed_mult: float = 1.0
var area_radius_mult: float = 1.0         # aura / explosion / orbit radius


func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"owner_id": owner_id,
		"weapon_mode": weapon_mode,
		"rarity": rarity,
		"weapon_xp": weapon_xp,
		"weapon_level": weapon_level,
		"tradeable": tradeable,
		"obtained_at_unix": obtained_at_unix,
		"damage_mult_bonus": damage_mult_bonus,
		"fire_rate_mult": fire_rate_mult,
		"pierce_bonus": pierce_bonus,
		"projectile_speed_mult": projectile_speed_mult,
		"area_radius_mult": area_radius_mult,
	}


static func from_dict(data: Dictionary) -> WeaponItem:
	var item := WeaponItem.new()
	item.item_id = str(data.get("item_id", ""))
	item.owner_id = str(data.get("owner_id", ""))
	item.weapon_mode = int(data.get("weapon_mode", 0))
	item.rarity = str(data.get("rarity", RARITY_COMMON))
	item.weapon_xp = int(data.get("weapon_xp", 0))
	item.weapon_level = int(data.get("weapon_level", 1))
	item.tradeable = bool(data.get("tradeable", false))
	item.obtained_at_unix = int(data.get("obtained_at_unix", 0))
	item.damage_mult_bonus = float(data.get("damage_mult_bonus", 0.0))
	item.fire_rate_mult = float(data.get("fire_rate_mult", 1.0))
	item.pierce_bonus = int(data.get("pierce_bonus", 0))
	item.projectile_speed_mult = float(data.get("projectile_speed_mult", 1.0))
	item.area_radius_mult = float(data.get("area_radius_mult", 1.0))
	return item


# Bound, untradeable starter — given to a player when they first pick a weapon mode.
static func create_starter(weapon_mode_value: int) -> WeaponItem:
	var item := WeaponItem.new()
	item.item_id = "starter_%d" % weapon_mode_value
	item.weapon_mode = weapon_mode_value
	item.rarity = RARITY_COMMON
	item.tradeable = false
	item.obtained_at_unix = int(Time.get_unix_time_from_system())
	return item


# Random rolled drop — used by future drop tables / marketplace.
static func create_random_drop(weapon_mode_value: int, forced_rarity: String = "") -> WeaponItem:
	var item := WeaponItem.new()
	item.weapon_mode = weapon_mode_value
	item.rarity = forced_rarity if forced_rarity != "" else _roll_rarity()
	item.tradeable = true
	item.obtained_at_unix = int(Time.get_unix_time_from_system())
	item.item_id = "drop_%d_%d_%d" % [weapon_mode_value, item.obtained_at_unix, randi() % 100000]
	var ranges: Dictionary = _stat_ranges_for_rarity(item.rarity)
	item.damage_mult_bonus = randf_range(float(ranges["damage_min"]), float(ranges["damage_max"]))
	item.fire_rate_mult = randf_range(float(ranges["rate_min"]), float(ranges["rate_max"]))
	item.pierce_bonus = randi_range(int(ranges["pierce_min"]), int(ranges["pierce_max"]))
	item.projectile_speed_mult = randf_range(float(ranges["speed_min"]), float(ranges["speed_max"]))
	item.area_radius_mult = randf_range(float(ranges["area_min"]), float(ranges["area_max"]))
	return item


static func _roll_rarity() -> String:
	var roll: float = randf()
	if roll < 0.03:
		return RARITY_LEGENDARY
	if roll < 0.15:
		return RARITY_EPIC
	if roll < 0.40:
		return RARITY_RARE
	return RARITY_COMMON


static func _stat_ranges_for_rarity(r: String) -> Dictionary:
	match r:
		RARITY_LEGENDARY:
			return {
				"damage_min": 0.50, "damage_max": 1.00,
				"rate_min": 0.78, "rate_max": 0.90,
				"pierce_min": 1, "pierce_max": 2,
				"speed_min": 1.10, "speed_max": 1.25,
				"area_min": 1.10, "area_max": 1.25,
			}
		RARITY_EPIC:
			return {
				"damage_min": 0.25, "damage_max": 0.50,
				"rate_min": 0.86, "rate_max": 0.94,
				"pierce_min": 0, "pierce_max": 1,
				"speed_min": 1.05, "speed_max": 1.15,
				"area_min": 1.05, "area_max": 1.15,
			}
		RARITY_RARE:
			return {
				"damage_min": 0.10, "damage_max": 0.25,
				"rate_min": 0.92, "rate_max": 0.98,
				"pierce_min": 0, "pierce_max": 0,
				"speed_min": 1.00, "speed_max": 1.08,
				"area_min": 1.00, "area_max": 1.08,
			}
		_:
			return {
				"damage_min": 0.00, "damage_max": 0.10,
				"rate_min": 0.97, "rate_max": 1.00,
				"pierce_min": 0, "pierce_max": 0,
				"speed_min": 1.00, "speed_max": 1.03,
				"area_min": 1.00, "area_max": 1.03,
			}


# Final damage = base * run_damage_multiplier * (1 + damage_mult_bonus) * level_scalar
func get_total_damage_multiplier(run_damage_multiplier: float) -> float:
	var level_scalar: float = 1.0 + 0.05 * float(max(0, weapon_level - 1))
	return run_damage_multiplier * (1.0 + damage_mult_bonus) * level_scalar


func get_modified_fire_interval(base_interval: float) -> float:
	return maxf(0.05, base_interval * fire_rate_mult)


func get_modified_pierce(base_pierce: int) -> int:
	return max(1, base_pierce + pierce_bonus)


func get_modified_projectile_speed(base_speed: float) -> float:
	return base_speed * projectile_speed_mult


func get_modified_area_radius(base_radius: float) -> float:
	return base_radius * area_radius_mult
