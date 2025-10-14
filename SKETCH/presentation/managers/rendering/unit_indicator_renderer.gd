# 🎯 UNIT INDICATOR RENDERER
# Purpose: Render unit indicators (fighter, healer, health emojis)
# Layer: Presentation Manager - Rendering

extends RefCounted
class_name UnitIndicatorRenderer

# Import dependencies
const FogOfWarService = preload("res://application/services/fog_of_war_service.gd")

# References
var main_node: Node2D
var camera_manager
var unit_manager

# Initialize with required references
func initialize(main_node_ref: Node2D, camera_manager_ref, unit_manager_ref):
	main_node = main_node_ref
	camera_manager = camera_manager_ref
	unit_manager = unit_manager_ref

# Universal emoji visibility rule
func should_show_emoji(unit, current_player_id: int, game_state: Dictionary) -> bool:
	# UNIVERSAL EMOJI RULE: All emojis are always visible to all players
	# This provides strategic information while respecting visibility boundaries
	
	# Only check fog of war for position visibility, not unit ownership
	if game_state.get("fog_of_war_enabled", false):
		# Only hide if the position itself is not visible due to fog of war
		var is_position_visible = FogOfWarService._is_position_visible_to_player(unit.position, current_player_id, game_state)
		return is_position_visible
	
	# If no fog of war, all emojis are always visible
	return true

# Render health indicators (🩹 for injured units)
func render_health_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("units" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# Check each unit for health status
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		# Only show indicator for injured units (health = 0)
		if not unit.is_injured():
			continue
		
		# Apply universal emoji visibility rule
		if not should_show_emoji(unit, current_player_id, game_state):
			continue
		
		# Unit is visible and injured, show curativo
		print("[CURATIVO] Showing curativo for injured unit ", unit.name, " (visible to player ", current_player_id, ")")
		
		# Get unit position on screen
		var screen_pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
		
		# Position curativo exactly over the unit name (which is below the emoji)
		var offset = Vector2(0, 15) * camera_manager.zoom_level
		screen_pos += offset
		
		# Draw health indicator emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = "🩹"  # Bandage emoji
			var size = int(18 * camera_manager.zoom_level)  # Increased size for visibility
			
			# Add stronger shadow for visibility
			var shadow_offset = Vector2(2, 2) * camera_manager.zoom_level
			main_node.draw_string(font, screen_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.8))
			
			# Draw main emoji with bright color
			main_node.draw_string(font, screen_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Render fighter indicators (🗡 for fighter units)
func render_fighter_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("units" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# Check each unit for fighter status
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		# Only show indicator for fighter units
		if not unit.is_fighter:
			continue
		
		# Apply universal emoji visibility rule
		if not should_show_emoji(unit, current_player_id, game_state):
			continue
		
		# Get unit position on screen
		var screen_pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
		
		# Offset the emoji to the left side of the unit
		var offset = Vector2(-20, 0) * camera_manager.zoom_level
		screen_pos += offset
		
		# Draw fighter indicator emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = "🗡"  # Sword emoji
			var size = int(16 * camera_manager.zoom_level)
			
			# Add shadow for visibility
			var shadow_offset = Vector2(1, 1) * camera_manager.zoom_level
			main_node.draw_string(font, screen_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.7))
			
			# Draw main emoji
			main_node.draw_string(font, screen_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Render climber indicators (🧗 for climber units)
func render_climber_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("units" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# Check each unit for climber status
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		# Only show indicator for climber units
		if not unit.is_climber:
			continue
		
		# Apply universal emoji visibility rule
		if not should_show_emoji(unit, current_player_id, game_state):
			continue
		
		# Get unit position on screen
		var screen_pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
		
		# Position the emoji to the right side of the unit
		var offset = Vector2(20, 0) * camera_manager.zoom_level
		screen_pos += offset
		
		# Draw climber indicator emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = "🧗"  # Climber emoji
			var size = int(16 * camera_manager.zoom_level)
			
			# Add shadow for visibility
			var shadow_offset = Vector2(1, 1) * camera_manager.zoom_level
			main_node.draw_string(font, screen_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.7))
			
			# Draw main emoji
			main_node.draw_string(font, screen_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Render healer indicators (♥ for healer units)
func render_healer_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("units" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# Check each unit for healer status
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		# Only show indicator for healer units
		if not unit.is_healer:
			continue
		
		# Apply universal emoji visibility rule
		if not should_show_emoji(unit, current_player_id, game_state):
			continue
		
		# Get unit position on screen
		var screen_pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
		
		# Position the emoji above and slightly to the left of the unit (on the head)
		var offset = Vector2(-8, -20) * camera_manager.zoom_level
		screen_pos += offset
		
		# Draw healer indicator emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = "♥"  # Heart emoji
			var size = int(16 * camera_manager.zoom_level)
			
			# Add shadow for visibility
			var shadow_offset = Vector2(1, 1) * camera_manager.zoom_level
			main_node.draw_string(font, screen_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.7))
			
			# Draw main emoji
			main_node.draw_string(font, screen_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Render rider indicators (🐎 for rider units)
func render_rider_indicators(game_state: Dictionary, fog_settings: Dictionary):
	if not ("units" in game_state):
		return
	
	var current_player_id = fog_settings.get("player_id", 1)
	
	# Check each unit for rider status
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		
		# Skip dead units - they should not be rendered
		if unit.is_dead():
			continue
		
		# Only show indicator for rider units
		if not unit.is_rider:
			continue
		
		# Apply universal emoji visibility rule
		if not should_show_emoji(unit, current_player_id, game_state):
			continue
		
		# Get unit position on screen
		var screen_pos = camera_manager.apply_full_transform(unit.position.pixel_pos)
		
		# Position the emoji at the base of the unit (below the name)
		var offset = Vector2(0, 30) * camera_manager.zoom_level
		screen_pos += offset
		
		# Draw rider indicator emoji
		var font = ThemeDB.fallback_font
		if font:
			var emoji = "🐎"  # Horse emoji
			var size = int(16 * camera_manager.zoom_level)
			
			# Add shadow for visibility
			var shadow_offset = Vector2(1, 1) * camera_manager.zoom_level
			main_node.draw_string(font, screen_pos + shadow_offset, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color(0, 0, 0, 0.7))
			
			# Draw main emoji
			main_node.draw_string(font, screen_pos, emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, size, Color.WHITE)

# Render attack targets (team color circles for valid attack positions)
func render_attack_targets(game_state: Dictionary, fog_settings: Dictionary):
	if not unit_manager or not unit_manager.selection_manager:
		return
	
	var valid_attack_targets = unit_manager.selection_manager.get_valid_attack_targets()
	if valid_attack_targets.is_empty():
		return
	
	# Get selected unit to determine team color
	var selected_unit_id = unit_manager.selection_manager.get_selected_unit_id()
	if selected_unit_id == -1 or not ("units" in game_state) or selected_unit_id not in game_state.units:
		return
	
	var selected_unit = game_state.units[selected_unit_id]
	var attacker_player_id = selected_unit.owner_id
	
	# Get attacker's team color
	var attack_color = Color.RED  # Default fallback
	if "players" in game_state and attacker_player_id in game_state.players:
		var player = game_state.players[attacker_player_id]
		attack_color = player.color
	
	# Render team color circles for each valid attack target
	for target_position in valid_attack_targets:
		var screen_pos = camera_manager.apply_full_transform(target_position.pixel_pos)
		
		# Draw attack target indicator (team color circle with glow)
		var base_radius = 25.0 * camera_manager.zoom_level
		
		# Draw glow layers for attack targets (team color theme)
		var glow_layers = [
			{"radius": base_radius * 2.0, "alpha": 0.1},
			{"radius": base_radius * 1.6, "alpha": 0.15},
			{"radius": base_radius * 1.3, "alpha": 0.25},
			{"radius": base_radius * 1.1, "alpha": 0.35}
		]
		
		# Draw glow layers
		for layer in glow_layers:
			var layer_color = Color(attack_color.r, attack_color.g, attack_color.b, layer.alpha)
			main_node.draw_circle(screen_pos, layer.radius, layer_color)
		
		# Draw main attack target circle
		var main_alpha = 0.6
		var main_color = Color(attack_color.r, attack_color.g, attack_color.b, main_alpha)
		main_node.draw_circle(screen_pos, base_radius, main_color)
		
		# Draw border for better visibility
		var border_thickness = 3.0 * camera_manager.zoom_level
		var border_color = Color(attack_color.r, attack_color.g, attack_color.b, 0.8)
		
		# Draw border by drawing multiple circles
		for i in range(int(border_thickness)):
			var border_radius = base_radius + i
			main_node.draw_arc(screen_pos, border_radius, 0, TAU, 32, border_color, 1.0)

# Render heal targets (team color circles for valid heal positions)
func render_heal_targets(game_state: Dictionary, fog_settings: Dictionary):
	if not unit_manager or not unit_manager.selection_manager:
		return
	
	var valid_heal_targets = unit_manager.selection_manager.get_valid_heal_targets()
	if valid_heal_targets.is_empty():
		return
	
	print("[HEAL_RENDER] Rendering ", valid_heal_targets.size(), " heal targets")
	
	# Get selected unit to determine team color
	var selected_unit_id = unit_manager.selection_manager.get_selected_unit_id()
	if selected_unit_id == -1 or not ("units" in game_state) or selected_unit_id not in game_state.units:
		return
	
	var selected_unit = game_state.units[selected_unit_id]
	var healer_player_id = selected_unit.owner_id
	
	# Get healer's team color
	var heal_color = Color.GREEN  # Default fallback for healing
	if "players" in game_state and healer_player_id in game_state.players:
		var player = game_state.players[healer_player_id]
		heal_color = player.color
	
	# Render team color circles for each valid heal target
	for target_position in valid_heal_targets:
		var screen_pos = camera_manager.apply_full_transform(target_position.pixel_pos)
		
		# Draw heal target indicator (team color circle with soft glow)
		var base_radius = 25.0 * camera_manager.zoom_level
		
		# Draw glow layers for heal targets (softer than attack targets)
		var glow_layers = [
			{"radius": base_radius * 2.2, "alpha": 0.08},
			{"radius": base_radius * 1.8, "alpha": 0.12},
			{"radius": base_radius * 1.4, "alpha": 0.18},
			{"radius": base_radius * 1.1, "alpha": 0.25}
		]
		
		# Draw glow layers
		for layer in glow_layers:
			var layer_color = Color(heal_color.r, heal_color.g, heal_color.b, layer.alpha)
			main_node.draw_circle(screen_pos, layer.radius, layer_color)
		
		# Draw main heal target circle (softer than attack)
		var main_alpha = 0.4  # Softer than attack targets
		var main_color = Color(heal_color.r, heal_color.g, heal_color.b, main_alpha)
		main_node.draw_circle(screen_pos, base_radius, main_color)
		
		# Draw border for better visibility
		var border_thickness = 2.0 * camera_manager.zoom_level  # Thinner than attack
		var border_color = Color(heal_color.r, heal_color.g, heal_color.b, 0.7)
		
		# Draw border by drawing multiple circles
		for i in range(int(border_thickness)):
			var border_radius = base_radius + i
			main_node.draw_arc(screen_pos, border_radius, 0, TAU, 32, border_color, 1.0)
		
		# Add healing cross symbol in the center
		draw_healing_cross(screen_pos, base_radius * 0.6, heal_color)

# Draw healing cross symbol
func draw_healing_cross(center: Vector2, size: float, color: Color):
	var cross_thickness = 3.0 * camera_manager.zoom_level
	var cross_color = Color(color.r, color.g, color.b, 0.9)
	
	# Draw vertical line
	var vertical_start = center + Vector2(0, -size)
	var vertical_end = center + Vector2(0, size)
	main_node.draw_line(vertical_start, vertical_end, cross_color, cross_thickness)
	
	# Draw horizontal line
	var horizontal_start = center + Vector2(-size, 0)
	var horizontal_end = center + Vector2(size, 0)
	main_node.draw_line(horizontal_start, horizontal_end, cross_color, cross_thickness)

# Cleanup method
func cleanup():
	main_node = null
	camera_manager = null
	unit_manager = null