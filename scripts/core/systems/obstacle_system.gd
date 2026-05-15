extends RefCounted

class_name ObstacleSystem

const ObstacleScript = preload("res://scripts/entities/obstacle.gd")

const COUNT: int = 70
const MAP_HALF: float = 1400.0
const PLAYER_CLEAR_RADIUS: float = 220.0
const MIN_GAP: float = 80.0
const CLUSTER_CHANCE: float = 0.35
const CLUSTER_DIST: float = 110.0


func spawn(parent: Node2D, player_world_pos: Vector2) -> void:
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < COUNT and tries < COUNT * 25:
		tries += 1
		var pos := Vector2(
			randf_range(-MAP_HALF, MAP_HALF),
			randf_range(-MAP_HALF, MAP_HALF)
		)
		if not _can_place(pos, player_world_pos, placed):
			continue
		placed.append(pos)
		_spawn_obstacle(parent, pos)
		# Cluster buddy — 1 extra near this one.
		if randf() < CLUSTER_CHANCE and placed.size() < COUNT:
			var dir := Vector2.RIGHT.rotated(randf() * TAU)
			var buddy := pos + dir * randf_range(60.0, CLUSTER_DIST)
			if _can_place(buddy, player_world_pos, placed):
				placed.append(buddy)
				_spawn_obstacle(parent, buddy)


func _can_place(pos: Vector2, player_pos: Vector2, placed: Array[Vector2]) -> bool:
	if pos.distance_squared_to(player_pos) < PLAYER_CLEAR_RADIUS * PLAYER_CLEAR_RADIUS:
		return false
	var gap_sq := MIN_GAP * MIN_GAP
	for p in placed:
		if pos.distance_squared_to(p) < gap_sq:
			return false
	return true


func _spawn_obstacle(parent: Node2D, world_pos: Vector2) -> void:
	var obs := ObstacleScript.new()
	parent.add_child(obs)
	obs.global_position = world_pos
	obs.rotation = randf() * TAU
	var roll := randf()
	var shape: int = 0 if roll < 0.45 else (1 if roll < 0.75 else 2)
	obs.call("setup", shape, randf_range(18.0, 34.0))
