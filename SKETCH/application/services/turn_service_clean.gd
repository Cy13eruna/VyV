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
static func advance_to_next_turn(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary, domains_data: Dictionary = {}, game_state: Dictionary = {}) -> bool:
	if not turn_data.is_game_active:
		return false
	
	# Restore actions for current player's units before switching
	var current_player = get_current_player(turn_data, players_data)
	if current_player:
		_restore_player_actions(current_player, units_data)
	
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
				
				# GENERATE POWER FOR NEW PLAYER AT START OF THEIR TURN
				_update_domain_occupations_turn(units_data, domains_data)
				_restore_player_power(next_player, domains_data)
				
				# Remove dead units from the game
				_remove_dead_units(units_data, players_data)
				
				# Clean up expired skull emojis
				_cleanup_expired_skulls(game_state, turn_data.turn_number)
				
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
static func skip_turn(turn_data: Dictionary, players_data: Dictionary, units_data: Dictionary, domains_data: Dictionary = {}, game_state: Dictionary = {}) -> bool:
	return advance_to_next_turn(turn_data, players_data, units_data, domains_data, game_state)

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

# Helper: Restore power for player's domains
static func _restore_player_power(player, domains_data: Dictionary) -> void:
	# Generate power for player's domains at start of turn (only if not occupied)
	for domain_id in player.domain_ids:
		if domain_id in domains_data:
			var domain = domains_data[domain_id]
			# Only generate power if domain is not occupied by enemy
			if not domain.get("is_occupied", false):
				# Generate 1 power per turn per domain (base)
				domain.power += 1
				
				# Generate additional power from Harvest upgrades
				var harvest_power = domain.get("power_per_turn", 0)
				if harvest_power > 0:
					domain.power += harvest_power
				
				# Generate additional power from Fish upgrades (random each turn)
				if domain.get("has_fish_upgrade", false):
					_apply_fish_bonus_per_turn(domain, domains_data)
				
				# Apply Market power duplication (duplicates power generated this turn)
				if domain.get("has_market_upgrade", false):
					_apply_market_power_duplication(domain)

# Helper: Update domain occupations at turn start
static func _update_domain_occupations_turn(units_data: Dictionary, domains_data: Dictionary) -> void:
	if not (domains_data and units_data):
		return
	
	# Reset all occupations
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		domain.is_occupied = false
		domain.occupied_by_player = -1
	
	# Check which domains are occupied by enemy units
	for unit_id in units_data:
		var unit = units_data[unit_id]
		
		for domain_id in domains_data:
			var domain = domains_data[domain_id]
			
			# Only enemy units can occupy domains (not the owner)
			if unit.owner_id != domain.owner_id:
				# Check if unit is exactly at domain center
				if unit.position.equals(domain.center_position):
					domain.is_occupied = true
					domain.occupied_by_player = unit.owner_id
					break

# Helper: Apply fish bonus per turn (random between 0 and number of waters)
static func _apply_fish_bonus_per_turn(domain, domains_data: Dictionary) -> void:
	# Get the number of water edges this domain has
	var water_count = domain.get("fish_water_count", 0)
	
	if water_count > 0:
		# Generate random number between 0 and water_count (inclusive) - NERFED
		var fish_bonus = randi() % (water_count + 1)
		
		domain.power += fish_bonus
		
		# Store current turn's fish bonus for display/debug
		domain.current_fish_bonus = fish_bonus
		
		# Update fish emoji positions to match current bonus (fixed positions)
		# Only update if fish_bonus > 0, otherwise clear positions
		if fish_bonus > 0:
			_update_fish_emoji_positions(domain, fish_bonus)
		else:
			# No fish this turn, clear emoji positions
			domain.fish_emoji_positions = []
		
		# Optional debug (can be removed)
		# print("[FISH] Domain ", domain.get("name", "Unknown"), " got +", fish_bonus, " power this turn")

# Helper: Update fish emoji positions for current turn (fixed positions)
static func _update_fish_emoji_positions(domain, fish_bonus: int) -> void:
	# Store fixed emoji positions based on domain seed to avoid random changes
	# Use domain ID as seed for consistent positioning
	var domain_id = domain.get("id", 1)
	var water_count = domain.get("fish_water_count", 0)
	
	if water_count > 0 and fish_bonus > 0:
		# Create deterministic sequence based on domain ID and current bonus
		var rng = RandomNumberGenerator.new()
		rng.seed = domain_id * 1000 + fish_bonus  # Unique seed per domain per bonus level
		
		# Generate fixed positions for this bonus amount
		var productive_positions = []
		for i in range(min(fish_bonus, water_count)):
			productive_positions.append(rng.randi() % water_count)
		
		# Remove duplicates and ensure we have exactly fish_bonus positions
		var unique_positions = []
		for pos in productive_positions:
			if pos not in unique_positions:
				unique_positions.append(pos)
		
		# If we need more positions due to duplicates, add remaining ones
		while unique_positions.size() < fish_bonus and unique_positions.size() < water_count:
			for i in range(water_count):
				if i not in unique_positions:
					unique_positions.append(i)
					if unique_positions.size() >= fish_bonus:
						break
		
		# Store the fixed positions in the domain
		domain.fish_emoji_positions = unique_positions.slice(0, fish_bonus)

# Helper: Apply market power duplication (duplicates power generated this turn)
static func _apply_market_power_duplication(domain) -> void:
	# Calculate power generated this turn
	var base_power = 1  # Base power generation per turn
	var harvest_power = domain.get("power_per_turn", 0)  # Harvest bonus
	var fish_power = domain.get("current_fish_bonus", 0)  # Fish bonus this turn
	
	# Total power generated this turn
	var power_generated_this_turn = base_power + harvest_power + fish_power
	
	# Duplicate the power generated this turn
	domain.power += power_generated_this_turn
	
	# Store market bonus for display/tracking
	domain.current_market_bonus = power_generated_this_turn
	
	# Optional debug
	# print("[MARKET] Domain ", domain.get("name", "Unknown"), " duplicated ", power_generated_this_turn, " power this turn")

# Helper: Remove dead units from the game
static func _remove_dead_units(units_data: Dictionary, players_data: Dictionary) -> void:
	if not units_data:
		return
	
	var units_to_remove = []
	
	# Find all dead units
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if unit.is_dead():
			units_to_remove.append(unit_id)
	
	# Remove dead units
	for unit_id in units_to_remove:
		var unit = units_data[unit_id]
		var owner_id = unit.owner_id
		
		# Remove from player's unit list
		if owner_id in players_data:
			var player = players_data[owner_id]
			if player.has_method("remove_unit"):
				player.remove_unit(unit_id)
			elif "unit_ids" in player:
				player.unit_ids.erase(unit_id)
		
		# Remove from units data
		units_data.erase(unit_id)
		
		# Optional debug
		# print("[HEALTH] Unit ", unit.name, " (ID: ", unit_id, ") died and was removed from the game")

# Helper: Clean up expired skull emojis
static func _cleanup_expired_skulls(game_state: Dictionary, current_turn: int) -> void:
	if not game_state or not ("skull_emojis" in game_state):
		return
	
	var skulls_to_remove = []
	
	# Find expired skulls
	for i in range(game_state.skull_emojis.size()):
		var skull_data = game_state.skull_emojis[i]
		if current_turn >= skull_data.get("expires_turn", 0):
			skulls_to_remove.append(i)
	
	# Remove expired skulls (in reverse order to maintain indices)
	for i in range(skulls_to_remove.size() - 1, -1, -1):
		var index = skulls_to_remove[i]
		game_state.skull_emojis.remove_at(index)
		print("[SKULL] Removed expired skull emoji at turn ", current_turn)