# 🧭 UNIT MOVEMENT TRACKER
# Purpose: Track unit movement directions for emoji flipping effects
# Layer: Core/Value Objects
# Dependencies: None

extends RefCounted

# Movement direction enumeration
enum MovementDirection {
	NONE,
	LEFT,      # Moving to left side (superior, inferior, central)
	RIGHT,     # Moving to right side (superior, inferior, central)
	NEUTRAL    # No clear left/right movement
}

# Static storage for unit movement directions
static var unit_directions = {}

# Board rotation constant (matches main game)
const BOARD_ROTATION = 30.0

# Apply 30-degree rotation to position (same as main game)
static func _apply_board_rotation(pos: Vector2) -> Vector2:
	var angle = deg_to_rad(BOARD_ROTATION)
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	
	var center = Vector2(512, 384)
	var relative_pos = pos - center
	var rotated = Vector2(
		relative_pos.x * cos_a - relative_pos.y * sin_a,
		relative_pos.x * sin_a + relative_pos.y * cos_a
	)
	return rotated + center

# Track unit movement and determine direction
static func track_unit_movement(unit_id: int, from_position, to_position) -> MovementDirection:
	if not from_position or not to_position:
		return MovementDirection.NONE
	
	# Get pixel positions for comparison
	var from_pixel: Vector2
	var to_pixel: Vector2
	
	# Extract pixel positions safely
	if from_position.has_method("pixel_pos"):
		from_pixel = from_position.pixel_pos
	elif "pixel_pos" in from_position:
		from_pixel = from_position.pixel_pos
	elif "x" in from_position and "y" in from_position:
		from_pixel = Vector2(from_position.x, from_position.y)
	else:
		print("[MOVEMENT_TRACKER] Warning: Cannot extract pixel position from from_position")
		return MovementDirection.NONE
	
	if to_position.has_method("pixel_pos"):
		to_pixel = to_position.pixel_pos
	elif "pixel_pos" in to_position:
		to_pixel = to_position.pixel_pos
	elif "x" in to_position and "y" in to_position:
		to_pixel = Vector2(to_position.x, to_position.y)
	else:
		print("[MOVEMENT_TRACKER] Warning: Cannot extract pixel position from to_position")
		return MovementDirection.NONE
	
	# Apply 30-degree rotation to coordinates before calculating direction
	var rotated_from = _apply_board_rotation(from_pixel)
	var rotated_to = _apply_board_rotation(to_pixel)
	
	# Calculate horizontal movement (with rotation applied)
	var delta_x = rotated_to.x - rotated_from.x
	
	# Determine direction based on horizontal movement (simple method)
	var direction: MovementDirection
	if abs(delta_x) < 1.0:  # Threshold reduzido para detectar movimentos menores
		direction = MovementDirection.NEUTRAL
	elif delta_x > 0:
		direction = MovementDirection.RIGHT
	else:
		direction = MovementDirection.LEFT
	
	# Store the direction for this unit
	unit_directions[unit_id] = direction
	
	# DEBUG: Log detalhado do movimento (com rotação aplicada)
	print("[MOVEMENT_TRACKER] Unit %d: from(%.1f,%.1f) to(%.1f,%.1f) rotated_delta_x=%.1f -> %s" % [unit_id, rotated_from.x, rotated_from.y, rotated_to.x, rotated_to.y, delta_x, _direction_to_string(direction)])
	
	return direction

# Get the current direction for a unit
static func get_unit_direction(unit_id: int) -> MovementDirection:
	return unit_directions.get(unit_id, MovementDirection.NONE)

# Check if unit should be flipped horizontally
static func should_flip_unit(unit_id: int) -> bool:
	var direction = get_unit_direction(unit_id)
	return direction == MovementDirection.LEFT

# Check if unit should have flipped emoji
static func should_flip_emoji(unit_id: int) -> bool:
	var direction = get_unit_direction(unit_id)
	return direction == MovementDirection.RIGHT

# Convert direction enum to string for debugging
static func _direction_to_string(direction: MovementDirection) -> String:
	match direction:
		MovementDirection.LEFT:
			return "LEFT"
		MovementDirection.RIGHT:
			return "RIGHT"
		MovementDirection.NEUTRAL:
			return "NEUTRAL"
		MovementDirection.NONE:
			return "NONE"
		_:
			return "UNKNOWN"

# Reset unit direction (useful when unit is created or reset)
static func reset_unit_direction(unit_id: int) -> void:
	unit_directions[unit_id] = MovementDirection.NONE

# Clear all unit directions (useful for game reset)
static func clear_all_directions() -> void:
	unit_directions.clear()

# Get direction as emoji for debugging
static func get_direction_emoji(unit_id: int) -> String:
	var direction = get_unit_direction(unit_id)
	match direction:
		MovementDirection.LEFT: return "⬅️"
		MovementDirection.RIGHT: return "➡️"
		MovementDirection.NEUTRAL: return "⏸️"
		_: return "❓"