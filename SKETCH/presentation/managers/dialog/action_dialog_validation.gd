# 🔍 ACTION DIALOG VALIDATION
# Purpose: Validation logic for unit actions
# Layer: Presentation Manager - Dialog Validation

extends RefCounted
class_name ActionDialogValidation

# Import dependencies
const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service.gd")

# References
var technology_manager

# Initialize with required references
func initialize(technology_manager_ref):
	technology_manager = technology_manager_ref

# Get all available actions for a unit
func get_available_actions(unit, game_state: Dictionary) -> Array:
	var actions = []
	
	# Check MOVE action
	if can_unit_move(unit, game_state):
		actions.append("MOVE")
	
	# Check SETTLE action (Settler technology)
	if can_unit_settle(unit, game_state):
		actions.append("SETTLE")
	
	# Check ATTACK action (Fighter units)
	if can_unit_attack(unit, game_state):
		actions.append("ATTACK")
	
	# Check TRAIN action
	if can_unit_train(unit, game_state):
		actions.append("TRAIN")
	
	# Check HEAL action (Healer units)
	if can_unit_heal(unit, game_state):
		actions.append("HEAL")
	
	return actions

# Check if unit can move
func can_unit_move(unit, game_state: Dictionary) -> bool:
	# Unit must be able to move and have actions
	if not unit.can_move():
		return false
	
	# Unit must have power in natal domain for movement (Regra Pétra: toda ação custa 1 poder)
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power <= 0:
		return false
	
	return true

# Check if unit can settle (Settler)
func can_unit_settle(unit, game_state: Dictionary) -> bool:
	# Must have actions remaining to establish domain
	if not unit.can_move():
		return false
	
	# Must have Settler technology
	if not technology_manager or not technology_manager.has_technology(unit.owner_id, "settler"):
		return false
	
	# Must have at least 1 power in natal domain to settle
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power < 1:
		return false
	
	# Must not share paths with existing domains
	if not can_domain_be_placed_without_sharing_paths(unit, game_state):
		return false
	
	# Must not be on the border of the map
	return is_unit_away_from_border(unit, game_state)

# Check if unit can attack (Fighter units)
func can_unit_attack(unit, game_state: Dictionary) -> bool:
	# Must be a fighter unit
	if not unit.is_fighter:
		return false
	
	# Must have actions remaining
	if not unit.can_attack():
		return false
	
	# Must have power in natal domain for attack
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power <= 0:
		return false
	
	# Use the new attack targeting system (grid-based)
	var valid_attack_targets = MovementService.get_valid_attack_targets(unit, game_state.grid, game_state.units, game_state)
	return valid_attack_targets.size() > 0

# Check if unit can heal (Healer units)
func can_unit_heal(unit, game_state: Dictionary) -> bool:
	# Must be a healer unit
	if not unit.is_healer:
		return false
	
	# Must have actions remaining
	if not unit.can_heal():
		return false
	
	# Must have power in natal domain for healing
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power <= 0:
		return false
	
	# Check if there are injured units nearby or self is injured
	if unit.is_injured():
		return true  # Can heal self
	
	# Check for injured units in adjacent positions
	var adjacent_positions = get_adjacent_positions(unit.position, game_state)
	
	for pos in adjacent_positions:
		var target_unit = get_unit_at_position(pos, game_state.units)
		if target_unit and target_unit.is_injured():
			# Check if path to target crosses blocking terrain
			if can_heal_without_crossing_blocking_terrain(unit.position, pos, game_state):
				# Allow healing any injured unit (including enemies) - no visibility restriction
				return true
	
	return false

# Check if unit can train
func can_unit_train(unit, game_state: Dictionary) -> bool:
	# Unit must have actions remaining (training now costs an action)
	if unit.actions_remaining <= 0:
		return false
	
	# Unit must be at any domain star (not just center)
	if not is_unit_at_domain_star(unit, game_state):
		return false
	
	# Unit must have enough power in natal domain for training
	var natal_power = get_unit_natal_power(unit, game_state)
	if natal_power < unit.level:  # Need at least unit.level power to train
		return false
	
	# Check if there are any training technologies available
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return false
	
	var available_trainings = get_available_trainings(unit, current_player, game_state)
	return not available_trainings.is_empty()

# Check if unit is at domain center
func is_unit_at_domain_center(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	# Find the domain that belongs to this unit's owner
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id:
			# Check if unit is at the center of this domain
			if unit.position.equals(domain.center_position):
				return true
	
	return false

# Check if unit is at any domain star (center or edge)
func is_unit_at_domain_star(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	# Find the domain that belongs to this unit's owner
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id:
			# Check if unit is at the center of this domain
			if unit.position.equals(domain.center_position):
				return true
			
			# Check if unit is within distance 1 of domain center (edge positions)
			if domain.center_position.is_within_distance(unit.position, 1):
				return true
	
	return false

# Get available trainings for a unit
func get_available_trainings(unit, player, game_state: Dictionary) -> Array:
	var trainings = []
	
	# Fighter training
	if can_train_fighter(unit, player, game_state):
		trainings.append({"type": "FIGHTER", "name": "Fighter", "cost": unit.level})
	
	# Healer training
	if can_train_healer(unit, player, game_state):
		trainings.append({"type": "HEALER", "name": "Healer", "cost": unit.level})
	
	# Rider training
	if can_train_rider(unit, player, game_state):
		trainings.append({"type": "RIDER", "name": "Rider", "cost": unit.level})
	
	# Climber training
	if can_train_climber(unit, player, game_state):
		trainings.append({"type": "CLIMBER", "name": "Climber", "cost": unit.level})
	
	# Shaman training
	if can_train_shaman(unit, player, game_state):
		trainings.append({"type": "SHAMAN", "name": "Shaman", "cost": unit.level})
	
	return trainings

# Check if unit can be trained as fighter
func can_train_fighter(unit, player, game_state: Dictionary) -> bool:
	# Unit must not already be a fighter
	if unit.is_fighter:
		return false
	
	# Player must have Fighter technology
	if not technology_manager or not technology_manager.has_technology(player.id, "fighter"):
		return false
	
	# Player must have enough power
	var total_power = get_player_total_power(player, game_state)
	if total_power < unit.level:
		return false
	
	return true

# Check if unit can be trained as healer
func can_train_healer(unit, player, game_state: Dictionary) -> bool:
	# Unit must not already be a healer
	if unit.is_healer:
		return false
	
	# Player must have Healer technology
	if not technology_manager or not technology_manager.has_technology(player.id, "healer"):
		return false
	
	# Player must have enough power
	var total_power = get_player_total_power(player, game_state)
	if total_power < unit.level:
		return false
	
	return true

# Check if unit can train as rider
func can_train_rider(unit, player, game_state: Dictionary) -> bool:
	# Unit must not already be a rider
	if unit.is_rider:
		return false
	
	# Player must have Rider technology
	if not technology_manager.has_technology(player.id, "rider"):
		return false
	
	# Player must have enough power
	var total_power = get_player_total_power(player, game_state)
	if total_power < unit.level:
		return false
	
	return true

# Check if unit can train as climber
func can_train_climber(unit, player, game_state: Dictionary) -> bool:
	# Unit must not already be a climber
	if unit.is_climber:
		return false
	
	# Player must have Climber technology
	if not technology_manager.has_technology(player.id, "climber"):
		return false
	
	# Player must have enough power
	var total_power = get_player_total_power(player, game_state)
	if total_power < unit.level:
		return false
	
	return true

# Check if unit can train as shaman
func can_train_shaman(unit, player, game_state: Dictionary) -> bool:
	# Debug: trace gating for shaman training
	print("[VALIDATION][SHAMAN] Checking training availability for unit ", unit.name, " (lvl ", unit.level, ")")
	
	# Unit must not already be a shaman
	if unit.is_shaman:
		print("[VALIDATION][SHAMAN] Blocked: unit already has shaman training")
		return false
	
	# Player must have Shaman technology
	if not technology_manager or not technology_manager.has_technology(player.id, "shaman"):
		print("[VALIDATION][SHAMAN] Blocked: player ", player.id, " lacks 'shaman' technology")
		return false
	
	# Player must have enough total power (across domains)
	var total_power = get_player_total_power(player, game_state)
	if total_power < unit.level:
		print("[VALIDATION][SHAMAN] Blocked: insufficient total power ", total_power, " < ", unit.level)
		return false
	
	print("[VALIDATION][SHAMAN] Allowed")
	return true

# Get power from unit's natal domain only
func get_unit_natal_power(unit, game_state: Dictionary) -> int:
	var natal_domain = find_natal_domain(unit, game_state)
	if natal_domain:
		return natal_domain.get("power", 0)
	return 0

# Find unit's natal domain (domain with same initial as unit name)
func find_natal_domain(unit, game_state: Dictionary):
	if not ("domains" in game_state):
		return null
	
	var unit_initial = unit.get_name_initial()
	if unit_initial == "":
		return null
	
	# Find domain with matching initial for this player
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var domain_initial = domain.get("initial", "")
		if domain.owner_id == unit.owner_id and domain_initial == unit_initial:
			return domain
	
	return null

# Get player's total power
func get_player_total_power(player, game_state: Dictionary) -> int:
	var total_power = 0
	if "domains" in game_state:
		for domain_id in player.domain_ids:
			if domain_id in game_state.domains:
				var domain = game_state.domains[domain_id]
				total_power += domain.power
	return total_power

# Check if domain can be placed without sharing paths with existing domains
func can_domain_be_placed_without_sharing_paths(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return true  # No existing domains, can place anywhere
	
	# Get the grid point where unit is located
	var unit_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			unit_point = point
			break
	
	if not unit_point:
		return false  # Unit position not found on grid
	
	# Get the "influence area" of the new domain (center + neighbors)
	var new_domain_positions = []
	new_domain_positions.append(unit.position)
	var unit_neighbors = get_point_neighbors(unit_point, game_state)
	for neighbor in unit_neighbors:
		new_domain_positions.append(neighbor.position)
	
	# Check each existing domain
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		
		# Get the domain's center point
		var domain_point = null
		for point_id in game_state.grid.points:
			var point = game_state.grid.points[point_id]
			if point.position.equals(domain.center_position):
				domain_point = point
				break
		
		if not domain_point:
			continue  # Domain position not found, skip
		
		# Get the "influence area" of the existing domain
		var existing_domain_positions = []
		existing_domain_positions.append(domain.center_position)
		var domain_neighbors = get_point_neighbors(domain_point, game_state)
		for neighbor in domain_neighbors:
			existing_domain_positions.append(neighbor.position)
		
		# Count shared positions between the two influence areas
		var shared_count = 0
		for new_pos in new_domain_positions:
			for existing_pos in existing_domain_positions:
				if new_pos.equals(existing_pos):
					shared_count += 1
					break  # Avoid double counting same position
		
		# If sharing more than one position, domains would share paths (not allowed)
		if shared_count > 1:
			return false
	
	return true

# Get neighbors of a grid point
func get_point_neighbors(point, game_state: Dictionary) -> Array:
	var neighbors = []
	if not point or not ("connected_edges" in point):
		return neighbors
	
	# Get all connected edges and find their other endpoints
	for edge_id in point.connected_edges:
		if edge_id in game_state.grid.edges:
			var edge = game_state.grid.edges[edge_id]
			# Find the other point of this edge
			var other_point_id = -1
			if "point_a_id" in edge and "point_b_id" in edge:
				other_point_id = edge.point_a_id if edge.point_b_id == point.id else edge.point_b_id
			elif "point1_id" in edge and "point2_id" in edge:
				other_point_id = edge.point1_id if edge.point2_id == point.id else edge.point2_id
			elif "point1" in edge and "point2" in edge:
				other_point_id = edge.point1 if edge.point2 == point.id else edge.point2
			else:
				continue  # Skip malformed edge
			
			if other_point_id != -1 and other_point_id in game_state.grid.points:
				neighbors.append(game_state.grid.points[other_point_id])
	
	return neighbors

# Check if unit is away from map border
func is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the point at unit's position
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			# Check if point has 6 connections (interior)
			var connections = point.get("connected_edges", [])
			if connections.size() < 6:
				return false  # Point is on border or corner
			return true  # Point has 6 connections (interior)
	
	return false  # Position not found on grid

# Check if healer can reach target without crossing blocking terrain
func can_heal_without_crossing_blocking_terrain(healer_pos, target_pos, game_state: Dictionary) -> bool:
	# Find the edge connecting healer and target positions
	if not ("grid" in game_state):
		return true  # No grid data, allow healing
	
	# Find points for both positions
	var healer_point = null
	var target_point = null
	var healer_unit = null
	
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(healer_pos):
			healer_point = point
		elif point.position.equals(target_pos):
			target_point = point
	
	# Find the healer unit to check if it's a climber
	if "units" in game_state:
		healer_unit = get_unit_at_position(healer_pos, game_state.units)
	
	if not healer_point or not target_point:
		return true  # Points not found, allow healing
	
	# BUGFIX: Check if both positions are within the same domain (free movement)
	if healer_unit and are_positions_in_same_domain(healer_unit, healer_pos, target_pos, game_state):
		return true  # Free healing within domain - ignore terrain restrictions
	
	# Find the edge connecting these two points
	for edge_id in healer_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		# Check if this edge connects to the target point
		if (edge.point_a_id == healer_point.id and edge.point_b_id == target_point.id) or \
		   (edge.point_a_id == target_point.id and edge.point_b_id == healer_point.id):
			# Found the connecting edge, check terrain restrictions
			var terrain_type = edge.get("terrain_type", 0)
			if terrain_type == 3:  # 3 = WATER
				return false  # Water always blocks healing
			elif terrain_type == 2:  # 2 = MOUNTAIN
				# Climbers can heal through mountains
				if healer_unit and healer_unit.is_climber:
					return true
				else:
					return false  # Non-climbers blocked by mountains
			else:
				return true  # Field/forest terrain allows healing
	
	# No direct edge found, cannot heal
	return false

# Get adjacent positions to a given position
func get_adjacent_positions(center_position, game_state: Dictionary) -> Array:
	var adjacent = []
	if not ("grid" in game_state):
		return adjacent
	
	# Find the point at center position
	var center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(center_position):
			center_point = point
			break
	
	if not center_point:
		return adjacent
	
	# Get neighbors using existing function
	var neighbors = get_point_neighbors(center_point, game_state)
	for neighbor in neighbors:
		adjacent.append(neighbor.position)
	
	return adjacent

# Check if position is visible and accessible to player
func is_position_visible_and_accessible(position, player_id: int, game_state: Dictionary) -> bool:
	# Check if position is visible using fog of war system
	if game_state.get("fog_of_war_enabled", false):
		var FogOfWarService = load("res://application/services/fog_of_war_service.gd")
		var is_position_visible = FogOfWarService._is_position_visible_to_player(position, player_id, game_state)
		if not is_position_visible:
			return false
	
	# Check if there's a unit at this position and if it's visible
	var target_unit = get_unit_at_position(position, game_state.units)
	if target_unit:
		var is_unit_visible = target_unit.is_visible_to_player(player_id)
		if not is_unit_visible:
			return false
	
	return true

# Check if both positions are within the same domain
func are_positions_in_same_domain(unit, from_position, to_position, game_state: Dictionary) -> bool:
	var from_in_domain = is_position_in_unit_domain(unit, from_position, game_state)
	var to_in_domain = is_position_in_unit_domain(unit, to_position, game_state)
	return from_in_domain and to_in_domain

# Check if position is within unit's domain (for free movement)
func is_position_in_unit_domain(unit, position, game_state: Dictionary) -> bool:
	if game_state.is_empty() or not "domains" in game_state:
		return false
	
	# Find unit's domain
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id:
			# Check if position is the domain center
			if domain.center_position.equals(position):
				return true
			
			# Check if position is within domain radius (adjacent to center)
			if domain.center_position.is_within_distance(position, 1):
				return true
	
	return false

# Get unit at specific position
func get_unit_at_position(position, units: Dictionary):
	for unit_id in units:
		var unit = units[unit_id]
		if unit.position.equals(position):
			return unit
	return null