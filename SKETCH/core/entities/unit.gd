# 🚶 UNIT
# Purpose: Game unit entity (replicable for N units per player)
# Layer: Core/Entities
# Dependencies: Position, GameConstants

class_name Unit
extends RefCounted

var id: int
var owner_id: int
var name: String
var position: Position
var actions_remaining: int
var is_revealed: bool = false
var force_revealed: bool = false

func _init(unit_id: int, player_id: int, unit_name: String, start_position: Position):
	id = unit_id
	owner_id = player_id
	name = unit_name
	position = start_position
	actions_remaining = GameConstants.INITIAL_ACTIONS

# Move unit to new position
func move_to(new_position: Position) -> bool:
	if can_move():
		position = new_position
		consume_action()
		return true
	return false

# Check if unit can move (has actions)
func can_move() -> bool:
	return actions_remaining > 0

# Consume one action
func consume_action() -> void:
	actions_remaining = max(0, actions_remaining - 1)

# Restore actions at start of turn
func restore_actions() -> void:
	actions_remaining = GameConstants.ACTIONS_PER_TURN

# Check if unit is at specific position
func is_at_position(check_position: Position) -> bool:
	return position.equals(check_position)

# Check if unit is adjacent to position
func is_adjacent_to(check_position: Position) -> bool:
	return position.distance_to(check_position) == 1

# Check if unit is within range of position
func is_within_range(check_position: Position, range: int) -> bool:
	return position.distance_to(check_position) <= range

# Reveal unit (make visible to enemies)
func reveal() -> void:
	is_revealed = true

# Hide unit (fog of war)
func hide() -> void:
	is_revealed = false

# Force reveal unit (forest mechanics)
func force_reveal() -> void:
	force_revealed = true
	is_revealed = true

# Reset forced revelation
func reset_force_reveal() -> void:
	force_revealed = false

# Check if unit should be visible to specific player
func is_visible_to_player(player_id: int, fog_of_war: bool = true) -> bool:
	# Always visible to owner
	if player_id == owner_id:
		return true
	
	# If no fog of war, always visible
	if not fog_of_war:
		return true
	
	# Visible if revealed or force revealed
	return is_revealed or force_revealed

# Check if mouse is hovering over unit
func is_mouse_over(mouse_pos: Vector2, radius: float = GameConstants.POINT_RADIUS) -> bool:
	return position.pixel_pos.distance_to(mouse_pos) <= radius

# Get unit color based on owner
func get_color() -> Color:
	return Player.get_default_color(owner_id)

# Get unit display emoji
func get_emoji() -> String:
	return GameConstants.UNIT_EMOJI

# String representation for debugging
func to_string() -> String:
	return "Unit[%d] '%s' (Player %d) at %s - Actions: %d" % [
		id, name, owner_id, position.hex_coord.to_string(), actions_remaining
	]