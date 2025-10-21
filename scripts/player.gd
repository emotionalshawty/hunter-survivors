extends KinematicBody2D

# Player stats
var speed = 200
var max_health = 100
var health = max_health

# Signals
signal health_changed(new_health)
signal player_died

func _ready():
	add_to_group("player")

func _physics_process(delta):
	# Get input direction
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	# Normalize direction and apply movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	var velocity = direction * speed
	move_and_slide(velocity)

func take_damage(amount):
	health -= amount
	emit_signal("health_changed", health)
	
	if health <= 0:
		health = 0
		die()

func die():
	emit_signal("player_died")
	# Could add death animation or game over logic here
	queue_free()

func heal(amount):
	health = min(health + amount, max_health)
	emit_signal("health_changed", health)
