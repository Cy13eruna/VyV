# 👁️ VISIBILITY SERVICE
# Purpose: Fog of war and visibility management
# Layer: Application/Services
# Dependencies: Core entities (Unit, Domain, HexPoint, HexEdge)

class_name VisibilityService
extends RefCounted

# Check if point is visible to specific player
static func is_point_visible_to_player(point_id: int, player_id: int, grid_data: Dictionary, 
									   units_data: Dictionary, domains_data: Dictionary, 
									   fog_of_war_enabled: bool = true) -> bool:
	# If fog of war is disabled, everything is visible
	if not fog_of_war_enabled:
		return true
	
	# Check if point is visible through unit visibility
	if _is_point_visible_through_units(point_id, player_id, grid_data, units_data):
		return true
	
	# Check if point is visible through domain revelation
	if _is_point_visible_through_domains(point_id, player_id, grid_data, domains_data):
		return true
	
	return false

# Check if edge is visible to specific player
static func is_edge_visible_to_player(edge_id: int, player_id: int, grid_data: Dictionary,
									  units_data: Dictionary, domains_data: Dictionary,
									  fog_of_war_enabled: bool = true) -> bool:
	# If fog of war is disabled, everything is visible
	if not fog_of_war_enabled:
		return true
	
	var edge = grid_data.edges[edge_id]
	
	# Edge is visible if either connected point is visible
	var point_a_visible = is_point_visible_to_player(edge.point_a_id, player_id, grid_data, units_data, domains_data, fog_of_war_enabled)
	var point_b_visible = is_point_visible_to_player(edge.point_b_id, player_id, grid_data, units_data, domains_data, fog_of_war_enabled)
	
	return point_a_visible or point_b_visible

# Check if unit is visible to specific player
static func is_unit_visible_to_player(unit: Unit, viewing_player_id: int, grid_data: Dictionary,
									  units_data: Dictionary, domains_data: Dictionary,
									  fog_of_war_enabled: bool = true) -> bool:
	# Unit is always visible to its owner
	if unit.owner_id == viewing_player_id:
		return true
	
	# If fog of war is disabled, all units are visible
	if not fog_of_war_enabled:
		return true
	
	# Unit is visible if it's force revealed
	if unit.force_revealed:
		return true
	
	# Unit is visible if its position is visible to the viewing player
	var point = _find_point_at_position(unit.position, grid_data)
	if point != null:
		return is_point_visible_to_player(point.id, viewing_player_id, grid_data, units_data, domains_data, fog_of_war_enabled)
	
	return false

# Check if domain is visible to specific player
static func is_domain_visible_to_player(domain: Domain, viewing_player_id: int, grid_data: Dictionary,
										units_data: Dictionary, domains_data: Dictionary,
										fog_of_war_enabled: bool = true) -> bool:
	# Domain is always visible to its owner
	if domain.owner_id == viewing_player_id:
		return true
	
	# If fog of war is disabled, all domains are visible
	if not fog_of_war_enabled:
		return true
	
	# Domain is visible if its center is visible
	var center_point = _find_point_at_position(domain.center_position, grid_data)
	if center_point != null:
		return is_point_visible_to_player(center_point.id, viewing_player_id, grid_data, units_data, domains_data, fog_of_war_enabled)
	
	return false

# Get all visible points for a player
static func get_visible_points_for_player(player_id: int, grid_data: Dictionary,
										  units_data: Dictionary, domains_data: Dictionary,
										  fog_of_war_enabled: bool = true) -> Array[int]:
	var visible_points: Array[int] = []
	
	for point_id in grid_data.points:
		if is_point_visible_to_player(point_id, player_id, grid_data, units_data, domains_data, fog_of_war_enabled):
			visible_points.append(point_id)
	
	return visible_points

# Get all visible edges for a player
static func get_visible_edges_for_player(player_id: int, grid_data: Dictionary,
										 units_data: Dictionary, domains_data: Dictionary,
										 fog_of_war_enabled: bool = true) -> Array[int]:
	var visible_edges: Array[int] = []
	
	for edge_id in grid_data.edges:
		if is_edge_visible_to_player(edge_id, player_id, grid_data, units_data, domains_data, fog_of_war_enabled):
			visible_edges.append(edge_id)
	
	return visible_edges

# Reset forced revelations (called at start of turn)
static func reset_forced_revelations(units_data: Dictionary) -> void:
	for unit_id in units_data:
		var unit = units_data[unit_id]
		unit.reset_force_reveal()

# Check visibility through player's units
static func _is_point_visible_through_units(point_id: int, player_id: int, grid_data: Dictionary, units_data: Dictionary) -> bool:
	var target_point = grid_data.points[point_id]
	
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.owner_id == player_id:
			# Unit can see its own position and adjacent positions
			if unit.position.equals(target_point.position):
				return true
			
			# Check adjacent positions through terrain rules
			if unit.position.is_within_distance(target_point.position, 1):
				var edge = _find_edge_between_positions(unit.position, target_point.position, grid_data)
				if edge != null and edge.allows_visibility():
					return true
	
	return false

# Check visibility through player's domains
static func _is_point_visible_through_domains(point_id: int, player_id: int, grid_data: Dictionary, domains_data: Dictionary) -> bool:
	var target_point = grid_data.points[point_id]
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.owner_id == player_id:
			# Domains permanently reveal their influence area
			if domain.contains_position(target_point.position):
				return true
	
	return false

# Find edge between two positions
static func _find_edge_between_positions(pos_a: Position, pos_b: Position, grid_data: Dictionary) -> HexEdge:
	var point_a = _find_point_at_position(pos_a, grid_data)
	var point_b = _find_point_at_position(pos_b, grid_data)
	
	if point_a == null or point_b == null:
		return null
	
	for edge_id in point_a.connected_edges:
		if edge_id in point_b.connected_edges:
			return grid_data.edges[edge_id]
	
	return null

# Find point at position
static func _find_point_at_position(position: Position, grid_data: Dictionary) -> HexPoint:
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(position):
			return point
	return null