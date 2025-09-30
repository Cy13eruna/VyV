# 🎮 MAIN GAME COORDINATOR
# Purpose: Coordinate all layers and manage game flow
# Layer: Presentation
# Dependencies: All layers (ONION architecture coordinator)

extends Node2D

# Game state
var game_state: Dictionary = {}
var input_manager
var current_player_id: int = 1
var selected_unit_id: int = -1
var valid_movement_targets = []

# UI components
@onready var skip_turn_button: Button

func _ready():
	print("=== V&V GAME STARTING ===")
	setup_game()
	setup_ui()
	setup_input()

func setup_game():
	# Initialize game
	var init_result = InitializeGameUseCase.execute(2)
	if init_result.success:
		game_state = init_result.game_state
		current_player_id = game_state.turn_data.current_player_id
		print("Game initialized successfully")
	else:
		print("Failed to initialize game: ", init_result.message)

func setup_ui():
	# Create skip turn button
	skip_turn_button = Button.new()
	skip_turn_button.text = "Skip Turn"
	skip_turn_button.custom_minimum_size = Vector2(100, 40)
	skip_turn_button.position = Vector2(900, 50)
	skip_turn_button.pressed.connect(_on_skip_turn_pressed)
	add_child(skip_turn_button)

func setup_input():
	input_manager = InputManager.new()
	input_manager.point_clicked.connect(_on_point_clicked)
	input_manager.point_hovered.connect(_on_point_hovered)
	input_manager.point_unhovered.connect(_on_point_unhovered)
	input_manager.fog_toggle_requested.connect(_on_fog_toggle_requested)
	input_manager.skip_turn_requested.connect(_on_skip_turn_pressed)

func _unhandled_input(event):
	if game_state.is_empty():
		return
	
	input_manager.handle_input_event(event, game_state.grid)

func _on_point_clicked(point_id: int):
	if not _is_current_player_turn():
		return
	
	var clicked_position = game_state.grid.points[point_id].position
	
	# Check if clicking on unit to select it
	var unit_at_position = _find_unit_at_position(clicked_position)
	if unit_at_position and unit_at_position.owner_id == current_player_id:
		_select_unit(unit_at_position.id)
		return
	
	# Check if moving selected unit
	if selected_unit_id != -1:
		_attempt_move_unit(clicked_position)

func _on_point_hovered(point_id: int):
	queue_redraw()

func _on_point_unhovered(point_id: int):
	queue_redraw()

func _on_fog_toggle_requested():
	var result = ToggleFogUseCase.execute(game_state)
	if result.success:
		print(result.message)
		queue_redraw()

func _on_skip_turn_pressed():
	var result = SkipTurnUseCase.execute(game_state)
	if result.success:
		current_player_id = result.new_player_id
		_clear_selection()
		print(result.message)
		
		if result.game_over:
			print("GAME OVER!")
			if result.winner:
				print("Winner: ", result.winner.name)
	else:
		print("Failed to skip turn: ", result.message)
	
	queue_redraw()

func _select_unit(unit_id: int):
	selected_unit_id = unit_id
	var unit = game_state.units[unit_id]
	valid_movement_targets = MovementService.get_valid_movement_targets(unit, game_state.grid, game_state.units)
	queue_redraw()

func _attempt_move_unit(target_position):
	if selected_unit_id == -1:
		return
	
	var result = MoveUnitUseCase.execute(selected_unit_id, target_position, game_state)
	if result.success:
		print("Unit moved successfully")
		if result.power_consumed:
			print("Power consumed")
		_clear_selection()
	else:
		print("Movement failed: ", result.message)
	
	queue_redraw()

func _clear_selection():
	selected_unit_id = -1
	valid_movement_targets.clear()

func _find_unit_at_position(position):
	for unit_id in game_state.units:
		var unit = game_state.units[unit_id]
		if unit.position.equals(position):
			return unit
	return null

func _is_current_player_turn() -> bool:
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	return current_player != null and current_player.id == current_player_id

func _draw():
	if game_state.is_empty():
		return
	
	# Render UI background
	UIRenderer.render_game_ui(self, game_state)
	
	# Render grid
	GridRenderer.render_grid(self, game_state.grid, game_state, current_player_id)
	
	# Render domains
	DomainRenderer.render_domains(self, game_state, current_player_id)
	
	# Render units
	UnitRenderer.render_units(self, game_state, current_player_id)
	
	# Render movement targets for selected unit
	if selected_unit_id != -1:
		UnitRenderer.render_movement_targets(self, valid_movement_targets)
	
	# Render hover highlight
	var hovered_point = input_manager.get_hovered_point()
	GridRenderer.render_hover_highlight(self, game_state.grid, hovered_point)