# 🏰 DOMAIN
# Purpose: Player territory entity (replicable for N domains per player)
# Layer: Core/Entities
# Dependencies: Position, GameConstants

extends RefCounted

# Preload dependencies
const Position = preload("res://core/value_objects/position.gd")
const HexCoordinate = preload("res://core/value_objects/hex_coordinate.gd")
const GameConstants = preload("res://core/constants/game_constants.gd")
const Player = preload("res://core/entities/player.gd")

var id: int
var owner_id: int
var name: String
var center_position: Position
var power: int
var influence_radius: int = 1  # Hexes around center
var is_occupied: bool = false
var occupied_by_player: int = -1

# NEW: Real domain structure (7 points + 12 edges)
var internal_point_ids: Array[int] = []  # 7 points: center + 6 around
var internal_edge_ids: Array[int] = []   # 12 edges: 6 from center + 6 outer ring

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
func contains_position(check_position) -> bool:
	return center_position.distance_to(check_position) <= influence_radius

# Get all positions within domain influence
func get_influence_positions() -> Array:
	var positions = []
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

# NEW: Set internal structure (called during domain creation)
func set_internal_structure(point_ids: Array[int], edge_ids: Array[int]) -> void:
	internal_point_ids = point_ids.duplicate()
	internal_edge_ids = edge_ids.duplicate()

# NEW: Check if point is part of this domain's internal structure
func contains_internal_point(point_id: int) -> bool:
	return point_id in internal_point_ids

# NEW: Check if edge is part of this domain's internal structure
func contains_internal_edge(edge_id: int) -> bool:
	return edge_id in internal_edge_ids

# NEW: Get center point ID (first in the array)
func get_center_point_id() -> int:
	if internal_point_ids.size() > 0:
		return internal_point_ids[0]
	return -1

# NEW: Get surrounding point IDs (excluding center)
func get_surrounding_point_ids() -> Array[int]:
	if internal_point_ids.size() > 1:
		return internal_point_ids.slice(1)  # Skip first (center)
	return []

# NEW: Check if domain has real internal structure
func has_internal_structure() -> bool:
	return internal_point_ids.size() == 7 and internal_edge_ids.size() == 12

# String representation for debugging
func get_string() -> String:
	var status = "Occupied by Player %d" % occupied_by_player if is_occupied else "Free"
	var structure_info = ""
	if has_internal_structure():
		structure_info = " [%d points, %d edges]" % [internal_point_ids.size(), internal_edge_ids.size()]
	return "Domain[%d] '%s' (Player %d) at %s - Power: %d (%s)%s" % [
		id, name, owner_id, center_position.hex_coord.get_string(), power, status, structure_info
	]