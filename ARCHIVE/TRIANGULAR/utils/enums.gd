# 📋 GAME ENUMERATIONS
# Duplicated from main_game.gd - DO NOT MODIFY ORIGINAL
class_name GameEnums
extends RefCounted

# Terrain/Edge Types (duplicated from main_game.gd EdgeType enum)
enum EdgeType {
	FIELD,          # Green: field (move + see) - 6/12
	FOREST,         # Grayish green: forest (move but don't see) - 2/12
	MOUNTAIN,       # Grayish yellow: mountain (don't move or see) - 2/12
	WATER           # Grayish cyan: water (see but don't move) - 2/12
}

# Player States
enum PlayerState {
	WAITING,
	ACTIVE,
	FINISHED
}

# Unit States
enum UnitState {
	IDLE,
	MOVING,
	REVEALED,
	HIDDEN
}

# Game States
enum GameState {
	INITIALIZING,
	PLAYING,
	PAUSED,
	FINISHED
}

# Input Types
enum InputType {
	MOUSE_CLICK,
	MOUSE_HOVER,
	KEYBOARD,
	SKIP_TURN
}

# Visibility Types
enum VisibilityType {
	VISIBLE,
	HIDDEN,
	FOG_OF_WAR,
	FORCE_REVEALED
}

# Movement Results
enum MovementResult {
	SUCCESS,
	BLOCKED,
	NO_ACTIONS,
	INVALID_TARGET,
	COLLISION
}