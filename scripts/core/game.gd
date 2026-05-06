extends Node2D

const WeaponSystem = preload("res://scripts/core/systems/weapon_system.gd")
const LevelUpSystem = preload("res://scripts/core/systems/level_up_system.gd")
const ProgressionSystem = preload("res://scripts/core/systems/progression_system.gd")
const DatabaseLoadSystem = preload("res://scripts/core/systems/database_load_system.gd")
const SpawnSystem = preload("res://scripts/core/systems/spawn_system.gd")
const SpatialHashScript = preload("res://scripts/core/systems/spatial_hash.gd")
const EnemyScript = preload("res://scripts/entities/enemy.gd")
const ProjectilePoolScript = preload("res://scripts/core/systems/projectile_pool.gd")
const WeaponRuntimeScript = preload("res://scripts/core/weapons/weapon_runtime.gd")

const ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy.tscn")
const BRUTE_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_brute.tscn")
const DASHER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_dasher.tscn")
const SHIELD_BEARER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_shield_bearer.tscn")
const SPLITTER_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_splitter.tscn")
const GHOST_ENEMY_SCENE: PackedScene = preload("res://scenes/entities/enemy_ghost.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/entities/projectile.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/entities/pickup.tscn")
const PLAYER_START_HEALTH: float = 100.0
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

var score: int = 0
var level: int = 1
var experience: int = 0
var experience_to_level: int = 6
var player_max_health: float = PLAYER_START_HEALTH
var player_health: float = PLAYER_START_HEALTH
var total_coins: int = 0
var highest_level: int = 1
var lifetime_deaths: int = 0
var best_score: int = 0
var total_xp_collected: int = 0
var run_xp_gained: int = 0
var run_kills: int = 0
var run_start_ticks_ms: int = 0
var player_id: String = ""

var enemy_spawn_interval: float = 1.25
var enemy_speed_scale: float = 1.0
var enemy_health_scale: float = 1.0
var contact_damage_cooldown: float = 0.0
var _startup_load_attempted: bool = false
var _weapon_system: WeaponSystem
var _level_up_system: LevelUpSystem
var _database_load_system: DatabaseLoadSystem
var _spawn_system: SpawnSystem
var _spatial_hash: SpatialHash
var _projectile_pool: ProjectilePool
var _weapon_runtime: WeaponRuntime

func _ready() -> void:
	if not Database.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")
		return

	_weapon_system = WeaponSystem.new()
	_level_up_system = LevelUpSystem.new()
	_database_load_system = DatabaseLoadSystem.new()
	_spatial_hash = SpatialHashScript.new(80.0)
	EnemyScript.spatial_hash = _spatial_hash
	_projectile_pool = ProjectilePoolScript.new(PROJECTILE_SCENE)
	_weapon_runtime = WeaponRuntimeScript.new()
	_weapon_runtime.player = player
	_weapon_runtime.projectiles_root = projectiles
	_weapon_runtime.enemies_root = enemies
	_weapon_runtime.spatial_hash = _spatial_hash
	_weapon_runtime.projectile_pool = _projectile_pool
	_weapon_runtime.effects = effects
	_weapon_runtime.stats = _weapon_system.stats
	if not _weapon_system.aura_changed.is_connected(_on_aura_changed):
		_weapon_system.aura_changed.connect(_on_aura_changed)
	if not _weapon_system.chain_beam_changed.is_connected(_on_chain_beam_changed):
		_weapon_system.chain_beam_changed.connect(_on_chain_beam_changed)
	_spawn_system = SpawnSystem.new(
		ENEMY_SCENE,
		BRUTE_ENEMY_SCENE,
		DASHER_ENEMY_SCENE,
		SHIELD_BEARER_ENEMY_SCENE,
		SPLITTER_ENEMY_SCENE,
		GHOST_ENEMY_SCENE
	)
	_reset_run_state()
	randomize()
	damage_upgrade_button.pressed.connect(_on_offer_pressed.bind(0))
	health_upgrade_button.pressed.connect(_on_offer_pressed.bind(1))
	speed_upgrade_button.pressed.connect(_on_offer_pressed.bind(2))
	level_up_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level_up_layer.visible = false
	if game_over_layer != null:
		game_over_layer.visible = false
		if game_over_layer.has_signal("retry_pressed") and not game_over_layer.retry_pressed.is_connected(_on_retry_pressed):
			game_over_layer.retry_pressed.connect(_on_retry_pressed)
		if game_over_layer.has_signal("sign_out_pressed") and not game_over_layer.sign_out_pressed.is_connected(_on_sign_out_pressed):
			game_over_layer.sign_out_pressed.connect(_on_sign_out_pressed)
	if pause_layer != null:
		if pause_layer.has_signal("resume_pressed") and not pause_layer.resume_pressed.is_connected(_on_pause_resume):
			pause_layer.resume_pressed.connect(_on_pause_resume)
		if pause_layer.has_signal("restart_pressed") and not pause_layer.restart_pressed.is_connected(_on_pause_restart):
			pause_layer.restart_pressed.connect(_on_pause_restart)
		if pause_layer.has_signal("sign_out_pressed") and not pause_layer.sign_out_pressed.is_connected(_on_pause_sign_out):
			pause_layer.sign_out_pressed.connect(_on_pause_sign_out)
	_apply_post_processing_setting()
	if Settings.has_signal("settings_changed") and not Settings.settings_changed.is_connected(_apply_post_processing_setting):
		Settings.settings_changed.connect(_apply_post_processing_setting)
	aura_visual.call("set_enabled", false)
	chain_lightning_visual.call("set_active", false)
	spawn_timer.timeout.connect(_on_spawn_tick)
	difficulty_timer.timeout.connect(_on_difficulty_tick)
	spawn_timer.wait_time = enemy_spawn_interval
	spawn_timer.start()
	difficulty_timer.start()
	if not _database_load_system.connect_signals(_on_player_data_loaded, _on_player_data_saved, _on_firebase_error):
		print("Database autoload not found.")
		return
	player_id = str(Database.current_user_id).strip_edges()
	if player_id.is_empty():
		print("Authenticated user id is empty; cannot load/save Firebase player data.")
		return
	_apply_loaded_data(Database._last_loaded_data)
	_ensure_loaded_progress_from_database()
	_update_ui()


func _reset_run_state() -> void:
	level = 1
	experience = 0
	experience_to_level = 6
	player_max_health = PLAYER_START_HEALTH
	player_health = PLAYER_START_HEALTH
	player.speed = PLAYER_BASE_SPEED
	if _weapon_system != null:
		_weapon_system.reset()
		# Runtime stats reference must be re-bound because reset() rebuilds the stats object.
		if _weapon_runtime != null:
			_weapon_runtime.stats = _weapon_system.stats
	contact_damage_cooldown = 0.0
	run_kills = 0
	run_xp_gained = 0
	run_start_ticks_ms = Time.get_ticks_msec()
	if _level_up_system != null:
		_level_up_system.reset()


func _physics_process(delta: float) -> void:
	if _spatial_hash != null:
		_spatial_hash.rebuild_from_node(enemies)

	if _weapon_system != null and _weapon_runtime != null:
		_weapon_system.tick(delta, _weapon_runtime)

	contact_damage_cooldown -= delta
	if contact_damage_cooldown > 0.0:
		return

	if _spatial_hash == null:
		return
	var nearby := _spatial_hash.query_circle(player.global_position, CONTACT_DAMAGE_RADIUS)
	for enemy in nearby:
		if not (enemy is CharacterBody2D):
			continue
		player_health = max(0.0, player_health - (enemy.contact_damage * CONTACT_DAMAGE_MULTIPLIER))
		contact_damage_cooldown = CONTACT_DAMAGE_COOLDOWN
		_shake(0.55)
		if effects != null:
			effects.spawn_player_hit(player.global_position)
		_update_ui()
		if player_health <= 0.0:
			_shake(0.95)
			_game_over()
		break


func _on_spawn_tick() -> void:
	if _spawn_system == null:
		return
	_spawn_system.spawn_tick(level, player, enemies, _on_enemy_defeated, enemy_speed_scale, enemy_health_scale, _on_enemy_damaged)
	spawn_timer.wait_time = _spawn_system.compute_spawn_interval(level, enemies.get_child_count(), enemy_spawn_interval)


func _on_enemy_defeated(xp: int, _world_position: Vector2) -> void:
	_spawn_pickup(xp, _world_position)
	run_kills += 1
	if effects != null:
		effects.spawn_death(_world_position)
	_shake(0.18)


func _on_enemy_damaged(world_position: Vector2, _damage_kind: String) -> void:
	if effects != null:
		effects.spawn_hit(world_position)


func _shake(amount: float) -> void:
	if not Settings.screen_shake_enabled:
		return
	if player_camera != null and player_camera.has_method("add_trauma"):
		player_camera.add_trauma(amount)


func _apply_post_processing_setting() -> void:
	if post_process_layer != null:
		post_process_layer.visible = Settings.post_processing_enabled


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if pause_layer == null:
		return
	if game_over_layer != null and game_over_layer.visible:
		return
	if level_up_layer != null and level_up_layer.visible:
		return
	if pause_layer.is_open():
		pause_layer.close()
	else:
		pause_layer.open()
	get_viewport().set_input_as_handled()


func _on_pause_resume() -> void:
	if pause_layer != null:
		pause_layer.close()


func _on_pause_restart() -> void:
	if pause_layer != null:
		pause_layer.close()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_pause_sign_out() -> void:
	if pause_layer != null:
		pause_layer.close()
	get_tree().paused = false
	Database.logout()
	get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")


func _refresh_leaderboard(is_new_best: bool, best_score_value: int) -> void:
	if Database == null:
		return
	if not Database.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		Database.leaderboard_loaded.connect(_on_leaderboard_loaded)
	if not Database.leaderboard_error.is_connected(_on_leaderboard_error):
		Database.leaderboard_error.connect(_on_leaderboard_error)

	# Submit first and AWAIT it so the write is confirmed before we fetch.
	# Without the await the fetch races the submit and shows stale data.
	if is_new_best and best_score_value > 0:
		var pilot_name: String = str(Database.current_username).strip_edges()
		if pilot_name.is_empty():
			pilot_name = "anonymous"
		await Database.submit_leaderboard_entry(pilot_name, best_score_value)

	Database.fetch_leaderboard(10)


func _on_leaderboard_loaded(entries: Array) -> void:
	if game_over_layer != null and game_over_layer.has_method("set_leaderboard"):
		game_over_layer.set_leaderboard(entries)


func _on_leaderboard_error(message: String) -> void:
	if game_over_layer != null and game_over_layer.has_method("set_leaderboard_error"):
		game_over_layer.set_leaderboard_error(message)


func _on_difficulty_tick() -> void:
	enemy_spawn_interval = max(0.35, enemy_spawn_interval - 0.06)
	enemy_speed_scale += 0.08
	enemy_health_scale += 0.12
	if _spawn_system != null:
		spawn_timer.wait_time = _spawn_system.compute_spawn_interval(level, enemies.get_child_count(), enemy_spawn_interval)


func _update_ui() -> void:
	if tactical_hud == null:
		return
	var username_label: String = str(Database.current_username)
	if username_label.is_empty():
		username_label = "anonymous"
	tactical_hud.set_pilot(username_label)
	tactical_hud.set_health(player_health, player_max_health)
	tactical_hud.set_level(level, experience, experience_to_level)
	tactical_hud.set_stats(score, highest_level, total_coins + score)


func _game_over() -> void:
	spawn_timer.stop()
	difficulty_timer.stop()
	for enemy in enemies.get_children():
		enemy.queue_free()
	for projectile in projectiles.get_children():
		projectile.queue_free()
	for pickup in pickups.get_children():
		pickup.queue_free()
	var run_score: int = score
	var run_level: int = level
	var run_xp: int = experience
	var run_xp_to_level: int = experience_to_level
	var run_kills_total: int = run_kills
	var run_time_ms: int = Time.get_ticks_msec() - run_start_ticks_ms
	var previous_best: int = best_score
	var is_new_best: bool = run_score > previous_best
	total_coins += run_score
	highest_level = max(highest_level, level)
	lifetime_deaths += 1
	best_score = max(best_score, run_score)
	total_xp_collected += run_xp_gained
	_save_progress({
		"best_score": best_score,
		"total_xp_collected": total_xp_collected,
		"lifetime_deaths": lifetime_deaths,
		"last_score": run_score,
		"last_level": run_level,
		"last_xp": run_xp,
		"last_xp_to_level": run_xp_to_level,
		"last_coins_earned": run_score,
		"last_total_coins": total_coins,
		"last_run_unix": int(Time.get_unix_time_from_system())
	})
	if tactical_hud != null:
		tactical_hud.show_game_over()
	get_tree().paused = false
	level_up_layer.visible = false
	chain_lightning_visual.call("set_active", false)
	if _level_up_system != null:
		_level_up_system.reset()
	set_physics_process(false)
	player.set_physics_process(false)
	if game_over_layer != null and game_over_layer.has_method("show_stats"):
		var pilot_name: String = str(Database.current_username).strip_edges()
		game_over_layer.show_stats({
			"pilot": pilot_name,
			"user_id": player_id,
			"score": run_score,
			"level": run_level,
			"kills": run_kills_total,
			"xp_gained": run_xp_gained,
			"credits_earned": run_score,
			"time_ms": run_time_ms,
			"previous_best": previous_best,
			"best_display": best_score,
			"is_new_best": is_new_best,
		})
	_refresh_leaderboard(is_new_best, best_score)


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_sign_out_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")


func _spawn_pickup(xp: int, world_position: Vector2) -> void:
	var pickup: Area2D = PICKUP_SCENE.instantiate()
	pickup.global_position = world_position
	pickup.xp_value = xp
	pickup.coin_value = max(1, xp)
	pickup.collected.connect(_on_pickup_collected)
	pickups.call_deferred("add_child", pickup)


func _on_pickup_collected(xp: int, coins: int) -> void:
	score += coins
	experience += xp
	run_xp_gained += xp
	if effects != null:
		effects.spawn_pickup_absorb(player.global_position)
	var leveled_up := false
	while experience >= experience_to_level:
		experience -= experience_to_level
		level += 1
		highest_level = max(highest_level, level)
		experience_to_level = int(round(experience_to_level * 1.35))
		if _level_up_system != null:
			_level_up_system.queue_for_level(level)
		leveled_up = true
	if leveled_up:
		_show_level_up_screen()
		_save_progress()
	_update_ui()


func _ensure_loaded_progress_from_database() -> void:
	if _database_load_system == null:
		return
	_startup_load_attempted = _database_load_system.ensure_initial_load(
		player_id,
		_startup_load_attempted,
		not Database._last_loaded_data.is_empty(),
		Database.is_data_request_in_progress()
	)


func _apply_loaded_data(data: Dictionary) -> void:
	var profile: Dictionary = ProgressionSystem.apply_loaded_profile(data, level, Database.current_username)
	total_coins = int(profile.get("total_coins", 0))
	highest_level = int(profile.get("highest_level", highest_level))
	lifetime_deaths = int(profile.get("lifetime_deaths", 0))
	best_score = int(profile.get("best_score", 0))
	total_xp_collected = int(profile.get("total_xp_collected", 0))
	Database.current_username = str(profile.get("username", Database.current_username)).strip_edges()


func _save_progress(extra_data: Dictionary = {}) -> void:
	var database := get_node_or_null("/root/Database")
	if database == null or player_id.is_empty():
		return
	var projectile_multiplier: float = 1.0
	if _weapon_system != null:
		projectile_multiplier = _weapon_system.get_damage_multiplier()
	var payload := ProgressionSystem.make_save_payload(level, experience, experience_to_level, player_health, player_max_health, projectile_multiplier, player.speed, best_score, total_xp_collected, lifetime_deaths, extra_data)
	database.save_player_data(player_id, total_coins, highest_level, payload)


func _on_player_data_loaded(loaded_player_id: String, data: Dictionary) -> void:
	if loaded_player_id != player_id:
		return
	_apply_loaded_data(data)
	_update_ui()


func _on_player_data_saved(saved_player_id: String, _data: Dictionary) -> void:
	if saved_player_id == player_id:
		print("Player data saved to Firebase.")


func _on_firebase_error(operation: String, errored_player_id: String, response_code: int, message: String) -> void:
	if errored_player_id == player_id:
		print("Firebase error [", operation, "] code=", response_code, " message=", message)


func _show_level_up_screen() -> void:
	if _level_up_system == null:
		return
	var buttons: Array = [damage_upgrade_button, health_upgrade_button, speed_upgrade_button]
	if not _level_up_system.show_next(level, _weapon_system, level_up_layer, level_up_title_label, level_up_description_label, buttons):
		return

	get_tree().paused = true


func _resolve_level_up_screen() -> void:
	if _level_up_system == null:
		return
	_save_progress()
	_update_ui()
	if _level_up_system.consume_choice(level_up_layer):
		_show_level_up_screen()
		return
	get_tree().paused = false


func _on_offer_pressed(index: int) -> void:
	if _level_up_system == null or not _level_up_system.active:
		return
	var offer: Dictionary = _level_up_system.get_offer(index)
	if offer.is_empty():
		return
	_apply_offer(offer)
	_resolve_level_up_screen()


func _apply_offer(offer: Dictionary) -> void:
	var kind: String = str(offer.get("kind", ""))
	match kind:
		"new_weapon":
			if _weapon_system != null:
				_weapon_system.add_weapon_by_id(str(offer.get("weapon_id", "")))
		"level_weapon":
			if _weapon_system != null:
				_weapon_system.level_up_weapon_by_id(str(offer.get("weapon_id", "")))
		"stat":
			_apply_stat_offer(str(offer.get("stat_id", "")), float(offer.get("value", 0.0)))


func _apply_stat_offer(stat_id: String, value: float) -> void:
	if _weapon_system == null:
		return
	match stat_id:
		"damage":
			_weapon_system.stats.damage_multiplier += value
		"fire_rate":
			_weapon_system.stats.fire_rate_multiplier += value
		"pierce":
			_weapon_system.stats.pierce_bonus += int(value)
		"crit":
			_weapon_system.stats.crit_chance = clampf(_weapon_system.stats.crit_chance + value, 0.0, 1.0)
		"max_health":
			player_max_health += value
			player_health = min(player_max_health, player_health + value)
		"move_speed":
			player.speed += value


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
	var typed_points: Array[Vector2] = []
	for p in points:
		typed_points.append(p as Vector2)
	chain_lightning_visual.call("set_chain_points", typed_points, true)
