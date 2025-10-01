# 🏰 DOMAIN SERVICE
# Purpose: Domain management and power economy
# Layer: Application/Services
# Dependencies: Core entities (Domain, Player, Position)

class_name DomainService
extends RefCounted

# Create domain for player at position
static func create_domain(domain_id: int, player_id: int, center_position: Position, players_data: Dictionary) -> Domain:
	# Generate domain name based on player
	var domain_name = _generate_domain_name(player_id, domain_id)
	
	# Create domain
	var domain = Domain.new(domain_id, player_id, domain_name, center_position)
	
	# Add domain to player's collection
	if player_id in players_data:
		var player = players_data[player_id]
		player.add_domain(domain_id)
	
	return domain

# Generate power for all domains at start of turn
static func generate_power_for_player(player_id: int, domains_data: Dictionary) -> int:
	var total_power_generated = 0
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id:
			total_power_generated += domain.generate_power()
	
	return total_power_generated

# Consume power from player's domains
static func consume_power_for_player(player_id: int, domains_data: Dictionary, amount: int = 1) -> bool:
	# Find domains with available power
	var available_domains = []
	var total_available_power = 0
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id and domain.can_afford_power(amount):
			available_domains.append(domain)
			total_available_power += domain.power
	
	# Check if player has enough total power
	if total_available_power < amount and available_domains.size() == 0:
		return false
	
	# Consume power from first available domain
	if available_domains.size() > 0:
		var domain = available_domains[0]
		return domain.consume_power(amount)
	
	return false

# Check if player can afford power cost
static func can_player_afford_power(player_id: int, domains_data: Dictionary, amount: int = 1) -> bool:
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id and domain.can_afford_power(amount):
			return true
	return false

# Get total power for player
static func get_total_power_for_player(player_id: int, domains_data: Dictionary) -> int:
	var total_power = 0
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id:
			total_power += domain.power
	
	return total_power

# Check domain occupation by units
static func update_domain_occupation(domains_data: Dictionary, units_data: Dictionary) -> void:
	# Reset all occupations first
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		domain.liberate()
	
	# Check for occupations
	for unit_id in units_data:
		var unit = units_data[unit_id]
		
		for domain_id in domains_data:
			var domain = domains_data[domain_id]
			
			# Skip if unit owns this domain
			if unit.owner_id == domain.owner_id:
				continue
			
			# Check if unit is in domain center
			if domain.contains_position(unit.position):
				domain.occupy(unit.owner_id)
				break

# Get domains owned by player
static func get_player_domains(player_id: int, domains_data: Dictionary) -> Array[Domain]:
	var player_domains: Array[Domain] = []
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id:
			player_domains.append(domain)
	
	return player_domains

# Find domain at position
static func find_domain_at_position(position: Position, domains_data: Dictionary) -> Domain:
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.contains_position(position):
			return domain
	return null

# Get spawn positions for players (corner points adjacent to domains)
static func get_spawn_positions(grid_data: Dictionary, domains_data: Dictionary) -> Array[Position]:
	var spawn_positions: Array[Position] = []
	var corner_points = GridService.get_corner_points(grid_data)
	
	# Use corner points as spawn positions
	for corner_point in corner_points:
		spawn_positions.append(corner_point.position)
	
	return spawn_positions

# Generate domain name based on player and domain index
static func _generate_domain_name(player_id: int, domain_id: int) -> String:
	var domain_names = ["Aldara", "Belthor", "Caldris", "Drakemoor", "Eldoria", "Frostheim", "Galthara", "Helvorn"]
	var name_index = (player_id * 2 + domain_id) % domain_names.size()
	return domain_names[name_index]

# Calculate domain influence area
static func calculate_domain_influence(domain: Domain, grid_data: Dictionary) -> Array[int]:
	var influenced_points: Array[int] = []
	var influence_positions = domain.get_influence_positions()
	
	for coord in influence_positions:
		var point = _find_point_by_coordinate(grid_data, coord)
		if point != null:
			influenced_points.append(point.id)
	
	return influenced_points

# Find point by coordinate
static func _find_point_by_coordinate(grid_data: Dictionary, coord: HexCoordinate) -> HexPoint:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.hex_coord.equals(coord):
			return point
	return null

# Expand domain influence (future feature)
static func expand_domain_influence(domain: Domain) -> void:
	domain.expand_influence()

# Check if position is in any player's domain
static func is_position_in_player_domain(position: Position, player_id: int, domains_data: Dictionary) -> bool:
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id and domain.contains_position(position):
			return true
	return false