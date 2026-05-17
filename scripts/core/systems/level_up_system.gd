extends RefCounted

class_name LevelUpSystem

const WeaponDataScript = preload("res://scripts/core/systems/weapon_data.gd")

const WEAPON_UPGRADE_LEVELS: Array[int] = [2, 5, 10, 15]
const WEAPON_UPGRADE_REPEAT_STEP: int = 5

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


func is_weapon_choice() -> bool:
	return current_choice_type == "weapon"


func get_offer(button_index: int) -> Dictionary:
	if button_index < 0 or button_index >= current_offers.size():
		return {}
	return current_offers[button_index]


func show_next(level: int, layer: Control, title_label: Label, description_label: Label, damage_button: Button, health_button: Button, speed_button: Button, owned_modes: Array[int] = [], owned_passives: Array[String] = []) -> bool:
	if pending_choices.is_empty():
		return false

	current_choice_type = str(pending_choices[0])
	active = true
	current_offers.clear()

	if current_choice_type == "weapon":
		title_label.text = "Weapon Upgrade!"
		description_label.text = "Choose one weapon evolution"
		current_offers = _build_weapon_offers(owned_modes, owned_passives)
		_apply_offers_to_buttons(damage_button, health_button, speed_button)
	else:
		title_label.text = "Level %d Reached! Choose an upgrade:" % level
		description_label.text = "Pick one stat reward"
		damage_button.text = "Damage +25%"
		health_button.text = "Max Health +20 (and heal +20)"
		speed_button.text = "Move Speed +35"

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
