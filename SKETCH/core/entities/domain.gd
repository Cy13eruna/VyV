# 🏰 DOMAIN
# Purpose: Player territory entity (replicable for N domains per player)
# Layer: Core/Entities
# Dependencies: Position, GameConstants

extends RefCounted

var id: int
var owner_id: int
var name: String
var center_position: Position
var power: int
var influence_radius: int = 1  # Hexes around center
var is_occupied: bool = false
var occupied_by_player: int = -1

func _init(domain_id: int, player_id: int, domain_name: String, center_pos: Position):
	id = domain_id
	owner_id = player_id
	name = domain_name
	center_position = center_pos
	power = GameConstants.INITIAL_DOMAIN_POWER

# Generate power at start of turn
func generate_power() -> int:
	if not is_occupied:
		power += GameConstants.POWER_GENERATION_PER_TURN
		return GameConstants.POWER_GENERATION_PER_TURN
	return 0

# Consume power for action
func consume_power(amount: int = GameConstants.POWER_COST_PER_ACTION) -> bool:
	if can_afford_power(amount):
		power -= amount
		return true
	return false

# Check if domain can afford power cost
func can_afford_power(amount: int = GameConstants.POWER_COST_PER_ACTION) -> bool:
	return power >= amount or is_occupied

# Check if position is within domain influence
func contains_position(check_position: Position) -> bool:
	return center_position.distance_to(check_position) <= influence_radius

# Get all positions within domain influence
func get_influence_positions() -> Array[HexCoordinate]:
	var positions: Array[HexCoordinate] = []
	var center_coord = center_position.hex_coord
	
	# Add center
	positions.append(center_coord)
	
	# Add positions within radius
	for q in range(-influence_radius, influence_radius + 1):
		for r in range(-influence_radius, influence_radius + 1):
			var coord = HexCoordinate.new(center_coord.q + q, center_coord.r + r)
			if center_coord.distance_to(coord) <= influence_radius and not coord.equals(center_coord):
				positions.append(coord)
	
	return positions

# Occupy domain by enemy player
func occupy(enemy_player_id: int) -> void:
	is_occupied = true
	occupied_by_player = enemy_player_id

# Liberate domain (remove occupation)
func liberate() -> void:
	is_occupied = false
	occupied_by_player = -1

# Check if domain is occupied by specific player
func is_occupied_by(player_id: int) -> bool:
	return is_occupied and occupied_by_player == player_id

# Check if domain should be visible to specific player
func is_visible_to_player(player_id: int, fog_of_war: bool = true) -> bool:
	# Always visible to owner
	if player_id == owner_id:
		return true
	
	# If no fog of war, always visible
	if not fog_of_war:
		return true
	
	# Visible if occupied by the player
	if is_occupied_by(player_id):
		return true
	
	# Additional visibility rules can be added here
	return false

# Expand domain influence (future feature)
func expand_influence() -> void:
	influence_radius += 1

# Get domain color based on owner
func get_color() -> Color:
	return Player.get_default_color(owner_id)

# Get domain outline color (different if occupied)
func get_outline_color() -> Color:
	if is_occupied:
		return Player.get_default_color(occupied_by_player)
	return get_color()

# String representation for debugging
func get_string() -> String:
	var status = "Occupied by Player %d" % occupied_by_player if is_occupied else "Free"
	return "Domain[%d] '%s' (Player %d) at %s - Power: %d (%s)" % [
		id, name, owner_id, center_position.hex_coord.get_string(), power, status
	]