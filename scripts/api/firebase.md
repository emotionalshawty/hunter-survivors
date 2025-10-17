# Firebase.gd - Singleton para toda la comunicación con Firebase
extends Node

# --- SEÑALES ---
signal login_success(user_id)
signal login_failed(error_message)
signal registration_success(user_id)
signal registration_failed(error_message)
signal save_success(document_id)
signal save_failed(error_message)
signal load_success(data)
signal load_failed(error_message)

# --- CONFIGURACIÓN ---
const API_KEY = "TU_API_KEY_AQUI"  # Pega tu API Key de la configuración del proyecto Firebase
const PROJECT_ID = "TU_ID_DE_PROYECTO_AQUI" # Pega el ID de tu proyecto

const AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const DB_URL_BASE = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents/"

# --- DATOS DE SESIÓN ---
var current_user_id: String
var id_token: String # Token para peticiones autenticadas

# --- GESTIÓN DE PETICIONES ---
var http_request: HTTPRequest
var current_request_type: String # Para saber qué hacer con la respuesta

func _ready():
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.connect("request_completed", self, "_on_request_completed")

# --- FUNCIONES DE AUTENTICACIÓN (CU1, CU2) ---
func register_user(email, password):
    current_request_type = "REGISTER"
    var url = AUTH_URL + "signUp?key=" + API_KEY
    var body = {"email": email, "password": password, "returnSecureToken": true}
    _make_request(url, body, HTTPClient.METHOD_POST)

func login_user(email, password):
    current_request_type = "LOGIN"
    var url = AUTH_URL + "signInWithPassword?key=" + API_KEY
    var body = {"email": email, "password": password, "returnSecureToken": true}
    _make_request(url, body, HTTPClient.METHOD_POST)

# --- FUNCIONES DE BASE DE DATOS (CU3, CU4) ---
func save_game(save_data: Dictionary):
    if not _is_authenticated(): return
    current_request_type = "SAVE_GAME"
    # Guardamos en una sub-colección del usuario
    var url = DB_URL_BASE + "usuarios/" + current_user_id + "/partidas_guardadas"
    var firestore_body = { "fields": _dict_to_firestore(save_data) }
    _make_request(url, firestore_body, HTTPClient.METHOD_POST, true) # POST para nuevo documento

func load_games():
    if not _is_authenticated(): return
    current_request_type = "LOAD_GAMES"
    var url = DB_URL_BASE + "usuarios/" + current_user_id + "/partidas_guardadas"
    _make_request(url, {}, HTTPClient.METHOD_GET, true)

# --- LÓGICA INTERNA ---
func _make_request(url: String, body: Dictionary = {}, method = HTTPClient.METHOD_GET, authenticated: bool = false):
    var headers = ["Content-Type: application/json"]
    var query = ""
    if authenticated:
        query = "?auth=" + id_token
    
    var body_json = JSON.print(body)
    http_request.request(url + query, headers, true, method, body_json)

func _on_request_completed(result, response_code, headers, body):
    var json = JSON.parse(body.get_string_from_utf8())
    var response_data = json.result

    if response_code >= 400:
        var error_msg = "Unknown error"
        if response_data and response_data.has("error"):
            error_msg = response_data.error.message
        _handle_error(error_msg)
        return

    # Procesar respuesta según el tipo de petición
    match current_request_type:
        "REGISTER":
            _handle_auth_response(response_data, "registration_success", "registration_failed")
        "LOGIN":
            _handle_auth_response(response_data, "login_success", "login_failed")
        "SAVE_GAME":
            print("Partida guardada! ID: ", response_data.name)
            emit_signal("save_success", response_data.name)
        "LOAD_GAMES":
            var games = []
            if response_data.has("documents"):
                for doc in response_data.documents:
                    games.append(_firestore_to_dict(doc.fields))
            emit_signal("load_success", games)

func _handle_auth_response(data, success_signal, fail_signal):
    if data and data.has("idToken"):
        self.id_token = data.idToken
        self.current_user_id = data.localId
        emit_signal(success_signal, self.current_user_id)
    else:
        emit_signal(fail_signal, "Invalid response from server")

func _handle_error(msg):
    match current_request_type:
        "REGISTER": emit_signal("registration_failed", msg)
        "LOGIN": emit_signal("login_failed", msg)
        "SAVE_GAME": emit_signal("save_failed", msg)
        "LOAD_GAMES": emit_signal("load_failed", msg)

func _is_authenticated() -> bool:
    if current_user_id.empty() or id_token.empty():
        print("Error: Usuario no autenticado.")
        return false
    return true

# --- FUNCIONES AUXILIARES DE CONVERSIÓN ---
func _dict_to_firestore(dict: Dictionary) -> Dictionary:
    # ... (código de conversión de la respuesta anterior)
    return {} # Implementar

func _firestore_to_dict(fields: Dictionary) -> Dictionary:
    # ... (código de conversión de la respuesta anterior)
    return {} # Implementar