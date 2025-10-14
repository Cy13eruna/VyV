# 🎨 RENDERING MANAGER (REFATORADO)
# Purpose: Coordenador principal para renderização visual do jogo
# Layer: Presentation Manager
#
# UNIVERSAL EMOJI RULE:
# All unit emojis (fighter 🗡, healer ♥, etc.) are ALWAYS visible to all players
# regardless of unit visibility rules. This provides strategic information
# while respecting the game's visibility boundaries.

extends Node
class_name RenderingManager

# Import modular components
const UnitIndicatorRenderer = preload("res://presentation/managers/rendering/unit_indicator_renderer.gd")
const DomainRenderer = preload("res://presentation/managers/rendering/domain_renderer.gd")
const GridOverlayRenderer = preload("res://presentation/managers/rendering/grid_overlay_renderer.gd")

# Import constants and dependencies
const GameConstants = preload("res://presentation/config/game_constants.gd")
const CameraManager = preload("res://presentation/managers/camera_manager.gd")

# References
var main_node: Node2D
var camera_manager: CameraManager
var unit_manager  # Reference to unit manager for indicators

# Modular components
var unit_indicator_renderer: UnitIndicatorRenderer
var domain_renderer: DomainRenderer
var grid_overlay_renderer: GridOverlayRenderer

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref: CameraManager, unit_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	unit_manager = unit_manager_ref
	
	print("[RENDERING_MANAGER] Initializing modular components...")
	
	# Initialize modular components with error checking
	unit_indicator_renderer = UnitIndicatorRenderer.new()
	if unit_indicator_renderer:
		unit_indicator_renderer.initialize(main_node, camera_manager, unit_manager)
		print("[RENDERING_MANAGER] UnitIndicatorRenderer initialized")
	else:
		print("[RENDERING_MANAGER] ERROR: Failed to create UnitIndicatorRenderer")
	
	domain_renderer = DomainRenderer.new()
	if domain_renderer:
		domain_renderer.initialize(main_node, camera_manager)
		print("[RENDERING_MANAGER] DomainRenderer initialized")
	else:
		print("[RENDERING_MANAGER] ERROR: Failed to create DomainRenderer")
	
	grid_overlay_renderer = GridOverlayRenderer.new()
	if grid_overlay_renderer:
		grid_overlay_renderer.initialize(main_node, camera_manager, domain_renderer)
		print("[RENDERING_MANAGER] GridOverlayRenderer initialized")
	else:
		print("[RENDERING_MANAGER] ERROR: Failed to create GridOverlayRenderer")
	
	print("[RENDERING_MANAGER] All components initialized successfully")

# Universal emoji visibility rule (delegated to unit indicator renderer)
func _should_show_emoji(unit, current_player_id: int, game_state: Dictionary) -> bool:
	if unit_indicator_renderer:
		return unit_indicator_renderer.should_show_emoji(unit, current_player_id, game_state)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _should_show_emoji")
		return false

# Load terrain textures
func load_terrain_textures():
	if grid_overlay_renderer:
		grid_overlay_renderer.load_terrain_textures()
	else:
		print("[RENDERING_MANAGER] ERROR: grid_overlay_renderer is null in load_terrain_textures")

# Render grid edges with terrain
func render_grid_edges(game_state: Dictionary, hover_state: Dictionary):
	if grid_overlay_renderer:
		grid_overlay_renderer.render_grid_edges(game_state, hover_state)
	else:
		print("[RENDERING_MANAGER] ERROR: grid_overlay_renderer is null in render_grid_edges")

# Render grid points (stars)
func render_grid_points(game_state: Dictionary, hover_state: Dictionary, fog_settings: Dictionary = {}):
	if grid_overlay_renderer:
		grid_overlay_renderer.render_grid_points(game_state, hover_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: grid_overlay_renderer is null in render_grid_points")

# Render domain shapes (hexagons) - LAYER 1
func render_domain_shapes(game_state: Dictionary, fog_settings: Dictionary):
	if domain_renderer:
		domain_renderer.render_domain_shapes(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: domain_renderer is null in render_domain_shapes")

# Render domain labels (titles) - LAYER 2
func render_domain_labels(game_state: Dictionary, fog_settings: Dictionary):
	if domain_renderer:
		domain_renderer.render_domain_labels(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: domain_renderer is null in render_domain_labels")

# Render market indicators (🤝🏻 for domains with market upgrade)
func render_market_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if domain_renderer:
		domain_renderer.render_market_indicators(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: domain_renderer is null in render_market_indicators")

# Legacy function for compatibility - calls both domain layers
func render_domains(game_state: Dictionary, fog_settings: Dictionary):
	if domain_renderer:
		domain_renderer.render_domains(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: domain_renderer is null in render_domains")

# Render harvest structures on top of everything
func render_harvest_structures(game_state: Dictionary, fog_settings: Dictionary):
	if grid_overlay_renderer:
		grid_overlay_renderer.render_harvest_structures(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: grid_overlay_renderer is null in render_harvest_structures")

# Render health indicators (🩹 for injured units)
func _render_health_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_health_indicators(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _render_health_indicators")

# Render fighter indicators (🗡 for fighter units)
func _render_fighter_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_fighter_indicators(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _render_fighter_indicators")

# Render healer indicators (♥ for healer units)
func _render_healer_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_healer_indicators(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _render_healer_indicators")

# Render rider indicators (delegated to unit indicator renderer)
func _render_rider_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_rider_indicators(game_state, fog_settings)

# Render climber indicators (delegated to unit indicator renderer)
func _render_climber_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_climber_indicators(game_state, fog_settings)

# Render attack targets (team color circles for valid attack positions)
func _render_attack_targets(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_attack_targets(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _render_attack_targets")

# Render heal targets (team color circles for valid heal positions)
func _render_heal_targets(game_state: Dictionary, fog_settings: Dictionary):
	if unit_indicator_renderer:
		unit_indicator_renderer.render_heal_targets(game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: unit_indicator_renderer is null in _render_heal_targets")

# Render train indicator (legacy - now removed)
func _render_train_indicator(game_state: Dictionary, fog_settings: Dictionary):
	# Note: Train indicator functionality removed with double-click removal
	return

# Check if position is a domain center with power >= level (nuclear star)
func _get_domain_nuclear_star_color(position, game_state: Dictionary, fog_settings: Dictionary) -> Color:
	if domain_renderer:
		return domain_renderer.get_domain_nuclear_star_color(position, game_state, fog_settings)
	else:
		print("[RENDERING_MANAGER] ERROR: domain_renderer is null in _get_domain_nuclear_star_color")
		return Color.TRANSPARENT

# Cleanup method to prevent memory leaks
func cleanup():
	# Cleanup all modules
	if unit_indicator_renderer:
		unit_indicator_renderer.cleanup()
		unit_indicator_renderer = null
	
	if domain_renderer:
		domain_renderer.cleanup()
		domain_renderer = null
	
	if grid_overlay_renderer:
		grid_overlay_renderer.cleanup()
		grid_overlay_renderer = null
	
	# Clear all references
	main_node = null
	camera_manager = null
	unit_manager = null