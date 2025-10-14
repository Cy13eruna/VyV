# 🎮 V&V UNIT RENDERER (REFATORADO)
# Purpose: Coordenador principal para renderização de unidades
# Layer: Presentation Manager

extends Node
class_name UnitRenderer

# Import modular components (loaded dynamically to avoid parse errors)
var UnitVisualEffects: GDScript
var UnitBasicRenderer: GDScript

# Modular components
var visual_effects
var basic_renderer

# References
var main_node: Node2D
var camera_manager

func _ready():
	call_deferred("setup_components")

# Setup modular components
func setup_components():
	# Load classes dynamically
	UnitVisualEffects = load("res://presentation/rendering/unit/unit_visual_effects.gd")
	UnitBasicRenderer = load("res://presentation/rendering/unit/unit_basic_renderer.gd")
	
	# Create components
	visual_effects = UnitVisualEffects.new()
	basic_renderer = UnitBasicRenderer.new()
	
	# Initialize components if main_node and camera_manager are available
	if main_node and camera_manager:
		initialize_components()

# Initialize components with references
func initialize_components():
	if visual_effects and visual_effects.has_method("initialize"):
		visual_effects.initialize(main_node, camera_manager)
	
	if basic_renderer and basic_renderer.has_method("initialize"):
		basic_renderer.initialize(main_node, camera_manager, visual_effects)

# Set main node reference
func set_main_node(node: Node2D):
	main_node = node
	if visual_effects and basic_renderer:
		initialize_components()

# Set camera manager reference
func set_camera_manager(manager):
	camera_manager = manager
	if visual_effects and basic_renderer:
		initialize_components()

# Render units with fog of war (delegated to basic renderer)
func render_units_with_fog(game_state: Dictionary, fog_settings: Dictionary, hover_state: Dictionary, selected_unit_id: int, font: Font, technology_manager = null):
	if basic_renderer and basic_renderer.has_method("render_units_with_fog"):
		basic_renderer.render_units_with_fog(game_state, fog_settings, hover_state, selected_unit_id, font, technology_manager)

# Render movement targets with terrain (delegated to basic renderer)
func render_movement_targets_with_terrain(game_state: Dictionary, selected_unit_id: int, valid_movement_targets: Array, font: Font):
	if basic_renderer and basic_renderer.has_method("render_movement_targets_with_terrain"):
		basic_renderer.render_movement_targets_with_terrain(game_state, selected_unit_id, valid_movement_targets, font)

# Helper functions (delegated to visual effects)
func should_flip_unit_emoji(unit_id: int) -> bool:
	if visual_effects and visual_effects.has_method("should_flip_unit_emoji"):
		return visual_effects.should_flip_unit_emoji(unit_id)
	return false

func get_enhanced_team_color(team_color: Color, has_actions: bool) -> Color:
	if visual_effects and visual_effects.has_method("get_enhanced_team_color"):
		return visual_effects.get_enhanced_team_color(team_color, has_actions)
	return team_color

func draw_flipped_emoji(font: Font, position: Vector2, emoji: String, size: int, color: Color) -> void:
	if visual_effects and visual_effects.has_method("draw_flipped_emoji"):
		visual_effects.draw_flipped_emoji(font, position, emoji, size, color)

func draw_bold_italic_text(font: Font, position: Vector2, text: String, size: int, color: Color) -> void:
	if visual_effects and visual_effects.has_method("draw_bold_italic_text"):
		visual_effects.draw_bold_italic_text(font, position, text, size, color)

func draw_team_color_glow_around_star(position: Vector2, terrain_cost: int, team_color: Color) -> void:
	if visual_effects and visual_effects.has_method("draw_team_color_glow_around_star"):
		visual_effects.draw_team_color_glow_around_star(position, terrain_cost, team_color)

# Settler technology functions (delegated to basic renderer)
func _can_unit_use_settler(unit, game_state: Dictionary, technology_manager) -> bool:
	if basic_renderer and basic_renderer.has_method("can_unit_use_settler"):
		return basic_renderer.can_unit_use_settler(unit, game_state, technology_manager)
	return false

func _is_unit_far_from_domains(unit, game_state: Dictionary) -> bool:
	if basic_renderer and basic_renderer.has_method("is_unit_far_from_domains"):
		return basic_renderer.is_unit_far_from_domains(unit, game_state)
	return false

func _is_unit_away_from_border(unit, game_state: Dictionary) -> bool:
	if basic_renderer and basic_renderer.has_method("is_unit_away_from_border"):
		return basic_renderer.is_unit_away_from_border(unit, game_state)
	return false

func _calculate_hex_distance(pos1, pos2) -> int:
	if basic_renderer and basic_renderer.has_method("calculate_hex_distance"):
		return basic_renderer.calculate_hex_distance(pos1, pos2)
	return 0

func _get_unit_natal_power(unit, game_state: Dictionary) -> int:
	if basic_renderer and basic_renderer.has_method("get_unit_natal_power"):
		return basic_renderer.get_unit_natal_power(unit, game_state)
	return 0

func _find_natal_domain(unit, game_state: Dictionary):
	if basic_renderer and basic_renderer.has_method("find_natal_domain"):
		return basic_renderer.find_natal_domain(unit, game_state)
	return null

func _can_domain_be_placed_without_sharing_paths(unit, game_state: Dictionary) -> bool:
	if basic_renderer and basic_renderer.has_method("can_domain_be_placed_without_sharing_paths"):
		return basic_renderer.can_domain_be_placed_without_sharing_paths(unit, game_state)
	return false

func _get_point_neighbors(point, game_state: Dictionary) -> Array:
	if basic_renderer and basic_renderer.has_method("get_point_neighbors"):
		return basic_renderer.get_point_neighbors(point, game_state)
	return []

func _draw_settler_flag(unit_pos: Vector2):
	if visual_effects and visual_effects.has_method("draw_settler_flag"):
		visual_effects.draw_settler_flag(unit_pos)

func _draw_settler_ready_glow(unit_pos: Vector2, team_color: Color):
	if visual_effects and visual_effects.has_method("draw_settler_ready_glow"):
		visual_effects.draw_settler_ready_glow(unit_pos, team_color)

# Cleanup method
func _exit_tree():
	if visual_effects and visual_effects.has_method("cleanup"):
		visual_effects.cleanup()
	if basic_renderer and basic_renderer.has_method("cleanup"):
		basic_renderer.cleanup()
	
	visual_effects = null
	basic_renderer = null
	main_node = null
	camera_manager = null