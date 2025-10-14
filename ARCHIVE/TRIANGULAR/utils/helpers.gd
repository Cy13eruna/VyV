# 🛠️ HELPER FUNCTIONS
# Utility functions for common operations
class_name GameHelpers
extends RefCounted

# Math Helpers
static func distance_between_points(point1: Vector2, point2: Vector2) -> float:
	return point1.distance_to(point2)

static func clamp_to_bounds(value: float, min_val: float, max_val: float) -> float:
	return clamp(value, min_val, max_val)

# Array Helpers
static func is_valid_index(array: Array, index: int) -> bool:
	return index >= 0 and index < array.size()

static func safe_get_array_element(array: Array, index: int, default_value = null):
	if is_valid_index(array, index):
		return array[index]
	return default_value

# Color Helpers
static func get_edge_type_color(edge_type: GameEnums.EdgeType) -> Color:
	match edge_type:
		GameEnums.EdgeType.FIELD:
			return Color.GREEN
		GameEnums.EdgeType.FOREST:
			return Color(0.4, 0.6, 0.4)  # Grayish green
		GameEnums.EdgeType.MOUNTAIN:
			return Color(0.6, 0.6, 0.4)  # Grayish yellow
		GameEnums.EdgeType.WATER:
			return Color(0.4, 0.6, 0.6)  # Grayish cyan
		_:
			return Color.WHITE

# Player Helpers
static func get_other_player(current_player: int) -> int:
	return GameConstants.PLAYER_2 if current_player == GameConstants.PLAYER_1 else GameConstants.PLAYER_1

static func is_valid_player(player: int) -> bool:
	return player == GameConstants.PLAYER_1 or player == GameConstants.PLAYER_2

# Unit Helpers
static func get_unit_color(player: int) -> Color:
	match player:
		GameConstants.PLAYER_1:
			return Color(1.0, 0.0, 0.0)  # Red
		GameConstants.PLAYER_2:
			return Color(0.5, 0.0, 0.8)  # Violet
		_:
			return Color.WHITE

# Validation Helpers
static func is_point_near_line(point: Vector2, line_start: Vector2, line_end: Vector2, threshold: float = 5.0) -> bool:
	var line_length = line_start.distance_to(line_end)
	if line_length == 0:
		return point.distance_to(line_start) <= threshold
	
	var t = ((point - line_start).dot(line_end - line_start)) / (line_length * line_length)
	t = clamp(t, 0.0, 1.0)
	var projection = line_start + t * (line_end - line_start)
	return point.distance_to(projection) <= threshold