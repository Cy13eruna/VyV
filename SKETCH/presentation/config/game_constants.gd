# 🎮 V&V GAME CONSTANTS
# Purpose: Centralized game constants and configuration
# Layer: Presentation Configuration

class_name GameConstants

# RESTORED GAMEPLAY CONSTANTS
const BOARD_ROTATION = 30.0
const PATH_THICKNESS = 13.3  # Reduced 3x from 40.0
const HEX_SIZE = 40.0  # From game constants
const DOMAIN_RADIUS = HEX_SIZE * 1.95  # Increased from 1.85 to 1.95

# Terrain colors
const TERRAIN_COLORS = {
	"FIELD": Color(0.0, 1.0, 0.0),      # 00FF00 - bright green
	"FOREST": Color(0.0, 0.4, 0.0),     # 006600 - dark green
	"MOUNTAIN": Color(0.4, 0.4, 0.4),   # 666666 - gray
	"WATER": Color(0.0, 1.0, 1.0)       # 00FFFF - cyan
}

# Remembered terrain colors (50% lighter than normal terrain)
const REMEMBERED_TERRAIN_COLORS = {
	"FIELD": Color(0.5, 1.0, 0.5),      # 50% lighter bright green
	"FOREST": Color(0.5, 0.7, 0.5),     # 50% lighter dark green
	"MOUNTAIN": Color(0.7, 0.7, 0.7),   # 50% lighter gray
	"WATER": Color(0.5, 1.0, 1.0)       # 50% lighter cyan
}

# Camera constants
const MIN_ZOOM = 0.3
const MAX_ZOOM = 3.0
const ZOOM_STEP = 0.1
const SCREEN_CENTER = Vector2(512, 384)

# UI constants
const SKIP_BUTTON_SIZE = Vector2(120, 40)
const SKIP_BUTTON_POS = Vector2(880, 20)
const NEW_GAME_BUTTON_SIZE = Vector2(120, 40)
const NEW_GAME_BUTTON_POS = Vector2(20, 20)
const TRANSITION_BUTTON_SIZE = Vector2(200, 60)
const TRANSITION_BUTTON_POS = Vector2(412, 354)

# Terrain texture paths
const TEXTURE_PATHS = {
	"FIELD": "res://textures/field/texture.png",
	"FOREST": "res://textures/forest/texture.png",
	"MOUNTAIN": "res://textures/mountain/texture.png",
	"WATER": "res://textures/water/texture.png"
}

const TEXTURE_PATHS_TRES = {
	"FIELD": "res://textures/field/texture.tres",
	"FOREST": "res://textures/forest/texture.tres",
	"MOUNTAIN": "res://textures/mountain/texture.tres",
	"WATER": "res://textures/water/texture.tres"
}

# Terrain emojis
const TERRAIN_EMOJIS = {
	0: "؛",    # FIELD - Semicolon invertido
	1: "🌳",   # FOREST - Árvore
	2: "⛰",   # MOUNTAIN - Montanha
	3: "〰"    # WATER - Onda
}

# Terrain emoji colors
const TERRAIN_EMOJI_COLORS = {
	0: Color(0.2, 0.4, 0.2),  # FIELD - Verde escuro para semicolons
	1: Color(0.1, 0.6, 0.1),  # FOREST - Verde brilhante para árvores
	2: Color(0.3, 0.3, 0.4),  # MOUNTAIN - Cinza escuro para montanhas
	3: Color(0.1, 0.3, 0.6)   # WATER - Azul escuro para ondas
}

# Menu options
const MENU_OPTIONS = [
	{"players": 2, "diameter": 9, "y": 300, "rect": Rect2(412, 285, 200, 40)},
	{"players": 3, "diameter": 11, "y": 360, "rect": Rect2(412, 345, 200, 40)},
	{"players": 4, "diameter": 13, "y": 420, "rect": Rect2(412, 405, 200, 40)},
	{"players": 6, "diameter": 15, "y": 480, "rect": Rect2(412, 465, 200, 40)}
]

# Optimal zoom levels by player count
const OPTIMAL_ZOOM_LEVELS = {
	2: 1.2,  # 2 players: diameter 9 - zoom maior para mapa menor
	3: 1.0,  # 3 players: diameter 11 - zoom médio-alto
	4: 0.8,  # 4 players: diameter 13 - zoom médio
	6: 0.6   # 6 players: diameter 15 - zoom menor para mapa maior
}

# Helper functions
static func get_terrain_color(terrain_type: int, is_remembered: bool = false) -> Color:
	var color_set = REMEMBERED_TERRAIN_COLORS if is_remembered else TERRAIN_COLORS
	match terrain_type:
		0:  # FIELD
			return color_set["FIELD"]
		1:  # FOREST
			return color_set["FOREST"]
		2:  # MOUNTAIN
			return color_set["MOUNTAIN"]
		3:  # WATER
			return color_set["WATER"]
		_:
			return Color.GRAY

static func get_terrain_emoji(terrain_type: int) -> String:
	return TERRAIN_EMOJIS.get(terrain_type, "")

static func get_terrain_emoji_color(terrain_type: int) -> Color:
	return TERRAIN_EMOJI_COLORS.get(terrain_type, Color.BLACK)

static func get_optimal_zoom(player_count: int) -> float:
	return OPTIMAL_ZOOM_LEVELS.get(player_count, 1.0)