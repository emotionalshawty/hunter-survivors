extends RefCounted

class_name LevelUpSystem

const WEAPON_UPGRADE_LEVELS: Array[int] = [2, 5, 10, 15]
const WEAPON_UPGRADE_REPEAT_STEP: int = 5

var pending_choices: Array[String] = []
var active: bool = false
var current_choice_type: String = ""


func reset() -> void:
	pending_choices.clear()
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


func show_next(level: int, layer: Control, title_label: Label, description_label: Label, damage_button: Button, health_button: Button, speed_button: Button) -> bool:
	if pending_choices.is_empty():
		return false

	current_choice_type = str(pending_choices[0])
	active = true
	if current_choice_type == "weapon":
		title_label.text = "Weapon Upgrade!"
		description_label.text = "Choose one weapon evolution"
		damage_button.text = "Chain Lightning"
		health_button.text = "Shotgun"
		speed_button.text = "Aura"
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
