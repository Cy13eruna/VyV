# ⏭️ SKIP TURN USE CASE (CLEAN)
# Purpose: Orchestrate turn skipping and advancement
# Layer: Application/UseCases
# Dependencies: Clean services

extends RefCounted

# Preload clean services
const TurnService = preload("res://application/services/turn_service_clean.gd")
# Structure service removed during cleanup
# const StructureService = preload("res://application/services/structure_service.gd")

# Execute turn skip
static func execute(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"new_player_id": -1,
		"turn_number": -1,
		"game_over": false,
		"winner": null
	}
	
	# Validate game state
	if not _validate_game_state(game_state, result):
		return result
	
	# Get current player info before advancing
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	var old_player_name = current_player.name if current_player else "Unknown"
	
	# Structure construction advancement removed during cleanup
	# var construction_result = StructureService.advance_all_construction(game_state)
	# if construction_result.completed_structures.size() > 0:
	#	print("🏗️ %s" % construction_result.message)
	
	# Advance to next turn using TurnService
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
		result.message = "Turn advanced from %s to Player %d" % [old_player_name, result.new_player_id]
		
		# Check if game is over after turn advance
		if TurnService.is_game_over(game_state.turn_data, game_state.players):
			result.game_over = true
			result.winner = TurnService.get_winner(game_state.players)
			
			if result.winner:
				result.message += " - GAME OVER! Winner: %s" % result.winner.name
			else:
				result.message += " - GAME OVER! Draw"
	else:
		# Turn advance failed - check if game is over
		if TurnService.is_game_over(game_state.turn_data, game_state.players):
			result.game_over = true
			result.winner = TurnService.get_winner(game_state.players)
			result.message = "Game Over"
			
			if result.winner:
				result.message += " - Winner: %s" % result.winner.name
			else:
				result.message += " - Draw"
		else:
			result.message = "Failed to advance turn"
	
	return result

# Force skip turn (even if player has actions)
static func force_skip(game_state: Dictionary) -> Dictionary:
	var result = execute(game_state)
	result.message = "Turn forcibly skipped - " + result.message
	return result

# Check if current player should skip automatically
static func should_auto_skip(game_state: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		return false
	
	return not TurnService.can_current_player_act(
		game_state.turn_data,
		game_state.players,
		game_state.units
	)

# Get turn skip preview (what would happen if we skip)
static func get_skip_preview(game_state: Dictionary) -> Dictionary:
	var preview = {
		"can_skip": false,
		"current_player": "",
		"next_player": "",
		"turn_number": -1,
		"would_end_game": false,
		"potential_winner": null
	}
	
	if not _validate_game_state_simple(game_state):
		return preview
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		preview.current_player = current_player.name
		preview.can_skip = true
	
	preview.turn_number = game_state.turn_data.turn_number
	
	# Simulate turn advance to see what would happen
	var temp_turn_data = game_state.turn_data.duplicate(true)
	var temp_players = game_state.players.duplicate(true)
	
	if TurnService.advance_to_next_turn(temp_turn_data, temp_players, game_state.units, game_state.domains):
		var next_player = TurnService.get_current_player(temp_turn_data, temp_players)
		if next_player:
			preview.next_player = next_player.name
		
		# Check if game would end
		if TurnService.is_game_over(temp_turn_data, temp_players):
			preview.would_end_game = true
			preview.potential_winner = TurnService.get_winner(temp_players)
	
	return preview

# Validate game state for turn operations
static func _validate_game_state(game_state: Dictionary, result: Dictionary) -> bool:
	if not _validate_game_state_simple(game_state):
		result.message = "Invalid game state structure"
		return false
	
	# Check if game is already over
	if TurnService.is_game_over(game_state.turn_data, game_state.players):
		result.message = "Game is already over"
		result.game_over = true
		result.winner = TurnService.get_winner(game_state.players)
		return false
	
	return true

# Simple game state validation
static func _validate_game_state_simple(game_state: Dictionary) -> bool:
	return (
		"turn_data" in game_state and
		"players" in game_state and
		"units" in game_state and
		game_state.turn_data.has("current_player_id") and
		game_state.turn_data.has("is_game_active")
	)

# Get detailed turn information
static func get_turn_info(game_state: Dictionary) -> Dictionary:
	var info = {
		"valid": false,
		"current_player": null,
		"turn_number": -1,
		"can_act": false,
		"active_players": 0,
		"game_active": false
	}
	
	if not _validate_game_state_simple(game_state):
		return info
	
	info.valid = true
	info.current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	info.turn_number = game_state.turn_data.turn_number
	info.game_active = game_state.turn_data.is_game_active
	
	if info.current_player:
		info.can_act = TurnService.can_current_player_act(
			game_state.turn_data,
			game_state.players,
			game_state.units
		)
	
	# Count active players
	for player_id in game_state.players:
		var player = game_state.players[player_id]
		if player.is_in_game():
			info.active_players += 1
	
	return info