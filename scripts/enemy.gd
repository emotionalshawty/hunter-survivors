extends KinematicBody2D

# Enemy stats
var speed = 100
var health = 20
var damage = 10
var attack_cooldown = 1.0
var can_attack = true

# References
var player = null

# Signals
signal enemy_died

func _ready():
	add_to_group("enemies")

func _physics_process(delta):
	if player == null:
		find_player()
		return
	
	# Chase player
	var direction = (player.global_position - global_position).normalized()
	var velocity = direction * speed
	move_and_slide(velocity)

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	emit_signal("enemy_died")
	queue_free()

func _on_HitBox_body_entered(body):
	if body.is_in_group("player") and can_attack:
		body.take_damage(damage)
		can_attack = false
		# Start attack cooldown
		yield(get_tree().create_timer(attack_cooldown), "timeout")
		can_attack = true
