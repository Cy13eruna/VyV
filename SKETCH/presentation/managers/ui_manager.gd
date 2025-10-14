# 🎮 V&V UI MANAGER (REFATORADO)
# Purpose: Coordenador principal para elementos de UI
# Layer: Presentation Manager

extends Node
class_name UIManager

# Import modular components (loaded dynamically to avoid parse errors)
var UIMenuManager: GDScript
var UIGameInterface: GDScript

# Modular components
var menu_manager
var game_interface

# References
var main_node: Node2D

# Signals (delegated from modules)
signal game_started(player_count: int)
signal transition_started()
signal new_game_requested()
signal skip_turn_requested()

func _ready():
	call_deferred("setup_components")

# Setup modular components
func setup_components():
	print("[UI_MANAGER] setup_components() called")
	# Load classes dynamically
	UIMenuManager = load("res://presentation/managers/ui/ui_menu_manager.gd")
	UIGameInterface = load("res://presentation/managers/ui/ui_game_interface.gd")
	print("[UI_MANAGER] Classes loaded")
	
	# Create components
	menu_manager = UIMenuManager.new()
	game_interface = UIGameInterface.new()
	print("[UI_MANAGER] Components created")
	
	# Initialize components if main_node is available
	if main_node:
		initialize_components()
	else:
		print("[UI_MANAGER] main_node not available yet, deferring initialization")

# Initialize components with references
func initialize_components():
	print("[UI_MANAGER] Initializing components...")
	print("[UI_MANAGER] main_node: ", main_node != null)
	print("[UI_MANAGER] menu_manager: ", menu_manager != null)
	print("[UI_MANAGER] game_interface: ", game_interface != null)
	
	if menu_manager and menu_manager.has_method("initialize"):
		menu_manager.initialize(main_node)
		print("[UI_MANAGER] menu_manager initialized")
	
	if game_interface and game_interface.has_method("initialize"):
		game_interface.initialize(main_node)
		print("[UI_MANAGER] game_interface initialized")
		
		# Setup buttons after initialization
		if game_interface.has_method("setup_buttons"):
			game_interface.setup_buttons()
			print("[UI_MANAGER] Buttons setup called after initialization")
	
	# Connect signals
	if menu_manager:
		if menu_manager.has_signal("game_started"):
			menu_manager.game_started.connect(_on_game_started)
		if menu_manager.has_signal("transition_started"):
			menu_manager.transition_started.connect(_on_transition_started)
	
	if game_interface:
		if game_interface.has_signal("new_game_requested"):
			game_interface.new_game_requested.connect(_on_new_game_requested)
		if game_interface.has_signal("skip_turn_requested"):
			game_interface.skip_turn_requested.connect(_on_skip_turn_requested)

# Set main node reference
func set_main_node(node: Node2D):
	print("[UI_MANAGER] set_main_node called with: ", node != null)
	main_node = node
	if menu_manager and game_interface:
		print("[UI_MANAGER] Components available, initializing...")
		initialize_components()
	else:
		print("[UI_MANAGER] Components not ready yet - menu_manager: ", menu_manager != null, ", game_interface: ", game_interface != null)

# Setup UI (delegated to components)
func setup_ui():
	print("[UI_MANAGER] setup_ui() called")
	print("[UI_MANAGER] menu_manager available: ", menu_manager != null)
	print("[UI_MANAGER] game_interface available: ", game_interface != null)
	
	if menu_manager and menu_manager.has_method("setup_transition_button"):
		menu_manager.setup_transition_button()
		print("[UI_MANAGER] menu_manager setup_transition_button called")
	
	if game_interface and game_interface.has_method("setup_buttons"):
		game_interface.setup_buttons()
		print("[UI_MANAGER] game_interface setup_buttons called")
	else:
		print("[UI_MANAGER] ERROR: game_interface is null or missing setup_buttons method")

# Menu management (delegated to menu manager)
func handle_menu_input(event: InputEvent) -> bool:
	if menu_manager and menu_manager.has_method("handle_menu_input"):
		return menu_manager.handle_menu_input(event)
	return false

func start_game_with_players(player_count: int):
	print("[UI_MANAGER] start_game_with_players called with ", player_count, " players")
	if menu_manager and menu_manager.has_method("start_game_with_players"):
		menu_manager.start_game_with_players(player_count)
	
	# Ensure buttons are created if they don't exist
	if game_interface and game_interface.has_method("setup_buttons"):
		if not game_interface.skip_turn_button or not game_interface.new_game_button:
			print("[UI_MANAGER] Buttons missing, creating them...")
			game_interface.setup_buttons()
	
	# Show game buttons when starting game
	print("[UI_MANAGER] Attempting to show game buttons...")
	if game_interface and game_interface.has_method("show_game_buttons"):
		game_interface.show_game_buttons()
		print("[UI_MANAGER] Game buttons show command sent")
	else:
		print("[UI_MANAGER] ERROR: game_interface is null or missing show_game_buttons method")

func reset_to_menu():
	if menu_manager and menu_manager.has_method("reset_to_menu"):
		menu_manager.reset_to_menu()
	
	# Hide game buttons when returning to menu
	if game_interface and game_interface.has_method("hide_game_buttons"):
		game_interface.hide_game_buttons()

# Turn transition management (delegated to menu manager)
func show_turn_transition(game_state: Dictionary):
	if menu_manager and menu_manager.has_method("show_turn_transition"):
		menu_manager.show_turn_transition(game_state)
	
	# Hide skip button during transition
	if game_interface and game_interface.has_method("hide_skip_button"):
		game_interface.hide_skip_button()

func hide_transition():
	if menu_manager and menu_manager.has_method("hide_transition"):
		menu_manager.hide_transition()
	
	# Show skip button after transition
	if game_interface and game_interface.has_method("show_skip_button"):
		game_interface.show_skip_button()

# Game interface management (delegated to game interface)
func update_skip_button_color(game_state: Dictionary):
	if game_interface and game_interface.has_method("update_skip_button_color"):
		game_interface.update_skip_button_color(game_state)

# Debug UI toggles (delegated to game interface)
func toggle_debug_info():
	if game_interface and game_interface.has_method("toggle_debug_info"):
		game_interface.toggle_debug_info()

func toggle_grid_stats():
	if game_interface and game_interface.has_method("toggle_grid_stats"):
		game_interface.toggle_grid_stats()

func toggle_analytics_dashboard():
	if game_interface and game_interface.has_method("toggle_analytics_dashboard"):
		game_interface.toggle_analytics_dashboard()

func toggle_debug_overlay():
	if game_interface and game_interface.has_method("toggle_debug_overlay"):
		game_interface.toggle_debug_overlay()

func toggle_performance_graph():
	if game_interface and game_interface.has_method("toggle_performance_graph"):
		game_interface.toggle_performance_graph()

func handle_tab_navigation():
	if game_interface and game_interface.has_method("handle_tab_navigation"):
		game_interface.handle_tab_navigation()

# Render functions (delegated to appropriate modules)
func render_menu():
	if menu_manager and menu_manager.has_method("render_menu"):
		menu_manager.render_menu()

func render_turn_transition():
	if menu_manager and menu_manager.has_method("render_turn_transition"):
		menu_manager.render_turn_transition()

func render_main_ui(game_over: bool, winner_player, game_state: Dictionary = {}):
	if game_interface and game_interface.has_method("render_main_ui"):
		game_interface.render_main_ui(game_over, winner_player, game_state)

# Getters for external access
func get_property(property_name: String):
	match property_name:
		"in_menu":
			if menu_manager and menu_manager.has_method("is_in_menu"):
				return menu_manager.is_in_menu()
			return true
		"in_turn_transition":
			if menu_manager and menu_manager.has_method("is_in_turn_transition"):
				return menu_manager.is_in_turn_transition()
			return false
		"selected_player_count":
			if menu_manager and menu_manager.has_method("get_selected_player_count"):
				return menu_manager.get_selected_player_count()
			return 0
		"show_debug_info":
			if game_interface and game_interface.has_method("is_debug_info_visible"):
				return game_interface.is_debug_info_visible()
			return false
		"show_grid_stats":
			if game_interface and game_interface.has_method("is_grid_stats_visible"):
				return game_interface.is_grid_stats_visible()
			return false
		"show_analytics_dashboard":
			if game_interface and game_interface.has_method("is_analytics_dashboard_visible"):
				return game_interface.is_analytics_dashboard_visible()
			return false
		"show_debug_overlay":
			if game_interface and game_interface.has_method("is_debug_overlay_visible"):
				return game_interface.is_debug_overlay_visible()
			return false
		"show_performance_graph":
			if game_interface and game_interface.has_method("is_performance_graph_visible"):
				return game_interface.is_performance_graph_visible()
			return false
		"current_dashboard_tab":
			if game_interface and game_interface.has_method("get_current_dashboard_tab"):
				return game_interface.get_current_dashboard_tab()
			return 0
		"skip_turn_button":
			if game_interface and "skip_turn_button" in game_interface:
				return game_interface.skip_turn_button
			return null
		_:
			return null

# Signal handlers
func _on_game_started(player_count: int):
	game_started.emit(player_count)

func _on_transition_started():
	transition_started.emit()

func _on_new_game_requested():
	new_game_requested.emit()

func _on_skip_turn_requested():
	skip_turn_requested.emit()

# Cleanup method
func _exit_tree():
	if menu_manager and menu_manager.has_method("cleanup"):
		menu_manager.cleanup()
	
	if game_interface and game_interface.has_method("cleanup"):
		game_interface.cleanup()
	
	menu_manager = null
	game_interface = null
	main_node = null