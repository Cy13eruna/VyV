# 🎮 GAME CONSTANTS
# Purpose: Central game configuration and constants
# Layer: Core/Constants
# Dependencies: None

extends RefCounted

# Domain constants
const INITIAL_DOMAIN_POWER = 1
const POWER_GENERATION_PER_TURN = 1
const POWER_COST_PER_ACTION = 1

# Unit constants
const INITIAL_UNIT_ACTIONS = 1
const MAX_UNIT_ACTIONS = 2

# Grid constants
const DEFAULT_GRID_RADIUS = 3
const HEX_SIZE = 40.0

# Movement constants
const MOVEMENT_COST_FIELD = 1
const MOVEMENT_COST_FOREST = 2
const MOVEMENT_COST_MOUNTAIN = 2
const MOVEMENT_COST_WATER = 999  # Impassable

# Unit names by initial letter
const UNIT_NAMES = {
	"A": ["Adrian", "Alexander", "Arthur", "Albert", "Antonio"],
	"B": ["Baldwin", "Bernard", "Boris", "Bruno", "Bartholomew"],
	"C": ["Constantine", "Charles", "Christopher", "Casimir", "Cyrus"],
	"D": ["Dimitri", "David", "Daniel", "Diego", "Dominic"],
	"E": ["Edmund", "Edward", "Eugene", "Emilio", "Erasmus"],
	"F": ["Frederick", "Ferdinand", "Francis", "Felix", "Fabio"],
	"G": ["Gregory", "Gabriel", "George", "Gustavo", "Godfrey"],
	"H": ["Henry", "Harold", "Hugo", "Hector", "Humphrey"]
}

# Player colors
const PLAYER_COLORS = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.MAGENTA,
	Color.CYAN,
	Color.ORANGE,
	Color.PURPLE
]

# Game limits
const MIN_PLAYERS = 2
const MAX_PLAYERS = 8
const MAX_TURNS = 100

# Structure constants (for future use)
const STRUCTURE_COST_FARM = 2
const STRUCTURE_COST_VILLAGE = 4
const STRUCTURE_COST_FORTRESS = 6
const STRUCTURE_COST_MARKET = 3
const STRUCTURE_COST_TEMPLE = 5