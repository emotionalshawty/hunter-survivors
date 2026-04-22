extends RefCounted

class_name DatabaseLoadSystem


func get_database() -> Node:
	var scene_tree := Engine.get_main_loop() as SceneTree
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null("Database")


func connect_signals(on_loaded: Callable, on_saved: Callable, on_error: Callable) -> bool:
	var database := get_database()
	if database == null:
		return false

	if database.has_signal("player_data_loaded") and not database.player_data_loaded.is_connected(on_loaded):
		database.player_data_loaded.connect(on_loaded)
	if database.has_signal("player_data_saved") and not database.player_data_saved.is_connected(on_saved):
		database.player_data_saved.connect(on_saved)
	if database.has_signal("firebase_error") and not database.firebase_error.is_connected(on_error):
		database.firebase_error.connect(on_error)
	return true


func load_player_data(player_id: String) -> void:
	if player_id.is_empty():
		return
	var database := get_database()
	if database == null:
		return
	database.load_player_data(player_id)


func ensure_initial_load(player_id: String, startup_load_attempted: bool, has_cached_data: bool, request_in_progress: bool) -> bool:
	if startup_load_attempted:
		return startup_load_attempted
	if has_cached_data:
		return startup_load_attempted
	if request_in_progress:
		return startup_load_attempted
	load_player_data(player_id)
	return true
