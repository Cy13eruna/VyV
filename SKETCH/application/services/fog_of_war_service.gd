# 👁️ FOG OF WAR SERVICE (REFATORADO)
# Purpose: Coordenador principal para sistema de fog of war
# Layer: Application Services

extends RefCounted
class_name FogOfWarService

# Import modular components
const FogVisibilityCalculator = preload("res://application/services/fog_of_war/fog_visibility_calculator.gd")
const FogStateManager = preload("res://application/services/fog_of_war/fog_state_manager.gd")

# Execute fog of war toggle (delegated to state manager)
static func execute(game_state: Dictionary) -> Dictionary:
	return FogStateManager.execute_toggle(game_state)

# Enable fog of war (delegated to state manager)
static func enable_fog(game_state: Dictionary) -> Dictionary:
	return FogStateManager.enable_fog(game_state)

# Disable fog of war (delegated to state manager)
static func disable_fog(game_state: Dictionary) -> Dictionary:
	return FogStateManager.disable_fog(game_state)

# Get fog of war status (delegated to state manager)
static func get_fog_status(game_state: Dictionary) -> Dictionary:
	return FogStateManager.get_fog_status(game_state)

# Set fog of war to specific state (delegated to state manager)
static func set_fog_state(game_state: Dictionary, enabled: bool) -> Dictionary:
	return FogStateManager.set_fog_state(game_state, enabled)

# Get visibility settings for rendering (delegated to state manager)
static func get_visibility_settings(game_state: Dictionary, player_id: int) -> Dictionary:
	return FogStateManager.get_visibility_settings(game_state, player_id)

# Check if element should be visible to player (delegated to visibility calculator)
static func is_visible_to_player(element_type: String, element_data, player_id: int, game_state: Dictionary) -> bool:
	return FogVisibilityCalculator.is_visible_to_player(element_type, element_data, player_id, game_state)

# Check if position is visible to player (delegated to visibility calculator)
static func _is_position_visible_to_player(position, player_id: int, game_state: Dictionary) -> bool:
	return FogVisibilityCalculator.is_position_visible_to_player(position, player_id, game_state)

# Check if edge is visible to player (delegated to visibility calculator)
static func is_edge_visible_to_player(edge, player_id: int, game_state: Dictionary) -> bool:
	return FogVisibilityCalculator.is_edge_visible_to_player(edge, player_id, game_state)

# Check if edge is visible to player (alternative name for compatibility)
static func _is_edge_visible_to_player(edge, player_id: int, game_state: Dictionary) -> bool:
	return FogVisibilityCalculator.is_edge_visible_to_player(edge, player_id, game_state)

# Check if point/edge is remembered by player (delegated to state manager)
static func is_remembered_by_player(element_type: String, element_id: int, player_id: int, game_state: Dictionary) -> bool:
	return FogStateManager.is_remembered_by_player(element_type, element_id, player_id, game_state)

# Initialize fog system (delegated to state manager)
static func initialize_fog_system(game_state: Dictionary) -> void:
	FogStateManager.initialize_fog_system(game_state)

# Clear remembered terrain (delegated to state manager)
static func clear_all_remembered_terrain(game_state: Dictionary) -> void:
	FogStateManager.clear_all_remembered_terrain(game_state)

# Test domain visibility (delegated to visibility calculator)
static func test_domain_visibility(game_state: Dictionary, player_id: int) -> Dictionary:
	return FogVisibilityCalculator.test_domain_visibility(game_state, player_id)

# Debug position visibility (delegated to visibility calculator)
static func debug_position_visibility(game_state: Dictionary, player_id: int, test_position) -> Dictionary:
	return FogVisibilityCalculator.debug_position_visibility(game_state, player_id, test_position)

# Get fog statistics (delegated to state manager)
static func get_fog_statistics(game_state: Dictionary) -> Dictionary:
	return FogStateManager.get_fog_statistics(game_state)

# Export fog settings for rendering (delegated to state manager)
static func export_fog_settings_for_rendering(game_state: Dictionary, player_id: int) -> Dictionary:
	return FogStateManager.export_fog_settings_for_rendering(game_state, player_id)