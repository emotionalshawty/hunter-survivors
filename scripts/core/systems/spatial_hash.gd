extends RefCounted

class_name SpatialHash

const DEFAULT_CELL_SIZE: float = 80.0

var cell_size: float = DEFAULT_CELL_SIZE
var _inv_cell_size: float = 1.0 / DEFAULT_CELL_SIZE
var _buckets: Dictionary = {}


func _init(cell: float = DEFAULT_CELL_SIZE) -> void:
	cell_size = maxf(8.0, cell)
	_inv_cell_size = 1.0 / cell_size


func clear() -> void:
	_buckets.clear()


func rebuild_from_node(parent: Node) -> void:
	_buckets.clear()
	if parent == null:
		return
	for child in parent.get_children():
		if not is_instance_valid(child):
			continue
		if not (child is Node2D):
			continue
		_insert(child)


func query_circle(center: Vector2, radius: float) -> Array:
	var result: Array = []
	if radius <= 0.0:
		return result
	var radius_sq: float = radius * radius
	var min_cell: Vector2i = _cell_for(Vector2(center.x - radius, center.y - radius))
	var max_cell: Vector2i = _cell_for(Vector2(center.x + radius, center.y + radius))
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var key: Vector2i = Vector2i(x, y)
			if not _buckets.has(key):
				continue
			var bucket: Array = _buckets[key]
			for node in bucket:
				if not is_instance_valid(node):
					continue
				var n2d: Node2D = node as Node2D
				if n2d == null:
					continue
				if n2d.global_position.distance_squared_to(center) <= radius_sq:
					result.append(n2d)
	return result


func _insert(node: Node2D) -> void:
	var key := _cell_for(node.global_position)
	var bucket: Array = _buckets.get(key, [])
	bucket.append(node)
	_buckets[key] = bucket


func _cell_for(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x * _inv_cell_size)), int(floor(pos.y * _inv_cell_size)))
