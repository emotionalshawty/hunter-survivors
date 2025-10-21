extends Node2D

# Spawning configuration
export var spawn_interval = 2.0
export var spawn_distance = 400.0
export var max_enemies = 50

var enemy_scene: PackedScene
var player = null
var spawn_timer = 0.0
var active_enemies = 0

func _ready():
	# Load enemy scene
	enemy_scene = load("res://scenes/enemy.tscn")

func _process(delta):
	if player == null:
		find_player()
		return
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval and active_enemies < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func spawn_enemy():
	if enemy_scene == null or player == null:
		return
	
	# Calculate random spawn position around player
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance
	
	# Instantiate enemy
	var enemy = enemy_scene.instance()
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)
	
	# Connect to enemy death signal
	enemy.connect("enemy_died", self, "_on_enemy_died")
	active_enemies += 1

func _on_enemy_died():
	active_enemies -= 1
