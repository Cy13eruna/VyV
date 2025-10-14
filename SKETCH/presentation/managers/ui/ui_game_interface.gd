# 🎮 UI GAME INTERFACE
# Purpose: Handle game UI elements, indicators and debug overlays
# Layer: Presentation Managers - UI

extends RefCounted
class_name UIGameInterface

# Import constants
const GameConstants = preload("res://presentation/config/game_constants.gd")
const TurnService = preload("res://application/services/turn_service_clean.gd")
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D

# UI Components
var skip_turn_button: Button
var new_game_button: Button

# UI state
var show_debug_info: bool = false
var show_grid_stats: bool = false
var show_analytics_dashboard: bool = false
var show_debug_overlay: bool = false
var show_performance_graph: bool = false
var current_dashboard_tab: int = 0

# Signals
signal new_game_requested()
signal skip_turn_requested()

# Initialize with references
func initialize(main_node_ref: Node2D):
	main_node = main_node_ref

# Setup UI buttons
func setup_buttons():
	print("[UI_GAME_INTERFACE] Setting up buttons...")
	if not main_node:
		print("[UI_GAME_INTERFACE] ERROR: main_node is null, cannot setup buttons")
		return
	
	setup_skip_turn_button()
	setup_new_game_button()
	print("[UI_GAME_INTERFACE] Buttons setup complete")
	
	# Make buttons visible immediately after creation
	show_game_buttons()

# Setup skip turn button
func setup_skip_turn_button():
	print("[UI_GAME_INTERFACE] Creating skip turn button...")
	skip_turn_button = Button.new()
	skip_turn_button.text = GameDialogStrings.BUTTON_SKIP_TURN
	skip_turn_button.custom_minimum_size = GameConstants.SKIP_BUTTON_SIZE
	skip_turn_button.position = GameConstants.SKIP_BUTTON_POS
	skip_turn_button.visible = false
	skip_turn_button.pressed.connect(_on_skip_turn)
	
	if main_node and is_instance_valid(main_node):
		main_node.add_child(skip_turn_button)
		print("[UI_GAME_INTERFACE] Skip turn button created and added to scene")
		print("[UI_GAME_INTERFACE] Skip button - Position: ", skip_turn_button.position, ", Size: ", skip_turn_button.custom_minimum_size, ", Visible: ", skip_turn_button.visible)
		print("[UI_GAME_INTERFACE] Skip button - Text: '", skip_turn_button.text, "', Parent: ", skip_turn_button.get_parent() != null)
	else:
		print("[UI_GAME_INTERFACE] ERROR: Cannot add skip turn button - main_node is invalid")

# Setup new game button
func setup_new_game_button():
	print("[UI_GAME_INTERFACE] Creating new game button...")
	new_game_button = Button.new()
	new_game_button.text = GameDialogStrings.BUTTON_NEW_GAME
	new_game_button.custom_minimum_size = GameConstants.NEW_GAME_BUTTON_SIZE
	new_game_button.position = GameConstants.NEW_GAME_BUTTON_POS
	new_game_button.visible = false
	new_game_button.pressed.connect(_on_new_game)
	
	if main_node and is_instance_valid(main_node):
		main_node.add_child(new_game_button)
		print("[UI_GAME_INTERFACE] New game button created and added to scene")
		print("[UI_GAME_INTERFACE] New game button - Position: ", new_game_button.position, ", Size: ", new_game_button.custom_minimum_size, ", Visible: ", new_game_button.visible)
		print("[UI_GAME_INTERFACE] New game button - Text: '", new_game_button.text, "', Parent: ", new_game_button.get_parent() != null)
	else:
		print("[UI_GAME_INTERFACE] ERROR: Cannot add new game button - main_node is invalid")

# Update skip button color based on current player
func update_skip_button_color(game_state: Dictionary):
	if not skip_turn_button or game_state.is_empty():
		return
	
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		skip_turn_button.modulate = current_player.color
	else:
		skip_turn_button.modulate = Color.WHITE

# Show/hide game buttons
func show_game_buttons():
	print("[UI_GAME_INTERFACE] show_game_buttons() called")
	if skip_turn_button:
		skip_turn_button.visible = true
		print("[UI_GAME_INTERFACE] Skip turn button made visible")
		print("[UI_GAME_INTERFACE] Skip button after show - Position: ", skip_turn_button.position, ", Visible: ", skip_turn_button.visible, ", In tree: ", skip_turn_button.is_inside_tree())
	else:
		print("[UI_GAME_INTERFACE] ERROR: skip_turn_button is null")
	
	if new_game_button:
		new_game_button.visible = true
		print("[UI_GAME_INTERFACE] New game button made visible")
		print("[UI_GAME_INTERFACE] New game button after show - Position: ", new_game_button.position, ", Visible: ", new_game_button.visible, ", In tree: ", new_game_button.is_inside_tree())
	else:
		print("[UI_GAME_INTERFACE] ERROR: new_game_button is null")

func hide_game_buttons():
	if skip_turn_button:
		skip_turn_button.visible = false
	if new_game_button:
		new_game_button.visible = false

func hide_skip_button():
	if skip_turn_button:
		skip_turn_button.visible = false

func show_skip_button():
	if skip_turn_button:
		skip_turn_button.visible = true

# Debug UI toggles
func toggle_debug_info():
	show_debug_info = not show_debug_info
	main_node.queue_redraw()

func toggle_grid_stats():
	show_grid_stats = not show_grid_stats
	main_node.queue_redraw()

func toggle_analytics_dashboard():
	show_analytics_dashboard = not show_analytics_dashboard
	main_node.queue_redraw()

func toggle_debug_overlay():
	show_debug_overlay = not show_debug_overlay
	main_node.queue_redraw()

func toggle_performance_graph():
	show_performance_graph = not show_performance_graph
	main_node.queue_redraw()

func handle_tab_navigation():
	if show_analytics_dashboard:
		current_dashboard_tab = (current_dashboard_tab + 1) % 5
		main_node.queue_redraw()

# Render main game UI
func render_main_ui(game_over: bool, winner_player, game_state: Dictionary = {}):
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	# Render power indicator at top of screen
	if not game_over and not game_state.is_empty():
		render_power_indicator(font, game_state)
	
	if game_over:
		main_node.draw_rect(Rect2(0, 0, 1024, 768), Color(0, 0, 0, 0.8))
		
		main_node.draw_string(font, Vector2(512, 300), GameDialogStrings.VICTORY_TITLE, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, Color.GOLD)
		
		var winner_name = winner_player.name if winner_player else "Draw"
		main_node.draw_string(font, Vector2(512, 360), GameDialogStrings.VICTORY_WINNER_FORMAT % winner_name, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
		
		main_node.draw_string(font, Vector2(512, 420), GameDialogStrings.VICTORY_QUIT_INSTRUCTION, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.LIGHT_GRAY)
		return
	
	render_controls_info(font)

# Render power indicator at top of screen
func render_power_indicator(font: Font, game_state: Dictionary):
	# Get current player
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if not current_player:
		return
	
	# Calculate total power and power production per turn
	var total_power = 0
	var power_per_turn = 0
	
	if "domains" in game_state:
		for domain_id in game_state.domains:
			var domain = game_state.domains[domain_id]
			if domain.owner_id == current_player.id:
				total_power += domain.get("power", 0)
				# Power production per turn = +1 per domain (base) + harvest bonus
				power_per_turn += 1  # Base power per domain
				var harvest_power = domain.get("power_per_turn", 0)
				power_per_turn += harvest_power  # Additional harvest power
	
	# Create power indicator text (only total power, no production indicator)
	var power_text = GameDialogStrings.POWER_INDICATOR_FORMAT % total_power
	
	# Calculate position (centered at top)
	var text_size = font.get_string_size(power_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	var pos = Vector2(512 - text_size.x / 2, 30)
	
	# Draw background
	var bg_rect = Rect2(pos.x - 10, pos.y - 20, text_size.x + 20, text_size.y + 10)
	main_node.draw_rect(bg_rect, Color(0, 0, 0, 0.7))
	
	# Draw border with player color
	main_node.draw_rect(bg_rect, current_player.color, false, 2.0)
	
	# Draw power text
	main_node.draw_string(font, pos, power_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

# Render controls information
func render_controls_info(font: Font):
	var controls_rect = Rect2(10, 660, 400, 100)
	main_node.draw_rect(controls_rect, Color(0, 0, 0, 0.7))
	
	var controls = [
		GameDialogStrings.CONTROLS_BASIC,
		GameDialogStrings.CONTROLS_CAMERA,
		GameDialogStrings.CONTROLS_OBJECTIVE
	]
	
	for i in range(controls.size()):
		var text = controls[i]
		main_node.draw_string(font, Vector2(20, 680 + i * 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

# Getters for debug state
func is_debug_info_visible() -> bool:
	return show_debug_info

func is_grid_stats_visible() -> bool:
	return show_grid_stats

func is_analytics_dashboard_visible() -> bool:
	return show_analytics_dashboard

func is_debug_overlay_visible() -> bool:
	return show_debug_overlay

func is_performance_graph_visible() -> bool:
	return show_performance_graph

func get_current_dashboard_tab() -> int:
	return current_dashboard_tab

# Signal handlers
func _on_skip_turn():
	skip_turn_requested.emit()

func _on_new_game():
	new_game_requested.emit()

# Cleanup method
func cleanup():
	if skip_turn_button and is_instance_valid(skip_turn_button):
		skip_turn_button.queue_free()
	
	if new_game_button and is_instance_valid(new_game_button):
		new_game_button.queue_free()
	
	main_node = null
	skip_turn_button = null
	new_game_button = null