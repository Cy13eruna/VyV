# 🏗️ STRUCTURE SERVICE
# Purpose: Structure building and management
# Layer: Application/Services
# Dependencies: Core entities (Structure, Domain, Player)

class_name StructureService
extends RefCounted

# Preload dependencies
const Structure = preload("res://core/entities/structure.gd")
const DomainService = preload("res://application/services/domain_service.gd")

# Build structure on domain edge
static func build_structure(structure_id: int, player_id: int, structure_type: int, edge_id: int, domain_id: int, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"structure": null,
		"power_consumed": 0
	}
	
	# Validate inputs
	if not _validate_build_inputs(player_id, edge_id, domain_id, game_state, result):
		return result
	
	# Check if player owns the domain
	var domain = game_state.domains[domain_id]
	if domain.owner_id != player_id:
		result.message = "Cannot build on enemy domain"
		return result
	
	# Check if edge is part of domain's internal structure
	if not domain.contains_internal_edge(edge_id):
		result.message = "Can only build on domain's internal edges"
		return result
	
	# Check if edge already has a structure
	if _edge_has_structure(edge_id, game_state.get("structures", {})):
		result.message = "Edge already has a structure"
		return result
	
	# Create structure
	var structure = Structure.new(structure_id, player_id, structure_type, edge_id, domain_id)
	
	# Check if player can afford construction
	var available_power = DomainService.get_total_power_for_player(player_id, game_state.domains)
	if not structure.can_afford_construction(available_power):
		result.message = "Insufficient power (need %d, have %d)" % [structure.get_construction_cost(), available_power]
		return result
	
	# Consume power for construction
	var power_consumed = structure.get_construction_cost()
	if not DomainService.consume_power_for_player(player_id, game_state.domains, power_consumed):
		result.message = "Failed to consume power for construction"
		return result
	
	# Add structure to game state
	if not "structures" in game_state:
		game_state.structures = {}
	
	game_state.structures[structure_id] = structure
	
	result.success = true
	result.structure = structure
	result.power_consumed = power_consumed
	result.message = "Construction of %s started" % structure.name
	
	return result

# Advance construction for all structures
static func advance_all_construction(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": true,
		"completed_structures": [],
		"message": ""
	}
	
	if not "structures" in game_state:
		return result
	
	for structure_id in game_state.structures:
		var structure = game_state.structures[structure_id]
		if structure.advance_construction():
			result.completed_structures.append(structure)
	
	if result.completed_structures.size() > 0:
		result.message = "%d structures completed construction" % result.completed_structures.size()
	
	return result

# Get structures owned by player
static func get_player_structures(player_id: int, game_state: Dictionary) -> Array:
	var player_structures = []
	
	if not "structures" in game_state:
		return player_structures
	
	for structure_id in game_state.structures:
		var structure = game_state.structures[structure_id]
		if structure.owner_id == player_id:
			player_structures.append(structure)
	
	return player_structures

# Get structures in domain
static func get_domain_structures(domain_id: int, game_state: Dictionary) -> Array:
	var domain_structures = []
	
	if not "structures" in game_state:
		return domain_structures
	
	for structure_id in game_state.structures:
		var structure = game_state.structures[structure_id]
		if structure.domain_id == domain_id:
			domain_structures.append(structure)
	
	return domain_structures

# Get buildable edges for domain
static func get_buildable_edges(domain_id: int, game_state: Dictionary) -> Array:
	var buildable_edges = []
	
	if not domain_id in game_state.domains:
		return buildable_edges
	
	var domain = game_state.domains[domain_id]
	if not domain.has_internal_structure():
		return buildable_edges
	
	# Check each internal edge
	for edge_id in domain.internal_edge_ids:
		if not _edge_has_structure(edge_id, game_state.get("structures", {})):
			buildable_edges.append(edge_id)
	
	return buildable_edges

# Calculate total power generation from structures
static func calculate_structure_power_generation(player_id: int, game_state: Dictionary) -> int:
	var total_power = 0
	var player_structures = get_player_structures(player_id, game_state)
	
	for structure in player_structures:
		total_power += structure.get_power_generation()
	
	return total_power

# Check if edge blocks movement
static func edge_blocks_movement(edge_id: int, game_state: Dictionary) -> bool:
	if not "structures" in game_state:
		return false
	
	for structure_id in game_state.structures:
		var structure = game_state.structures[structure_id]
		if structure.edge_id == edge_id and structure.blocks_movement():
			return true
	
	return false

# Destroy structure
static func destroy_structure(structure_id: int, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"destroyed_structure": null
	}
	
	if not "structures" in game_state or not structure_id in game_state.structures:
		result.message = "Structure not found"
		return result
	
	var structure = game_state.structures[structure_id]
	result.destroyed_structure = structure
	game_state.structures.erase(structure_id)
	
	result.success = true
	result.message = "Structure %s destroyed" % structure.name
	
	return result

# Validate build inputs
static func _validate_build_inputs(player_id: int, edge_id: int, domain_id: int, game_state: Dictionary, result: Dictionary) -> bool:
	# Check player exists
	if not player_id in game_state.players:
		result.message = "Player not found"
		return false
	
	# Check domain exists
	if not domain_id in game_state.domains:
		result.message = "Domain not found"
		return false
	
	# Check edge exists
	if not edge_id in game_state.grid.edges:
		result.message = "Edge not found"
		return false
	
	return true

# Check if edge already has a structure
static func _edge_has_structure(edge_id: int, structures_data: Dictionary) -> bool:
	for structure_id in structures_data:
		var structure = structures_data[structure_id]
		if structure.edge_id == edge_id:
			return true
	return false

# Get structure at edge
static func get_structure_at_edge(edge_id: int, game_state: Dictionary) -> Structure:
	if not "structures" in game_state:
		return null
	
	for structure_id in game_state.structures:
		var structure = game_state.structures[structure_id]
		if structure.edge_id == edge_id:
			return structure
	
	return null

# Get next available structure ID
static func get_next_structure_id(game_state: Dictionary) -> int:
	if not "structures" in game_state:
		return 1
	
	var max_id = 0
	for structure_id in game_state.structures:
		if structure_id > max_id:
			max_id = structure_id
	
	return max_id + 1