## Unit Manager
## 
## Gerenciador central de todas as unidades no jogo
## Controla spawn, movimento, turnos e interações
##
## @author: V&V Game Studio
## @version: 1.0 - UNIT SYSTEM

extends Node2D
class_name UnitManager

## Signals
signal unit_spawned(unit: Vagabond, position: Vector2)
signal unit_moved(unit: Vagabond, from_pos: Vector2, to_pos: Vector2)
signal unit_destroyed(unit: Vagabond, position: Vector2)
signal turn_completed()

## Unit storage
var all_units: Array[Vagabond] = []
var units_by_player: Dictionary = {}  # player_id -> Array[Vagabond]
var units_at_position: Dictionary = {}  # Vector2 -> Array[Vagabond]

## Game state
var current_player: int = 1
var turn_number: int = 1
var max_players: int = 2

## References
var hex_grid_ref
var domain_selection_ref

## Unit spawning settings
var spawn_cost: int = 1  # Future: cost to spawn units
var max_units_per_player: int = -1  # -1 = unlimited

## Initialize unit manager
func _ready() -> void:
	_initialize_player_arrays()
	print("UnitManager initialized for %d players" % max_players)

## Initialize player unit arrays
func _initialize_player_arrays() -> void:
	for player_id in range(1, max_players + 1):
		units_by_player[player_id] = []

## Set hex grid reference
func set_hex_grid_reference(hex_grid) -> void:
	hex_grid_ref = hex_grid
	print("UnitManager: Hex grid reference set")

## Set domain selection reference
func set_domain_selection_reference(domain_selection) -> void:
	domain_selection_ref = domain_selection
	print("UnitManager: Domain selection reference set")

## Spawn vagabond at domain center
func spawn_vagabond_at_domain(domain_index: int, player_id: int = 1) -> Vagabond:
	if not hex_grid_ref:
		push_error("UnitManager: No hex grid reference set")
		return null
	
	# Get domain center position (star position)
	var star_positions = hex_grid_ref.cache.get_dot_positions()
	if domain_index < 0 or domain_index >= star_positions.size():
		push_error("UnitManager: Invalid domain index %d" % domain_index)
		return null
	
	var spawn_position = star_positions[domain_index]
	return spawn_vagabond_at_position(spawn_position, player_id, domain_index)

## Spawn vagabond at specific position
func spawn_vagabond_at_position(position: Vector2, player_id: int = 1, origin_domain: int = -1) -> Vagabond:
	# Check if position is already occupied
	if is_position_occupied(position):
		print("UnitManager: Position %s already occupied" % position)
		return null
	
	# Check unit limit
	if max_units_per_player > 0:
		var player_units = get_units_for_player(player_id)
		if player_units.size() >= max_units_per_player:
			print("UnitManager: Player %d reached unit limit" % player_id)
			return null
	
	# Create new vagabond
	var vagabond = Vagabond.new()
	vagabond.initialize_at_position(position, origin_domain)
	vagabond.unit_manager_ref = self
	vagabond.hex_grid_ref = hex_grid_ref
	
	# Connect signals
	vagabond.unit_moved.connect(_on_unit_moved)
	vagabond.unit_destroyed.connect(_on_unit_destroyed)
	vagabond.unit_state_changed.connect(_on_unit_state_changed)
	
	# Add to scene and tracking
	add_child(vagabond)
	_add_unit_to_tracking(vagabond, player_id, position)
	
	unit_spawned.emit(vagabond, position)
	print("UnitManager: Spawned Vagabond for player %d at %s" % [player_id, position])
	
	return vagabond

## Add unit to tracking systems
func _add_unit_to_tracking(unit: Vagabond, player_id: int, position: Vector2) -> void:
	all_units.append(unit)
	units_by_player[player_id].append(unit)
	
	if not units_at_position.has(position):
		units_at_position[position] = []
	units_at_position[position].append(unit)

## Remove unit from tracking systems
func _remove_unit_from_tracking(unit: Vagabond) -> void:
	all_units.erase(unit)
	
	# Remove from player arrays
	for player_id in units_by_player:
		units_by_player[player_id].erase(unit)
	
	# Remove from position tracking
	var position = unit.current_star_position
	if units_at_position.has(position):
		units_at_position[position].erase(unit)
		if units_at_position[position].is_empty():
			units_at_position.erase(position)

## Check if position is occupied
func is_position_occupied(position: Vector2) -> bool:
	return units_at_position.has(position) and not units_at_position[position].is_empty()

## Get units at specific position
func get_units_at_position(position: Vector2) -> Array[Vagabond]:
	if units_at_position.has(position):
		return units_at_position[position]
	return []

## Get all units for specific player
func get_units_for_player(player_id: int) -> Array[Vagabond]:
	if units_by_player.has(player_id):
		return units_by_player[player_id]
	return []

## Get unit at exact position
func get_unit_at_position(position: Vector2) -> Vagabond:
	var units = get_units_at_position(position)
	return units[0] if not units.is_empty() else null

## Move unit to new position
func move_unit(unit: Vagabond, target_position: Vector2) -> bool:
	if not unit or not unit.can_move_to(target_position):
		return false
	
	# Check if target position is valid star
	if not _is_valid_star_position(target_position):
		return false
	
	# Check if target is occupied
	if is_position_occupied(target_position):
		print("UnitManager: Target position occupied")
		return false
	
	var old_position = unit.current_star_position
	
	# Update position tracking
	if units_at_position.has(old_position):
		units_at_position[old_position].erase(unit)
		if units_at_position[old_position].is_empty():
			units_at_position.erase(old_position)
	
	# Move the unit
	var success = unit.move_to(target_position)
	
	if success:
		# Add to new position tracking
		if not units_at_position.has(target_position):
			units_at_position[target_position] = []
		units_at_position[target_position].append(unit)
	
	return success

## Check if position is valid star position
func _is_valid_star_position(position: Vector2) -> bool:
	if not hex_grid_ref:
		return false
	
	var star_positions = hex_grid_ref.cache.get_dot_positions()
	var tolerance = 10.0  # Allow small position differences
	
	for star_pos in star_positions:
		if position.distance_to(star_pos) <= tolerance:
			return true
	
	return false

## Get nearest star position to given position
func get_nearest_star_position(position: Vector2) -> Vector2:
	if not hex_grid_ref:
		return position
	
	var star_positions = hex_grid_ref.cache.get_dot_positions()
	var nearest_pos = position
	var min_distance = INF
	
	for star_pos in star_positions:
		var distance = position.distance_to(star_pos)
		if distance < min_distance:
			min_distance = distance
			nearest_pos = star_pos
	
	return nearest_pos

## Start new turn
func start_new_turn() -> void:
	turn_number += 1
	current_player = (current_player % max_players) + 1
	
	# Reset all units for new turn
	for unit in all_units:
		unit.reset_turn()
	
	print("UnitManager: Turn %d started, Player %d" % [turn_number, current_player])

## Get game statistics
func get_unit_stats() -> Dictionary:
	var stats = {
		"total_units": all_units.size(),
		"units_by_player": {},
		"units_by_state": {"BEM": 0, "MAL": 0},
		"current_player": current_player,
		"turn_number": turn_number
	}
	
	# Count units by player
	for player_id in units_by_player:
		stats.units_by_player[player_id] = units_by_player[player_id].size()
	
	# Count units by state
	for unit in all_units:
		if unit.estado == Vagabond.UnitState.BEM:
			stats.units_by_state.BEM += 1
		else:
			stats.units_by_state.MAL += 1
	
	return stats

## Handle unit movement
func _on_unit_moved(from_pos: Vector2, to_pos: Vector2) -> void:
	var unit = get_unit_at_position(to_pos)
	if unit:
		unit_moved.emit(unit, from_pos, to_pos)

## Handle unit destruction
func _on_unit_destroyed() -> void:
	var unit = null
	# Find the unit that was destroyed (signal sender)
	for u in all_units:
		if not is_instance_valid(u):
			unit = u
			break
	
	if unit:
		var position = unit.current_star_position
		_remove_unit_from_tracking(unit)
		unit_destroyed.emit(unit, position)

## Handle unit state change
func _on_unit_state_changed(new_state: Vagabond.UnitState) -> void:
	print("UnitManager: Unit state changed to %s" % Vagabond.UnitState.keys()[new_state])

## Clean up all units
func clear_all_units() -> void:
	for unit in all_units.duplicate():
		if is_instance_valid(unit):
			unit.queue_free()
	
	all_units.clear()
	units_by_player.clear()
	units_at_position.clear()
	print("UnitManager: All units cleared")

## Get debug info
func get_debug_info() -> String:
	var info = "=== UNIT MANAGER DEBUG ===\n"
	info += "Total Units: %d\n" % all_units.size()
	info += "Current Player: %d\n" % current_player
	info += "Turn: %d\n" % turn_number
	
	for player_id in units_by_player:
		info += "Player %d Units: %d\n" % [player_id, units_by_player[player_id].size()]
	
	info += "Occupied Positions: %d\n" % units_at_position.size()
	
	return info