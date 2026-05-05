extends Node

const SETTINGS_PATH := "user://settings.cfg"

signal settings_changed

var screen_shake_enabled: bool = true
var post_processing_enabled: bool = true
var fullscreen: bool = false


func _ready() -> void:
	load_from_disk()
	_apply_window_mode()


func load_from_disk() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	screen_shake_enabled = bool(config.get_value("video", "screen_shake", true))
	post_processing_enabled = bool(config.get_value("video", "post_processing", true))
	fullscreen = bool(config.get_value("video", "fullscreen", false))


func save_to_disk() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "screen_shake", screen_shake_enabled)
	config.set_value("video", "post_processing", post_processing_enabled)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func set_screen_shake(value: bool) -> void:
	if screen_shake_enabled == value:
		return
	screen_shake_enabled = value
	save_to_disk()
	settings_changed.emit()


func set_post_processing(value: bool) -> void:
	if post_processing_enabled == value:
		return
	post_processing_enabled = value
	save_to_disk()
	settings_changed.emit()


func set_fullscreen(value: bool) -> void:
	if fullscreen == value:
		return
	fullscreen = value
	_apply_window_mode()
	save_to_disk()
	settings_changed.emit()


func _apply_window_mode() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
