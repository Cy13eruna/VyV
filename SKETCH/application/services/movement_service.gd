# 🚶 MOVEMENT SERVICE (REFATORADO)
# Purpose: Coordenador principal para movimento de unidades
# Layer: Application Services

extends RefCounted
class_name MovementService

# Import modular components
const PathfindingCalculator = preload("res://application/services/movement/pathfinding_calculator.gd")
const MovementValidator = preload("res://application/services/movement/movement_validator.gd")

# Validate if unit can move to target position (delegated to validator)
static func can_unit_move_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	return MovementValidator.can_unit_move_to(unit, target_position, grid_data, units_data, game_state)

# Get all valid movement targets for a unit (delegated to pathfinding calculator)
static func get_valid_movement_targets(unit, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> Array:
	return PathfindingCalculator.get_valid_movement_targets(unit, grid_data, units_data, game_state)

# Get valid attack targets for a fighter unit (delegated to pathfinding calculator)
static func get_valid_attack_targets(unit, grid: Dictionary, units: Dictionary, game_state: Dictionary) -> Array:
	return PathfindingCalculator.get_valid_attack_targets(unit, grid, units, game_state)

# Execute unit movement (delegated to validator)
static func move_unit_to(unit, target_position, grid_data: Dictionary, units_data: Dictionary, game_state: Dictionary = {}) -> bool:
	return MovementValidator.move_unit_to(unit, target_position, grid_data, units_data, game_state)

# Get movement path between two positions (delegated to pathfinding calculator)
static func get_movement_path(start_position, end_position, grid_data: Dictionary, units_data: Dictionary) -> Array:
	return PathfindingCalculator.get_movement_path(start_position, end_position, grid_data, units_data)

# Calculate movement cost (delegated to pathfinding calculator)
static func get_movement_cost(unit, target_position, domain_data: Dictionary = {}) -> int:
	return PathfindingCalculator.get_movement_cost(unit, target_position, domain_data)

# Check if position is reachable within movement range (delegated to pathfinding calculator)
static func is_position_reachable(unit, target_position, grid_data: Dictionary, units_data: Dictionary, max_moves: int = 1) -> bool:
	return PathfindingCalculator.is_position_reachable(unit, target_position, grid_data, units_data, max_moves)

# Get all positions reachable within movement range (delegated to pathfinding calculator)
static func get_reachable_positions(unit, grid_data: Dictionary, units_data: Dictionary, max_moves: int = 1) -> Array:
	return PathfindingCalculator.get_reachable_positions(unit, grid_data, units_data, max_moves)

# Get adjacent positions to a given position (delegated to pathfinding calculator)
static func _get_adjacent_positions(center_position, grid: Dictionary) -> Array:
	return PathfindingCalculator.get_adjacent_positions(center_position, grid)

# Get unit at position (delegated to pathfinding calculator)
static func get_unit_at_position(position, units_data: Dictionary):
	return PathfindingCalculator.get_unit_at_position(position, units_data)

# Get terrain movement cost (delegated to pathfinding calculator)
static func get_terrain_movement_cost(unit, target_position, grid_data: Dictionary, game_state: Dictionary = {}) -> int:
	return PathfindingCalculator.get_terrain_movement_cost(unit, target_position, grid_data, game_state)

# Check if terrain blocks line of sight (delegated to pathfinding calculator)
static func does_terrain_block_sight(edge) -> bool:
	return PathfindingCalculator.does_terrain_block_sight(edge)

# Domain-related methods (delegated to validator)
static func _is_position_in_unit_domain(unit, position, game_state: Dictionary) -> bool:
	return MovementValidator.is_position_in_unit_domain(unit, position, game_state)

static func _are_positions_in_same_domain(unit, from_position, to_position, game_state: Dictionary) -> bool:
	return MovementValidator.are_positions_in_same_domain(unit, from_position, to_position, game_state)

# Terrain and fog validation methods (delegated to validator)
static func _can_move_through_terrain(unit, target_position, grid_data: Dictionary) -> bool:
	return MovementValidator.can_move_through_terrain(unit, target_position, grid_data)

static func _is_unit_visible_and_accessible_for_attack(target_unit, attacker_player_id: int, game_state: Dictionary) -> bool:
	return MovementValidator.is_unit_visible_and_accessible_for_attack(target_unit, attacker_player_id, game_state)

# Helper methods for backward compatibility
static func _is_position_on_grid(position, grid_data: Dictionary) -> bool:
	return MovementValidator._is_position_on_grid(position, grid_data)

static func _is_position_occupied(position, units_data: Dictionary) -> bool:
	return MovementValidator._is_position_occupied(position, units_data)

static func _is_position_occupied_with_forest_exception(moving_unit, target_position, grid_data: Dictionary, units_data: Dictionary) -> bool:
	return MovementValidator._is_position_occupied_with_forest_exception(moving_unit, target_position, grid_data, units_data)

static func _get_enemy_unit_at_position(position, attacker_player_id: int, units: Dictionary):
	return PathfindingCalculator._get_enemy_unit_at_position(position, attacker_player_id, units)

static func _get_edge_between_positions(pos1, pos2, grid_data: Dictionary):
	return PathfindingCalculator._get_edge_between_positions(pos1, pos2, grid_data)