# This file outlines the proposed Firestore database structure for the Vampsur game.
# It's a reference for developers and not meant to be executed directly.

# /players/{user_id}
#   - username: String
#   - email: String (optional)
#   - created_at: Timestamp
#   - last_login: Timestamp
#   - player_stats: Sub-collection -> /players/{user_id}/stats

# /players/{user_id}/stats/{stats_id} (Can be a single document: "main_stats")
#   - total_kills: Integer
#   - total_damage_dealt: Integer
#   - total_gold_collected: Integer
#   - high_score: Integer
#   - unlocked_characters: Array<String> (character_ids)
#   - unlocked_weapons: Array<String> (weapon_ids)
#   - achievements: Array<String> (achievement_ids)

# /characters/{character_id} (Static game data)
#   - name: String
#   - description: String
#   - base_health: Integer
#   - base_speed: Float
#   - starting_weapon: String (weapon_id)

# /weapons/{weapon_id} (Static game data)
#   - name: String
#   - description: String
#   - base_damage: Integer
#   - cooldown: Float
#   - area_of_effect: String (e.g., "circle", "line")
#   - evolution: String (weapon_id of the evolved weapon, can be null)

# /enemies/{enemy_id} (Static game data)
#   - name: String
#   - health: Integer
#   - damage: Integer
#   - speed: Float
#   - sprite_name: String # Reference to the sprite in the project

# /game_sessions/{session_id} (For multiplayer)
#   - players: Array<String> (user_ids)
#   - start_time: Timestamp
#   - end_time: Timestamp (nullable)
#   - game_state: String ("in_progress", "finished", "abandoned")
#   - waves_survived: Integer
