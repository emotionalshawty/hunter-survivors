extends Node2D

const WeaponSystem = preload("res://scripts/core/systems/weapon_system.gd")
const LevelUpSystem = preload("res://scripts/core/systems/level_up_system.gd")
const ProgressionSystem = preload("res://scripts/core/systems/progression_system.gd")
const DatabaseLoadSystem = preload("res://scripts/core/systems/database_load_system.gd")
const SpawnSystem = preload("res://scripts/core/systems/spawn_system.gd")
const SpatialHashScript = preload("res://scripts/core/systems/spatial_hash.gd")
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

# Tracks weapons the player has acquired this run so the level-up screen
# can offer unowned ones first.
var _owned_weapon_modes: Array[int] = []
var _owned_passives: Array[String] = []

func _ready() -> void:
	if not Database.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")
		return

	_weapon_system = WeaponSystem.new()
	_level_up_system = LevelUpSystem.new()
	_database_load_system = DatabaseLoadSystem.new()
	_spatial_hash = SpatialHashScript.new(80.0)
	EnemyScript.spatial_hash = _spatial_hash
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
	# player.shoot_requested is intentionally not connected — firing is now
	# driven by WeaponSystem.tick_active_weapons so each equipped weapon has
	# its own cooldown and can fire concurrently.
	damage_upgrade_button.pressed.connect(_on_damage_upgrade_pressed)
	health_upgrade_button.pressed.connect(_on_health_upgrade_pressed)
	speed_upgrade_button.pressed.connect(_on_speed_upgrade_pressed)
	level_up_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level_up_layer.visible = false
	if game_over_layer != null:
		game_over_layer.visible = false
		if game_over_layer.has_signal("retry_pressed") and not game_over_layer.retry_pressed.is_connected(_on_retry_pressed):
			game_over_layer.retry_pressed.connect(_on_retry_pressed)
		if game_over_layer.has_signal("sign_out_pressed") and not game_over_layer.sign_out_pressed.is_connected(_on_sign_out_pressed):
			game_over_layer.sign_out_pressed.connect(_on_sign_out_pressed)
		if game_over_layer.has_signal("main_menu_pressed") and not game_over_layer.main_menu_pressed.is_connected(_on_game_over_main_menu):
			game_over_layer.main_menu_pressed.connect(_on_game_over_main_menu)
	if pause_layer != null:
		if pause_layer.has_signal("resume_pressed") and not pause_layer.resume_pressed.is_connected(_on_pause_resume):
			pause_layer.resume_pressed.connect(_on_pause_resume)
		if pause_layer.has_signal("restart_pressed") and not pause_layer.restart_pressed.is_connected(_on_pause_restart):
			pause_layer.restart_pressed.connect(_on_pause_restart)
		if pause_layer.has_signal("sign_out_pressed") and not pause_layer.sign_out_pressed.is_connected(_on_pause_sign_out):
			pause_layer.sign_out_pressed.connect(_on_pause_sign_out)
		if pause_layer.has_signal("main_menu_pressed") and not pause_layer.main_menu_pressed.is_connected(_on_pause_main_menu):
			pause_layer.main_menu_pressed.connect(_on_pause_main_menu)
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
		_weapon_system.reset(player)
	contact_damage_cooldown = 0.0
	run_kills = 0
	run_xp_gained = 0
	run_start_ticks_ms = Time.get_ticks_msec()
	_owned_weapon_modes.clear()
	_owned_weapon_modes.append(WeaponSystem.MODE_NORMAL)
	_owned_passives.clear()
	if _level_up_system != null:
		_level_up_system.reset()


func _physics_process(delta: float) -> void:
	if _spatial_hash != null:
		_spatial_hash.rebuild_from_node(enemies)

	if _weapon_system != null:
		_weapon_system.tick_active_weapons(delta, player, PROJECTILE_SCENE, projectiles, enemies)
		_weapon_system.apply_aura_damage(delta, _spatial_hash, player)
		_weapon_system.process_chain_lightning_beam(delta, _spatial_hash, player.global_position)
		_weapon_system.update_orbit_damage(delta)
		_sync_aura_visual()
		_sync_chain_lightning_visual()

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


func _on_pause_main_menu() -> void:
	if pause_layer != null:
		pause_layer.close()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


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
	# Fire-and-forget: update global aggregate stats for the landing page
	_push_global_stats(run_xp_gained, run_score)
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
	Database.logout()
	get_tree().change_scene_to_file("res://scenes/ui/LoginScreen.tscn")


func _on_game_over_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


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
		projectile_multiplier = _weapon_system.projectile_damage_multiplier
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
	if not _level_up_system.show_next(level, level_up_layer, level_up_title_label, level_up_description_label, damage_upgrade_button, health_upgrade_button, speed_upgrade_button, _owned_weapon_modes, _owned_passives):
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


func _on_damage_upgrade_pressed() -> void:
	_handle_level_up_button(0, "damage")


func _on_health_upgrade_pressed() -> void:
	_handle_level_up_button(1, "health")


func _on_speed_upgrade_pressed() -> void:
	_handle_level_up_button(2, "speed")


func _handle_level_up_button(button_index: int, stat_kind: String) -> void:
	if _level_up_system == null or not _level_up_system.active:
		return
	if _level_up_system.is_weapon_choice():
		var offer: Dictionary = _level_up_system.get_offer(button_index)
		_apply_weapon_offer(offer)
	else:
		_apply_stat_upgrade(stat_kind)
	_resolve_level_up_screen()


func _apply_weapon_offer(offer: Dictionary) -> void:
	if _weapon_system == null or offer.is_empty():
		return
	var kind: String = str(offer.get("kind", ""))
	if kind == "active":
		var mode: int = int(offer.get("mode", WeaponSystem.MODE_NORMAL))
		var displaced: WeaponItem = _weapon_system.choose_weapon_mode(mode, player)
		# If the new weapon kicked an old one out of the 3-slot cap, drop the
		# displaced mode from the owned list so the level-up screen can offer it again.
		if displaced != null:
			_owned_weapon_modes.erase(displaced.weapon_mode)
		if not (mode in _owned_weapon_modes):
			_owned_weapon_modes.append(mode)
	elif kind == "passive":
		var passive_id: String = str(offer.get("id", ""))
		if passive_id == "aura":
			_weapon_system.choose_aura()
			_sync_aura_visual()
		elif passive_id == "orbit":
			_weapon_system.choose_orbit(PROJECTILE_SCENE, projectiles, player)
		if not (passive_id in _owned_passives) and passive_id != "":
			_owned_passives.append(passive_id)


func _apply_stat_upgrade(stat_kind: String) -> void:
	match stat_kind:
		"damage":
			if _weapon_system != null:
				_weapon_system.apply_damage_upgrade()
		"health":
			player_max_health += HEALTH_UPGRADE_STEP
			player_health = min(player_max_health, player_health + HEALTH_UPGRADE_STEP)
		"speed":
			player.speed += SPEED_UPGRADE_STEP


func _sync_aura_visual() -> void:
	if _weapon_system == null:
		aura_visual.call("set_enabled", false)
		return
	aura_visual.call("set_radius", _weapon_system.get_aura_radius())
	aura_visual.call("set_enabled", _weapon_system.is_aura_active())


func _sync_chain_lightning_visual() -> void:
	if _weapon_system == null:
		chain_lightning_visual.call("set_active", false)
		return
	if not _weapon_system.has_chain_beam_points():
		chain_lightning_visual.call("set_active", false)
		return
	chain_lightning_visual.call("set_chain_points", _weapon_system.get_chain_beam_points(), true)


# ---------------------------------------------------------
# GLOBAL STATS (landing page aggregate counters)
# ---------------------------------------------------------
# Atomically increments /global_stats/summary in Firestore.
# Called fire-and-forget from _game_over() — failures are silent
# so they never block the game-over screen.
#
# Firestore security rule needed (add to your rules):
#   match /global_stats/{doc} {
#     allow read: if true;          // public read for landing page
#     allow write: if request.auth != null;  // authenticated write
#   }
func _push_global_stats(xp_gained: int, coins_earned: int) -> void:
	if not Database.is_authenticated():
		return
	Database._sync_firestore_auth()
	var collection: FirestoreCollection = Firebase.Firestore.collection("global_stats")
	var doc := FirestoreDocument.new()
	doc.doc_name = "summary"
	doc.collection_name = "global_stats"
	# doc_must_exist = false → Firestore creates the document on first write
	doc._transforms.push_back(IncrementTransform.new("summary", false, "total_deaths",      1))
	doc._transforms.push_back(IncrementTransform.new("summary", false, "total_xp_collected", xp_gained))
	doc._transforms.push_back(IncrementTransform.new("summary", false, "total_coins_earned", coins_earned))
	doc._transforms.push_back(IncrementTransform.new("summary", false, "total_games_played", 1))
	var result = await collection.commit(doc)
	if result == null or (result is Dictionary and result.has("error")):
		print("[GlobalStats] Failed to push global stats: ", result)
