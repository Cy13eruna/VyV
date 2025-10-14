# 🚶 UNIT MOVEMENT HANDLER (REFATORADO)
# Purpose: Coordenador principal para movimento de unidades
# Layer: Application Use Cases

extends RefCounted
class_name UnitMovementHandler

# Import modular components
const MovementOrchestrator = preload("res://application/use_cases/unit_movement/movement_orchestrator.gd")
const MovementPowerManager = preload("res://application/use_cases/unit_movement/movement_power_manager.gd")

# Execute unit movement (delegated to orchestrator)
static func execute(unit_id: int, target_position, game_state: Dictionary) -> Dictionary:
	return MovementOrchestrator.execute(unit_id, target_position, game_state)

# Validation methods (delegated to orchestrator)
static func _validate_inputs(unit_id: int, target_position, game_state: Dictionary, result: Dictionary) -> bool:
	return MovementOrchestrator.validate_inputs(unit_id, target_position, game_state, result)

static func _get_movement_restriction_message(unit, target_position, game_state: Dictionary) -> String:
	return MovementOrchestrator.get_movement_restriction_message(unit, target_position, game_state)

static func get_movement_summary(unit_id: int, target_position, game_state: Dictionary) -> String:
	return MovementOrchestrator.get_movement_summary(unit_id, target_position, game_state)

# Power management methods (delegated to power manager)
static func _calculate_power_cost(unit, target_position, game_state: Dictionary) -> int:
	return MovementPowerManager.calculate_power_cost(unit, target_position, game_state)

static func _can_afford_power(unit, cost: int, game_state: Dictionary) -> bool:
	return MovementPowerManager.can_afford_power(unit, cost, game_state)

static func _get_natal_domain_power(unit, game_state: Dictionary) -> int:
	return MovementPowerManager.get_natal_domain_power(unit, game_state)

static func _find_natal_domain(unit, game_state: Dictionary):
	return MovementPowerManager.find_natal_domain(unit, game_state)

static func _consume_power_from_natal_domain(unit, cost: int, game_state: Dictionary) -> bool:
	return MovementPowerManager.consume_power_from_natal_domain(unit, cost, game_state)

static func _consume_power(player_id: int, cost: int, game_state: Dictionary) -> void:
	MovementPowerManager.consume_power(player_id, cost, game_state)

static func _update_domain_occupations(game_state: Dictionary) -> void:
	MovementPowerManager.update_domain_occupations(game_state)

# Revelation and forest traversal methods (delegated to orchestrator)
static func _clear_force_revealed_on_movement(moving_unit, game_state: Dictionary) -> void:
	MovementOrchestrator.clear_force_revealed_on_movement(moving_unit, game_state)

static func _check_forest_traversal_revelation(unit, target_position, game_state: Dictionary) -> void:
	MovementOrchestrator.check_forest_traversal_revelation(unit, target_position, game_state)

static func _find_edge_between_positions(pos1, pos2, grid_data: Dictionary):
	return MovementOrchestrator.find_edge_between_positions(pos1, pos2, grid_data)

# Additional power management utilities
static func is_domain_in_panic_mode(domain_id: int, game_state: Dictionary) -> bool:
	return MovementPowerManager.is_domain_in_panic_mode(domain_id, game_state)

static func get_total_player_power(player_id: int, game_state: Dictionary) -> int:
	return MovementPowerManager.get_total_player_power(player_id, game_state)

static func get_power_distribution(player_id: int, game_state: Dictionary) -> Dictionary:
	return MovementPowerManager.get_power_distribution(player_id, game_state)

static func validate_power_state(game_state: Dictionary) -> Dictionary:
	return MovementPowerManager.validate_power_state(game_state)

# Cache management (delegated to orchestrator)
static func clear_edge_cache():
	MovementOrchestrator.clear_edge_cache()