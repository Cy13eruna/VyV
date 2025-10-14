class_name GameState
extends RefCounted

# Hexagonal grid data
var points: Array = []
var hex_coords: Array = []  # Axial coordinates (q, r) for each point
var paths: Array = []

# Hover state
var hovered_point: int = -1
var hovered_edge: int = -1

# Unit positions and states
var unit1_position: int = 0  # Index of the point where unit 1 is
var unit2_position: int = 0  # Index of the point where unit 2 is
var unit1_actions: int = GameConstants.INITIAL_ACTIONS   # Action points of unit 1
var unit2_actions: int = GameConstants.INITIAL_ACTIONS   # Action points of unit 2
var current_player: int = GameConstants.PlayerID.PLAYER_1  # Current player (1 or 2)

# Game settings
var fog_of_war: bool = true   # Fog of war control

# Domain data
var unit1_domain_center: int = 0  # Center of unit 1's domain
var unit2_domain_center: int = 0  # Center of unit 2's domain
var unit1_domain_name: String = ""   # Name of unit 1's domain
var unit2_domain_name: String = ""   # Name of unit 2's domain
var unit1_name: String = ""          # Name of unit 1
var unit2_name: String = ""          # Name of unit 2

# Power system
var unit1_domain_power: int = GameConstants.INITIAL_DOMAIN_POWER  # Accumulated power of domain 1
var unit2_domain_power: int = GameConstants.INITIAL_DOMAIN_POWER  # Accumulated power of domain 2

# Forced revelation (for forest mechanics)
var unit1_force_revealed: bool = false  # Unit 1 was forcefully revealed
var unit2_force_revealed: bool = false  # Unit 2 was forcefully revealed

# Initialize the game state
func _init():
	reset_to_defaults()

# Reset all state to default values
func reset_to_defaults() -> void:
	points.clear()
	hex_coords.clear()
	paths.clear()
	
	hovered_point = -1
	hovered_edge = -1
	
	unit1_position = 0
	unit2_position = 0
	unit1_actions = GameConstants.INITIAL_ACTIONS
	unit2_actions = GameConstants.INITIAL_ACTIONS
	current_player = GameConstants.PlayerID.PLAYER_1
	
	fog_of_war = true
	
	unit1_domain_center = 0
	unit2_domain_center = 0
	unit1_domain_name = ""
	unit2_domain_name = ""
	unit1_name = ""
	unit2_name = ""
	
	unit1_domain_power = GameConstants.INITIAL_DOMAIN_POWER
	unit2_domain_power = GameConstants.INITIAL_DOMAIN_POWER
	
	unit1_force_revealed = false
	unit2_force_revealed = false

# Get current player's unit position
func get_current_unit_position() -> int:
	return unit1_position if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_position

# Get enemy unit position
func get_enemy_unit_position() -> int:
	return unit2_position if current_player == GameConstants.PlayerID.PLAYER_1 else unit1_position

# Get current player's actions
func get_current_actions() -> int:
	return unit1_actions if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_actions

# Get current player's domain center
func get_current_domain_center() -> int:
	return unit1_domain_center if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_domain_center

# Get current player's domain power
func get_current_domain_power() -> int:
	return unit1_domain_power if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_domain_power

# Set current player's unit position
func set_current_unit_position(position: int) -> void:
	if current_player == GameConstants.PlayerID.PLAYER_1:
		unit1_position = position
	else:
		unit2_position = position

# Consume current player's action
func consume_current_action() -> void:
	if current_player == GameConstants.PlayerID.PLAYER_1:
		unit1_actions = max(0, unit1_actions - 1)
	else:
		unit2_actions = max(0, unit2_actions - 1)

# Consume current player's domain power
func consume_current_domain_power() -> void:
	if current_player == GameConstants.PlayerID.PLAYER_1:
		unit1_domain_power = max(0, unit1_domain_power - 1)
	else:
		unit2_domain_power = max(0, unit2_domain_power - 1)

# Switch to next player
func switch_player() -> void:
	current_player = GameConstants.PlayerID.PLAYER_2 if current_player == GameConstants.PlayerID.PLAYER_1 else GameConstants.PlayerID.PLAYER_1

# Restore actions for current player
func restore_current_actions() -> void:
	if current_player == GameConstants.PlayerID.PLAYER_1:
		unit1_actions = GameConstants.INITIAL_ACTIONS
	else:
		unit2_actions = GameConstants.INITIAL_ACTIONS

# Generate power for domains (if not occupied)
func generate_domain_power() -> void:
	# Domain 1: generate power if not occupied by unit 2
	if unit2_position != unit1_domain_center:
		unit1_domain_power += 1
	
	# Domain 2: generate power if not occupied by unit 1
	if unit1_position != unit2_domain_center:
		unit2_domain_power += 1

# Check if current domain is occupied by enemy
func is_current_domain_occupied() -> bool:
	var domain_center = get_current_domain_center()
	var enemy_pos = get_enemy_unit_position()
	return enemy_pos == domain_center

# Get player name for display
func get_current_player_name() -> String:
	return "Player 1 (Red)" if current_player == GameConstants.PlayerID.PLAYER_1 else "Player 2 (Violet)"

# Get current player's unit name
func get_current_unit_name() -> String:
	return unit1_name if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_name

# Get current player's domain name
func get_current_domain_name() -> String:
	return unit1_domain_name if current_player == GameConstants.PlayerID.PLAYER_1 else unit2_domain_name