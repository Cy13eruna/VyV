# 🏘️ UNIT SETTLER MANAGER
# Purpose: Handle settler technology and domain creation
# Layer: Presentation Manager

extends RefCounted
class_name UnitSettlerManager

# Import dependencies
const UnitGridUtils = preload("res://presentation/managers/unit/unit_grid_utils.gd")
const UnitNameGenerator = preload("res://presentation/managers/unit/unit_name_generator.gd")
const UnitPowerManager = preload("res://presentation/managers/unit/unit_power_manager.gd")

# References
var main_node: Node2D
var dialog_manager
var technology_manager
var selection_manager
var game_state_cache: Dictionary = {}

# Initialize with references
func initialize(main_node_ref: Node2D, dialog_manager_ref, technology_manager_ref, selection_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	technology_manager = technology_manager_ref
	selection_manager = selection_manager_ref

# Set game state reference (temporary solution)
func set_game_state_reference(game_state: Dictionary):
	game_state_cache = game_state

func get_game_state() -> Dictionary:
	return game_state_cache

# Check if unit can use Settler technology
func can_unit_use_settler(unit, game_state: Dictionary) -> bool:
	# Check if player has Settler technology
	if not technology_manager or not technology_manager.has_technology(unit.owner_id, "settler"):
		return false
	
	# Must have at least 1 power in natal domain to establish domain
	var natal_power = UnitPowerManager.get_unit_natal_power(unit, game_state)
	if natal_power < 1:
		return false
	
	# Must not share paths with existing domains (can share at most one star)
	if not UnitGridUtils.can_domain_be_placed_without_sharing_paths(unit, game_state):
		return false
	
	# Check if unit is not on the border of the map
	return UnitGridUtils.is_unit_away_from_border(unit, game_state)

# Show Settler confirmation dialog
func show_settler_confirmation_dialog(unit):
	# Check if there's already a dialog open
	if dialog_manager.has_open_dialog():
		return
	
	var dialog = AcceptDialog.new()
	dialog.title = "Sacrifice Unit to Set a New Domain"
	dialog.dialog_text = "Are you sure you want to sacrifice this unit to create a new domain?"
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Create custom buttons
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var set_button = Button.new()
	set_button.text = "Set"
	set_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create horizontal container for buttons
	var button_container = HBoxContainer.new()
	button_container.add_child(cancel_button)
	button_container.add_child(set_button)
	
	# Add button container to dialog
	dialog.add_child(button_container)
	
	# Add to scene tree (with null safety)
	if main_node and is_instance_valid(main_node):
		main_node.add_child(dialog)
		dialog_manager.current_dialog = dialog  # Track current dialog
	else:
		print("[SETTLER] Error: main_node is null, cannot show dialog")
		dialog.queue_free()
		return
	
	# Show dialog
	dialog.popup_centered()
	
	# Set Cancel as default (focus)
	cancel_button.grab_focus()
	
	# Connect button signals
	cancel_button.pressed.connect(_on_settler_canceled.bind(dialog))
	set_button.pressed.connect(_on_settler_confirmed.bind(dialog, unit))

# Handle Settler confirmation cancellation
func _on_settler_canceled(dialog):
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle Settler confirmation
func _on_settler_confirmed(dialog, unit):
	# Close dialog first
	dialog_manager.clear_current_dialog()
	dialog.queue_free()
	
	# Execute settler action
	execute_settler_action(unit)

# Execute the settler action (sacrifice unit, create domain)
func execute_settler_action(unit):
	var game_state = get_game_state()
	if unit.id in game_state.units:
		# CRITICAL: Check if unit has actions remaining
		if not unit.can_move():
			print("ERROR: Unit has no actions remaining for domain establishment")
			return  # Cannot establish domain without actions
		
		# CONSUME 1 ACTION FOR ESTABLISHING DOMAIN (NEW REQUIREMENT)
		unit.consume_action()
		
		# CONSUME 1 POWER FOR ESTABLISHING DOMAIN (INDEPENDENT OF NATAL DOMAIN)
		# Consume power from unit's natal domain only
		var power_consumed = UnitPowerManager.consume_unit_natal_power(unit, 1, game_state)
		if not power_consumed:
			print("ERROR: Failed to consume power for domain establishment")
			# Restore the action since power consumption failed
			unit.restore_actions()
			return  # Cannot establish domain without power
		
		# Get next available domain ID
		var new_domain_id = 1
		while new_domain_id in game_state.domains:
			new_domain_id += 1
		
		# Generate domain name with unique initial
		var domain_initial = UnitNameGenerator.get_next_available_initial(game_state)
		var domain_name = UnitNameGenerator.generate_domain_name(domain_initial, game_state)
		
		# Create new domain at unit position
		var domain_data = {
			"id": new_domain_id,
			"owner_id": unit.owner_id,
			"name": domain_name,
			"initial": domain_initial,
			"center_position": unit.position,
			"power": 0,  # Start with 0 power (as per i.txt directive)
			"level": 1,  # Start at level I
			"is_occupied": false,
			"occupied_by_player": -1
		}
		
		# Add domain to game state
		game_state.domains[new_domain_id] = domain_data
		
		# Add domain to player
		var player = game_state.players[unit.owner_id]
		player.add_domain(new_domain_id)
		
		# Remove unit from game state
		game_state.units.erase(unit.id)
		
		# Remove unit from player
		player.remove_unit(unit.id)
		
		# Clear selection if this was the selected unit
		if selection_manager and selection_manager.get_selected_unit_id() == unit.id:
			selection_manager.clear_selection()
		
		# Redraw (with null safety)
		if main_node and is_instance_valid(main_node):
			main_node.queue_redraw()
		else:
			print("[SETTLER] Warning: main_node is null, cannot redraw")

# Cleanup method
func cleanup():
	main_node = null
	dialog_manager = null
	technology_manager = null
	selection_manager = null
	game_state_cache.clear()