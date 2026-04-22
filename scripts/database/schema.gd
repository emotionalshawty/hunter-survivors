# Firestore database structure reference for the VampSur game.
# Not executed at runtime — used as developer documentation.

# /users/{user_id}   (document ID == Firebase Auth localId)
#   - username: String
#   - total_coins: int
#   - highest_level: int
#   - current_level: int
#   - current_xp: int
#   - current_xp_to_level: int
#   - current_health: float
#   - max_health: float
#   - projectile_damage_multiplier: float
#   - move_speed: float
#   - best_score: int
#   - total_xp_collected: int
#   - lifetime_deaths: int

# /listings/{listing_id}   (marketplace — reserved for future use)
#   - seller_id: String       (user_id of seller)
#   - item_type: String       (e.g. "weapon", "character")
#   - item_id: String
#   - price: int              (in-game coins)
#   - listed_at: Timestamp
#   - status: String          ("active", "sold", "cancelled")
