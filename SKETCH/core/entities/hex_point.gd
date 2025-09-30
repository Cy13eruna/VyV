# 🔷 HEX POINT
# Purpose: Individual point in hexagonal grid
# Layer: Core/Entities
# Dependencies: Position, HexCoordinate

extends RefCounted

var id: int
var position
var connected_edges: Array[int] = []
var is_corner: bool = false

func _init(point_id: int, hex_coord):
	id = point_id
	var pos_script = load("res://core/value_objects/position.gd")
	position = pos_script.from_hex(hex_coord)

# Add connection to edge
func add_edge_connection(edge_id: int) -> void:
	if edge_id not in connected_edges:
		connected_edges.append(edge_id)

# Remove edge connection
func remove_edge_connection(edge_id: int) -> void:
	connected_edges.erase(edge_id)

# Get number of connections
func get_connection_count() -> int:
	return connected_edges.size()

# Check if this is a corner point (3 connections)
func update_corner_status() -> void:
	is_corner = (get_connection_count() == 3)

# Get neighbor points (requires grid context)
func get_neighbors() -> Array:
	var neighbors = []
	for direction in range(6):
		neighbors.append(position.hex_coord.get_neighbor(direction))
	return neighbors

# Check if point is adjacent to another
func is_adjacent_to(other) -> bool:
	return position.distance_to(other.position) == 1

# Check if mouse is hovering over this point
func is_mouse_over(mouse_pos: Vector2, radius: float = 8.0) -> bool:
	return position.pixel_pos.distance_to(mouse_pos) <= radius

# String representation for debugging
func get_string() -> String:
	return "HexPoint[%d] at %s (edges: %d)" % [id, position.hex_coord.get_string(), get_connection_count()]