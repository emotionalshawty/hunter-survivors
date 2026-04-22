extends Area2D

signal collected(xp: int, coins: int)

@export var xp_value: int = 1
@export var coin_value: int = 1
@export var attract_radius: float = 140.0
@export var min_follow_speed: float = 40.0
@export var max_follow_speed: float = 220.0

var _player: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_find_player()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return

	var distance := global_position.distance_to(_player.global_position)
	if distance > attract_radius:
		return

	var direction := (_player.global_position - global_position).normalized()
	var t := 1.0 - (distance / attract_radius)
	var speed: float = lerpf(min_follow_speed, max_follow_speed, t)
	global_position += direction * speed * delta


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collected.emit(xp_value, coin_value)
		queue_free()
