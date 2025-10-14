# 🚶 UNIT (CLEAN)
# Purpose: Game unit entity (replicable for N units per player)
# Layer: Core/Entities
# Dependencies: Position only

extends RefCounted

# Signals
signal damage_applied(unit)

# Unit properties
var id: int
var owner_id: int
var name: String
var position
var actions_remaining: int = 1
var max_actions: int = 1
var level: int = 1  # Unit level, starts at 1 (not shown in frontend)
var health: int = 1  # Unit health: 1 = Bem (Good), 0 = Mal (Bad), <0 = removed
var is_fighter: bool = false  # Whether unit has fighter training
var is_healer: bool = false   # Whether unit has healer training
var is_rider: bool = false    # Whether unit has rider training
var is_climber: bool = false  # Whether unit has climber training
var is_shaman: bool = false    # Whether unit has shaman training
var is_converted: bool = false  # Unit was converted by shaman
var original_owner_id: int = -1  # Original owner before conversion
var is_revealed: bool = false
var force_revealed: bool = false

func _init(unit_id: int, player_id: int, unit_name: String, start_position):
	id = unit_id
	owner_id = player_id
	name = unit_name
	position = start_position
	actions_remaining = 1
	level = 1
	health = 1
	is_fighter = false
	is_healer = false
	is_rider = false

# Move unit to new position
func move_to(new_position) -> bool:
	if can_move():
		# Track movement direction for emoji effects
		var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
		UnitMovementTracker.track_unit_movement(id, position, new_position)
		
		position = new_position
		consume_action()
		return true
	return false

# Check if unit can move to position
func can_move_to(target_position) -> bool:
	return can_move() and position.distance_to(target_position) == 1

# Check if position is within movement range
func is_within_movement_range(target_position) -> bool:
	return position.distance_to(target_position) <= 1

# Check if unit can move (has actions)
func can_move() -> bool:
	return actions_remaining > 0

# Consume one action
func consume_action() -> void:
	actions_remaining = max(0, actions_remaining - 1)

# Restore actions (start of turn)
func restore_actions() -> void:
	if is_rider:
		actions_remaining = 2  # Riders get 2 actions per turn
		max_actions = 2
	else:
		actions_remaining = 1
		max_actions = 1

# Check if unit is at specific position
func is_at_position(check_position) -> bool:
	return position.equals(check_position)

# Check if unit is adjacent to position
func is_adjacent_to(check_position) -> bool:
	return position.distance_to(check_position) == 1

# Check if unit is within range of position
func is_within_range(check_position, range: int) -> bool:
	return position.distance_to(check_position) <= range

# Reveal unit (make visible to enemies)
func reveal() -> void:
	is_revealed = true

# Hide unit (fog of war)
func hide() -> void:
	is_revealed = false

# Force reveal (always visible)
func force_reveal() -> void:
	force_revealed = true

# Remove force reveal
func remove_force_reveal() -> void:
	force_revealed = false

# Check if unit is visible to player
func is_visible_to_player(player_id: int) -> bool:
	# Own units are always visible
	if owner_id == player_id:
		return true
	
	# Visible if revealed or force revealed
	return is_revealed or force_revealed

# Check if mouse is hovering over unit
func is_mouse_over(mouse_pos: Vector2, radius: float = 8.0) -> bool:
	return position.pixel_pos.distance_to(mouse_pos) <= radius

# Get unit color for rendering
func get_color() -> Color:
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.CYAN, Color.MAGENTA]
	return colors[(owner_id - 1) % colors.size()]

# Get unit display emoji
func get_emoji() -> String:
	return "🚶🏻‍♀️"

# Check if emoji should be flipped based on movement direction
func should_flip_emoji() -> bool:
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	return UnitMovementTracker.should_flip_emoji(id)

# Get team color for this unit (requires game state)
func get_team_color(game_state: Dictionary) -> Color:
	if owner_id in game_state.players:
		return game_state.players[owner_id].color
	return Color.WHITE

# Get the initial (first letter) of the unit's name
func get_name_initial() -> String:
	if name.length() > 0:
		return name.substr(0, 1).to_upper()
	return ""

# Health management methods
func is_healthy() -> bool:
	return health == 1

func is_injured() -> bool:
	return health == 0

func is_dead() -> bool:
	return health < 0

func damage_unit(damage: int = 1) -> void:
	health -= damage
	# Signal that damage was applied for immediate visual update
	damage_applied.emit(self)

func heal_unit(healing: int = 1) -> void:
	health = min(1, health + healing)  # Cap at 1 (Bem)

func kill_unit() -> void:
	health = -1

# Fighter training methods
func make_fighter() -> void:
	is_fighter = true

func can_attack() -> bool:
	return is_fighter and can_move()  # Fighter can attack if has actions

# Healer training methods
func make_healer() -> void:
	is_healer = true

func can_heal() -> bool:
	return is_healer and can_move()  # Healer can heal if has actions

# Rider training methods
# Make unit a rider (2 actions per turn)
func make_rider() -> void:
	is_rider = true
	# Update max actions immediately
	max_actions = 2
	# If unit currently has actions, give it the extra action
	if actions_remaining > 0:
		actions_remaining = 2

# Make unit a climber
func make_climber():
	is_climber = true
	print("[UNIT] ", name, " is now a climber!")

# Make unit a shaman
func make_shaman():
	is_shaman = true
	print("[UNIT] ", name, " is now a shaman!")

# Convert unit to new owner (shaman ability)
func convert_to_owner(new_owner_id: int):
	if not is_converted:
		original_owner_id = owner_id  # Store original owner
	owner_id = new_owner_id
	is_converted = true
	print("[UNIT] ", name, " converted to player ", new_owner_id, " (original: ", original_owner_id, ")")
# String representation for debugging
func get_string() -> String:
	return "Unit[%d] '%s' (Player %d) at %s - Actions: %d" % [
		id, name, owner_id, position.hex_coord.get_string(), actions_remaining
	]