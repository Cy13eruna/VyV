# 🖥️ UI RENDERER
# Purpose: Render user interface elements
# Layer: Infrastructure/Rendering
# Dependencies: Core entities only

class_name UIRenderer
extends RefCounted

static func render_game_ui(canvas: CanvasItem, game_state: Dictionary) -> void:
	_render_background(canvas)
	_render_current_player_info(canvas, game_state)
	_render_game_info(canvas, game_state)

static func _render_background(canvas: CanvasItem) -> void:
	# Draw expanded white background
	canvas.draw_rect(
		Rect2(-200, -200, 1400, 1200),
		GameConstants.BACKGROUND_COLOR
	)

static func _render_current_player_info(canvas: CanvasItem, game_state: Dictionary) -> void:
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	var font = ThemeDB.fallback_font
	var font_size = 18
	
	# Current player info
	var player_text = "Current Player: %s" % current_player.name
	canvas.draw_string(
		font,
		Vector2(50, 30),
		player_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		current_player.color
	)
	
	# Player power
	var total_power = DomainService.get_total_power_for_player(current_player.id, game_state.domains)
	var power_text = "Total Power: %d" % total_power
	canvas.draw_string(
		font,
		Vector2(50, 55),
		power_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.BLACK
	)
	
	# Player units with actions
	var units_with_actions = 0
	for unit_id in current_player.unit_ids:
		if unit_id in game_state.units:
			var unit = game_state.units[unit_id]
			if unit.can_move():
				units_with_actions += 1
	
	var actions_text = "Units with actions: %d" % units_with_actions
	canvas.draw_string(
		font,
		Vector2(50, 80),
		actions_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.BLACK
	)

static func _render_game_info(canvas: CanvasItem, game_state: Dictionary) -> void:
	var font = ThemeDB.fallback_font
	var font_size = 14
	
	# Turn number
	var turn_text = "Turn: %d" % game_state.turn_data.turn_number
	canvas.draw_string(
		font,
		Vector2(50, 120),
		turn_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.BLACK
	)
	
	# Fog of war status
	var fog_text = "Fog of War: %s" % ("ON" if game_state.fog_of_war_enabled else "OFF")
	canvas.draw_string(
		font,
		Vector2(50, 140),
		fog_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.BLACK
	)
	
	# Controls
	var controls = [
		"Controls:",
		"Click - Move unit",
		"SPACE - Toggle fog",
		"ENTER - Skip turn"
	]
	
	for i in range(controls.size()):
		canvas.draw_string(
			font,
			Vector2(50, 180 + i * 20),
			controls[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color.DARK_GRAY
		)