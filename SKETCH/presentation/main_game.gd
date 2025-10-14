# 🎮 V&V MAIN GAME (REFATORADO)
# Purpose: Coordenador principal para o jogo modular V&V
# Layer: Presentation (ONION Coordinator)

extends Node2D

# Import constants
const GameConstants = preload("res://presentation/config/game_constants.gd")

# Import modular components (loaded dynamically to avoid parse errors)
var GameSceneManager: GDScript
var GameEventDispatcher: GDScript

# Modular components
var scene_manager
var event_dispatcher

func _ready():
	call_deferred("setup_coordination")
	call_deferred("setup_managers")
	call_deferred("setup_connections")
	call_deferred("queue_redraw")

# Setup coordination modules
func setup_coordination():
	print("[MAIN_GAME] Initializing coordination modules...")
	
	# Load classes dynamically
	GameSceneManager = load("res://presentation/game_coordination/game_scene_manager.gd")
	GameEventDispatcher = load("res://presentation/game_coordination/game_event_dispatcher.gd")
	
	# Create scene manager
	scene_manager = GameSceneManager.new()
	if scene_manager and scene_manager.has_method("initialize"):
		scene_manager.initialize(self)
	else:
		print("[MAIN_GAME] ERROR: Failed to create or initialize scene_manager")
		return
	
	# Create event dispatcher
	event_dispatcher = GameEventDispatcher.new()
	if event_dispatcher and event_dispatcher.has_method("initialize"):
		event_dispatcher.initialize(self, scene_manager)
	else:
		print("[MAIN_GAME] ERROR: Failed to create or initialize event_dispatcher")
		return
	
	print("[MAIN_GAME] Coordination modules initialized successfully")

# Setup managers (delegated to scene manager)
func setup_managers():
	if scene_manager:
		scene_manager.setup_managers()
		scene_manager.start_integrity_monitoring()

# Setup connections (delegated to event dispatcher)
func setup_connections():
	if event_dispatcher:
		event_dispatcher.setup_connections()

# Deferred method for rendering manager setup
func _setup_rendering_manager_deferred():
	if scene_manager:
		scene_manager.setup_rendering_manager()

# Handle unhandled input (delegated to event dispatcher)
func _unhandled_input(event):
	if event_dispatcher:
		event_dispatcher.handle_unhandled_input(event)

# Main drawing function
func _draw():
	# Check if managers are initialized
	if not scene_manager or not scene_manager.are_managers_ready():
		return
	
	var ui_manager = scene_manager.get_ui_manager()
	var gameplay_manager = scene_manager.get_gameplay_manager()
	var rendering_manager = scene_manager.get_rendering_manager()
	var input_manager = scene_manager.get_input_manager()
	var unit_renderer = scene_manager.get_unit_renderer()
	
	# Show menu if in menu state
	if ui_manager.get_property("in_menu"):
		ui_manager.call("render_menu")
		return
	
	# Show turn transition if in transition state
	if ui_manager.get_property("in_turn_transition"):
		ui_manager.call("render_turn_transition")
		return
	
	var game_state = gameplay_manager.get_game_state()
	if not game_state or game_state.is_empty():
		return
	
	# Draw background
	draw_rect(Rect2(0, 0, 1024, 768), Color.WHITE)
	
	var fog_settings = gameplay_manager.get_fog_settings()
	var hover_state = input_manager.call("get_hover_state")
	var font = ThemeDB.fallback_font
	
	# Render grid with restored style (edges only)
	rendering_manager.call("render_grid_edges", game_state, hover_state)
	
	# Render harvest structures BEHIND domains
	rendering_manager.call("render_harvest_structures", game_state, fog_settings)
	
	# Render domains OVER harvest structures
	rendering_manager.call("render_domains", game_state, fog_settings)
	
	# Render movement targets BEFORE stars so glow appears behind them
	var valid_targets = gameplay_manager.get_valid_movement_targets()
	if valid_targets and valid_targets.size() > 0:
		unit_renderer.call("render_movement_targets_with_terrain",
			game_state, 
			gameplay_manager.get_selected_unit_id(), 
			valid_targets, 
			font
		)
	
	# Render attack targets on top of everything
	rendering_manager.call("_render_attack_targets", game_state, fog_settings)
	
	# Render heal targets on top of everything
	rendering_manager.call("_render_heal_targets", game_state, fog_settings)
	
	# Render grid points (stars) AFTER movement targets and attack targets to overlay them
	rendering_manager.call("render_grid_points", game_state, hover_state, fog_settings)
	
	# Render units using the correct function
	unit_renderer.call("render_units_with_fog",
		game_state, 
		fog_settings, 
		hover_state, 
		gameplay_manager.get_selected_unit_id(), 
		font,
		gameplay_manager.get_technology_manager()
	)
	
	# Render train indicator on top of everything
	rendering_manager.call("_render_train_indicator", game_state, fog_settings)
	
	# Render fighter indicators on top of everything
	rendering_manager.call("_render_fighter_indicators", game_state, fog_settings)
	
	# Render healer indicators on top of everything
	rendering_manager.call("_render_healer_indicators", game_state, fog_settings)
	
	# Render rider indicators on top of everything
	rendering_manager.call("_render_rider_indicators", game_state, fog_settings)
	
	# Render health indicators on top of everything
	rendering_manager.call("_render_health_indicators", game_state, fog_settings)
	
	# Render UI layers
	ui_manager.call("render_main_ui", gameplay_manager.is_game_over(), gameplay_manager.get_winner_player(), game_state)

# Deferred focus restoration method called by dialog manager
func _restore_focus_deferred():
	if event_dispatcher:
		event_dispatcher.restore_focus_deferred()

# Cleanup method to prevent memory leaks
func _exit_tree():
	# Cleanup coordination modules
	if event_dispatcher:
		event_dispatcher.cleanup()
		event_dispatcher = null
	
	if scene_manager:
		scene_manager.cleanup()
		scene_manager = null