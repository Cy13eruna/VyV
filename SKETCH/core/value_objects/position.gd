# 📍 POSITION
# Purpose: Immutable position value object
# Layer: Core/ValueObjects
# Dependencies: HexCoordinate

class_name Position
extends RefCounted

var hex_coord: HexCoordinate
var pixel_pos: Vector2

func _init(coordinate: HexCoordinate, pixel_position: Vector2):
	hex_coord = coordinate
	pixel_pos = pixel_position

# Create position from hex coordinate
static func from_hex(coord: HexCoordinate, hex_size: float = GameConstants.HEX_SIZE, 
					 center: Vector2 = GameConstants.HEX_CENTER, 
					 rotation: float = GameConstants.GRID_ROTATION) -> Position:
	var pixel = coord.to_pixel(hex_size, center, rotation)
	return Position.new(coord, pixel)

# Create position from pixel
static func from_pixel(pixel: Vector2, hex_size: float = GameConstants.HEX_SIZE,
					   center: Vector2 = GameConstants.HEX_CENTER,
					   rotation: float = GameConstants.GRID_ROTATION) -> Position:
	var coord = HexCoordinate.from_pixel(pixel, hex_size, center, rotation)
	return Position.new(coord, pixel)

# Distance to another position
func distance_to(other: Position) -> int:
	return hex_coord.distance_to(other.hex_coord)

# Check if position is within distance
func is_within_distance(other: Position, max_distance: int) -> bool:
	return distance_to(other) <= max_distance

# Check equality
func equals(other: Position) -> bool:
	return hex_coord.equals(other.hex_coord)

# String representation
func to_string() -> String:
	return "Position%s at %s" % [hex_coord.to_string(), pixel_pos]