# ✨ UNIT VISUAL EFFECTS
# Purpose: Handle visual effects, animations and special rendering for units
# Layer: Presentation - Unit Rendering

extends RefCounted
class_name UnitVisualEffects

# References
var main_node: Node2D
var camera_manager

# No longer needed - using direct emoji rendering with color masks

# Initialize with references
func initialize(main_node_ref: Node2D, camera_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref

# Removed - no longer needed with direct emoji color masking approach

# Draw emoji normally without tinting
func draw_tinted_emoji(font: Font, position: Vector2, emoji: String, size: int, color: Color) -> void:
	# Just draw the emoji normally - no tinting
	main_node.draw_string(font, position, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Draw flipped emoji normally without tinting
func draw_flipped_tinted_emoji(font: Font, position: Vector2, emoji: String, size: int, color: Color) -> void:
	# Set up flip transformation
	var text_size = font.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	main_node.draw_set_transform(position, 0, Vector2(-1, 1))
	var adjusted_pos = Vector2(-text_size.x, 0)
	
	# Just draw the emoji flipped normally - no tinting
	main_node.draw_string(font, adjusted_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)
	
	# Reset transformation
	main_node.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# Draw flipped emoji for units moving in different directions
func draw_flipped_emoji(font: Font, position: Vector2, emoji: String, size: int, color: Color) -> void:
	var text_size = font.get_string_size(emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	main_node.draw_set_transform(position, 0, Vector2(-1, 1))
	var adjusted_pos = Vector2(-text_size.x, 0)
	main_node.draw_string(font, adjusted_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)
	main_node.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# Draw bold italic text with multiple layers for enhanced visibility
func draw_bold_italic_text(font: Font, position: Vector2, text: String, size: int, color: Color) -> void:
	var zoomed_size = int(size * camera_manager.zoom_level)
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, zoomed_size)
	var centered_pos = position - Vector2(text_size.x / 2, 0)
	
	var italic_offsets = [
		Vector2(0, 0),
		Vector2(1, -2) * camera_manager.zoom_level,
		Vector2(2, -4) * camera_manager.zoom_level,
		Vector2(-1, 2) * camera_manager.zoom_level,
		Vector2(-2, 4) * camera_manager.zoom_level
	]
	
	var bold_offsets = [
		Vector2(-1, -1) * camera_manager.zoom_level, Vector2(0, -1) * camera_manager.zoom_level, Vector2(1, -1) * camera_manager.zoom_level,
		Vector2(-1, 0) * camera_manager.zoom_level,                                Vector2(1, 0) * camera_manager.zoom_level,
		Vector2(-1, 1) * camera_manager.zoom_level,  Vector2(0, 1) * camera_manager.zoom_level,  Vector2(1, 1) * camera_manager.zoom_level
	]
	
	for italic_offset in italic_offsets:
		for bold_offset in bold_offsets:
			main_node.draw_string(font, centered_pos + italic_offset + bold_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, zoomed_size, Color.BLACK)
	
	main_node.draw_string(font, centered_pos + Vector2(1, -1) * camera_manager.zoom_level, text, HORIZONTAL_ALIGNMENT_LEFT, -1, zoomed_size, color)

# Draw team color glow around movement targets
func draw_team_color_glow_around_star(position: Vector2, terrain_cost: int, team_color: Color) -> void:
	var glow_layers = [
		{"radius": 20.0 * camera_manager.zoom_level, "alpha": 0.15},
		{"radius": 16.0 * camera_manager.zoom_level, "alpha": 0.25},
		{"radius": 12.0 * camera_manager.zoom_level, "alpha": 0.35},
		{"radius": 8.0 * camera_manager.zoom_level, "alpha": 0.45}
	]
	
	var glow_color: Color
	match terrain_cost:
		1:
			glow_color = team_color
		2:
			glow_color = team_color.lerp(Color.ORANGE, 0.3)
		999:
			glow_color = Color.RED
		_:
			glow_color = team_color
	
	for layer in glow_layers:
		var layer_color = Color(glow_color.r, glow_color.g, glow_color.b, layer.alpha)
		main_node.draw_circle(position, layer.radius, layer_color)

# Draw settler flag indicator
func draw_settler_flag(unit_pos: Vector2):
	var flag_emoji = "🚩"
	var flag_size = int(16 * camera_manager.zoom_level)
	var flag_offset = Vector2(20, -10) * camera_manager.zoom_level  # Right side of unit
	
	# Draw flag with slight glow
	var flag_color = Color.WHITE
	var ThemeDB = Engine.get_singleton("ThemeDB")
	var font = ThemeDB.fallback_font if ThemeDB else null
	
	if font:
		# Draw glow effect
		for i in range(3):
			var glow_offset = Vector2(i-1, i-1) * camera_manager.zoom_level
			main_node.draw_string(font, unit_pos + flag_offset + glow_offset, flag_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, flag_size, Color.BLACK)
		
		# Draw main flag
		main_node.draw_string(font, unit_pos + flag_offset, flag_emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, flag_size, flag_color)

# Draw team color glow behind unit when ready for Settler second click
func draw_settler_ready_glow(unit_pos: Vector2, team_color: Color):
	# Create multiple glow layers for smooth effect
	var glow_layers = [
		{"radius": 35.0 * camera_manager.zoom_level, "alpha": 0.15},
		{"radius": 30.0 * camera_manager.zoom_level, "alpha": 0.25},
		{"radius": 25.0 * camera_manager.zoom_level, "alpha": 0.35},
		{"radius": 20.0 * camera_manager.zoom_level, "alpha": 0.45}
	]
	
	# Draw glow layers from largest to smallest
	for layer in glow_layers:
		var glow_color = Color(team_color.r, team_color.g, team_color.b, layer.alpha)
		main_node.draw_circle(unit_pos, layer.radius, glow_color)

# Draw hover effect around unit
func draw_hover_effect(position: Vector2):
	var hover_radius = 31.0 * camera_manager.zoom_level
	var hover_width = 2.0 * camera_manager.zoom_level
	main_node.draw_arc(position, hover_radius, 0, TAU, 32, Color.WHITE, hover_width)

# Get enhanced team color based on unit state
func get_enhanced_team_color(team_color: Color, has_actions: bool) -> Color:
	# Make team color more vibrant and visible on emojis
	var enhanced_color = team_color
	
	# Increase saturation and brightness for better visibility
	enhanced_color = Color(
		clamp(team_color.r * 1.2, 0.0, 1.0),  # Boost red channel
		clamp(team_color.g * 1.2, 0.0, 1.0),  # Boost green channel
		clamp(team_color.b * 1.2, 0.0, 1.0),  # Boost blue channel
		1.0  # Full alpha
	)
	
	# If unit has no actions, make it slightly faded but still colored
	if not has_actions:
		enhanced_color = enhanced_color.lerp(Color.WHITE, 0.3)  # Less fading than before
	
	return enhanced_color

# Check if unit emoji should be flipped based on movement direction
func should_flip_unit_emoji(unit_id: int) -> bool:
	var UnitMovementTracker = load("res://core/value_objects/unit_movement_tracker.gd")
	if UnitMovementTracker:
		return UnitMovementTracker.should_flip_emoji(unit_id)
	return false

# Draw terrain cost indicators on movement targets
func draw_terrain_cost_indicator(position: Vector2, terrain_cost: int, font: Font):
	if terrain_cost > 1 and terrain_cost < 999:
		var cost_size = int(12 * camera_manager.zoom_level)
		var cost_offset = Vector2(-4, 4) * camera_manager.zoom_level
		main_node.draw_string(font, position + cost_offset, str(terrain_cost), HORIZONTAL_ALIGNMENT_CENTER, -1, cost_size, Color.BLACK)
	elif terrain_cost >= 999:
		var cost_size = int(12 * camera_manager.zoom_level)
		var cost_offset = Vector2(-4, 4) * camera_manager.zoom_level
		main_node.draw_string(font, position + cost_offset, "X", HORIZONTAL_ALIGNMENT_CENTER, -1, cost_size, Color.RED)

# Cleanup method
func cleanup():
	main_node = null
	camera_manager = null