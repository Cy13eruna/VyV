# ✅ UNIT ACTION VALIDATOR
# Purpose: Validate available actions for units
# Layer: Presentation Managers - Unit Selection

extends RefCounted
class_name UnitActionValidator

# Import dependencies
const TurnService = preload("res://application/services/turn_service_clean.gd")
const MovementService = preload("res://application/services/movement_service.gd")
const UnitPowerManager = preload("res://presentation/managers/unit/unit_power_manager.gd")

# Count available actions for a unit
static func count_available_actions(unit, game_state: Dictionary) -> int:
	var action_count = 0
	
	# Check movement
	if unit.can_move():
		action_count += 1
	
	# Check attack (for fighters)
	if has_adjacent_enemies(unit, game_state):
		action_count += 1
	
	# Check train
	var can_train = can_unit_train(unit, game_state)
	print("[TRAIN] Unit ", unit.name, " can train: ", can_train)
	if can_train:
		action_count += 1
	
	# Check establish domain
	if can_establish_domain(unit, game_state):
		action_count += 1
	
	# Note: Upgrade action removed - units on nucleus prevent domain upgrade
	
	return action_count

# Check if unit can train (updated version)
static func can_unit_train(unit, game_state: Dictionary) -> bool:
	# Unit must have actions remaining (training now costs an action)
	if unit.actions_remaining <= 0:
		return false
	
	# Unit must have enough level (simplified check)
	if unit.level < 1:
		return false
	
	# Unit must be at any domain star (not just center)
	if not is_unit_at_domain_star(unit, game_state):
		return false
	
	return true

# Check if unit is at domain center
static func is_unit_at_domain_center(unit, game_state: Dictionary) -> bool:
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
static func is_unit_at_domain_star(unit, game_state: Dictionary) -> bool:
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

# Check if unit has adjacent enemies (using new attack targeting system)
static func has_adjacent_enemies(unit, game_state: Dictionary) -> bool:
	if not unit.is_fighter or not unit.can_attack():
		return false
	
	# Use the new attack targeting system
	var valid_attack_targets = MovementService.get_valid_attack_targets(unit, game_state.grid, game_state.units, game_state)
	return valid_attack_targets.size() > 0

# Check if unit can establish domain (simplified)
static func can_establish_domain(unit, game_state: Dictionary) -> bool:
	# Simplified check - should match action_dialog_manager logic
	return unit.can_move() and is_unit_away_from_border(unit, game_state)

# Check if unit is away from border (simplified)
static func is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if not ("grid" in game_state):
		return false
	
	# Find the point at unit's position
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(unit.position):
			# Check if point has 6 connections (interior)
			var connections = point.get("connected_edges", [])
			return connections.size() >= 6
	
	return false

# Check if unit is on domain nucleus (center)
static func is_unit_on_domain_nucleus(unit, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	# Check if unit position matches any domain center
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.center_position.equals(unit.position):
			return true
	
	return false

# Check if unit can use Settler technology (simplified version)
static func can_unit_use_settler(unit, game_state: Dictionary, domain_manager = null) -> bool:
	# This is a simplified check - full logic should be in UnitSettlerManager
	return false

# Get power from unit's natal domain only
static func get_unit_natal_power(unit, game_state: Dictionary) -> int:
	var natal_domain = find_natal_domain(unit, game_state)
	if natal_domain:
		return natal_domain.get("power", 0)
	return 0

# Find unit's natal domain (domain with same initial as unit name)
static func find_natal_domain(unit, game_state: Dictionary):
	if not ("domains" in game_state):
		return null
	
	var unit_initial = unit.get_name_initial()
	if unit_initial == "":
		return null
	
	# Find domain with matching initial for this player
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == unit.owner_id and domain.get("initial", "") == unit_initial:
			return domain
	
	return null

# Calculate hex distance between two positions
static func calculate_hex_distance(pos1, pos2) -> int:
	# Use the built-in distance calculation from Position class
	return pos1.distance_to(pos2)

# Get player's total power
static func get_player_total_power(player, game_state: Dictionary) -> int:
	var total_power = 0
	if "domains" in game_state:
		for domain_id in player.domain_ids:
			if domain_id in game_state.domains:
				var domain = game_state.domains[domain_id]
				total_power += domain.power
	return total_power

# Deduct power from player's domains
static func deduct_power_from_player(player, game_state: Dictionary, cost: int):
	var remaining_cost = cost
	for domain_id in player.domain_ids:
		if domain_id in game_state.domains and remaining_cost > 0:
			var domain = game_state.domains[domain_id]
			var deduction = min(domain.power, remaining_cost)
			domain.power -= deduction
			remaining_cost -= deduction

# Validate unit ownership for current player
static func validate_unit_ownership(unit, game_state: Dictionary) -> bool:
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	return current_player and unit.owner_id == current_player.id

# Check if unit has power to move
static func unit_has_power_to_move(unit, game_state: Dictionary, domain_manager = null) -> bool:
	return UnitPowerManager.unit_has_power_to_move(unit, game_state, domain_manager)

# Validate unit can perform action
static func validate_unit_action(unit, action_type: String, game_state: Dictionary) -> bool:
	match action_type:
		"move":
			return unit.can_move()
		"attack":
			return unit.is_fighter and unit.can_attack() and has_adjacent_enemies(unit, game_state)
		"train":
			return can_unit_train(unit, game_state)
		"establish_domain":
			return can_establish_domain(unit, game_state)
		_:
			return false