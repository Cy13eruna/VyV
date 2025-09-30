# 🎯 GAME CONSTANTS
# Purpose: Immutable game configuration values
# Layer: Core/ValueObjects
# Dependencies: None (pure constants)

extends RefCounted

# Grid Configuration
const HEX_SIZE: float = 40.0
const HEX_CENTER: Vector2 = Vector2(400, 300)
const GRID_RADIUS: int = 3  # 37 points total
const GRID_ROTATION: float = PI / 3.0  # 60 degrees

# Terrain Types
enum TerrainType {
	FIELD,    # 50% - Move + See
	FOREST,   # 16.7% - Move only
	MOUNTAIN, # 16.7% - Blocked
	WATER     # 16.7% - See only
}

# Terrain Distribution
const TERRAIN_DISTRIBUTION = {
	TerrainType.FIELD: 0.5,
	TerrainType.FOREST: 0.167,
	TerrainType.MOUNTAIN: 0.167,
	TerrainType.WATER: 0.167
}

# Unit Configuration
const INITIAL_ACTIONS: int = 1
const ACTIONS_PER_TURN: int = 1
const UNIT_EMOJI: String = "🚶🏻‍♀️"
const UNIT_FONT_SIZE: int = 24

# Domain Configuration
const INITIAL_DOMAIN_POWER: int = 1
const POWER_GENERATION_PER_TURN: int = 1
const POWER_COST_PER_ACTION: int = 1

# Visual Configuration
const POINT_RADIUS: float = 8.0
const EDGE_WIDTH: float = 8.0
const DOMAIN_OUTLINE_WIDTH: float = 4.0
const HIGHLIGHT_COLOR: Color = Color.MAGENTA
const BACKGROUND_COLOR: Color = Color.WHITE

# Player Configuration
const MAX_PLAYERS: int = 8  # Scalable design
const MIN_PLAYERS: int = 2

# Input Configuration
const FOG_TOGGLE_KEY: Key = KEY_SPACE

# Domain Names Pool
const DOMAIN_NAMES: Array[String] = [
	"Aldara", "Belthor", "Caldris", "Drakemoor", 
	"Eldoria", "Frostheim", "Galthara", "Helvorn"
]

# Unit Names by Domain Initial
const UNIT_NAMES: Dictionary = {
	"A": ["Aldric", "Alara", "Arden", "Astrid"],
	"B": ["Bjorn", "Brenna", "Baldur", "Bianca"],
	"C": ["Castor", "Celia", "Cyrus", "Clara"],
	"D": ["Darius", "Diana", "Drake", "Delara"],
	"E": ["Elias", "Elena", "Erik", "Evelyn"],
	"F": ["Felix", "Freya", "Finn", "Fiona"],
	"G": ["Gareth", "Gilda", "Gideon", "Grace"],
	"H": ["Hector", "Helena", "Hugo", "Hazel"]
}