# 🎮 UI MENU MANAGER
# Purpose: Handle menu navigation, transitions and game start
# Layer: Presentation Managers - UI

extends RefCounted
class_name UIMenuManager

# Import constants
const GameConstants = preload("res://presentation/config/game_constants.gd")
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D

# UI Components
var transition_button: Button

# Menu state
var in_menu: bool = true
var selected_player_count: int = 0
var menu_options: Array = []
var hovered_menu_option: int = -1
var clicked_menu_option: int = -1

# Turn transition state
var in_turn_transition: bool = false
var next_player_id: int = -1

# Signals
signal game_started(player_count: int)
signal transition_started()

# Initialize with references
func initialize(main_node_ref: Node2D):
	main_node = main_node_ref

# Setup transition button
func setup_transition_button():
	transition_button = Button.new()
	transition_button.text = GameDialogStrings.BUTTON_START
	transition_button.custom_minimum_size = GameConstants.TRANSITION_BUTTON_SIZE
	transition_button.position = GameConstants.TRANSITION_BUTTON_POS
	transition_button.visible = false
	transition_button.pressed.connect(_on_transition_start)
	main_node.add_child(transition_button)

# Handle menu input events
func handle_menu_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		hovered_menu_option = -1
		for i in range(menu_options.size()):
			var option = menu_options[i]
			if option.rect.has_point(event.position):
				hovered_menu_option = i
				break
		main_node.queue_redraw()
		return true
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(menu_options.size()):
			var option = menu_options[i]
			if option.rect.has_point(event.position):
				clicked_menu_option = i
				main_node.queue_redraw()
				# Use call_deferred instead of await to avoid blocking
				call_deferred("_delayed_start_game", option.players)
				return true
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_2:
				start_game_with_players(2)
				return true
			KEY_3:
				start_game_with_players(3)
				return true
			KEY_4:
				start_game_with_players(4)
				return true
			KEY_6:
				start_game_with_players(6)
				return true
			KEY_ESCAPE:
				main_node.get_tree().quit()
				return true
	
	return false

# Helper function for delayed game start
func _delayed_start_game(player_count: int):
	start_game_with_players(player_count)

# Start game with specified player count
func start_game_with_players(player_count: int):
	selected_player_count = player_count
	in_menu = false
	
	game_started.emit(player_count)

# Reset to menu state
func reset_to_menu():
	in_menu = true
	selected_player_count = 0
	hovered_menu_option = -1
	clicked_menu_option = -1
	in_turn_transition = false
	
	if transition_button:
		transition_button.visible = false

# Show turn transition
func show_turn_transition(game_state: Dictionary):
	var TurnService = load("res://application/services/turn_service_clean.gd")
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	if current_player:
		next_player_id = current_player.id
		# Ensure transition button exists before using it
		if not transition_button:
			setup_transition_button()
		
		if transition_button:
			transition_button.modulate = current_player.color
			in_turn_transition = true
			transition_button.visible = true

# Hide turn transition
func hide_transition():
	in_turn_transition = false
	if transition_button:
		transition_button.visible = false

# Render menu
func render_menu():
	main_node.draw_rect(Rect2(0, 0, 1024, 768), Color.BLACK)
	
	var font = ThemeDB.fallback_font
	if not font:
		return
	
	menu_options = GameConstants.MENU_OPTIONS.duplicate()
	
	for i in range(menu_options.size()):
		var option = menu_options[i]
		var text_color = Color.WHITE
		if clicked_menu_option == i:
			text_color = Color.GREEN
		elif hovered_menu_option == i:
			text_color = Color.MAGENTA
		
		var text = "%d" % option.players
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
		var pos = Vector2(512 - text_size.x/2, option.y)
		main_node.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, text_color)

# Render turn transition
func render_turn_transition():
	main_node.draw_rect(Rect2(0, 0, 1024, 768), Color.BLACK)

# Getters for external access
func is_in_menu() -> bool:
	return in_menu

func is_in_turn_transition() -> bool:
	return in_turn_transition

func get_selected_player_count() -> int:
	return selected_player_count

func get_next_player_id() -> int:
	return next_player_id

# Signal handler
func _on_transition_start():
	transition_started.emit()

# Cleanup method
func cleanup():
	if transition_button and is_instance_valid(transition_button):
		transition_button.queue_free()
	
	main_node = null
	transition_button = null
	menu_options.clear()