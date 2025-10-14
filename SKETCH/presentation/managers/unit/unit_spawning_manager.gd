# 🐣 UNIT SPAWNING MANAGER
# Purpose: Handle unit creation and spawning
# Layer: Presentation Manager

extends RefCounted
class_name UnitSpawningManager

# Import dependencies
const UnitNameGenerator = preload("res://presentation/managers/unit/unit_name_generator.gd")

# References
var game_state_cache: Dictionary = {}

# Set game state reference (temporary solution)
func set_game_state_reference(game_state: Dictionary):
	game_state_cache = game_state

func get_game_state() -> Dictionary:
	return game_state_cache

# Spawn a new unit at domain center (VAGABOND bonus)
func spawn_unit_at_domain_center(domain):
	print("[UNIT SPAWN] Starting spawn at domain center for domain: ", domain.name)
	# Get next available unit ID
	var new_unit_id = 1
	var game_state = get_game_state()  # This needs to be passed from gameplay_manager
	while new_unit_id in game_state.units:
		new_unit_id += 1
	
	print("[UNIT SPAWN] New unit ID: ", new_unit_id)
	
	# Generate a proper name for the new unit using the domain's initial
	var unit_name = UnitNameGenerator.generate_unit_name_for_domain(domain, game_state)
	print("[UNIT SPAWN] Generated unit name: ", unit_name)
	
	# Create new unit at domain center (no birth domain tracking needed)
	var UnitClean = load("res://core/entities/unit_clean.gd")
	var new_unit = UnitClean.new(new_unit_id, domain.owner_id, unit_name, domain.center_position)
	
	print("[UNIT SPAWN] Created unit at position: ", domain.center_position.hex_coord.get_string() if domain.center_position.hex_coord else "no hex_coord")
	
	# Add unit to game state
	game_state.units[new_unit_id] = new_unit
	print("[UNIT SPAWN] Added unit to game_state. Total units now: ", game_state.units.size())
	
	# Add unit to player
	var player = game_state.players[domain.owner_id]
	player.add_unit(new_unit_id)
	print("[UNIT SPAWN] Added unit to player. Player ", domain.owner_id, " now has ", player.unit_ids.size(), " units")
	print("[UNIT SPAWN] Spawn completed successfully!")

# Generate next available unit ID
func get_next_unit_id(game_state: Dictionary) -> int:
	var new_unit_id = 1
	while new_unit_id in game_state.units:
		new_unit_id += 1
	return new_unit_id

# Create unit with specific parameters
func create_unit(unit_id: int, owner_id: int, unit_name: String, position, game_state: Dictionary):
	print("[UNIT CREATE] Creating unit ", unit_id, " (", unit_name, ") for player ", owner_id)
	var UnitClean = load("res://core/entities/unit_clean.gd")
	var new_unit = UnitClean.new(unit_id, owner_id, unit_name, position)
	
	print("[UNIT CREATE] Unit created at position: ", position.hex_coord.get_string() if position.hex_coord else "no hex_coord")
	
	# Add unit to game state
	game_state.units[unit_id] = new_unit
	print("[UNIT CREATE] Added to game_state. Total units: ", game_state.units.size())
	
	# Add unit to player
	var player = game_state.players[owner_id]
	player.add_unit(unit_id)
	print("[UNIT CREATE] Added to player. Player has ", player.unit_ids.size(), " units")
	
	return new_unit

# Remove unit from game
func remove_unit(unit_id: int, game_state: Dictionary):
	if unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Remove unit from game state
		game_state.units.erase(unit_id)
		
		# Remove unit from player
		var player = game_state.players[unit.owner_id]
		player.remove_unit(unit_id)

# Cleanup method
func cleanup():
	game_state_cache.clear()