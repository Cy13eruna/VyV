# 👤 PLAYER (CLEAN)
# Purpose: Game player entity (replicable for N players)
# Layer: Core/Entities  
# Dependencies: None

extends RefCounted

var id: int
var name: String
var color: Color
var unit_ids: Array[int] = []
var domain_ids: Array[int] = []
var is_active: bool = true
var is_eliminated: bool = false

func _init(player_id: int, player_name: String, player_color: Color):
	id = player_id
	name = player_name
	color = player_color

# Add unit to player
func add_unit(unit_id: int) -> void:
	if unit_id not in unit_ids:
		unit_ids.append(unit_id)

# Remove unit from player
func remove_unit(unit_id: int) -> void:
	unit_ids.erase(unit_id)

# Add domain to player
func add_domain(domain_id: int) -> void:
	if domain_id not in domain_ids:
		domain_ids.append(domain_id)

# Remove domain from player
func remove_domain(domain_id: int) -> void:
	domain_ids.erase(domain_id)

# Get unit count
func get_unit_count() -> int:
	return unit_ids.size()

# Get domain count
func get_domain_count() -> int:
	return domain_ids.size()

# Check if player has units
func has_units() -> bool:
	return unit_ids.size() > 0

# Check if player has domains
func has_domains() -> bool:
	return domain_ids.size() > 0

# Check if player is still in game
func is_in_game() -> bool:
	return is_active and not is_eliminated and (has_units() or has_domains())

# Eliminate player
func eliminate() -> void:
	is_eliminated = true
	is_active = false

# Activate player
func activate() -> void:
	if not is_eliminated:
		is_active = true

# Deactivate player
func deactivate() -> void:
	is_active = false

# Get default color for player ID
static func get_default_color(player_id: int) -> Color:
	var colors = [
		Color.RED,
		Color(0.5, 0.0, 1.0),  # Purple (#8000FF)
		Color.GREEN,
		Color.YELLOW,
		Color.PURPLE,
		Color.ORANGE,
		Color.CYAN,
		Color.MAGENTA
	]
	return colors[(player_id - 1) % colors.size()]

# String representation for debugging
func get_string() -> String:
	var status = "Active" if is_active else ("Eliminated" if is_eliminated else "Inactive")
	return "Player[%d] '%s' (%s) - Units: %d, Domains: %d" % [id, name, status, get_unit_count(), get_domain_count()]