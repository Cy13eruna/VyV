# ⚡ UNIT POWER MANAGER
# Purpose: Handle power consumption and management for units
# Layer: Presentation Manager

extends RefCounted
class_name UnitPowerManager

# Check if unit has power to move (from natal domain only)
static func unit_has_power_to_move(unit, game_state: Dictionary, domain_manager = null) -> bool:
	# Check if unit's natal domain has enough power for movement
	var natal_domain = _find_natal_domain(unit, game_state)
	if natal_domain:
		return natal_domain.get("power", 0) > 0
	return false

# Consume power from unit's natal domain ONLY
static func consume_unit_natal_power(unit, power_needed: int, game_state: Dictionary) -> bool:
	if not ("domains" in game_state):
		return false
	
	var natal_domain = _find_natal_domain(unit, game_state)
	if not natal_domain:
		return false  # No natal domain found
	
	# Check if natal domain has enough power
	if natal_domain.get("power", 0) < power_needed:
		return false  # Insufficient power in natal domain
	
	# Consume power from natal domain only
	natal_domain.power -= power_needed
	return true

# Find unit's natal domain (domain with same initial as unit name)
static func _find_natal_domain(unit, game_state: Dictionary):
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

# Get power from unit's natal domain only
static func get_unit_natal_power(unit, game_state: Dictionary) -> int:
	var natal_domain = _find_natal_domain(unit, game_state)
	if natal_domain:
		return natal_domain.get("power", 0)
	return 0