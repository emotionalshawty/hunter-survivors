extends RefCounted

class_name ProjectilePool

const POOL_CAP: int = 96

var _projectile_scene: PackedScene
var _inactive: Array = []


func _init(scene: PackedScene) -> void:
	_projectile_scene = scene


func acquire(parent: Node) -> Area2D:
	var p: Area2D = null
	while not _inactive.is_empty():
		var candidate: Area2D = _inactive.pop_back()
		if is_instance_valid(candidate):
			p = candidate
			break

	if p != null:
		if p.get_parent() != parent:
			if p.get_parent() != null:
				p.get_parent().remove_child(p)
			parent.add_child(p)
		p.visible = true
		p.set_process(true)
		p.monitoring = true
		p.monitorable = true
		return p

	p = _projectile_scene.instantiate() as Area2D
	if p == null:
		return null
	p.set_meta("pool", self)
	parent.add_child(p)
	return p


func release(p: Area2D) -> void:
	if not is_instance_valid(p):
		return
	p.visible = false
	p.monitoring = false
	p.monitorable = false
	p.set_process(false)
	if _inactive.size() < POOL_CAP:
		_inactive.append(p)
	else:
		p.queue_free()
