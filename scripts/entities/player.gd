extends CharacterBody2D

# Kept for backwards-compat with anything still listening (e.g. effects). The
# WeaponSystem now drives firing itself via tick_active_weapons so each
# equipped weapon has its own cooldown — this signal is no longer emitted by
# the player.
signal shoot_requested(origin: Vector2, direction: Vector2)

@export var speed: float = 260.0
# Legacy field — no longer used now that each equipped weapon owns its own
# cooldown inside WeaponSystem. Kept for save-payload compatibility.
@export var fire_interval: float = 0.65


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle() + PI * 0.5
	move_and_slide()
