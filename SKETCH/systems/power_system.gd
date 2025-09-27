extends Node

# Power management system for V&V game
# Handles domain power generation, consumption, and availability checks

signal power_generated(player_id: int, domain_name: String, new_total: int)
signal power_consumed(player_id: int, domain_name: String, remaining: int)
signal domain_occupied(player_id: int, domain_name: String, occupied_by: int)
signal domain_freed(player_id: int, domain_name: String)

# Power state
var unit1_domain_power: int = 1  # Domain 1 power (starts with 1)
var unit2_domain_power: int = 1  # Domain 2 power (starts with 1)

# Domain data
var unit1_domain_center: int = 0
var unit2_domain_center: int = 0
var unit1_domain_name: String = ""
var unit2_domain_name: String = ""

# Game state
var current_player: int = 1

# Unit positions (for occupation checks)
var unit1_position: int = 0
var unit2_position: int = 0

# Initialize power system
func initialize() -> void:
	print("⚡ PowerSystem initialized")

# Setup domain data
func setup_domains(domain1_center: int, domain2_center: int, domain1_name: String, domain2_name: String) -> void:
	unit1_domain_center = domain1_center
	unit2_domain_center = domain2_center
	unit1_domain_name = domain1_name
	unit2_domain_name = domain2_name
	
	print("⚡ PowerSystem: Domains setup - %s at %d, %s at %d" % [
		domain1_name, domain1_center, domain2_name, domain2_center
	])

# Update game state
func update_game_state(state_data: Dictionary) -> void:
	if state_data.has("current_player"):
		current_player = state_data.current_player
	if state_data.has("unit1_position"):
		unit1_position = state_data.unit1_position
	if state_data.has("unit2_position"):
		unit2_position = state_data.unit2_position

# Generate power for current player's domain only
func generate_power_for_current_player() -> void:
	print("⚡ PowerSystem: Player %d turn - Generating power ONLY for Player %d's domain" % [current_player, current_player])
	
	if current_player == 1:
		# Domain 1: generate power if not occupied
		if not is_domain_occupied(1):
			unit1_domain_power += 1
			print("⚡ PowerSystem: Domain 1 (%s) generated 1 power (Total: %d)" % [unit1_domain_name, unit1_domain_power])
			power_generated.emit(1, unit1_domain_name, unit1_domain_power)
		else:
			print("⚡ PowerSystem: Domain 1 (%s) occupied - didn't generate power" % unit1_domain_name)
			domain_occupied.emit(1, unit1_domain_name, 2)
	else:
		# Domain 2: generate power if not occupied
		if not is_domain_occupied(2):
			unit2_domain_power += 1
			print("⚡ PowerSystem: Domain 2 (%s) generated 1 power (Total: %d)" % [unit2_domain_name, unit2_domain_power])
			power_generated.emit(2, unit2_domain_name, unit2_domain_power)
		else:
			print("⚡ PowerSystem: Domain 2 (%s) occupied - didn't generate power" % unit2_domain_name)
			domain_occupied.emit(2, unit2_domain_name, 1)

# Check if domain has power for action
func has_domain_power_for_action() -> bool:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# If domain center is occupied by enemy, actions are free
	if enemy_unit_pos == domain_center:
		print("⚡ PowerSystem: Domain occupied! Free actions for original units.")
		return true
	
	# Otherwise, check if has power
	var current_power = unit1_domain_power if current_player == 1 else unit2_domain_power
	return current_power > 0

# Consume domain power
func consume_domain_power() -> void:
	var domain_center = unit1_domain_center if current_player == 1 else unit2_domain_center
	var enemy_unit_pos = unit2_position if current_player == 1 else unit1_position
	
	# If center is occupied, don't consume power
	if enemy_unit_pos == domain_center:
		print("⚡ PowerSystem: Domain occupied - no power consumed")
		return
	
	# Consume 1 power
	if current_player == 1:
		unit1_domain_power = max(0, unit1_domain_power - 1)
		print("⚡ PowerSystem: Domain 1 consumed 1 power (Remaining: %d)" % unit1_domain_power)
		power_consumed.emit(1, unit1_domain_name, unit1_domain_power)
	else:
		unit2_domain_power = max(0, unit2_domain_power - 1)
		print("⚡ PowerSystem: Domain 2 consumed 1 power (Remaining: %d)" % unit2_domain_power)
		power_consumed.emit(2, unit2_domain_name, unit2_domain_power)

# Check if specific domain is occupied
func is_domain_occupied(domain_id: int) -> bool:
	if domain_id == 1:
		return unit2_position == unit1_domain_center
	else:
		return unit1_position == unit2_domain_center

# Get current player's domain power
func get_current_player_power() -> int:
	return unit1_domain_power if current_player == 1 else unit2_domain_power

# Get specific player's domain power
func get_player_power(player_id: int) -> int:
	return unit1_domain_power if player_id == 1 else unit2_domain_power

# Get power state for UI updates
func get_power_state() -> Dictionary:
	return {
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"unit1_domain_name": unit1_domain_name,
		"unit2_domain_name": unit2_domain_name,
		"unit1_domain_center": unit1_domain_center,
		"unit2_domain_center": unit2_domain_center,
		"current_player": current_player,
		"domain1_occupied": is_domain_occupied(1),
		"domain2_occupied": is_domain_occupied(2)
	}

# Set power values (for initialization/loading)
func set_power_values(domain1_power: int, domain2_power: int) -> void:
	unit1_domain_power = domain1_power
	unit2_domain_power = domain2_power
	print("⚡ PowerSystem: Power values set - Domain 1: %d, Domain 2: %d" % [domain1_power, domain2_power])

# Reset power to initial state
func reset_power() -> void:
	unit1_domain_power = 1
	unit2_domain_power = 1
	print("⚡ PowerSystem: Power reset to initial state (1, 1)")

# Get debug information
func get_debug_info() -> Dictionary:
	return {
		"current_player": current_player,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"current_player_power": get_current_player_power(),
		"has_power_for_action": has_domain_power_for_action(),
		"domain1_occupied": is_domain_occupied(1),
		"domain2_occupied": is_domain_occupied(2),
		"unit_positions": [unit1_position, unit2_position],
		"domain_centers": [unit1_domain_center, unit2_domain_center]
	}