# 👁️ FOG VISIBILITY CALCULATOR
# Purpose: Calculate visibility rules and fog of war mechanics
# Layer: Application Services - Fog of War

extends RefCounted
class_name FogVisibilityCalculator

# Check if element should be visible to player
static func is_visible_to_player(element_type: String, element_data, player_id: int, game_state: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		return true  # Default to visible if invalid state
	
	# If fog is disabled, everything is visible
	if not game_state.fog_of_war_enabled:
		return true
	
	# Fog is enabled - check visibility rules
	match element_type:
		"unit":
			return _is_unit_visible(element_data, player_id, game_state)
		"domain":
			return _is_domain_visible(element_data, player_id, game_state)
		"grid_point":
			return _is_grid_point_visible(element_data, player_id, game_state)
		_:
			return true  # Unknown elements default to visible

# Check if a position is visible to a specific player
static func is_position_visible_to_player(position, player_id: int, game_state: Dictionary) -> bool:
	if not ("units" in game_state and "domains" in game_state and "grid" in game_state):
		return false
	
	# Check visibility from player's units (7 points: own position + 6 adjacent)
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			# Unit can see its own position AND 6 adjacent hexes (7 total)
			if unit.position.equals(position):
				# Unit can always see its own position
				return true
			elif unit.position.is_within_distance(position, 1):
				# Check if vision is blocked by terrain (mountains/forests)
				if not _is_vision_blocked_by_terrain(unit.position, position, game_state):
					return true
	
	# Check visibility from player's domains
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		# Handle both dictionary and object domains
		var domain_owner = domain.get("owner_id", -1) if typeof(domain) == TYPE_DICTIONARY else domain.owner_id
		if domain_owner == player_id:
			# NEW: If domain has real internal structure, use the actual 7 points
			if typeof(domain) == TYPE_OBJECT and domain.has_method("has_internal_structure") and domain.has_internal_structure():
				# Check if position matches any of the 7 internal points
				for point_id in domain.internal_point_ids:
					if point_id in game_state.grid.points:
						var domain_point = game_state.grid.points[point_id]
						if domain_point.position.equals(position):
							return true
			else:
				# Fallback for dictionary domains: simulate 7-point visibility
				var center_pos = domain.get("center_position")
				if center_pos:
					# Domain can see its center position
					if center_pos.equals(position):
						return true
					# Domain can see 6 surrounding positions
					if center_pos.is_within_distance(position, 1):
						return true
	
	return false

# Check if a position is visible to a specific player (IGNORING TERRAIN BLOCKING - for domains)
static func is_position_visible_to_player_ignore_terrain(position, player_id: int, game_state: Dictionary) -> bool:
	if not ("units" in game_state and "domains" in game_state and "grid" in game_state):
		return false
	
	# Check visibility from player's units (7 points: own position + 6 adjacent) - IGNORE TERRAIN
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			# Unit can see its own position AND 6 adjacent hexes (7 total)
			if unit.position.equals(position):
				# Unit can always see its own position
				return true
			elif unit.position.is_within_distance(position, 1):
				# IGNORE terrain blocking for domain visibility
				return true
	
	# Check visibility from player's domains - IGNORE TERRAIN
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		# Handle both dictionary and object domains
		var domain_owner = domain.get("owner_id", -1) if typeof(domain) == TYPE_DICTIONARY else domain.owner_id
		if domain_owner == player_id:
			# NEW: If domain has real internal structure, use the actual 7 points
			if typeof(domain) == TYPE_OBJECT and domain.has_method("has_internal_structure") and domain.has_internal_structure():
				# Check if position matches any of the 7 internal points
				for point_id in domain.internal_point_ids:
					if point_id in game_state.grid.points:
						var domain_point = game_state.grid.points[point_id]
						if domain_point.position.equals(position):
							return true
			else:
				# Fallback for dictionary domains: simulate 7-point visibility
				var center_pos = domain.get("center_position")
				if center_pos:
					# Domain can see its center position
					if center_pos.equals(position):
						return true
					# Domain can see 6 surrounding positions
					if center_pos.is_within_distance(position, 1):
						return true
	
	return false

# Helper: Check if unit is visible to player
static func _is_unit_visible(unit, player_id: int, game_state: Dictionary) -> bool:
	# Safety check
	if unit == null:
		return false
	
	# Own units are always visible (special case)
	if unit.owner_id == player_id:
		return true
	
	# Enemy units are visible if force revealed (forest traversal)
	if "force_revealed" in unit and unit.force_revealed:
		return true
	
	# Enemy units are visible only if their position is within visibility
	if is_position_visible_to_player(unit.position, player_id, game_state):
		return true
	
	return false

# Helper: Check if domain is visible to player
# NEW RULE: Domain is visible if ANY of its 7 internal points is visible (IGNORING TERRAIN BLOCKING)
static func _is_domain_visible(domain, player_id: int, game_state: Dictionary) -> bool:
	# Own domains are always visible
	var domain_owner_id = domain.get("owner_id", -1)
	if domain_owner_id == player_id:
		return true
	
	# NEW: Check if domain has real internal structure (7 points)
	if typeof(domain) == TYPE_OBJECT and domain.has_method("has_internal_structure") and domain.has_internal_structure():
		# Domain with real structure: check if ANY of the 7 internal points is visible (ignoring terrain)
		for point_id in domain.internal_point_ids:
			if point_id in game_state.grid.points:
				var point = game_state.grid.points[point_id]
				if is_position_visible_to_player_ignore_terrain(point.position, player_id, game_state):
					return true
		return false
	
	# Fallback for dictionary domains (clean system): simulate 7-point check (ignoring terrain)
	var center_position = domain.get("center_position")
	if center_position:
		# Check center position (point 1 of 7)
		if is_position_visible_to_player_ignore_terrain(center_position, player_id, game_state):
			return true
		
		# Check 6 surrounding positions (points 2-7 of 7)
		var surrounding_positions = _get_surrounding_positions(center_position)
		
		for i in range(surrounding_positions.size()):
			var pos = surrounding_positions[i]
			if is_position_visible_to_player_ignore_terrain(pos, player_id, game_state):
				return true
	
	return false

# Helper: Check if grid point is visible to player
static func _is_grid_point_visible(point, player_id: int, game_state: Dictionary) -> bool:
	# Check if point is visible through normal visibility rules
	if is_position_visible_to_player(point.position, player_id, game_state):
		return true
	
	# Special case: point is visible if a player's unit is standing on it
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id and unit.position.equals(point.position):
			return true
	
	return false

# Check if an edge/path is visible to a specific player
static func is_edge_visible_to_player(edge, player_id: int, game_state: Dictionary) -> bool:
	if not ("units" in game_state and "domains" in game_state and "grid" in game_state):
		return false
	
	# Get the two points connected by this edge
	var point_a = game_state.grid.points.get(edge.point_a_id)
	var point_b = game_state.grid.points.get(edge.point_b_id)
	
	if not (point_a and point_b):
		return false
	
	# Check if this edge is visible from units (6 paths from unit position + paths within unit's visibility)
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			# Edge is visible if it connects unit's position to an adjacent point
			if (unit.position.equals(point_a.position) and unit.position.is_within_distance(point_b.position, 1)) or \
			   (unit.position.equals(point_b.position) and unit.position.is_within_distance(point_a.position, 1)):
				return true
			# Edge is also visible if both endpoints are visible to the unit
			if is_position_visible_to_player(point_a.position, player_id, game_state) and \
			   is_position_visible_to_player(point_b.position, player_id, game_state):
				return true
	
	# Check if this edge is visible from domains (12 internal paths)
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id:
			# Edge is visible if both endpoints are within the domain (internal paths only)
			var a_in_domain = domain.center_position.equals(point_a.position) or domain.center_position.is_within_distance(point_a.position, 1)
			var b_in_domain = domain.center_position.equals(point_b.position) or domain.center_position.is_within_distance(point_b.position, 1)
			
			if a_in_domain and b_in_domain:
				return true
	
	return false

# Check if vision is blocked by terrain (mountains/forests)
static func _is_vision_blocked_by_terrain(from_position, to_position, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the edge between the two positions
	var blocking_edge = _find_edge_between_positions(from_position, to_position, game_state.grid)
	if not blocking_edge:
		return false
	
	# Check if the edge has blocking terrain
	var terrain_type = blocking_edge.get("terrain_type", 0)
	match terrain_type:
		2:  # MOUNTAIN - blocks vision
			return true
		1:  # FOREST - blocks vision
			return true
		_:  # FIELD, WATER - don't block vision
			return false

# Find edge between two positions
static func _find_edge_between_positions(pos_a, pos_b, grid_data: Dictionary):
	if not ("points" in grid_data and "edges" in grid_data):
		return null
	
	# Find points at the given positions
	var point_a = null
	var point_b = null
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if point.position.equals(pos_a):
			point_a = point
		elif point.position.equals(pos_b):
			point_b = point
	
	if not (point_a and point_b):
		return null
	
	# Find edge connecting these points
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		if (edge.point_a_id == point_a.id and edge.point_b_id == point_b.id) or \
		   (edge.point_a_id == point_b.id and edge.point_b_id == point_a.id):
			return edge
	
	return null

# Helper: Get 6 surrounding positions around a center position (for domain visibility)
static func _get_surrounding_positions(center_position) -> Array:
	var surrounding = []
	
	# For clean system: positions have hex_coord property
	if center_position.has_method("hex_coord") or "hex_coord" in center_position:
		var hex_coord = center_position.hex_coord
		
		if hex_coord and hex_coord.has_method("get_neighbor"):
			
			# Use the clean system's get_neighbor method for all 6 directions
			for direction in range(6):
				var neighbor_coord = hex_coord.get_neighbor(direction)
				
				# Create position from coordinate using clean system
				var pos_script = load("res://core/value_objects/position_clean.gd")
				var neighbor_pos = pos_script.from_hex(neighbor_coord)
				surrounding.append(neighbor_pos)
			
			return surrounding
	
	# Fallback: Try to access hex_coord properties directly
	if center_position.has_method("hex_coord") or "hex_coord" in center_position:
		var hex_coord = center_position.hex_coord
		
		if hex_coord and "q" in hex_coord and "r" in hex_coord:
			
			var q = hex_coord.q
			var r = hex_coord.r
			
			# 6 hex directions using clean system coordinate system
			var directions = [
				[1, 0],   # East
				[1, -1],  # Northeast
				[0, -1],  # Northwest
				[-1, 0],  # West
				[-1, 1],  # Southwest
				[0, 1]    # Southeast
			]
			
			for dir in directions:
				var neighbor_q = q + dir[0]
				var neighbor_r = r + dir[1]
				
				# Create hex coordinate using clean system
				var coord_script = load("res://core/value_objects/hex_coordinate_clean.gd")
				var neighbor_coord = coord_script.new(neighbor_q, neighbor_r)
				
				# Create position from coordinate using clean system
				var pos_script = load("res://core/value_objects/position_clean.gd")
				var neighbor_pos = pos_script.from_hex(neighbor_coord)
				surrounding.append(neighbor_pos)
			
			return surrounding
	
	return surrounding

# Simple validation
static func _validate_game_state_simple(game_state: Dictionary) -> bool:
	return "fog_of_war_enabled" in game_state

# Debug function to test position visibility
static func debug_position_visibility(game_state: Dictionary, player_id: int, test_position) -> Dictionary:
	var result = {
		"position_visible": false,
		"visible_from_units": [],
		"visible_from_domains": [],
		"details": []
	}
	
	# Check visibility from units
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.owner_id == player_id:
			if unit.position.equals(test_position):
				result.visible_from_units.append("Unit %d (same position)" % unit_id)
			elif unit.position.is_within_distance(test_position, 1):
				if not _is_vision_blocked_by_terrain(unit.position, test_position, game_state):
					result.visible_from_units.append("Unit %d (adjacent)" % unit_id)
	
	# Check visibility from domains
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var domain_owner = domain.get("owner_id", -1) if typeof(domain) == TYPE_DICTIONARY else domain.owner_id
		if domain_owner == player_id:
			var center_pos = domain.get("center_position")
			if center_pos:
				if center_pos.equals(test_position):
					result.visible_from_domains.append("Domain %d (center)" % domain_id)
				elif center_pos.is_within_distance(test_position, 1):
					result.visible_from_domains.append("Domain %d (adjacent)" % domain_id)
	
	result.position_visible = result.visible_from_units.size() > 0 or result.visible_from_domains.size() > 0
	
	return result

# Test function to verify domain visibility logic
static func test_domain_visibility(game_state: Dictionary, player_id: int) -> Dictionary:
	var result = {
		"total_domains": 0,
		"visible_domains": 0,
		"own_domains": 0,
		"enemy_domains_visible": 0,
		"details": []
	}
	
	if not ("domains" in game_state):
		return result
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		result.total_domains += 1
		
		var domain_owner = domain.get("owner_id", -1) if typeof(domain) == TYPE_DICTIONARY else domain.owner_id
		var is_own = domain_owner == player_id
		var is_visible = _is_domain_visible(domain, player_id, game_state)
		
		if is_own:
			result.own_domains += 1
		elif is_visible:
			result.enemy_domains_visible += 1
		
		if is_visible:
			result.visible_domains += 1
		
		result.details.append({
			"domain_id": domain_id,
			"owner_id": domain_owner,
			"is_own": is_own,
			"is_visible": is_visible,
			"has_structure": typeof(domain) == TYPE_OBJECT and domain.has_method("has_internal_structure") and domain.has_internal_structure()
		})
	
	return result