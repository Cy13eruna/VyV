# 🔗 HEX EDGE  
# Purpose: Connection between two hex points (path)
# Layer: Core/Entities
# Dependencies: GameConstants

class_name HexEdge
extends RefCounted

var id: int
var point_a_id: int
var point_b_id: int
var terrain_type: GameConstants.TerrainType
var structures: Array[int] = []  # Structure IDs built on this edge

func _init(edge_id: int, point_a: int, point_b: int, terrain: GameConstants.TerrainType = GameConstants.TerrainType.FIELD):
	id = edge_id
	point_a_id = point_a
	point_b_id = point_b
	terrain_type = terrain

# Check if edge connects to specific point
func connects_to_point(point_id: int) -> bool:
	return point_id == point_a_id or point_id == point_b_id

# Get the other point connected by this edge
func get_other_point(point_id: int) -> int:
	if point_id == point_a_id:
		return point_b_id
	elif point_id == point_b_id:
		return point_a_id
	else:
		return -1  # Point not connected to this edge

# Check if movement is allowed through this terrain
func allows_movement() -> bool:
	return terrain_type in [GameConstants.TerrainType.FIELD, GameConstants.TerrainType.FOREST]

# Check if visibility is allowed through this terrain  
func allows_visibility() -> bool:
	return terrain_type in [GameConstants.TerrainType.FIELD, GameConstants.TerrainType.WATER]

# Get terrain color for rendering
func get_terrain_color() -> Color:
	match terrain_type:
		GameConstants.TerrainType.FIELD:
			return Color.GREEN
		GameConstants.TerrainType.FOREST:
			return Color(0.2, 0.7, 0.2)  # Dark green
		GameConstants.TerrainType.MOUNTAIN:
			return Color(0.7, 0.7, 0.2)  # Yellow-brown
		GameConstants.TerrainType.WATER:
			return Color(0.2, 0.7, 0.7)  # Cyan
		_:
			return Color.BLACK

# Add structure to this edge
func add_structure(structure_id: int) -> void:
	if structure_id not in structures:
		structures.append(structure_id)

# Remove structure from this edge
func remove_structure(structure_id: int) -> void:
	structures.erase(structure_id)

# Check if edge has structures
func has_structures() -> bool:
	return structures.size() > 0

# Check if mouse is near this edge (for hover detection)
func is_mouse_near(mouse_pos: Vector2, point_a_pos: Vector2, point_b_pos: Vector2, tolerance: float = 10.0) -> bool:
	return _point_near_line(mouse_pos, point_a_pos, point_b_pos, tolerance)

# Helper: Check if point is near line segment
func _point_near_line(point: Vector2, line_start: Vector2, line_end: Vector2, tolerance: float) -> bool:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	
	if line_len == 0:
		return point.distance_to(line_start) <= tolerance
	
	var t = point_vec.dot(line_vec) / (line_len * line_len)
	t = clamp(t, 0.0, 1.0)
	
	var closest_point = line_start + t * line_vec
	return point.distance_to(closest_point) <= tolerance

# String representation for debugging
func to_string() -> String:
	return "HexEdge[%d] (%d-%d) %s" % [id, point_a_id, point_b_id, GameConstants.TerrainType.keys()[terrain_type]]