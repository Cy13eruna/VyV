extends Node

# UI management system for V&V game
# Handles creation, positioning, and updates of all UI elements

signal skip_turn_requested
signal ui_element_created(element_name: String, element: Control)

# UI element references
var skip_turn_button: Button
var action_label: Label
var unit1_label: Label
var unit2_label: Label
var unit1_name_label: Label
var unit2_name_label: Label
var unit1_domain_label: Label
var unit2_domain_label: Label

# Parent node reference
var parent_node: Node2D

# Game state for UI updates
var current_player: int = 1
var unit1_actions: int = 1
var unit2_actions: int = 1
var unit1_domain_power: int = 1
var unit2_domain_power: int = 1
var fog_of_war: bool = true

# Unit data
var unit1_name: String = ""
var unit2_name: String = ""
var unit1_domain_name: String = ""
var unit2_domain_name: String = ""

# Position data
var points: Array = []
var unit1_position: int = 0
var unit2_position: int = 0
var unit1_domain_center: int = 0
var unit2_domain_center: int = 0
var unit1_force_revealed: bool = false
var unit2_force_revealed: bool = false

# Initialize UI system
func initialize(game_parent: Node2D, game_points: Array) -> void:
	parent_node = game_parent
	points = game_points
	print("🖥️ UISystem initialized with parent node and %d points" % points.size())

# Create all UI elements
func create_ui_elements() -> void:
	_create_unit_labels()
	_create_name_labels()
	_create_game_ui()
	print("🖥️ UISystem: All UI elements created")

# Create unit emoji labels
func _create_unit_labels() -> void:
	# Unit 1 label (red emoji)
	unit1_label = Label.new()
	unit1_label.text = "🚶🏻‍♀️"  # Walking person emoji
	unit1_label.add_theme_font_size_override("font_size", 24)
	unit1_label.modulate = Color(1.0, 0.0, 0.0)  # Red using modulate
	parent_node.add_child(unit1_label)
	ui_element_created.emit("unit1_label", unit1_label)
	
	# Unit 2 label (violet emoji)
	unit2_label = Label.new()
	unit2_label.text = "🚶🏻‍♀️"  # Walking person emoji
	unit2_label.add_theme_font_size_override("font_size", 24)
	unit2_label.modulate = Color(0.5, 0.0, 0.8)  # Violet using modulate
	parent_node.add_child(unit2_label)
	ui_element_created.emit("unit2_label", unit2_label)

# Create name labels for units and domains
func _create_name_labels() -> void:
	# Domain 1 label
	unit1_domain_label = Label.new()
	unit1_domain_label.text = unit1_domain_name
	unit1_domain_label.add_theme_font_size_override("font_size", 12)
	unit1_domain_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	parent_node.add_child(unit1_domain_label)
	ui_element_created.emit("unit1_domain_label", unit1_domain_label)
	
	# Domain 2 label
	unit2_domain_label = Label.new()
	unit2_domain_label.text = unit2_domain_name
	unit2_domain_label.add_theme_font_size_override("font_size", 12)
	unit2_domain_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	parent_node.add_child(unit2_domain_label)
	ui_element_created.emit("unit2_domain_label", unit2_domain_label)
	
	# Unit 1 name label
	unit1_name_label = Label.new()
	unit1_name_label.text = unit1_name
	unit1_name_label.add_theme_font_size_override("font_size", 10)
	unit1_name_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	parent_node.add_child(unit1_name_label)
	ui_element_created.emit("unit1_name_label", unit1_name_label)
	
	# Unit 2 name label
	unit2_name_label = Label.new()
	unit2_name_label.text = unit2_name
	unit2_name_label.add_theme_font_size_override("font_size", 10)
	unit2_name_label.add_theme_color_override("font_color", Color(0.5, 0.0, 0.8))
	parent_node.add_child(unit2_name_label)
	ui_element_created.emit("unit2_name_label", unit2_name_label)

# Create game UI (buttons, action display)
func _create_game_ui() -> void:
	# Skip Turn button
	skip_turn_button = Button.new()
	skip_turn_button.text = "Skip Turn"
	skip_turn_button.size = Vector2(100, 40)
	skip_turn_button.position = Vector2(680, 20)  # Top right corner
	skip_turn_button.pressed.connect(_on_skip_turn_pressed)
	parent_node.add_child(skip_turn_button)
	ui_element_created.emit("skip_turn_button", skip_turn_button)
	
	# Action label
	action_label = Label.new()
	action_label.text = "Player 1 (Red)\nActions: 1"
	action_label.position = Vector2(580, 70)
	action_label.add_theme_font_size_override("font_size", 14)
	parent_node.add_child(action_label)
	ui_element_created.emit("action_label", action_label)

# Update game state for UI
func update_game_state(state_data: Dictionary) -> void:
	if state_data.has("current_player"):
		current_player = state_data.current_player
	if state_data.has("unit1_actions"):
		unit1_actions = state_data.unit1_actions
	if state_data.has("unit2_actions"):
		unit2_actions = state_data.unit2_actions
	if state_data.has("unit1_domain_power"):
		unit1_domain_power = state_data.unit1_domain_power
	if state_data.has("unit2_domain_power"):
		unit2_domain_power = state_data.unit2_domain_power
	if state_data.has("fog_of_war"):
		fog_of_war = state_data.fog_of_war
	if state_data.has("unit1_position"):
		unit1_position = state_data.unit1_position
	if state_data.has("unit2_position"):
		unit2_position = state_data.unit2_position
	if state_data.has("unit1_domain_center"):
		unit1_domain_center = state_data.unit1_domain_center
	if state_data.has("unit2_domain_center"):
		unit2_domain_center = state_data.unit2_domain_center
	if state_data.has("unit1_force_revealed"):
		unit1_force_revealed = state_data.unit1_force_revealed
	if state_data.has("unit2_force_revealed"):
		unit2_force_revealed = state_data.unit2_force_revealed

# Set unit and domain names
func set_names(unit1_name_val: String, unit2_name_val: String, unit1_domain_val: String, unit2_domain_val: String) -> void:
	unit1_name = unit1_name_val
	unit2_name = unit2_name_val
	unit1_domain_name = unit1_domain_val
	unit2_domain_name = unit2_domain_val
	
	# Update labels if they exist
	if unit1_name_label:
		unit1_name_label.text = unit1_name
	if unit2_name_label:
		unit2_name_label.text = unit2_name
	if unit1_domain_label:
		unit1_domain_label.text = unit1_domain_name
	if unit2_domain_label:
		unit2_domain_label.text = unit2_domain_name

# Update all UI positions and visibility
func update_ui() -> void:
	_update_units_visibility_and_position()
	_update_action_display()

# Update unit positions and visibility
func _update_units_visibility_and_position() -> void:
	if not unit1_label or not unit2_label or points.size() == 0:
		return
	
	# Update unit 1
	if unit1_position < points.size():
		var unit1_pos = points[unit1_position]
		unit1_label.position = unit1_pos + Vector2(-12, -35)  # Center emoji above point
		
		# Unit 1 visibility logic
		if not fog_of_war:
			unit1_label.visible = true
		elif current_player == 1:
			unit1_label.visible = true
		elif unit1_force_revealed:
			unit1_label.visible = true
		else:
			unit1_label.visible = _is_point_visible_to_current_unit(unit1_position)
	
	# Update unit 2
	if unit2_position < points.size():
		var unit2_pos = points[unit2_position]
		unit2_label.position = unit2_pos + Vector2(-12, -35)  # Center emoji above point
		
		# Unit 2 visibility logic
		if not fog_of_war:
			unit2_label.visible = true
		elif current_player == 2:
			unit2_label.visible = true
		elif unit2_force_revealed:
			unit2_label.visible = true
		else:
			unit2_label.visible = _is_point_visible_to_current_unit(unit2_position)
	
	# Update name positions
	_update_name_positions()

# Update name label positions
func _update_name_positions() -> void:
	if points.size() == 0:
		return
	
	# Position unit names
	if unit1_name_label and unit1_position < points.size():
		var unit1_pos = points[unit1_position]
		unit1_name_label.position = unit1_pos + Vector2(-15, 15)  # Below unit
		unit1_name_label.visible = unit1_label.visible if unit1_label else false
	
	if unit2_name_label and unit2_position < points.size():
		var unit2_pos = points[unit2_position]
		unit2_name_label.position = unit2_pos + Vector2(-15, 15)  # Below unit
		unit2_name_label.visible = unit2_label.visible if unit2_label else false
	
	# Position domain names and update power
	if unit1_domain_label and unit1_domain_center < points.size():
		var domain1_pos = points[unit1_domain_center]
		unit1_domain_label.position = domain1_pos + Vector2(-30, 35)  # Below domain
		unit1_domain_label.text = "%s ⚡%d" % [unit1_domain_name, unit1_domain_power]
		unit1_domain_label.visible = _is_domain_visible(unit1_domain_center) or not fog_of_war
	
	if unit2_domain_label and unit2_domain_center < points.size():
		var domain2_pos = points[unit2_domain_center]
		unit2_domain_label.position = domain2_pos + Vector2(-30, 35)  # Below domain
		unit2_domain_label.text = "%s ⚡%d" % [unit2_domain_name, unit2_domain_power]
		unit2_domain_label.visible = _is_domain_visible(unit2_domain_center) or not fog_of_war

# Update action display
func _update_action_display() -> void:
	if action_label:
		var player_name = "Player 1 (Red)" if current_player == 1 else "Player 2 (Violet)"
		var actions = unit1_actions if current_player == 1 else unit2_actions
		action_label.text = "%s\nActions: %d" % [player_name, actions]

# Skip turn button callback
func _on_skip_turn_pressed() -> void:
	print("🖥️ UISystem: Skip Turn button pressed")
	skip_turn_requested.emit()

# Visibility helper functions - proper fog of war implementation
func _is_point_visible_to_current_unit(point_index: int) -> bool:
	# Get current unit position
	var current_unit_pos = unit1_position if current_player == 1 else unit2_position
	
	# Use GameManager if available for proper visibility logic
	if GameManager:
		return GameManager.is_point_visible_to_unit(point_index, current_unit_pos)
	else:
		# Fallback to local visibility logic
		return _is_point_visible_to_unit_fallback(point_index, current_unit_pos)

func _is_domain_visible(domain_center: int) -> bool:
	# Domain always visible if it belongs to current player
	if (current_player == 1 and domain_center == unit1_domain_center) or \
	   (current_player == 2 and domain_center == unit2_domain_center):
		return true
	
	# For UI purposes, simplified visibility
	return not fog_of_war

# Fallback visibility function when GameManager is not available
func _is_point_visible_to_unit_fallback(point_index: int, unit_pos: int) -> bool:
	# This is a fallback implementation - we need access to paths data
	# For now, we'll use a conservative approach
	if parent_node and parent_node.has_method("_is_point_visible_to_unit"):
		return parent_node._is_point_visible_to_unit(point_index, unit_pos)
	else:
		# Ultra-conservative fallback - only show if same position
		return point_index == unit_pos

# Get UI element references
func get_ui_elements() -> Dictionary:
	return {
		"skip_turn_button": skip_turn_button,
		"action_label": action_label,
		"unit1_label": unit1_label,
		"unit2_label": unit2_label,
		"unit1_name_label": unit1_name_label,
		"unit2_name_label": unit2_name_label,
		"unit1_domain_label": unit1_domain_label,
		"unit2_domain_label": unit2_domain_label
	}

# Get current UI state for debugging
func get_ui_state() -> Dictionary:
	return {
		"current_player": current_player,
		"unit1_actions": unit1_actions,
		"unit2_actions": unit2_actions,
		"unit1_domain_power": unit1_domain_power,
		"unit2_domain_power": unit2_domain_power,
		"fog_of_war": fog_of_war,
		"elements_created": get_ui_elements().size()
	}

# Clean up UI elements
func cleanup() -> void:
	var elements = get_ui_elements()
	for element_name in elements:
		var element = elements[element_name]
		if element and is_instance_valid(element):
			element.queue_free()
	
	print("🖥️ UISystem: Cleanup completed")