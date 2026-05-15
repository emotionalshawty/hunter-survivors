extends Node2D

const DOT_COLOR := Color(0.08, 0.15, 0.20, 0.55)
const TILE := 64.0


func _ready() -> void:
	# Detach from parent transform so this node draws in world space.
	top_level = true
	z_index = -100
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var cam_pos := camera.get_screen_center_position() if camera != null else Vector2.ZERO
	var half := get_viewport_rect().size * 0.5 + Vector2(TILE, TILE)

	# Solid black fill covering the visible screen (plus a buffer tile).
	draw_rect(Rect2(cam_pos - half, half * 2.0), Color.BLACK, true)

	# World-aligned dot grid the pattern tiles as the camera moves in any direction.
	var origin_x := cam_pos.x - fmod(cam_pos.x, TILE) - half.x
	var origin_y := cam_pos.y - fmod(cam_pos.y, TILE) - half.y
	var end_x := cam_pos.x + half.x
	var end_y := cam_pos.y + half.y

	var wx := origin_x
	while wx <= end_x:
		var wy := origin_y
		while wy <= end_y:
			draw_circle(Vector2(wx, wy), 1.2, DOT_COLOR)
			wy += TILE
		wx += TILE
