extends Node

const FIREBASE_URL = "https://huntersurv-2f7da-default-rtdb.europe-west1.firebasedatabase.app/"
const FIREBASE_WEB_API_KEY = "AIzaSyA3flUW6457UE-yCenjkAhYwjQN57XCsTA"
const AUTH_BASE_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const AUTH_REQUEST_TIMEOUT_SECONDS: float = 12.0
const DATABASE_REQUEST_TIMEOUT_SECONDS: float = 10.0

signal player_data_loaded(player_id: String, data: Dictionary)
signal player_data_saved(player_id: String, data: Dictionary)
signal firebase_error(operation: String, player_id: String, response_code: int, message: String)
signal login_success(user_id: String, email: String)
signal login_failed(message: String)
signal register_success(user_id: String, email: String)
signal register_failed(message: String)
signal username_saved(user_id: String, username: String)
signal username_save_failed(message: String)

enum RequestOperation {
	NONE,
	LOAD,
	SAVE
}

var http_request: HTTPRequest
var _pending_operation: RequestOperation = RequestOperation.NONE
var _pending_player_id: String = ""
var _pending_payload: Dictionary = {}
var _queued_save_player_id: String = ""
var _queued_save_payload: Dictionary = {}
var _has_queued_save: bool = false
var _auth_http_request: HTTPRequest
var _pending_auth_operation: String = ""

var current_user_id: String = ""
var current_user_email: String = ""
var current_username: String = ""
var id_token: String = ""
var refresh_token: String = ""
var _pending_register_username: String = ""
var _last_loaded_data: Dictionary = {}
var _pending_login_success: bool = false
var _pending_login_user_id: String = ""
var _pending_login_email: String = ""

func _ready():
	# Create the HTTPRequest node dynamically
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = DATABASE_REQUEST_TIMEOUT_SECONDS
	http_request.request_completed.connect(_on_request_completed)

	_auth_http_request = HTTPRequest.new()
	add_child(_auth_http_request)
	_auth_http_request.timeout = AUTH_REQUEST_TIMEOUT_SECONDS
	_auth_http_request.request_completed.connect(_on_auth_request_completed)


func is_authenticated() -> bool:
	return not current_user_id.is_empty() and not id_token.is_empty()


func is_data_request_in_progress() -> bool:
	return _pending_operation != RequestOperation.NONE


func login_with_email(email: String, password: String) -> void:
	_start_auth_request("login", "signInWithPassword", email, password)


func register_with_email(email: String, password: String, username: String = "") -> void:
	_pending_register_username = username.strip_edges()
	_start_auth_request("register", "signUp", email, password)


func logout() -> void:
	current_user_id = ""
	current_user_email = ""
	current_username = ""
	id_token = ""
	refresh_token = ""
	_pending_register_username = ""
	_last_loaded_data = {}
	_pending_login_success = false
	_pending_login_user_id = ""
	_pending_login_email = ""


func save_username(username: String) -> void:
	if not is_authenticated():
		emit_signal("username_save_failed", "You must be authenticated to save username.")
		return

	var trimmed_username := username.strip_edges()
	if trimmed_username.is_empty():
		emit_signal("username_save_failed", "Username cannot be empty.")
		return

	current_username = trimmed_username
	_save_progress_with_username(current_user_id, trimmed_username)


func _start_auth_request(operation: String, endpoint: String, email: String, password: String) -> void:
	if FIREBASE_WEB_API_KEY.strip_edges().is_empty():
		var missing_key_message := "Missing Firebase Web API key in database.gd (FIREBASE_WEB_API_KEY)."
		if operation == "login":
			emit_signal("login_failed", missing_key_message)
		else:
			emit_signal("register_failed", missing_key_message)
		return

	if _pending_auth_operation != "":
		if operation == "login":
			emit_signal("login_failed", "Another authentication request is already in progress.")
		else:
			emit_signal("register_failed", "Another authentication request is already in progress.")
		return

	var url := "%s%s?key=%s" % [AUTH_BASE_URL, endpoint, FIREBASE_WEB_API_KEY]
	var payload := {
		"email": email.strip_edges(),
		"password": password,
		"returnSecureToken": true
	}
	var headers := ["Content-Type: application/json"]
	_pending_auth_operation = operation
	var error := _auth_http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_pending_auth_operation = ""
		if operation == "login":
			emit_signal("login_failed", "Failed to start authentication request.")
		else:
			emit_signal("register_failed", "Failed to start registration request.")


func _on_auth_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation := _pending_auth_operation
	_pending_auth_operation = ""

	if operation == "":
		return

	var body_text := body.get_string_from_utf8()
	var response_data: Variant = {}
	if not body_text.strip_edges().is_empty():
		var json := JSON.new()
		if json.parse(body_text) == OK:
			response_data = json.get_data()

	if result != HTTPRequest.RESULT_SUCCESS:
		var network_message := "Network error while authenticating."
		if result == HTTPRequest.RESULT_TIMEOUT:
			network_message = "Login timed out. Check your internet connection and try again."
		if operation == "login":
			emit_signal("login_failed", network_message)
		else:
			emit_signal("register_failed", network_message)
		return

	if response_code < 200 or response_code >= 300:
		var error_message := _extract_auth_error_message(response_data)
		if operation == "login":
			emit_signal("login_failed", error_message)
		else:
			emit_signal("register_failed", error_message)
		return

	if not (response_data is Dictionary):
		var invalid_message := "Invalid authentication response from Firebase."
		if operation == "login":
			emit_signal("login_failed", invalid_message)
		else:
			emit_signal("register_failed", invalid_message)
		return

	var data := response_data as Dictionary
	current_user_id = str(data.get("localId", ""))
	current_user_email = str(data.get("email", ""))
	id_token = str(data.get("idToken", ""))
	refresh_token = str(data.get("refreshToken", ""))

	if current_user_id.is_empty() or id_token.is_empty():
		var incomplete_message := "Authentication response missing required fields."
		if operation == "login":
			emit_signal("login_failed", incomplete_message)
		else:
			emit_signal("register_failed", incomplete_message)
		return

	if operation == "login":
		_pending_login_success = true
		_pending_login_user_id = current_user_id
		_pending_login_email = current_user_email
		_load_progress_for_user(current_user_id)
		if _pending_operation != RequestOperation.LOAD or _pending_player_id != current_user_id:
			_emit_pending_login_success()
	else:
		var username_to_store := _pending_register_username
		_pending_register_username = ""
		if not username_to_store.is_empty():
			save_username(username_to_store)
		emit_signal("register_success", current_user_id, current_user_email)


func _emit_pending_login_success() -> void:
	if not _pending_login_success:
		return
	_pending_login_success = false
	var user_id := _pending_login_user_id
	var email := _pending_login_email
	_pending_login_user_id = ""
	_pending_login_email = ""
	emit_signal("login_success", user_id, email)


func _extract_auth_error_message(response_data: Variant) -> String:
	if response_data is Dictionary:
		var data: Dictionary = response_data as Dictionary
		var error_value: Variant = data.get("error", {})
		if error_value is Dictionary:
			var error_dict: Dictionary = error_value as Dictionary
			if error_dict.has("message"):
				return str(error_dict.get("message", "Authentication failed."))
	return "Authentication failed."


func _build_user_data_url(player_id: String) -> String:
	var base_url := "%susers/%s.json" % [FIREBASE_URL, player_id]
	if id_token.strip_edges().is_empty():
		return base_url
	# RTDB reliably accepts Firebase ID tokens via auth query parameter.
	return "%s?auth=%s" % [base_url, id_token.uri_encode()]


func _get_auth_headers(include_content_type: bool = false) -> PackedStringArray:
	var headers := PackedStringArray(["Authorization: Bearer " + id_token])
	if include_content_type:
		headers.append("Content-Type: application/json")
	return headers

# ---------------------------------------------------------
# SAVING DATA
# ---------------------------------------------------------
func save_player_data(player_id: String, coins: int, max_level: int, extra_data: Dictionary = {}):
	var data_to_save := {
		"total_coins": coins,
		"highest_level": max_level
	}
	var username_to_save := current_username.strip_edges()
	if username_to_save.is_empty():
		username_to_save = str(_last_loaded_data.get("username", "")).strip_edges()
	if not username_to_save.is_empty():
		current_username = username_to_save
		data_to_save["username"] = username_to_save
	for key in extra_data.keys():
		data_to_save[key] = extra_data[key]

	if _pending_operation != RequestOperation.NONE:
		# Keep the most recent save request; this prevents losing important game-over stats.
		_queued_save_player_id = player_id
		_queued_save_payload = data_to_save
		_has_queued_save = true
		return

	_start_save_request(player_id, data_to_save)


func _start_save_request(player_id: String, data_to_save: Dictionary) -> void:
	if _pending_operation != RequestOperation.NONE:
		return
	if not is_authenticated():
		emit_signal("firebase_error", "save", player_id, 401, "Not authenticated. Please log in again.")
		return

	# We append .json to the URL for Firebase REST API
	var url = _build_user_data_url(player_id)
	
	var json_string = JSON.stringify(data_to_save)
	var headers := _get_auth_headers(true)
	_pending_operation = RequestOperation.SAVE
	_pending_player_id = player_id
	_pending_payload = data_to_save
	
	# METHOD_PATCH preserves existing keys while updating only provided fields.
	var error = http_request.request(url, headers, HTTPClient.METHOD_PATCH, json_string)
	
	if error != OK:
		_reset_pending_request()
		print("An error occurred while making the save request.")
		emit_signal("firebase_error", "save", player_id, -1, "Failed to start save request.")
		_process_queued_save()

# ---------------------------------------------------------
# LOADING DATA
# ---------------------------------------------------------
func load_player_data(player_id: String):
	if _pending_operation != RequestOperation.NONE:
		emit_signal("firebase_error", "load", player_id, -1, "A Firebase request is already in progress.")
		return
	if not is_authenticated():
		emit_signal("firebase_error", "load", player_id, 401, "Not authenticated. Please log in again.")
		emit_signal("player_data_loaded", player_id, {})
		return

	var url = _build_user_data_url(player_id)
	_pending_operation = RequestOperation.LOAD
	_pending_player_id = player_id
	_pending_payload = {}
	var error = http_request.request(url, _get_auth_headers(), HTTPClient.METHOD_GET)
	
	if error != OK:
		_reset_pending_request()
		print("An error occurred while making the load request.")
		emit_signal("firebase_error", "load", player_id, -1, "Failed to start load request.")

# ---------------------------------------------------------
# HANDLING RESPONSES
# ---------------------------------------------------------
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	var operation := _pending_operation
	var player_id := _pending_player_id
	var payload := _pending_payload
	_reset_pending_request()

	var operation_name := "load" if operation == RequestOperation.LOAD else "save"
	var body_text := body.get_string_from_utf8()

	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("firebase_error", operation_name, player_id, response_code, "Network request failed.")
		if operation == RequestOperation.LOAD and player_id == current_user_id:
			_emit_pending_login_success()
		_process_queued_save()
		return

	if response_code < 200 or response_code >= 300:
		emit_signal("firebase_error", operation_name, player_id, response_code, body_text)
		if operation == RequestOperation.LOAD and player_id == current_user_id:
			_emit_pending_login_success()
		_process_queued_save()
		return

	var response_data: Variant = {}
	if not body_text.strip_edges().is_empty():
		var json := JSON.new()
		var parse_error := json.parse(body_text)
		if parse_error != OK:
			emit_signal("firebase_error", operation_name, player_id, response_code, "JSON parse error.")
			if operation == RequestOperation.LOAD and player_id == current_user_id:
				_emit_pending_login_success()
			_process_queued_save()
			return
		response_data = json.get_data()

	if operation == RequestOperation.LOAD:
		if response_data == null:
			if player_id == current_user_id:
				_last_loaded_data = {}
				current_username = ""
			emit_signal("player_data_loaded", player_id, {})
			if player_id == current_user_id:
				_emit_pending_login_success()
		elif response_data is Dictionary:
			if player_id == current_user_id:
				_last_loaded_data = (response_data as Dictionary).duplicate(true)
				current_username = str((response_data as Dictionary).get("username", "")).strip_edges()
			emit_signal("player_data_loaded", player_id, response_data)
			if player_id == current_user_id:
				_emit_pending_login_success()
		else:
			emit_signal("firebase_error", operation_name, player_id, response_code, "Unexpected response format.")
			if player_id == current_user_id:
				_emit_pending_login_success()
			_process_queued_save()
		return

	emit_signal("player_data_saved", player_id, payload)
	_process_queued_save()


func _reset_pending_request() -> void:
	_pending_operation = RequestOperation.NONE
	_pending_player_id = ""
	_pending_payload = {}


func _process_queued_save() -> void:
	if not _has_queued_save:
		return

	var queued_player_id := _queued_save_player_id
	var queued_payload := _queued_save_payload.duplicate(true)
	_has_queued_save = false
	_queued_save_player_id = ""
	_queued_save_payload = {}
	_start_save_request(queued_player_id, queued_payload)


func _save_progress_with_username(player_id: String, username: String) -> void:
	var payload := {
		"username": username
	}
	if _pending_operation != RequestOperation.NONE:
		_queued_save_player_id = player_id
		_queued_save_payload = payload
		_has_queued_save = true
		return

	_start_save_request(player_id, payload)
	emit_signal("username_saved", player_id, username)


func _load_progress_for_user(player_id: String) -> void:
	if player_id.strip_edges().is_empty():
		return
	if _pending_operation != RequestOperation.NONE:
		return
	load_player_data(player_id)