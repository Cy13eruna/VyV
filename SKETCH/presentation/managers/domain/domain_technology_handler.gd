# 💫 DOMAIN TECHNOLOGY HANDLER
# Purpose: Handle domain technology integration and validation
# Layer: Presentation Manager - Domain Technology

extends RefCounted
class_name DomainTechnologyHandler

# References
var technology_manager
var unit_manager

# Initialize with required references
func initialize(technology_manager_ref, unit_manager_ref):
	technology_manager = technology_manager_ref
	unit_manager = unit_manager_ref

# Check if nuclear star (domain center) is clickable
func is_nuclear_star_clickable(position, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	# Get current player to check ownership
	var TurnService = load("res://application/services/turn_service_clean.gd")
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return false
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Check if this position is the domain center
		if domain.center_position.equals(position):
			# Check if current player owns this domain
			if domain.owner_id != current_player.id:
				return false
			
			# Check if power >= level
			var domain_power = domain.get("power", 1)
			var domain_level = domain.get("level", 1)
			
			if domain_power >= domain_level:
				# Check if no unit is occupying this position
				var unit_at_position = -1
				if unit_manager:
					unit_at_position = unit_manager.find_unit_at_position(position, game_state)
				if unit_at_position == -1:
					return true
	
	return false

# Get the clicked domain by position
func get_domain_at_position(position, game_state: Dictionary):
	if not ("domains" in game_state):
		return null
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.center_position.equals(position):
			return domain
	
	return null

# Get player's total power from domains (includes market sharing)
func get_player_total_power(player_id: int, game_state: Dictionary) -> int:
	var total_power = 0
	
	if "domains" in game_state:
		# Check if player has any market domains
		var player_has_market = false
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == player_id and domain.get("has_market_upgrade", false):
				player_has_market = true
				break
		
		if player_has_market and "market_domains" in game_state:
			# Player has market access - can use power from ALL market domains globally
			for domain_id in game_state.market_domains:
				if domain_id in game_state.domains:
					var domain = game_state.domains[domain_id]
					total_power += domain.power
		else:
			# Player has no market access - only own domains
			for domain_id in game_state.domains:
				var domain = game_state.domains[domain_id]
				if domain.owner_id == player_id:
					total_power += domain.power
	
	return total_power

# Check if player has specific technology
func has_technology(player_id: int, tech_name: String) -> bool:
	if technology_manager:
		return technology_manager.has_technology(player_id, tech_name)
	return false

# Get available technologies for player
func get_available_technologies(player_id: int) -> Array:
	if technology_manager:
		return technology_manager.get_available_technologies(player_id)
	return []

# Check if domain can use harvest technology
func can_domain_use_harvest(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Check if player has harvest technology
	if not has_technology(domain.owner_id, "harvest"):
		return false
	
	# Check if domain has forest edges without harvest
	var forest_edges = get_domain_forest_edges(domain, game_state)
	for edge_id in forest_edges:
		var edge = game_state.grid.edges[edge_id]
		var structures = edge.get("structures", [])
		
		var has_harvest = false
		for structure in structures:
			if structure.get("type", "") == "harvest":
				has_harvest = true
				break
		
		if not has_harvest:
			return true
	
	return false

# Check if domain can use fish technology
func can_domain_use_fish(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Check if player has fish technology
	if not has_technology(domain.owner_id, "fish"):
		return false
	
	# Check if domain already has fish upgrade
	if domain.get("has_fish_upgrade", false):
		return false
	
	# Check if domain has water edges
	var water_edges = get_domain_water_edges(domain, game_state)
	return water_edges.size() > 0

# Get domain forest edges (helper function)
func get_domain_forest_edges(domain, game_state: Dictionary) -> Array:
	var forest_edges = []
	
	if not ("grid" in game_state):
		return forest_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return forest_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# Get radial forest edges
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 1:  # 1 = FOREST
			forest_edges.append(edge_id)
	
	# Get perimeter forest edges
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 1:  # 1 = FOREST
						forest_edges.append(edge_id)
					break
	
	return forest_edges

# Get domain water edges (helper function)
func get_domain_water_edges(domain, game_state: Dictionary) -> Array:
	var water_edges = []
	
	if not ("grid" in game_state):
		return water_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return water_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# Get radial water edges
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 3:  # 3 = WATER
			water_edges.append(edge_id)
	
	# Get perimeter water edges
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 3:  # 3 = WATER
						water_edges.append(edge_id)
					break
	
	return water_edges

# Validate domain upgrade requirements
func validate_upgrade_requirements(domain, upgrade_type: String, game_state: Dictionary) -> Dictionary:
	var result = {
		"valid": false,
		"reason": ""
	}
	
	if not domain:
		result.reason = "Domain not found"
		return result
	
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power < domain_level:
		result.reason = "Insufficient power (%d/%d)" % [domain_power, domain_level]
		return result
	
	# Check upgrade-specific requirements
	match upgrade_type:
		"HARVEST":
			if not has_technology(domain.owner_id, "harvest"):
				result.reason = "Harvest technology not available"
				return result
			if not can_domain_use_harvest(domain, game_state):
				result.reason = "All forests already have harvest"
				return result
		"FISH":
			if not has_technology(domain.owner_id, "fish"):
				result.reason = "Fish technology not available"
				return result
			if not can_domain_use_fish(domain, game_state):
				result.reason = "Domain is dry or already has fish upgrade"
				return result
		"TECH":
			var available_techs = get_available_technologies(domain.owner_id)
			if available_techs.is_empty():
				result.reason = "No technologies available for purchase"
				return result
	
	result.valid = true
	return result

# Get upgrade cost for domain
func get_upgrade_cost(domain) -> int:
	if domain:
		return domain.get("level", 1)
	return 1

# Check if domain is owned by current player
func is_domain_owned_by_current_player(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	var TurnService = load("res://application/services/turn_service_clean.gd")
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return false
	
	return domain.owner_id == current_player.id

# Cleanup method
func cleanup():
	technology_manager = null
	unit_manager = null