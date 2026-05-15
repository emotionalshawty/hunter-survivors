extends Node2D

const WeaponSystem = preload("res://scripts/core/systems/weapon_system.gd")
const LevelUpSystem = preload("res://scripts/core/systems/level_up_system.gd")
const DatabaseLoadSystem = preload("res://scripts/core/systems/database_load_system.gd")
const SpawnSystem = preload("res://scripts/core/systems/spawn_system.gd")
const SpatialHashScript = preload("res://scripts/core/systems/spatial_hash.gd")
const RunStatsScript = preload("res://scripts/core/systems/run_stats.gd")
const DifficultySystemScript = preload("res://scripts/core/systems/difficulty_system.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")

const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy.tscn")
const BRUTE_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_brute.tscn")
const DASHER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_dasher.tscn")
const SHIELD_BEARER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_shield_bearer.tscn")
const SPLITTER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_splitter.tscn")
const GHOST_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_ghost.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/entities/projectile.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/entities/pickup.tscn")

const PLAYER_START_HEALTH: float = 100.0
const HEALTH_UPGRADE_STEP: float = 20.0
const SPEED_UPGRADE_STEP: float = 35.0
const PLAYER_BASE_SPEED: float = 260.0
const CONTACT_DAMAGE_MULTIPLIER: float = 2.1
const CONTACT_DAMAGE_COOLDOWN: float = 0.2
const CONTACT_DAMAGE_RADIUS: float = 30.0

@onready var player: CharacterBody2D = $Player
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var effects: Node2D = $EffectsManager
@onready var spawn_timer: Timer = $SpawnTimer
@onready var difficulty_timer: Timer = $DifficultyTimer
@onready var tactical_hud: Control = $CanvasLayer/MarginContainer/HUDPanel/TacticalHUD
@onready var player_camera: Camera2D = $Player/Camera2D
@onready var level_up_layer: Control = $CanvasLayer/LevelUpLayer
@onready var game_over_layer: Control = $CanvasLayer/GameOverLayer
@onready var level_up_title_label: Label = $CanvasLayer/LevelUpLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var level_up_description_label: Label = $CanvasLayer/LevelUpLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var damage_upgrade_button: Button = $CanvasLayer/LevelUpLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/DamageButton
@onready var health_upgrade_button: Button = $CanvasLayer/LevelUpLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/HealthButton
@onready var speed_upgrade_button: Button = $CanvasLayer/LevelUpLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Choices/MoveSpeedButton
@onready var aura_visual: Node2D = $Player/AuraVisual
@onready var chain_lightning_visual: Node2D = $Player/ChainLightningVisual
@onready var pause_layer: Control = $CanvasLayer/PauseLayer
@onready var post_process_layer: CanvasLayer = $PostProcessLayer

var player_id: String = ""
var contact_damage_cooldown: float = 0.0
var _startup_load_attempted: bool = false
var _owned_weapon_modes: Array[int] = []
var _owned_passives: Array[String] = []

var _run: RunStats
var _difficulty: DifficultySystem
var _weapon_system: WeaponSystem
var _level_up_system: LevelUpSystem
var _database_load_system: DatabaseLoadSystem
var _spawn_system: SpawnSystem
var _spatial_hash: SpatialHash


func _ready() -> void:
	if not Database.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")
		return

	_run = RunStatsScript.new()
	_difficulty = DifficultySystemScript.new()
	_weapon_system = WeaponSystem.new()
	_level_up_system = LevelUpSystem.new()
	_database_load_system = DatabaseLoadSystem.new()
	_spatial_hash = SpatialHashScript.new(80.0)
	EnemyScript.spatial_hash = _spatial_hash
	_spawn_system = SpawnSystem.new(
		ENEMY_SCENE, BRUTE_ENEMY_SCENE, DASHER_ENEMY_SCENE,
		SHIELD_BEARER_ENEMY_SCENE, SPLITTER_ENEMY_SCENE, GHOST_ENEMY_SCENE
	)

	_reset_run_state()
	randomize()

	damage_upgrade_button.pressed.connect(_on_damage_upgrade_pressed)
	health_upgrade_button.pressed.connect(_on_health_upgrade_pressed)
	speed_upgrade_button.pressed.connect(_on_speed_upgrade_pressed)
	level_up_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level_up_layer.visible = false

	_weapon_system.aura_changed.connect(_on_aura_changed)
	_weapon_system.chain_beam_changed.connect(_on_chain_beam_changed)

	if game_over_layer != null:
		game_over_layer.visible = false
		_try_connect(game_over_layer, "retry_pressed", _on_retry_pressed)
		_try_connect(game_over_layer, "sign_out_pressed", _on_sign_out_pressed)
		_try_connect(game_over_layer, "main_menu_pressed", _on_navigate_main_menu)

	if pause_layer != null:
		_try_connect(pause_layer, "resume_pressed", _on_pause_resume)
		_try_connect(pause_layer, "restart_pressed", _on_pause_restart)
		_try_connect(pause_layer, "sign_out_pressed", _on_sign_out_pressed)
		_try_connect(pause_layer, "main_menu_pressed", _on_navigate_main_menu)

	_apply_post_processing_setting()
	if not Settings.settings_changed.is_connected(_apply_post_processing_setting):
		Settings.settings_changed.connect(_apply_post_processing_setting)

	spawn_timer.timeout.connect(_on_spawn_tick)
	difficulty_timer.timeout.connect(_on_difficulty_tick)
	spawn_timer.wait_time = _difficulty.enemy_spawn_interval
	spawn_timer.start()
	difficulty_timer.start()

	if not _database_load_system.connect_signals(_on_player_data_loaded, _on_player_data_saved, _on_firebase_error):
		return
	player_id = str(Database.current_user_id).strip_edges()
	if player_id.is_empty():
		return
	var loaded_username := _run.apply_loaded_profile(Database._last_loaded_data, Database.current_username)
	if not loaded_username.is_empty():
		Database.current_username = loaded_username
	_ensure_loaded_progress_from_database()
	_update_ui()


func _reset_run_state() -> void:
	_run.reset(PLAYER_START_HEALTH)
	_difficulty.reset()
	player.speed = PLAYER_BASE_SPEED
	_weapon_system.reset(player)
	contact_damage_cooldown = 0.0
	_owned_weapon_modes = [WeaponSystem.MODE_NORMAL]
	_owned_passives.clear()
	_level_up_system.reset()


func _physics_process(delta: float) -> void:
	if _spatial_hash != null:
		_spatial_hash.rebuild_from_node(enemies)

	if _weapon_system != null:
		_weapon_system.tick_active_weapons(delta, player, PROJECTILE_SCENE, projectiles, enemies)
		_weapon_system.apply_aura_damage(delta, _spatial_hash, player)
		_weapon_system.process_chain_lightning_beam(delta, _spatial_hash, player.global_position)
		_weapon_system.update_orbit_damage(delta)

	_check_contact_damage(delta)


func _check_contact_damage(delta: float) -> void:
	contact_damage_cooldown -= delta
	if contact_damage_cooldown > 0.0 or _spatial_hash == null:
		return
	var nearby := _spatial_hash.query_circle(player.global_position, CONTACT_DAMAGE_RADIUS)
	for enemy in nearby:
		if not (enemy is CharacterBody2D):
			continue
		_run.player_health = max(0.0, _run.player_health - (enemy.contact_damage * CONTACT_DAMAGE_MULTIPLIER))
		contact_damage_cooldown = CONTACT_DAMAGE_COOLDOWN
		_shake(0.55)
		if effects != null:
			effects.spawn_player_hit(player.global_position)
		_update_ui()
		if _run.player_health <= 0.0:
			_shake(0.95)
			_game_over()
		break


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if pause_layer == null or (game_over_layer != null and game_over_layer.visible):
		return
	if level_up_layer != null and level_up_layer.visible:
		return
	if pause_layer.is_open():
		pause_layer.close()
	else:
		pause_layer.open()
	get_viewport().set_input_as_handled()


func _on_spawn_tick() -> void:
	_spawn_system.spawn_tick(
		_run.level, player, enemies,
		_on_enemy_defeated, _difficulty.enemy_speed_scale,
		_difficulty.enemy_health_scale, _on_enemy_damaged
	)
	spawn_timer.wait_time = _spawn_system.compute_spawn_interval(
		_run.level, enemies.get_child_count(), _difficulty.enemy_spawn_interval
	)


func _on_difficulty_tick() -> void:
	_difficulty.tick()
	spawn_timer.wait_time = _spawn_system.compute_spawn_interval(
		_run.level, enemies.get_child_count(), _difficulty.enemy_spawn_interval
	)


func _on_enemy_defeated(xp: int, world_position: Vector2) -> void:
	_run.on_enemy_killed()
	_spawn_pickup(xp, world_position)
	if effects != null:
		effects.spawn_death(world_position)
	_shake(0.18)


func _on_enemy_damaged(world_position: Vector2, _damage_kind: String) -> void:
	if effects != null:
		effects.spawn_hit(world_position)


func _spawn_pickup(xp: int, world_position: Vector2) -> void:
	var pickup: Area2D = PICKUP_SCENE.instantiate()
	pickup.global_position = world_position
	pickup.xp_value = xp
	pickup.coin_value = max(1, xp)
	pickup.collected.connect(_on_pickup_collected)
	pickups.call_deferred("add_child", pickup)


func _on_pickup_collected(xp: int, coins: int) -> void:
	if effects != null:
		effects.spawn_pickup_absorb(player.global_position)
	var new_levels: Array[int] = _run.on_pickup_collected(xp, coins)
	for lvl in new_levels:
		_level_up_system.queue_for_level(lvl)
	if not new_levels.is_empty():
		_show_level_up_screen()
		_save_progress()
	_update_ui()


func _show_level_up_screen() -> void:
	if not _level_up_system.show_next(
		_run.level, level_up_layer,
		level_up_title_label, level_up_description_label,
		damage_upgrade_button, health_upgrade_button, speed_upgrade_button,
		_owned_weapon_modes, _owned_passives
	):
		return
	get_tree().paused = true


func _resolve_level_up_screen() -> void:
	_save_progress()
	_update_ui()
	if _level_up_system.consume_choice(level_up_layer):
		_show_level_up_screen()
		return
	get_tree().paused = false


func _on_damage_upgrade_pressed() -> void:
	_handle_level_up_button(0, "damage")

func _on_health_upgrade_pressed() -> void:
	_handle_level_up_button(1, "health")

func _on_speed_upgrade_pressed() -> void:
	_handle_level_up_button(2, "speed")


func _handle_level_up_button(button_index: int, stat_kind: String) -> void:
	if not _level_up_system.active:
		return
	if _level_up_system.is_weapon_choice():
		_apply_weapon_offer(_level_up_system.get_offer(button_index))
	else:
		_apply_stat_upgrade(stat_kind)
	_resolve_level_up_screen()


func _apply_weapon_offer(offer: Dictionary) -> void:
	if offer.is_empty():
		return
	var kind: String = str(offer.get("kind", ""))
	if kind == "active":
		var mode: int = int(offer.get("mode", WeaponSystem.MODE_NORMAL))
		var displaced: WeaponItem = _weapon_system.choose_weapon_mode(mode, player)
		if displaced != null:
			_owned_weapon_modes.erase(displaced.weapon_mode)
		if not (mode in _owned_weapon_modes):
			_owned_weapon_modes.append(mode)
	elif kind == "passive":
		var passive_id: String = str(offer.get("id", ""))
		if passive_id == "aura":
			_weapon_system.choose_aura()
		elif passive_id == "orbit":
			_weapon_system.choose_orbit(PROJECTILE_SCENE, projectiles, player)
		if not (passive_id in _owned_passives) and passive_id != "":
			_owned_passives.append(passive_id)


func _apply_stat_upgrade(stat_kind: String) -> void:
	match stat_kind:
		"damage": _weapon_system.apply_damage_upgrade()
		"health":
			_run.player_max_health += HEALTH_UPGRADE_STEP
			_run.player_health = min(_run.player_max_health, _run.player_health + HEALTH_UPGRADE_STEP)
		"speed": player.speed += SPEED_UPGRADE_STEP


func _game_over() -> void:
	spawn_timer.stop()
	difficulty_timer.stop()
	for enemy in enemies.get_children():
		enemy.queue_free()
	for projectile in projectiles.get_children():
		projectile.queue_free()
	for pickup in pickups.get_children():
		pickup.queue_free()

	var pilot_name: String = str(Database.current_username).strip_edges()
	if pilot_name.is_empty():
		pilot_name = "anonymous"

	var stats: Dictionary = _run.finalize_run(pilot_name, player_id)
	_save_progress({
		"best_score": _run.best_score,
		"total_xp_collected": _run.total_xp_collected,
		"lifetime_deaths": _run.lifetime_deaths,
		"last_score": stats.get("score", 0),
		"last_level": stats.get("level", 1),
		"last_coins_earned": stats.get("credits_earned", 0),
		"last_total_coins": _run.total_coins,
		"last_run_unix": int(Time.get_unix_time_from_system()),
	})
	Database.push_global_stats(_run.run_xp_gained, stats.get("score", 0))

	get_tree().paused = false
	level_up_layer.visible = false
	chain_lightning_visual.call("set_active", false)
	_level_up_system.reset()
	set_physics_process(false)
	player.set_physics_process(false)

	if tactical_hud != null:
		tactical_hud.show_game_over()
	if game_over_layer != null and game_over_layer.has_method("show_stats"):
		game_over_layer.show_stats(stats)


func _navigate_to(scene_path: String, logout: bool = false) -> void:
	if pause_layer != null and pause_layer.is_open():
		pause_layer.close()
	get_tree().paused = false
	if logout:
		Database.logout()
	get_tree().change_scene_to_file(scene_path)


func _on_pause_resume() -> void:
	if pause_layer != null:
		pause_layer.close()

func _on_pause_restart() -> void:
	_navigate_to("res://scenes/main.tscn")

func _on_sign_out_pressed() -> void:
	_navigate_to("res://scenes/ui/LoginScreen.tscn", true)

func _on_navigate_main_menu() -> void:
	_navigate_to("res://scenes/ui/MainMenu.tscn")

func _on_retry_pressed() -> void:
	_navigate_to("res://scenes/main.tscn")


func _ensure_loaded_progress_from_database() -> void:
	_startup_load_attempted = _database_load_system.ensure_initial_load(
		player_id, _startup_load_attempted,
		not Database._last_loaded_data.is_empty(),
		Database.is_data_request_in_progress()
	)


func _save_progress(extra_data: Dictionary = {}) -> void:
	var database := get_node_or_null("/root/Database")
	if database == null or player_id.is_empty():
		return
	var mult: float = _weapon_system.projectile_damage_multiplier if _weapon_system != null else 1.0
	database.save_player_data(player_id, _run.total_coins, _run.highest_level,
		_run.make_save_payload(player.speed, mult, extra_data))


func _on_player_data_loaded(loaded_player_id: String, data: Dictionary) -> void:
	if loaded_player_id != player_id:
		return
	var username := _run.apply_loaded_profile(data, Database.current_username)
	if not username.is_empty():
		Database.current_username = username
	_update_ui()


func _on_player_data_saved(_saved_id: String, _data: Dictionary) -> void:
	pass


func _on_firebase_error(operation: String, errored_id: String, code: int, message: String) -> void:
	if errored_id == player_id:
		push_warning("[Firebase] %s code=%d: %s" % [operation, code, message])


func _update_ui() -> void:
	if tactical_hud == null:
		return
	var username: String = str(Database.current_username)
	if username.is_empty():
		username = "anonymous"
	tactical_hud.set_pilot(username)
	tactical_hud.set_health(_run.player_health, _run.player_max_health)
	tactical_hud.set_level(_run.level, _run.experience, _run.experience_to_level)
	tactical_hud.set_stats(_run.score, _run.highest_level, _run.total_coins + _run.score)


func _on_aura_changed(radius: float, active: bool) -> void:
	if aura_visual == null:
		return
	aura_visual.call("set_radius", radius)
	aura_visual.call("set_enabled", active)


func _on_chain_beam_changed(points: Array, active: bool) -> void:
	if chain_lightning_visual == null:
		return
	if not active or points.size() < 2:
		chain_lightning_visual.call("set_active", false)
		return
	var typed: Array[Vector2] = []
	for p in points:
		typed.append(p as Vector2)
	chain_lightning_visual.call("set_chain_points", typed, true)


func _shake(amount: float) -> void:
	if not Settings.screen_shake_enabled:
		return
	if player_camera != null and player_camera.has_method("add_trauma"):
		player_camera.add_trauma(amount)


func _apply_post_processing_setting() -> void:
	if post_process_layer != null:
		post_process_layer.visible = Settings.post_processing_enabled


func _try_connect(node: Node, signal_name: String, callable: Callable) -> void:
	if node.has_signal(signal_name) and not node.get(signal_name).is_connected(callable):
		node.get(signal_name).connect(callable)
