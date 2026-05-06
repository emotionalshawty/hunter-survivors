extends CharacterBody2D

@export var speed: float = 260.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle() + PI * 0.5
	move_and_slide()
