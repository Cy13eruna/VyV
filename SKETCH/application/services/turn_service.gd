# 🔄 TURN SERVICE
# Purpose: Turn management and player sequence
# Layer: Application/Services
# Dependencies: Core entities (Player, Unit, Domain)

class_name TurnService
extends RefCounted

# Initialize turn system
static func initialize_turn_system(players_data: Dictionary) -> Dictionary:
	var turn_data = {
		"current_player_id": -1,
		"turn_number": 0,
		"player_order": [],
		"is_game_active": false
	}
	
	# Set up player order
	var player_ids = players_data.keys()
	player_ids.sort()  # Ensure consistent order
	turn_data.player_order = player_ids
	
	if player_ids.size() > 0:
		turn_data.current_player_id = player_ids[0]
		turn_data.is_game_active = true
		
		# Activate first player
		_activate_player(turn_data.current_player_id, players_data)
	
	return turn_data

# Start next player's turn
static func advance_to_next_turn(turn_data: Dictionary, players_data: Dictionary, 
								units_data: Dictionary, domains_data: Dictionary) -> bool:
	if not turn_data.is_game_active:
		return false
	
	# End current player's turn
	_end_current_player_turn(turn_data, players_data, units_data, domains_data)
	
	# Find next active player
	var next_player_id = _get_next_active_player(turn_data, players_data)
	
	if next_player_id == -1:
		# No active players left, end game
		turn_data.is_game_active = false
		return false
	
	# Start next player's turn
	turn_data.current_player_id = next_player_id
	_start_player_turn(next_player_id, players_data, units_data, domains_data)
	
	# Increment turn number if we completed a full round
	if _is_full_round_completed(turn_data, players_data):
		turn_data.turn_number += 1
	
	return true

# Skip current player's turn
static func skip_current_turn(turn_data: Dictionary, players_data: Dictionary,
							  units_data: Dictionary, domains_data: Dictionary) -> bool:
	return advance_to_next_turn(turn_data, players_data, units_data, domains_data)

# Check if current player can perform actions
static func can_current_player_act(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary) -> bool:
	if not turn_data.is_game_active:
		return false
	
	var current_player_id = turn_data.current_player_id
	if current_player_id not in players_data:
		return false
	
	var player = players_data[current_player_id]
	if not player.can_play():
		return false
	
	# Check if player has any units with actions
	for unit_id in player.unit_ids:
		if unit_id in units_data:
			var unit = units_data[unit_id]
			if unit.can_move():
				return true
	
	return false

# Get current active player
static func get_current_player(turn_data: Dictionary, players_data: Dictionary) -> Player:
	var current_player_id = turn_data.current_player_id
	if current_player_id in players_data:
		return players_data[current_player_id]
	return null

# Check if game is over
static func is_game_over(turn_data: Dictionary, players_data: Dictionary) -> bool:
	if not turn_data.is_game_active:
		return true
	
	var active_players = 0
	for player_id in players_data:
		var player = players_data[player_id]
		if player.can_play():
			active_players += 1
	
	return active_players <= 1

# Get game winner (if game is over)
static func get_winner(players_data: Dictionary) -> Player:
	for player_id in players_data:
		var player = players_data[player_id]
		if player.can_play():
			return player
	return null

# End current player's turn
static func _end_current_player_turn(turn_data: Dictionary, players_data: Dictionary,
									units_data: Dictionary, domains_data: Dictionary) -> void:
	var current_player_id = turn_data.current_player_id
	if current_player_id in players_data:
		var player = players_data[current_player_id]
		player.deactivate()

# Start player's turn
static func _start_player_turn(player_id: int, players_data: Dictionary,
							   units_data: Dictionary, domains_data: Dictionary) -> void:
	if player_id not in players_data:
		return
	
	var player = players_data[player_id]
	player.activate()
	
	# Restore actions for all player's units
	for unit_id in player.unit_ids:
		if unit_id in units_data:
			var unit = units_data[unit_id]
			unit.restore_actions()
	
	# Generate power for all player's domains
	for domain_id in player.domain_ids:
		if domain_id in domains_data:
			var domain = domains_data[domain_id]
			domain.generate_power()
	
	# Reset forced revelations
	VisibilityService.reset_forced_revelations(units_data)

# Activate specific player
static func _activate_player(player_id: int, players_data: Dictionary) -> void:
	# Deactivate all players first
	for pid in players_data:
		players_data[pid].deactivate()
	
	# Activate target player
	if player_id in players_data:
		players_data[player_id].activate()

# Get next active player in turn order
static func _get_next_active_player(turn_data: Dictionary, players_data: Dictionary) -> int:
	var current_index = turn_data.player_order.find(turn_data.current_player_id)
	var player_count = turn_data.player_order.size()
	
	# Try each player in order
	for i in range(player_count):
		var next_index = (current_index + 1 + i) % player_count
		var next_player_id = turn_data.player_order[next_index]
		
		if next_player_id in players_data:
			var player = players_data[next_player_id]
			if player.can_play():
				return next_player_id
	
	return -1  # No active players found

# Check if a full round is completed
static func _is_full_round_completed(turn_data: Dictionary, players_data: Dictionary) -> bool:
	var current_player_id = turn_data.current_player_id
	var first_player_id = turn_data.player_order[0]
	return current_player_id == first_player_id