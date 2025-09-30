# ⏭️ SKIP TURN USE CASE
# Purpose: Orchestrate turn skipping and player transitions
# Layer: Application/UseCases
# Dependencies: Services only

class_name SkipTurnUseCase
extends RefCounted

static func execute(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"new_player_id": -1,
		"turn_number": 0,
		"game_over": false,
		"winner": null
	}
	
	# Validate game state
	if not _validate_game_state(game_state, result):
		return result
	
	# Advance to next turn
	var turn_advanced = TurnService.advance_to_next_turn(
		game_state.turn_data,
		game_state.players,
		game_state.units,
		game_state.domains
	)
	
	if turn_advanced:
		result.success = true
		result.new_player_id = game_state.turn_data.current_player_id
		result.turn_number = game_state.turn_data.turn_number
		result.message = "Turn advanced to Player %d" % result.new_player_id
	else:
		# Game might be over
		if TurnService.is_game_over(game_state.turn_data, game_state.players):
			result.game_over = true
			result.winner = TurnService.get_winner(game_state.players)
			result.message = "Game Over"
			if result.winner:
				result.message += " - Winner: %s" % result.winner.name
		else:
			result.message = "Failed to advance turn"
	
	return result

static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not game_state.turn_data.is_game_active:
		result.message = "Game is not active"
		return false
	
	return true