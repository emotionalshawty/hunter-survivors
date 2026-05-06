extends RefCounted

class_name WeaponSystem

signal aura_changed(radius: float, active: bool)
signal chain_beam_changed(points: Array, active: bool)

const BasicShotWeaponScript = preload("res://scripts/core/weapons/basic_shot_weapon.gd")
const ShotgunWeaponScript = preload("res://scripts/core/weapons/shotgun_weapon.gd")
const SniperWeaponScript = preload("res://scripts/core/weapons/sniper_weapon.gd")
const ChainLightningWeaponScript = preload("res://scripts/core/weapons/chain_lightning_weapon.gd")
const AuraWeaponScript = preload("res://scripts/core/weapons/aura_weapon.gd")

const MAX_ACTIVE_WEAPONS: int = 6

const ALL_WEAPON_IDS: Array[String] = [
	"basic",
	"shotgun",
	"sniper",
	"chain_lightning",
	"aura",
]

var stats: PlayerStats = PlayerStats.new()
var weapons: Array[Weapon] = []


func reset() -> void:
	stats.reset()
	weapons.clear()
	# Every run starts with the auto-pistol so the player can hit something immediately.
	add_weapon_by_id("basic")


func tick(delta: float, runtime: WeaponRuntime) -> void:
	for w in weapons:
		w.tick(delta, runtime)


func get_weapon_by_id(id: String) -> Weapon:
	for w in weapons:
		if w.get_id() == id:
			return w
	return null


func has_weapon(id: String) -> bool:
	return get_weapon_by_id(id) != null


func is_full() -> bool:
	return weapons.size() >= MAX_ACTIVE_WEAPONS


func add_weapon_by_id(id: String) -> Weapon:
	if has_weapon(id):
		return get_weapon_by_id(id)
	if is_full():
		return null
	var w: Weapon = _instantiate_weapon(id)
	if w == null:
		return null
	weapons.append(w)
	_connect_weapon_signals(w)
	return w


func level_up_weapon_by_id(id: String) -> bool:
	var w: Weapon = get_weapon_by_id(id)
	if w == null:
		return false
	if w.is_max_level():
		return false
	w.level_up()
	return true


func get_unowned_weapon_ids() -> Array[String]:
	var out: Array[String] = []
	if is_full():
		return out
	for id in ALL_WEAPON_IDS:
		if not has_weapon(id):
			out.append(id)
	return out


func get_levelable_weapon_ids() -> Array[String]:
	var out: Array[String] = []
	for w in weapons:
		if not w.is_max_level():
			out.append(w.get_id())
	return out


# Used by progression save payload to keep the existing schema field meaningful.
func get_damage_multiplier() -> float:
	return stats.damage_multiplier


# Used by tactical HUD / debug if needed.
func get_weapon_summary() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w in weapons:
		out.append({
			"id": w.get_id(),
			"name": w.get_display_name(),
			"level": w.level,
			"max_level": w.get_max_level(),
		})
	return out


# Display metadata for any weapon id (whether owned or not), used by the level-up UI.
static func get_display_name_for(id: String) -> String:
	match id:
		"basic": return "Auto Pistol"
		"shotgun": return "Shotgun"
		"sniper": return "Railgun"
		"chain_lightning": return "Chain Lightning"
		"aura": return "Plasma Aura"
	return id


func _instantiate_weapon(id: String) -> Weapon:
	match id:
		"basic": return BasicShotWeaponScript.new()
		"shotgun": return ShotgunWeaponScript.new()
		"sniper": return SniperWeaponScript.new()
		"chain_lightning": return ChainLightningWeaponScript.new()
		"aura": return AuraWeaponScript.new()
	return null


func _connect_weapon_signals(w: Weapon) -> void:
	if w.has_signal("aura_changed") and not w.aura_changed.is_connected(_relay_aura_changed):
		w.aura_changed.connect(_relay_aura_changed)
	if w.has_signal("beam_changed") and not w.beam_changed.is_connected(_relay_chain_beam_changed):
		w.beam_changed.connect(_relay_chain_beam_changed)


func _relay_aura_changed(radius: float, active: bool) -> void:
	aura_changed.emit(radius, active)


func _relay_chain_beam_changed(points: Array, active: bool) -> void:
	chain_beam_changed.emit(points, active)
