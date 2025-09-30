# 🌍 GENERATE TERRAIN USE CASE
# Purpose: Orchestrate terrain generation for grid
# Layer: Application/UseCases
# Dependencies: Services only

class_name GenerateTerrainUseCase
extends RefCounted

static func execute(game_state: Dictionary) -> Dictionary:
	var result = {
		"success": false,
		"message": "",
		"terrain_generated": 0
	}
	
	# Validate grid exists
	if game_state.grid.edges.is_empty():
		result.message = "No grid to generate terrain for"
		return result
	
	# Generate terrain for all edges
	var terrain_count = 0
	for edge_id in game_state.grid.edges:
		var edge = game_state.grid.edges[edge_id]
		edge.terrain_type = _get_random_terrain_type()
		terrain_count += 1
	
	result.success = true
	result.terrain_generated = terrain_count
	result.message = "Generated terrain for %d edges" % terrain_count
	
	return result

static func _get_random_terrain_type() -> GameConstants.TerrainType:
	var rand_value = randf()
	var cumulative = 0.0
	
	for terrain_type in GameConstants.TERRAIN_DISTRIBUTION:
		cumulative += GameConstants.TERRAIN_DISTRIBUTION[terrain_type]
		if rand_value <= cumulative:
			return terrain_type
	
	return GameConstants.TerrainType.FIELD