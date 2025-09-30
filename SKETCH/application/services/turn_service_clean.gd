# ⏰ TURN SERVICE (CLEAN)
# Purpose: Turn management and game flow control
# Layer: Application/Services
# Dependencies: Clean core entities only

extends RefCounted

# Initialize turn system
static func initialize_turn_system(players_data: Dictionary) -> Dictionary:
	var active_players = []
	
	# Get all active players
	for player_id in players_data:
		var player = players_data[player_id]
		if player.is_in_game():
			active_players.append(player_id)
	
	# Sort players by ID for consistent order
	active_players.sort()
	
	return {
		"current_player_id": active_players[0] if active_players.size() > 0 else 1,
		"player_order": active_players,
		"turn_number": 1,
		"is_game_active": true,
		"current_player_index": 0
	}

# Get current player
static func get_current_player(turn_data: Dictionary, players_data: Dictionary):
	if "current_player_id" in turn_data and turn_data.current_player_id in players_data:
		return players_data[turn_data.current_player_id]
	return null

# Check if current player can act
static func can_current_player_act(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary) -> bool:
	var current_player = get_current_player(turn_data, players_data)
	if not current_player:
		return false
	
	# Check if any of player's units can move
	for unit_id in current_player.unit_ids:
		if unit_id in units_data:
			var unit = units_data[unit_id]
			if unit.can_move():
				return true
	
	return false

# Advance to next turn
static func advance_to_next_turn(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary, domains_data: Dictionary = {}) -> bool:
	if not turn_data.is_game_active:
		return false
	
	# Restore actions for current player's units before switching
	var current_player = get_current_player(turn_data, players_data)
	if current_player:
		_restore_player_actions(current_player, units_data)
		_restore_player_power(current_player, domains_data)
	
	# Move to next player
	var player_order = turn_data.player_order
	var current_index = turn_data.current_player_index
	
	# Find next active player
	var next_index = (current_index + 1) % player_order.size()
	var attempts = 0
	
	while attempts < player_order.size():
		var next_player_id = player_order[next_index]
		
		if next_player_id in players_data:
			var next_player = players_data[next_player_id]
			
			if next_player.is_in_game():
				# Found valid next player
				turn_data.current_player_id = next_player_id
				turn_data.current_player_index = next_index
				
				# If we completed a full round, increment turn number
				if next_index == 0:
					turn_data.turn_number += 1
				
				return true
		
		# Try next player
		next_index = (next_index + 1) % player_order.size()
		attempts += 1
	
	# No valid players found - game should end
	turn_data.is_game_active = false
	return false

# Check if game is over
static func is_game_over(turn_data: Dictionary, players_data: Dictionary) -> bool:
	if not turn_data.is_game_active:
		return true
	
	var active_players = 0
	
	for player_id in players_data:
		var player = players_data[player_id]
		if player.is_in_game():
			active_players += 1
	
	return active_players <= 1

# Get winner (if game is over)
static func get_winner(players_data: Dictionary):
	var active_players = []
	
	for player_id in players_data:
		var player = players_data[player_id]
		if player.is_in_game():
			active_players.append(player)
	
	if active_players.size() == 1:
		return active_players[0]
	
	return null

# Skip current player's turn
static func skip_turn(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary, domains_data: Dictionary = {}) -> bool:
	return advance_to_next_turn(turn_data, players_data, units_data, domains_data)

# Eliminate player from game
static func eliminate_player(player_id: int, turn_data: Dictionary, players_data: Dictionary) -> void:
	if player_id in players_data:
		var player = players_data[player_id]
		player.eliminate()
		
		# If it was current player's turn, advance to next
		if turn_data.current_player_id == player_id:
			# This will be handled by the next advance_to_next_turn call
			pass

# Get turn statistics
static func get_turn_stats(turn_data: Dictionary, players_data: Dictionary) -> Dictionary:
	var active_players = 0
	var eliminated_players = 0
	
	for player_id in players_data:
		var player = players_data[player_id]
		if player.is_in_game():
			active_players += 1
		elif player.is_eliminated:
			eliminated_players += 1
	
	return {
		"turn_number": turn_data.turn_number,
		"current_player_id": turn_data.current_player_id,
		"active_players": active_players,
		"eliminated_players": eliminated_players,
		"is_game_active": turn_data.is_game_active
	}

# Helper: Restore actions for all player's units
static func _restore_player_actions(player, units_data: Dictionary) -> void:
	for unit_id in player.unit_ids:
		if unit_id in units_data:
			var unit = units_data[unit_id]
			unit.restore_actions()

# Helper: Restore power for player's domains (future implementation)
static func _restore_player_power(player, domains_data: Dictionary) -> void:
	# Future: Restore power for player's domains
	for domain_id in player.domain_ids:
		if domain_id in domains_data:
			var domain = domains_data[domain_id]
			# domain.generate_power()
			pass