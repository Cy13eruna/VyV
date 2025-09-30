# 👤 PLAYER
# Purpose: Game player entity (replicable for N players)
# Layer: Core/Entities  
# Dependencies: GameConstants

extends RefCounted

var id: int
var name: String
var color: Color
var is_active: bool = false
var is_eliminated: bool = false

# Collections of owned entities
var unit_ids: Array[int] = []
var domain_ids: Array[int] = []

func _init(player_id: int, player_name: String = "", player_color: Color = Color.WHITE):
	id = player_id
	name = player_name if player_name != "" else "Player %d" % player_id
	color = player_color

# Add unit to player's collection
func add_unit(unit_id: int) -> void:
	if unit_id not in unit_ids:
		unit_ids.append(unit_id)

# Remove unit from player's collection
func remove_unit(unit_id: int) -> void:
	unit_ids.erase(unit_id)

# Add domain to player's collection
func add_domain(domain_id: int) -> void:
	if domain_id not in domain_ids:
		domain_ids.append(domain_id)

# Remove domain from player's collection
func remove_domain(domain_id: int) -> void:
	domain_ids.erase(domain_id)

# Check if player owns unit
func owns_unit(unit_id: int) -> bool:
	return unit_id in unit_ids

# Check if player owns domain
func owns_domain(domain_id: int) -> bool:
	return domain_id in domain_ids

# Get total unit count
func get_unit_count() -> int:
	return unit_ids.size()

# Get total domain count
func get_domain_count() -> int:
	return domain_ids.size()

# Check if player has any units left
func has_units() -> bool:
	return unit_ids.size() > 0

# Check if player has any domains left
func has_domains() -> bool:
	return domain_ids.size() > 0

# Eliminate player from game
func eliminate() -> void:
	is_eliminated = true
	is_active = false

# Activate player for their turn
func activate() -> void:
	if not is_eliminated:
		is_active = true

# Deactivate player (end turn)
func deactivate() -> void:
	is_active = false

# Check if player can still play
func can_play() -> bool:
	return not is_eliminated and (has_units() or has_domains())

# Generate default color based on player ID
static func get_default_color(player_id: int) -> Color:
	var colors = [
		Color.RED,        # Player 1
		Color.BLUE,       # Player 2  
		Color.GREEN,      # Player 3
		Color.YELLOW,     # Player 4
		Color.MAGENTA,    # Player 5
		Color.CYAN,       # Player 6
		Color.ORANGE,     # Player 7
		Color.PURPLE      # Player 8
	]
	return colors[player_id % colors.size()]

# String representation for debugging
func get_string() -> String:
	var status = "Active" if is_active else ("Eliminated" if is_eliminated else "Inactive")
	return "Player[%d] '%s' (%s) - Units: %d, Domains: %d" % [id, name, status, get_unit_count(), get_domain_count()]