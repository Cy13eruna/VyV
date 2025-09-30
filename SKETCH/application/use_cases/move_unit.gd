# 🚶 MOVE UNIT USE CASE
# Purpose: Orchestrate unit movement with all validations
# Layer: Application/UseCases
# Dependencies: Services only

class_name MoveUnitUseCase
extends RefCounted

static func execute(unit_id: int, target_position: Position, game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"action_consumed": false,
		"power_consumed": false
	}
	
	# Validate inputs
	if not _validate_inputs(unit_id, target_position, game_state, result):
		return result
	
	var unit = game_state.units[unit_id]
	var player = game_state.players[unit.owner_id]
	
	# Check if it's player's turn
	if not TurnService.get_current_player(game_state.turn_data, game_state.players).id == unit.owner_id:
		result.message = "Not your turn"
		return result
	
	# Validate movement
	if not MovementService.can_unit_move_to(unit, target_position, game_state.grid, game_state.units):
		result.message = "Invalid movement"
		return result
	
	# Check power cost (if not in own domain)
	var needs_power = not DomainService.is_position_in_player_domain(target_position, unit.owner_id, game_state.domains)
	if needs_power and not DomainService.can_player_afford_power(unit.owner_id, game_state.domains):
		result.message = "Insufficient power"
		return result
	
	# Execute movement
	if MovementService.move_unit_to(unit, target_position, game_state.grid, game_state.units):
		result.success = true
		result.action_consumed = true
		result.message = "Movement successful"
		
		# Consume power if needed
		if needs_power:
			DomainService.consume_power_for_player(unit.owner_id, game_state.domains)
			result.power_consumed = true
		
		# Update domain occupations
		DomainService.update_domain_occupation(game_state.domains, game_state.units)
	else:
		result.message = "Movement failed"
	
	return result

static func _validate_inputs(unit_id: int, target_position: Position, game_state: Dictionary, result: Dictionary) -> bool:
	if unit_id not in game_state.units:
		result.message = "Unit not found"
		return false
	
	if target_position == null:
		result.message = "Invalid target position"
		return false
	
	return true