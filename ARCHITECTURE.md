# System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Game Scene                               │
│                     (scenes/game.tscn)                          │
│                                                                  │
│  ┌──────────────────────────┐    ┌────────────────────────┐   │
│  │      Player              │    │   Enemy Spawner        │   │
│  │ (KinematicBody2D)        │    │   (Node2D)             │   │
│  │                          │    │                        │   │
│  │ - Health: 100            │◄───│ - Tracks player pos    │   │
│  │ - Speed: 200             │    │ - Timer: 2s interval   │   │
│  │ - Movement: WASD/Arrows  │    │ - Max: 50 enemies      │   │
│  │ - Collision Shape        │    │                        │   │
│  │                          │    └────────┬───────────────┘   │
│  │ Signals:                 │             │                    │
│  │  • health_changed        │             │ spawns             │
│  │  • player_died           │             ▼                    │
│  └──────────────────────────┘    ┌────────────────────────┐   │
│                                   │   Enemy (x N)          │   │
│                                   │ (KinematicBody2D)      │   │
│                                   │                        │   │
│                                   │ - Health: 20           │   │
│                                   │ - Speed: 100           │   │
│                                   │ - Damage: 10           │   │
│                                   │ - Attack CD: 1s        │   │
│                                   │                        │   │
│                                   │ Components:            │   │
│                                   │  • Sprite (red)        │   │
│                                   │  • CollisionShape2D    │   │
│                                   │  • HitBox (Area2D)     │   │
│                                   │                        │   │
│                                   │ Behavior:              │   │
│                                   │  1. Find player        │   │
│                                   │  2. Chase player       │   │
│                                   │  3. Detect collision   │   │
│                                   │  4. Deal damage        │   │
│                                   └────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Game Loop Flow

```
1. Game Starts
   ├─> Player spawns at (512, 300)
   └─> Enemy Spawner activates

2. Every Frame (_process/_physics_process)
   ├─> Player: Read input, move
   ├─> Enemy Spawner: Update timer
   │   └─> If timer > 2s && enemies < 50
   │       └─> Spawn enemy at random angle, 400 units from player
   │
   └─> Each Enemy:
       ├─> Find player (if not found)
       ├─> Calculate direction to player
       ├─> Move toward player
       └─> Check HitBox collision
           └─> If touching player && can_attack
               ├─> Deal 10 damage to player
               └─> Start 1s cooldown

3. On Collision
   ├─> Enemy's HitBox enters Player's body
   ├─> Enemy calls player.take_damage(10)
   ├─> Player health decreases
   └─> If health <= 0
       └─> Player emits player_died signal
           └─> Player is destroyed (queue_free)

4. Enemy Management
   ├─> Spawner tracks active enemy count
   ├─> When enemy dies (health <= 0)
   │   ├─> Enemy emits enemy_died signal
   │   ├─> Spawner decrements counter
   │   └─> Enemy removed (queue_free)
   └─> New enemies can spawn when count < 50
```

## Collision Detection

```
Enemy (KinematicBody2D)
├─> CollisionShape2D (radius: 14)
│   └─> Physical collision with environment
│
└─> HitBox (Area2D)
    ├─> CollisionShape2D (radius: 16)
    └─> Signal: body_entered
        └─> Connected to: _on_HitBox_body_entered()
            └─> Checks if body is in "player" group
                └─> Calls body.take_damage(10)

Player (KinematicBody2D)
└─> CollisionShape2D (radius: 16)
    └─> Can be entered by Enemy's HitBox Area2D
```

## Data Flow

```
Input (WASD/Arrows)
    ↓
Player Movement
    ↓
Player Position Changes
    ↓
Camera Follows ←─────────────┐
    ↓                        │
Enemy Spawner Tracks Position │
    ↓                        │
Spawns Enemies Off-Screen ───┘
    ↓
Enemies Chase Player Position
    ↓
HitBox Collision Detection
    ↓
Damage Signal to Player
    ↓
Health System Update
    ↓
[Optional] Health Changed Signal → UI Update
    ↓
Death Check
    ↓
[If dead] Game Over
```

## Key Design Decisions

1. **Groups System**: Player/enemies use Godot groups for easy identification
2. **Signals**: Decoupled communication (enemy_died, health_changed, player_died)
3. **Off-screen Spawning**: 400 units ensures enemies spawn outside camera view
4. **Cooldown System**: Prevents damage spam from single enemy
5. **Population Control**: Max 50 enemies prevents performance issues
6. **KinematicBody2D**: Proper physics with collision handling
7. **Area2D HitBox**: Separate damage detection from physical collision

## Scalability

The system is designed for easy extension:

- **New Enemy Types**: Extend enemy.gd, override speed/health/damage
- **Weapons**: Add weapon nodes to player, detect enemies in range
- **UI**: Connect to player signals (health_changed, player_died)
- **Progression**: Modify spawner variables over time
- **Pickups**: Use Area2D similar to enemy HitBox
- **Boss Enemies**: Create new scene, use same base scripts
