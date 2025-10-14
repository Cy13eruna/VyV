# 📐 HEX COORDINATE (CLEAN)
# Purpose: Immutable axial coordinate system for hexagonal grid
# Layer: Core/ValueObjects  
# Dependencies: None (pure math)

extends RefCounted

var q: int  # Column coordinate
var r: int  # Row coordinate

func _init(column: int, row: int):
	q = column
	r = row

# Convert to pixel position
func to_pixel(hex_size: float, center: Vector2, rotation: float = 0.0) -> Vector2:
	var x = hex_size * (3.0/2.0 * q)
	var y = hex_size * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	
	# Apply rotation if needed
	if rotation != 0.0:
		var cos_r = cos(rotation)
		var sin_r = sin(rotation)
		var rotated_x = x * cos_r - y * sin_r
		var rotated_y = x * sin_r + y * cos_r
		x = rotated_x
		y = rotated_y
	
	return center + Vector2(x, y)

# Calculate distance to another coordinate
func distance_to(other) -> int:
	return int((abs(q - other.q) + abs(q + r - other.q - other.r) + abs(r - other.r)) / 2)

# Add coordinates (for neighbor calculation)
func add(other):
	var script = load("res://core/value_objects/hex_coordinate_clean.gd")
	return script.new(q + other.q, r + other.r)

# Get neighbor in direction (0-5)
func get_neighbor(direction: int):
	var script = load("res://core/value_objects/hex_coordinate_clean.gd")
	var directions = [
		script.new(1, 0),   # East
		script.new(1, -1),  # Northeast  
		script.new(0, -1),  # Northwest
		script.new(-1, 0),  # West
		script.new(-1, 1),  # Southwest
		script.new(0, 1)    # Southeast
	]
	return add(directions[direction % 6])

# Check equality
func equals(other) -> bool:
	return q == other.q and r == other.r

# String representation for debugging
func get_string() -> String:
	return "(%d, %d)" % [q, r]

# Static helper: Create from pixel position (inverse conversion)
static func from_pixel(pixel: Vector2, hex_size: float, center: Vector2, rotation: float = 0.0):
	var local_pos = pixel - center
	
	# Reverse rotation if applied
	if rotation != 0.0:
		var cos_r = cos(-rotation)
		var sin_r = sin(-rotation)
		var unrotated_x = local_pos.x * cos_r - local_pos.y * sin_r
		var unrotated_y = local_pos.x * sin_r + local_pos.y * cos_r
		local_pos = Vector2(unrotated_x, unrotated_y)
	
	# Convert pixel to axial coordinates
	var q_float = (2.0/3.0 * local_pos.x) / hex_size
	var r_float = (-1.0/3.0 * local_pos.x + sqrt(3.0)/3.0 * local_pos.y) / hex_size
	
	# Round to nearest integer coordinates
	var script = load("res://core/value_objects/hex_coordinate_clean.gd")
	return script.new(int(round(q_float)), int(round(r_float)))