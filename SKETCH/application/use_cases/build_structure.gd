# 🏗️ BUILD STRUCTURE USE CASE
# Purpose: Handle structure building requests
# Layer: Application/UseCases
# Dependencies: StructureService, DomainService

class_name BuildStructureUseCase
extends RefCounted

# Preload services
const StructureService = preload("res://application/services/structure_service.gd")
const DomainService = preload("res://application/services/domain_service.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")

# Execute structure building
static func execute(player_id: int, structure_type: int, edge_id: int, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"structure": null,
		"power_consumed": 0
	}
	
	# Validate game state
	if not _validate_game_state(game_state, result):
		return result
	
	# Find domain that contains this edge
	var domain_id = _find_domain_for_edge(edge_id, game_state.domains)
	if domain_id == -1:
		result.message = "Edge is not part of any domain"
		return result
	
	# Check if it's player's turn
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player or current_player.id != player_id:
		result.message = "Not your turn"
		return result
	
	# Get next structure ID
	var structure_id = StructureService.get_next_structure_id(game_state)
	
	# Attempt to build structure
	var build_result = StructureService.build_structure(
		structure_id, player_id, structure_type, edge_id, domain_id, game_state
	)
	
	if build_result.success:
		result.success = true
		result.structure = build_result.structure
		result.power_consumed = build_result.power_consumed
		result.message = build_result.message
		
		# Log the construction
		print("🏗️ Player %d started building %s on edge %d (cost: %d power)" % [
			player_id, build_result.structure.name, edge_id, build_result.power_consumed
		])
	else:
		result.message = build_result.message
	
	return result

# Get buildable locations for player
static func get_buildable_locations(player_id: int, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"buildable_edges": [],
		"player_domains": [],
		"message": "Structure building temporarily disabled - domains need internal structure"
	}
	
	# TEMPORARY: Disable structure building until domains have internal structure
	return result
	
	if not _validate_game_state(game_state, result):
		return result
	
	# Get player's domains
	var player_domains = DomainService.get_player_domains(player_id, game_state.domains)
	result.player_domains = player_domains
	
	# Get buildable edges for each domain
	var all_buildable_edges = []
	for domain in player_domains:
		var domain_edges = StructureService.get_buildable_edges(domain.id, game_state)
		all_buildable_edges.append_array(domain_edges)
	
	result.buildable_edges = all_buildable_edges
	result.success = true
	result.message = "Found %d buildable locations" % all_buildable_edges.size()
	
	return result

# Get structure types and costs
static func get_structure_info() -> Dictionary:
	return {
		"types": [
			{
				"id": 0,
				"name": "Farm",
				"icon": "🌾",
				"cost": 2,
				"time": 1,
				"effect": "+1 Power/turn"
			},
			{
				"id": 1,
				"name": "Village",
				"icon": "🏘️",
				"cost": 4,
				"time": 2,
				"effect": "+2 Power/turn, +1 Unit capacity"
			},
			{
				"id": 2,
				"name": "Fortress",
				"icon": "🏰",
				"cost": 6,
				"time": 3,
				"effect": "+3 Defense, Blocks movement"
			},
			{
				"id": 3,
				"name": "Market",
				"icon": "🏪",
				"cost": 3,
				"time": 2,
				"effect": "+1 Power/turn, Enables trade"
			},
			{
				"id": 4,
				"name": "Temple",
				"icon": "⛪",
				"cost": 5,
				"time": 3,
				"effect": "+1 Power/turn, +1 Influence"
			}
		]
	}

# Validate game state
static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not ("domains" in game_state and "players" in game_state and "grid" in game_state):
		result.message = "Invalid game state"
		return false
	
	return true

# Find which domain contains an edge
static func _find_domain_for_edge(edge_id: int, domains_data: Dictionary) -> int:
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		if domain.has_internal_structure() and domain.contains_internal_edge(edge_id):
			return domain_id
	return -1

# Check if player can afford any structure
static func can_player_build_anything(player_id: int, game_state: Dictionary) -> bool:
	var available_power = DomainService.get_total_power_for_player(player_id, game_state.domains)
	var structure_info = get_structure_info()
	
	# Check if player can afford the cheapest structure
	var min_cost = 999
	for structure_type in structure_info.types:
		if structure_type.cost < min_cost:
			min_cost = structure_type.cost
	
	return available_power >= min_cost