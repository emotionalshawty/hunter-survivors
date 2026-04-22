extends "res://scripts/entities/enemy.gd"

const SPLITLING_SCENE: PackedScene = preload("res://scenes/entities/enemy_splitling.tscn")

@export var split_count: int = 2
@export var splitling_speed_scale: float = 1.18
@export var splitling_health_scale: float = 0.58
@export var split_spawn_min_offset: float = 10.0
@export var split_spawn_max_offset: float = 22.0

var _has_split: bool = false


func take_damage(amount: float, source_position: Vector2 = Vector2.INF, damage_kind: String = "generic") -> void:
	if amount <= 0.0:
		return
	if not _can_receive_damage(amount, source_position, damage_kind):
		return

	_health -= amount
	queue_redraw()
	if _health > 0.0:
		return

	if not _has_split:
		_has_split = true
		_spawn_splitlings()
	defeated.emit(xp_reward, global_position)
	queue_free()


func _spawn_splitlings() -> void:
	if SPLITLING_SCENE == null:
		return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	for _i in split_count:
		var child: CharacterBody2D = SPLITLING_SCENE.instantiate()
		if child == null:
			continue
		if child.has_method("apply_spawn_scalars"):
			child.apply_spawn_scalars(get_spawn_speed_scale() * splitling_speed_scale, get_spawn_health_scale() * splitling_health_scale)
		parent_node.add_child(child)
		var offset_dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
		child.global_position = global_position + offset_dir * randf_range(split_spawn_min_offset, split_spawn_max_offset)
		if child.has_method("set_target"):
			child.set_target(_target)
		copy_defeat_connections_to(child)
