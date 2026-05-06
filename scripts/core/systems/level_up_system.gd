extends RefCounted

class_name LevelUpSystem

const WeaponDataScript = preload("res://scripts/core/systems/weapon_data.gd")

const WEAPON_UPGRADE_LEVELS: Array[int] = [2, 5, 10, 15]
const WEAPON_UPGRADE_REPEAT_STEP: int = 5
const OFFER_COUNT: int = 3

# Stat upgrade definitions: id, label, description, type, value.
const STAT_OFFERS: Array[Dictionary] = [
	{"id": "damage", "label": "Damage +25%", "description": "Boosts every weapon", "value": 0.25},
	{"id": "fire_rate", "label": "Fire Rate +15%", "description": "All weapons attack faster", "value": 0.15},
	{"id": "pierce", "label": "Pierce +1", "description": "Projectiles hit one extra enemy", "value": 1.0},
	{"id": "crit", "label": "Crit Chance +5%", "description": "Random hits deal 2× damage", "value": 0.05},
	{"id": "max_health", "label": "Max Health +20", "description": "Heals you for the same amount", "value": 20.0},
	{"id": "move_speed", "label": "Move Speed +35", "description": "Permanent speed bonus", "value": 35.0},
]

# Order of weapons in the unlockable pool. NORMAL is the starter, excluded.
const UNLOCKABLE_ACTIVE_MODES: Array[int] = [
	WeaponDataScript.MODE_SHOTGUN,
	WeaponDataScript.MODE_CHAIN_LIGHTNING,
	WeaponDataScript.MODE_BURST,
	WeaponDataScript.MODE_SNIPER,
	WeaponDataScript.MODE_ROCKET,
	WeaponDataScript.MODE_BOOMERANG,
]

const UNLOCKABLE_PASSIVE_IDS: Array[String] = [
	WeaponDataScript.PASSIVE_AURA,
	WeaponDataScript.PASSIVE_ORBIT,
]

var pending_choices: Array[String] = []
var active: bool = false
var current_choice_type: String = ""
var current_offers: Array[Dictionary] = []

# Each entry describes a single button offer:
# {"kind": "active", "mode": int, "label": String}
# {"kind": "passive", "id": String, "label": String}
var current_offers: Array[Dictionary] = []


func reset() -> void:
	pending_choices.clear()
	current_offers.clear()
	active = false
	current_choice_type = ""


func queue_for_level(level: int) -> void:
	if _is_weapon_upgrade_level(level):
		pending_choices.append("weapon")
	else:
		pending_choices.append("stat")


func has_pending() -> bool:
	return not pending_choices.is_empty()


# Used by game.gd to know if a button slot represents a weapon offer.
func get_offer(index: int) -> Dictionary:
	if index < 0 or index >= current_offers.size():
		return {}
	return current_offers[index]


<<<<<<< HEAD
func get_offer_count() -> int:
	return current_offers.size()


func show_next(level: int, weapon_system: WeaponSystem, layer: Control, title_label: Label, description_label: Label, buttons: Array) -> bool:
=======
func get_offer(button_index: int) -> Dictionary:
	if button_index < 0 or button_index >= current_offers.size():
		return {}
	return current_offers[button_index]


func show_next(level: int, layer: Control, title_label: Label, description_label: Label, damage_button: Button, health_button: Button, speed_button: Button, owned_modes: Array[int] = [], owned_passives: Array[String] = []) -> bool:
>>>>>>> dcdc05faf45bd9c9ea451c8b73905604e8bfbf17
	if pending_choices.is_empty():
		return false

	current_choice_type = str(pending_choices[0])
	active = true
<<<<<<< HEAD
	current_offers = _build_offers(current_choice_type, weapon_system)

	if current_offers.is_empty():
		# Nothing to offer — drop this choice silently rather than block.
		pending_choices.remove_at(0)
		active = false
		current_choice_type = ""
		layer.visible = false
		return false

	if current_choice_type == "weapon":
		title_label.text = "Weapon Upgrade!"
		description_label.text = "Choose one"
=======
	current_offers.clear()

	if current_choice_type == "weapon":
		title_label.text = "Weapon Upgrade!"
		description_label.text = "Choose one weapon evolution"
		current_offers = _build_weapon_offers(owned_modes, owned_passives)
		_apply_offers_to_buttons(damage_button, health_button, speed_button)
>>>>>>> dcdc05faf45bd9c9ea451c8b73905604e8bfbf17
	else:
		title_label.text = "Level %d Reached!" % level
		description_label.text = "Pick one upgrade"

	for i in buttons.size():
		var button: Button = buttons[i]
		if button == null:
			continue
		if i < current_offers.size():
			button.text = _format_offer_label(current_offers[i])
			button.disabled = false
			button.visible = true
		else:
			button.text = "—"
			button.disabled = true
			button.visible = false

	layer.visible = true
	return true


func consume_choice(layer: Control) -> bool:
	if not pending_choices.is_empty():
		pending_choices.remove_at(0)
	current_offers.clear()
	if pending_choices.is_empty():
		active = false
		current_choice_type = ""
		layer.visible = false
		return false
	return true


func _is_weapon_upgrade_level(level: int) -> bool:
	if level in WEAPON_UPGRADE_LEVELS:
		return true
	var anchor_level: int = WEAPON_UPGRADE_LEVELS[WEAPON_UPGRADE_LEVELS.size() - 1]
	if level > anchor_level and level % WEAPON_UPGRADE_REPEAT_STEP == 0:
		return true
	return false


<<<<<<< HEAD
func _build_offers(choice_type: String, weapon_system: WeaponSystem) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	if choice_type == "weapon":
		# Pool: new weapons + level-ups for owned weapons.
		for id in weapon_system.get_unowned_weapon_ids():
			pool.append({
				"kind": "new_weapon",
				"weapon_id": id,
				"label": "%s (NEW)" % WeaponSystem.get_display_name_for(id),
				"description": "",
			})
		for id in weapon_system.get_levelable_weapon_ids():
			var w: Weapon = weapon_system.get_weapon_by_id(id)
			if w == null:
				continue
			pool.append({
				"kind": "level_weapon",
				"weapon_id": id,
				"label": "%s Lv.%d → Lv.%d" % [w.get_display_name(), w.level, w.level + 1],
				"description": w.get_level_description(),
			})
		# Fall back to stat offers if no weapon offers are available (e.g. all maxed and inventory full).
		if pool.is_empty():
			pool = _build_stat_pool()
	else:
		pool = _build_stat_pool()

	pool.shuffle()
	var picked: Array[Dictionary] = []
	for offer in pool:
		picked.append(offer)
		if picked.size() >= OFFER_COUNT:
			break
	return picked


func _build_stat_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for entry in STAT_OFFERS:
		pool.append({
			"kind": "stat",
			"stat_id": str(entry.get("id", "")),
			"value": float(entry.get("value", 0.0)),
			"label": str(entry.get("label", "")),
			"description": str(entry.get("description", "")),
		})
	return pool


func _format_offer_label(offer: Dictionary) -> String:
	var label: String = str(offer.get("label", ""))
	var description: String = str(offer.get("description", ""))
	if description.is_empty():
		return label
	return "%s\n%s" % [label, description]
=======
func _build_weapon_offers(owned_modes: Array[int], owned_passives: Array[String]) -> Array[Dictionary]:
	# Build a shuffled candidate pool of unowned weapons; fall back to owned if pool is exhausted.
	var pool: Array[Dictionary] = []

	for mode in UNLOCKABLE_ACTIVE_MODES:
		if mode in owned_modes:
			continue
		pool.append({
			"kind": "active",
			"mode": mode,
			"label": WeaponDataScript.get_mode_name(mode),
		})

	for passive_id in UNLOCKABLE_PASSIVE_IDS:
		if passive_id in owned_passives:
			continue
		pool.append({
			"kind": "passive",
			"id": passive_id,
			"label": WeaponDataScript.get_passive_name(passive_id),
		})

	pool.shuffle()

	# If we have fewer than 3 unowned options, top up from owned actives so the screen always has 3.
	if pool.size() < 3:
		var fillers: Array[Dictionary] = []
		for mode in UNLOCKABLE_ACTIVE_MODES:
			if not (mode in owned_modes):
				continue
			fillers.append({
				"kind": "active",
				"mode": mode,
				"label": "%s (re-roll)" % WeaponDataScript.get_mode_name(mode),
			})
		fillers.shuffle()
		for entry in fillers:
			if pool.size() >= 3:
				break
			pool.append(entry)

	var result: Array[Dictionary] = []
	for i in range(min(3, pool.size())):
		result.append(pool[i])
	return result


func _apply_offers_to_buttons(damage_button: Button, health_button: Button, speed_button: Button) -> void:
	var buttons: Array[Button] = [damage_button, health_button, speed_button]
	for i in buttons.size():
		var btn: Button = buttons[i]
		if i < current_offers.size():
			btn.text = str(current_offers[i].get("label", "?"))
			btn.disabled = false
			btn.visible = true
		else:
			btn.text = "—"
			btn.disabled = true
			btn.visible = true
>>>>>>> dcdc05faf45bd9c9ea451c8b73905604e8bfbf17
