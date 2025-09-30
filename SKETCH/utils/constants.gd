# 🔧 GAME CONSTANTS
# Duplicated from main_game.gd - DO NOT MODIFY ORIGINAL
class_name GameConstants
extends RefCounted

# Grid Configuration
const HEX_SIZE: float = 40.0
const HEX_CENTER: Vector2 = Vector2(400, 300)
const GRID_RADIUS: int = 3  # Expanded hexagonal grid (37 points)

# Unit Configuration
const INITIAL_ACTIONS: int = 1
const INITIAL_POWER: int = 1

# Player Configuration
const PLAYER_1: int = 1
const PLAYER_2: int = 2

# Hover States
const NO_HOVER: int = -1

# UI Configuration
const SKIP_TURN_BUTTON_TEXT: String = "Skip Turn"

# Visual Configuration
const POINT_RADIUS: float = 15.0
const EDGE_WIDTH: float = 8.0
const HIGHLIGHT_DURATION: float = 0.5

# Color Configuration
const WHITE_BACKGROUND: Color = Color.WHITE
const BLACK_POINTS_EDGES: Color = Color.BLACK
const MAGENTA_HIGHLIGHT: Color = Color.MAGENTA

# Domain Configuration
const DOMAIN_OUTLINE_WIDTH: float = 4.0

# Fog of War
const FOG_OF_WAR_DEFAULT: bool = true

# Unit Emojis
const UNIT_EMOJI: String = "🚶🏻‍♀️"
const UNIT_FONT_SIZE: int = 24

# Power System
const POWER_GENERATION_PER_ROUND: int = 1
const POWER_COST_PER_ACTION: int = 1