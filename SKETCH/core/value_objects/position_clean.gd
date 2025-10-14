# 📍 POSITION (CLEAN)
# Purpose: Immutable position value object
# Layer: Core/ValueObjects
# Dependencies: HexCoordinate only

extends RefCounted

var hex_coord
var pixel_pos: Vector2

func _init(coordinate, pixel_position: Vector2):
	hex_coord = coordinate
	pixel_pos = pixel_position

# Create position from hex coordinate
static func from_hex(coord, hex_size: float = 40.0, 
					 center: Vector2 = Vector2(400, 300), 
					 rotation: float = 0.0):
	var pixel = coord.to_pixel(hex_size, center, rotation)
	var script = load("res://core/value_objects/position_clean.gd")
	return script.new(coord, pixel)

# Create position from pixel
static func from_pixel(pixel: Vector2, hex_size: float = 40.0,
					   center: Vector2 = Vector2(400, 300),
					   rotation: float = 0.0):
	var hex_script = load("res://core/value_objects/hex_coordinate_clean.gd")
	var coord = hex_script.from_pixel(pixel, hex_size, center, rotation)
	var script = load("res://core/value_objects/position_clean.gd")
	return script.new(coord, pixel)

# Distance to another position
func distance_to(other) -> int:
	return hex_coord.distance_to(other.hex_coord)

# Check if position is within distance
func is_within_distance(other, max_distance: int) -> bool:
	return distance_to(other) <= max_distance

# Check equality
func equals(other) -> bool:
	return hex_coord.equals(other.hex_coord)

# String representation
func get_string() -> String:
	return "Position%s at %s" % [hex_coord.get_string(), pixel_pos]