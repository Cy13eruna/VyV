# ⚡ MOVEMENT POWER MANAGER
# Purpose: Manage power consumption and domain interactions for movement
# Layer: Application Use Cases - Unit Movement

extends RefCounted
class_name MovementPowerManager

# Calculate power cost for movement
static func calculate_power_cost(unit, target_position, game_state: Dictionary) -> int:
	# Check if unit's NATAL domain is occupied by enemy (PANIC MODE)
	var natal_domain = find_natal_domain(unit, game_state)
	if natal_domain and natal_domain.get("is_occupied", false):
		return 0  # Free movement when natal domain is occupied (PANIC MODE)
	
	# Normal movement costs 1 power
	return 1

# Check if unit can afford power cost from natal domain
static func can_afford_power(unit, cost: int, game_state: Dictionary) -> bool:
	if cost <= 0:
		return true
	
	# Check power only from unit's natal domain
	var natal_power = get_natal_domain_power(unit, game_state)
	return natal_power >= cost

# Get power from unit's natal domain only
static func get_natal_domain_power(unit, game_state: Dictionary) -> int:
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

# Consume power from unit's natal domain ONLY
static func consume_power_from_natal_domain(unit, cost: int, game_state: Dictionary) -> bool:
	if cost <= 0:
		return true
	
	var natal_domain = find_natal_domain(unit, game_state)
	if not natal_domain:
		return false  # No natal domain found
	
	# Check if natal domain has enough power
	if natal_domain.get("power", 0) < cost:
		return false  # Insufficient power in natal domain
	
	# Consume power from natal domain only
	natal_domain.power -= cost
	return true

# Consume power from player's domains (legacy function for compatibility)
static func consume_power(player_id: int, cost: int, game_state: Dictionary) -> void:
	if cost <= 0 or not ("domains" in game_state):
		return
	
	var remaining_cost = cost
	
	# Consume power from player's domains
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id and remaining_cost > 0:
			var consumed = min(domain.power, remaining_cost)
			domain.power -= consumed
			remaining_cost -= consumed
			if remaining_cost <= 0:
				break

# Update domain occupations based on unit positions
static func update_domain_occupations(game_state: Dictionary) -> void:
	if not ("domains" in game_state and "units" in game_state):
		return
	
	# Reset all occupations
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		domain.is_occupied = false
		domain.occupied_by_player = -1
	
	# Check which domains are occupied by enemy units
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			
			# Only enemy units can occupy domains (not the owner)
			if unit.owner_id != domain.owner_id:
				# Check if unit is exactly at domain center
				if unit.position.equals(domain.center_position):
					domain.is_occupied = true
					domain.occupied_by_player = unit.owner_id
					break

# Check if domain is in panic mode (occupied by enemy)
static func is_domain_in_panic_mode(domain_id: int, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	var domain = game_state.domains.get(domain_id)
	if not domain:
		return false
	
	return domain.get("is_occupied", false)

# Get total power available to player from all domains
static func get_total_player_power(player_id: int, game_state: Dictionary) -> int:
	if not ("domains" in game_state):
		return 0
	
	var total_power = 0
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id:
			total_power += domain.get("power", 0)
	
	return total_power

# Get power distribution for player (for debugging/UI)
static func get_power_distribution(player_id: int, game_state: Dictionary) -> Dictionary:
	var distribution = {
		"total_power": 0,
		"domains": [],
		"occupied_domains": 0,
		"panic_mode": false
	}
	
	if not ("domains" in game_state):
		return distribution
	
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if domain.owner_id == player_id:
			var domain_info = {
				"id": domain_id,
				"name": domain.get("name", "Unknown"),
				"power": domain.get("power", 0),
				"is_occupied": domain.get("is_occupied", false),
				"occupied_by": domain.get("occupied_by_player", -1)
			}
			distribution.domains.append(domain_info)
			distribution.total_power += domain_info.power
			
			if domain_info.is_occupied:
				distribution.occupied_domains += 1
				distribution.panic_mode = true
	
	return distribution

# Validate power state consistency
static func validate_power_state(game_state: Dictionary) -> Dictionary:
	var validation = {
		"valid": true,
		"errors": [],
		"warnings": []
	}
	
	if not ("domains" in game_state):
		validation.valid = false
		validation.errors.append("No domains found in game state")
		return validation
	
	# Check for negative power values
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		var power = domain.get("power", 0)
		if power < 0:
			validation.warnings.append("Domain %d has negative power: %d" % [domain_id, power])
	
	# Check for orphaned domains (no owner)
	for domain_id in game_state.domains:
		var domain = game_state.domains[domain_id]
		if not ("owner_id" in domain):
			validation.valid = false
			validation.errors.append("Domain %d has no owner" % domain_id)
	
	return validation