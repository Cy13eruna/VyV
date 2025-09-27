extends Node

# Terrain generation and management system
# Handles random terrain generation and path coloring

signal terrain_generated()

# Generate random terrain with proportions for all paths
static func generate_random_terrain(paths: Array) -> void:
	print("🌍 Generating random terrain...")
	
	# Create pool of types based on proportions
	var terrain_pool = []
	
	# Field: 6/12 (50%)
	for i in range(GameConstants.TERRAIN_FIELD_COUNT):
		terrain_pool.append(GameConstants.EdgeType.FIELD)
	
	# Forest: 2/12 (16.7%)
	for i in range(GameConstants.TERRAIN_FOREST_COUNT):
		terrain_pool.append(GameConstants.EdgeType.FOREST)
	
	# Water: 2/12 (16.7%)
	for i in range(GameConstants.TERRAIN_WATER_COUNT):
		terrain_pool.append(GameConstants.EdgeType.WATER)
	
	# Mountain: 2/12 (16.7%)
	for i in range(GameConstants.TERRAIN_MOUNTAIN_COUNT):
		terrain_pool.append(GameConstants.EdgeType.MOUNTAIN)
	
	# Shuffle and apply to paths
	terrain_pool.shuffle()
	for i in range(paths.size()):
		var pool_index = i % terrain_pool.size()
		paths[i].type = terrain_pool[pool_index]
	
	print("✨ Random terrain generated! Field: 50%, Forest/Water/Mountain: 16.7% each")
	print("Press SPACE again to regenerate.")

# Get path color based on terrain type (more saturated colors)
static func get_path_color(path_type: GameConstants.EdgeType) -> Color:
	match path_type:
		GameConstants.EdgeType.FIELD:
			return GameConstants.COLOR_FIELD
		GameConstants.EdgeType.FOREST:
			return GameConstants.COLOR_FOREST
		GameConstants.EdgeType.MOUNTAIN:
			return GameConstants.COLOR_MOUNTAIN
		GameConstants.EdgeType.WATER:
			return GameConstants.COLOR_WATER
		_:
			return GameConstants.COLOR_POINT_DEFAULT

# Check if terrain type allows movement
static func allows_movement(terrain_type: GameConstants.EdgeType) -> bool:
	return terrain_type == GameConstants.EdgeType.FIELD or terrain_type == GameConstants.EdgeType.FOREST

# Check if terrain type allows visibility
static func allows_visibility(terrain_type: GameConstants.EdgeType) -> bool:
	return terrain_type == GameConstants.EdgeType.FIELD or terrain_type == GameConstants.EdgeType.WATER

# Get terrain type name for display
static func get_terrain_name(terrain_type: GameConstants.EdgeType) -> String:
	match terrain_type:
		GameConstants.EdgeType.FIELD:
			return "Field"
		GameConstants.EdgeType.FOREST:
			return "Forest"
		GameConstants.EdgeType.MOUNTAIN:
			return "Mountain"
		GameConstants.EdgeType.WATER:
			return "Water"
		_:
			return "Unknown"

# Get terrain description
static func get_terrain_description(terrain_type: GameConstants.EdgeType) -> String:
	match terrain_type:
		GameConstants.EdgeType.FIELD:
			return "Green: field (move + see)"
		GameConstants.EdgeType.FOREST:
			return "Grayish green: forest (move but don't see)"
		GameConstants.EdgeType.MOUNTAIN:
			return "Grayish yellow: mountain (don't move or see)"
		GameConstants.EdgeType.WATER:
			return "Grayish cyan: water (see but don't move)"
		_:
			return "Unknown terrain type"

# Get terrain distribution info
static func get_terrain_distribution() -> Dictionary:
	return {
		"field_percentage": 50.0,
		"forest_percentage": 16.7,
		"water_percentage": 16.7,
		"mountain_percentage": 16.7,
		"total_types": 4
	}