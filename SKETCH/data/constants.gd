extends Node

# Terrain types (edges/paths)
enum EdgeType {
	FIELD,          # Green: field (move + see) - 6/12
	FOREST,         # Grayish green: forest (move but don't see) - 2/12
	MOUNTAIN,       # Grayish yellow: mountain (don't move or see) - 2/12
	WATER           # Grayish cyan: water (see but don't move) - 2/12
}

# Player identifiers
enum PlayerID {
	PLAYER_1 = 1,
	PLAYER_2 = 2
}

# Game configuration constants
const HEX_SIZE: float = 40.0
const HEX_CENTER: Vector2 = Vector2(400, 300)
const GRID_RADIUS: int = 3
const TOTAL_POINTS: int = 37

# UI constants
const POINT_RADIUS: float = 8.0
const PATH_WIDTH: float = 8.0
const DOMAIN_LINE_WIDTH: float = 4.0
const HOVER_TOLERANCE: float = 20.0
const PATH_HOVER_TOLERANCE: float = 10.0

# Color constants
const COLOR_UNIT1: Color = Color(1.0, 0.0, 0.0)      # Red
const COLOR_UNIT2: Color = Color(0.5, 0.0, 0.8)      # Violet
const COLOR_HOVER: Color = Color.MAGENTA
const COLOR_BACKGROUND: Color = Color.WHITE
const COLOR_POINT_DEFAULT: Color = Color.BLACK

# Terrain colors (more saturated)
const COLOR_FIELD: Color = Color.GREEN
const COLOR_FOREST: Color = Color(0.2, 0.7, 0.2)
const COLOR_MOUNTAIN: Color = Color(0.7, 0.7, 0.2)
const COLOR_WATER: Color = Color(0.2, 0.7, 0.7)

# Game mechanics constants
const INITIAL_ACTIONS: int = 1
const INITIAL_DOMAIN_POWER: int = 1
const POWER_COST_PER_ACTION: int = 1

# Terrain distribution (out of 12)
const TERRAIN_FIELD_COUNT: int = 6      # 50%
const TERRAIN_FOREST_COUNT: int = 2     # 16.7%
const TERRAIN_WATER_COUNT: int = 2      # 16.7%
const TERRAIN_MOUNTAIN_COUNT: int = 2   # 16.7%

# Font sizes
const FONT_SIZE_UNIT_EMOJI: int = 24
const FONT_SIZE_DOMAIN_NAME: int = 12
const FONT_SIZE_UNIT_NAME: int = 10
const FONT_SIZE_ACTION_LABEL: int = 14

# UI positions
const SKIP_BUTTON_POS: Vector2 = Vector2(680, 20)
const SKIP_BUTTON_SIZE: Vector2 = Vector2(100, 40)
const ACTION_LABEL_POS: Vector2 = Vector2(580, 70)

# Label offsets
const UNIT_EMOJI_OFFSET: Vector2 = Vector2(-12, -35)
const UNIT_NAME_OFFSET: Vector2 = Vector2(-15, 15)
const DOMAIN_NAME_OFFSET: Vector2 = Vector2(-30, 35)

# Background rect
const BACKGROUND_RECT: Rect2 = Rect2(-200, -200, 1200, 1000)