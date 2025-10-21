# Enemy Movement and Collision System

This document describes the enemy movement and collision system implemented for VampSur.

## Overview

The system consists of three main components:
1. **Player**: Enhanced with health and collision detection
2. **Enemy**: AI-driven entities that chase and damage the player
3. **Enemy Spawner**: Manages enemy creation and wave mechanics

## Components

### Player (scripts/player.gd, scenes/player.tscn)

The player is a CharacterBody2D with:
- **Movement**: WASD/Arrow key controls at 200 units/second
- **Health System**: 100 HP with damage and healing support
- **Collision**: CircleShape2D for physics interactions
- **Signals**: 
  - `health_changed(new_health)` - Emitted when health changes
  - `player_died` - Emitted when player dies

### Enemy (scripts/enemy.gd, scenes/enemy.tscn)

Enemies are CharacterBody2D entities with:
- **AI Behavior**: Chase the player using simple pathfinding
- **Stats**: 
  - Speed: 100 units/second
  - Health: 20 HP
  - Damage: 10 HP per hit
  - Attack cooldown: 1 second
- **Collision Detection**: 
  - Body collision for physics
  - HitBox Area2D for damage detection
- **Signals**: 
  - `enemy_died` - Emitted when enemy is destroyed

### Enemy Spawner (scripts/enemy_spawner.gd)

The spawner manages enemy waves:
- **Spawn Rate**: Every 2 seconds (configurable)
- **Spawn Distance**: 400 units from player (outside camera view)
- **Max Enemies**: 50 concurrent enemies
- **Random Positioning**: Enemies spawn in a circle around the player

## Game Scene (scenes/game.tscn)

The main game scene includes:
- Player instance at center position
- Enemy Spawner node
- Camera2D attached to player for following

## How It Works

### Movement System
1. Player moves using keyboard input with `move_and_slide()`
2. Enemies calculate direction vector to player each frame
3. Enemies move toward player using `move_and_slide()`

### Collision System
1. Enemy HitBox (Area2D) detects when it enters player's body
2. On collision, enemy calls `player.take_damage(damage)`
3. Attack cooldown prevents rapid damage
4. Player health decreases and emits signal

### Spawning System
1. Spawner checks timer every frame
2. When timer expires and enemy count < max:
   - Random angle calculated around player
   - Enemy spawned at calculated position
   - Enemy connected to death signal
3. When enemy dies, counter decrements

## Configuration

All systems are configurable through exported variables:
- **Player**: `speed`, `max_health`
- **Enemy**: `speed`, `health`, `damage`, `attack_cooldown`
- **Spawner**: `spawn_interval`, `spawn_distance`, `max_enemies`

## Running the Game

Open the project in Godot and press F5 to run. The main scene is set to `res://scenes/game.tscn`.

Use arrow keys or WASD to move. Enemies will spawn and chase you, dealing damage on contact.
