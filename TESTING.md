# Testing Guide for Enemy Movement and Collision System

## Prerequisites
- Godot Engine 3.x installed
- This repository cloned locally

## How to Test

### 1. Open the Project
1. Open Godot Engine
2. Click "Import"
3. Navigate to the project directory and select `project.godot`
4. Click "Import & Edit"

### 2. Run the Game
1. Press **F5** or click the "Play" button in the top-right corner
2. The main game scene will start automatically

### 3. Test Player Movement
- Use **Arrow Keys** or **WASD** to move the player (blue circle)
- The player should move smoothly in all directions
- Camera follows the player automatically

### 4. Test Enemy System
- **Enemy Spawning**: Red circles (enemies) should spawn around the player every 2 seconds
- **Enemy Movement**: Enemies should chase the player continuously
- **Enemy Count**: Maximum of 50 enemies will spawn at once

### 5. Test Collision System
- Allow enemies to touch the player
- Each hit deals 10 damage (player has 100 HP)
- There's a 1-second cooldown between attacks from the same enemy
- After 10 hits, the player should be destroyed

## Expected Behavior

### Player
- ✓ Moves in 8 directions with keyboard input
- ✓ Has 100 HP at start
- ✓ Takes 10 damage per enemy hit
- ✓ Dies after health reaches 0
- ✓ Camera follows player

### Enemies
- ✓ Spawn every 2 seconds in a circle around the player
- ✓ Chase the player at 100 units/second
- ✓ Deal damage on collision
- ✓ Have attack cooldown (1 second)
- ✓ Can be destroyed (health system ready for weapons)

### Spawner
- ✓ Maintains up to 50 active enemies
- ✓ Spawns enemies off-screen (400 units away)
- ✓ Tracks active enemy count

## Configuration

To adjust game balance, edit these exported variables in the Godot editor:

**Enemy Spawner**:
- `spawn_interval`: Time between spawns (default: 2.0 seconds)
- `spawn_distance`: Distance from player (default: 400 units)
- `max_enemies`: Maximum concurrent enemies (default: 50)

**In Scripts**:
- Player speed, health: `scripts/player.gd`
- Enemy speed, health, damage: `scripts/enemy.gd`

## Troubleshooting

**No enemies spawning?**
- Check that the enemy scene path is correct: `res://scenes/enemy.tscn`
- Verify the spawner is a child of the Game node

**Enemies not chasing?**
- Ensure player has the "player" group assigned
- Check that player node exists in the scene tree

**No collision damage?**
- Verify the HitBox Area2D is properly configured
- Check that the signal connection exists in enemy.tscn
- Ensure player has collision layers set up

## Next Steps

This system provides the foundation for a Vampire Survivors-style game. Consider adding:
- Weapons/attacks for the player
- Different enemy types
- Health pickups
- Experience/leveling system
- Wave progression (difficulty increase over time)
- UI for health display
- Particle effects for hits/deaths
