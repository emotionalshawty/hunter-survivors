extends Control

const LOGIN_PREFS_PATH := "user://login_prefs.cfg"

@onready var email_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PasswordInput
@onready var username_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/UsernameInput
@onready var status_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var remember_email_checkbox: CheckBox = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RememberEmailCheckBox
@onready var login_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/LoginButton
@onready var register_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/RegisterButton


func _ready() -> void:
	if has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/LoginButton"):
		login_button.pressed.connect(_on_login_pressed)
	if has_node("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/RegisterButton"):
		register_button.pressed.connect(_on_register_pressed)

	if Database.has_signal("login_success") and not Database.login_success.is_connected(_on_login_success):
		Database.login_success.connect(_on_login_success)
	if Database.has_signal("login_failed") and not Database.login_failed.is_connected(_on_login_failed):
		Database.login_failed.connect(_on_login_failed)
	if Database.has_signal("register_success") and not Database.register_success.is_connected(_on_register_success):
		Database.register_success.connect(_on_register_success)
	if Database.has_signal("register_failed") and not Database.register_failed.is_connected(_on_register_failed):
		Database.register_failed.connect(_on_register_failed)
	if Database.has_signal("username_save_failed") and not Database.username_save_failed.is_connected(_on_username_save_failed):
		Database.username_save_failed.connect(_on_username_save_failed)

	_load_login_preferences()

	status_label.text = "> AWAITING OPERATOR · ENTER CREDENTIALS"


func _on_login_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text
	if email.is_empty() or password.is_empty():
		status_label.text = "Email and password are required."
		return

	_save_login_preferences(email)

	_set_busy(true)
	status_label.text = "Logging in..."
	Database.login_with_email(email, password)


func _on_register_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text
	var username := username_input.text.strip_edges()
	if email.is_empty() or password.is_empty():
		status_label.text = "Email and password are required."
		return
	if username.is_empty():
		status_label.text = "Username is required for registration."
		return
	if password.length() < 6:
		status_label.text = "Password must have at least 6 characters."
		return

	_save_login_preferences(email)

	_set_busy(true)
	status_label.text = "Creating account..."
	Database.register_with_email(email, password, username)


func _on_login_success(_user_id: String, email: String) -> void:
	_set_busy(false)
	_persist_username_from_input()
	var username := str(Database.current_username).strip_edges()
	if username.is_empty():
		status_label.text = "Welcome"
	else:
		status_label.text = "Welcome %s" % username
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_login_failed(message: String) -> void:
	_set_busy(false)
	status_label.text = "Login failed: %s" % message


func _on_register_success(_user_id: String, email: String) -> void:
	_set_busy(false)
	_persist_username_from_input()
	if Database.current_username.is_empty():
		status_label.text = "Account created for %s. You are now logged in." % email
	else:
		status_label.text = "Account created. Welcome %s" % Database.current_username
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_register_failed(message: String) -> void:
	_set_busy(false)
	status_label.text = "Register failed: %s" % message


func _on_username_save_failed(message: String) -> void:
	_set_busy(false)
	status_label.text = "Username save failed: %s" % message


func _set_busy(value: bool) -> void:
	login_button.disabled = value
	register_button.disabled = value
	remember_email_checkbox.disabled = value
	email_input.editable = not value
	password_input.editable = not value
	username_input.editable = not value


func _load_login_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(LOGIN_PREFS_PATH) != OK:
		remember_email_checkbox.button_pressed = false
		return

	var remember := bool(config.get_value("login", "remember_email", false))
	var saved_email := str(config.get_value("login", "email", "")).strip_edges()
	remember_email_checkbox.button_pressed = remember
	if remember and not saved_email.is_empty():
		email_input.text = saved_email


func _save_login_preferences(email: String) -> void:
	var config := ConfigFile.new()
	config.set_value("login", "remember_email", remember_email_checkbox.button_pressed)
	if remember_email_checkbox.button_pressed:
		config.set_value("login", "email", email)
	else:
		config.set_value("login", "email", "")
	config.save(LOGIN_PREFS_PATH)


func _persist_username_from_input() -> void:
	var username := username_input.text.strip_edges()
	if username.is_empty():
		return
	if str(Database.current_username).strip_edges() == username:
		return
	Database.save_username(username)
