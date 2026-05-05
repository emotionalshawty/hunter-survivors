extends Control

signal resume_pressed
signal sign_out_pressed
signal restart_pressed

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/ResumeButton
@onready var restart_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/RestartButton
@onready var sign_out_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBox/Buttons/SignOutButton
@onready var shake_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBox/Settings/ShakeCheckBox
@onready var post_processing_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBox/Settings/PostProcessCheckBox
@onready var fullscreen_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBox/Settings/FullscreenCheckBox


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	sign_out_button.pressed.connect(func() -> void: sign_out_pressed.emit())
	shake_checkbox.toggled.connect(Settings.set_screen_shake)
	post_processing_checkbox.toggled.connect(Settings.set_post_processing)
	fullscreen_checkbox.toggled.connect(Settings.set_fullscreen)
	_sync_checkboxes_from_settings()


func open() -> void:
	_sync_checkboxes_from_settings()
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _sync_checkboxes_from_settings() -> void:
	shake_checkbox.button_pressed = Settings.screen_shake_enabled
	post_processing_checkbox.button_pressed = Settings.post_processing_enabled
	fullscreen_checkbox.button_pressed = Settings.fullscreen


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			resume_pressed.emit()
			accept_event()
