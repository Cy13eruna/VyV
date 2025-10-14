# 🔧 DOMAIN UPGRADE HANDLER
# Purpose: Handle domain upgrade system (VAGABOND, TECH, HARVEST, FISH)
# Layer: Presentation Manager - Domain Upgrades

extends RefCounted
class_name DomainUpgradeHandler

# Import dependencies
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D
var dialog_manager
var technology_manager
var unit_manager

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, technology_manager_ref, unit_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	technology_manager = technology_manager_ref
	unit_manager = unit_manager_ref

# Show nuclear star dialog (upgrade system)
func show_nuclear_star_dialog(clicked_domain, game_state: Dictionary):
	# Check if there's already a dialog open
	if dialog_manager.has_open_dialog():
		return
	
	if not clicked_domain:
		return
	
	# Calculate upgrade cost
	var domain_level = clicked_domain.get("level", 1)
	var upgrade_cost = domain_level
	
	# Create dialog using centralized styling
	var dialog = GameDialogStrings.create_styled_dialog(
		"Choose an Upgrade!",
		"Domain Enhancement",
		"Cost: %d ⭐" % upgrade_cost
	)
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Get the main container from the dialog
	var main_container = null
	for child in dialog.get_children():
		if child is VBoxContainer:
			main_container = child
			break
	
	# Get current player to check technologies
	var TurnService = load("res://application/services/turn_service_clean.gd")
	var current_player = TurnService.get_current_player(game_state.turn_data, game_state.players)
	
	# Create VAGABOND button
	var vagabond_button = Button.new()
	vagabond_button.text = "🚶🏻‍♀️\nVAGABOND"
	vagabond_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Apply black text styling
	GameDialogStrings.apply_button_style(vagabond_button)
	
	var tech_button = Button.new()
	tech_button.text = "💫\nTECH"
	tech_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Apply black text styling
	GameDialogStrings.apply_button_style(tech_button)
	
	# Create harvest button if player has harvest technology
	var harvest_button = null
	if current_player and technology_manager and technology_manager.has_technology(current_player.id, "harvest"):
		harvest_button = Button.new()
		harvest_button.text = "🧺\nHARVEST"
		harvest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(harvest_button)
		
		# Check if harvest can be used on this domain
		if not can_use_harvest_on_domain(clicked_domain, game_state):
			harvest_button.disabled = true
			harvest_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
	
	# Create fish button if player has fish technology
	var fish_button = null
	if current_player and technology_manager and technology_manager.has_technology(current_player.id, "fish"):
		fish_button = Button.new()
		fish_button.text = "🎣\nFISH"
		fish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(fish_button)
		
		# Check if fish can be used on this domain (only once per domain)
		if not can_use_fish_on_domain(clicked_domain, game_state):
			fish_button.disabled = true
			fish_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
	
	# Create market button if player has market technology
	var market_button = null
	if current_player and technology_manager and technology_manager.has_technology(current_player.id, "market"):
		market_button = Button.new()
		market_button.text = "🤝🏻\nMARKET"
		market_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(market_button)
		
		# Check if market can be used on this domain (only once per domain)
		if not can_use_market_on_domain(clicked_domain, game_state):
			market_button.disabled = true
			market_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
	
	# Create hamlet button if player has hamlet technology
	var hamlet_button = null
	if current_player and technology_manager and technology_manager.has_technology(current_player.id, "hamlet"):
		hamlet_button = Button.new()
		hamlet_button.text = "🏡\nHAMLET"
		hamlet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Apply black text styling
		GameDialogStrings.apply_button_style(hamlet_button)
		
		# Check if hamlet can be used on this domain
		if not can_use_hamlet_on_domain(clicked_domain, game_state):
			hamlet_button.disabled = true
			hamlet_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
	
	# Create horizontal container for buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", GameDialogStrings.BUTTON_SPACING)
	button_container.add_child(vagabond_button)
	button_container.add_child(tech_button)
	if harvest_button:
		button_container.add_child(harvest_button)
	if fish_button:
		button_container.add_child(fish_button)
	if market_button:
		button_container.add_child(market_button)
	if hamlet_button:
		button_container.add_child(hamlet_button)
	
	# Add button container to main container (if found) or dialog directly
	if main_container:
		main_container.add_child(button_container)
	else:
		dialog.add_child(button_container)
	
	# Add to scene tree
	main_node.add_child(dialog)
	dialog_manager.current_dialog = dialog  # Track current dialog
	
	# Show dialog with universal centering
	GameDialogStrings.center_dialog(dialog)
	
	# Set VAGABOND as default (focus) - after adding to tree
	vagabond_button.grab_focus()
	
	# Connect button signals
	vagabond_button.pressed.connect(_on_vagabond_upgrade.bind(dialog, clicked_domain))
	tech_button.pressed.connect(_on_tech_upgrade.bind(dialog, clicked_domain))
	if harvest_button:
		if harvest_button.disabled:
			harvest_button.pressed.connect(_on_harvest_unavailable.bind(dialog))
		else:
			harvest_button.pressed.connect(_on_harvest_upgrade.bind(dialog, clicked_domain, game_state))
	if fish_button:
		if fish_button.disabled:
			fish_button.pressed.connect(_on_fish_unavailable.bind(dialog))
		else:
			fish_button.pressed.connect(_on_fish_upgrade.bind(dialog, clicked_domain, game_state))
	if market_button:
		if market_button.disabled:
			market_button.pressed.connect(_on_market_unavailable.bind(dialog))
		else:
			market_button.pressed.connect(_on_market_upgrade.bind(dialog, clicked_domain, game_state))
	if hamlet_button:
		if hamlet_button.disabled:
			hamlet_button.pressed.connect(_on_hamlet_unavailable.bind(dialog))
		else:
			hamlet_button.pressed.connect(_on_hamlet_upgrade.bind(dialog, clicked_domain, game_state))

# Handle VAGABOND upgrade
func _on_vagabond_upgrade(dialog, domain):
	# Execute VAGABOND upgrade: UP + spawn new unit at center
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Execute base upgrade
		domain.power -= domain_level
		domain.level += 1
		
		# VAGABOND bonus: spawn new unit at domain center
		unit_manager.spawn_unit_at_domain_center(domain)
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle TECH upgrade
func _on_tech_upgrade(dialog, domain):
	# Check TECH upgrade: Verify power but don't consume yet
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Close upgrade dialog
		dialog_manager.clear_current_dialog()
		dialog.queue_free()
		
		# Wait a frame before opening technology selection to avoid dialog conflicts
		await main_node.get_tree().process_frame
		
		# Open technology selection screen with domain reference for later upgrade
		technology_manager.show_technology_selection_with_upgrade(domain.owner_id, domain)
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	else:
		dialog_manager.clear_current_dialog()
		dialog.queue_free()

# Handle Harvest upgrade
func _on_harvest_upgrade(dialog, domain, game_state: Dictionary):
	# Execute HARVEST upgrade: UP + add harvest to random forest + increase power generation
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Execute base upgrade
		domain.power -= domain_level
		domain.level += 1
		
		# HARVEST bonus: add harvest emoji to random forest
		apply_harvest_to_random_forest(domain, game_state)
		
		# Increase domain power generation
		var power_per_turn = domain.get("power_per_turn", 0)
		domain.power_per_turn = power_per_turn + 1
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle Fish upgrade
func _on_fish_upgrade(dialog, domain, game_state: Dictionary):
	# Execute FISH upgrade: UP + add fish bonus + mark domain as having fish
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Execute base upgrade
		domain.power -= domain_level
		domain.level += 1
		
		# FISH bonus: calculate random bonus based on water count
		apply_fish_to_domain(domain, game_state)
		
		# Mark domain as having fish upgrade (can only be used once)
		domain.has_fish_upgrade = true
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Check if harvest can be used on a domain
func can_use_harvest_on_domain(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Get all forest edges connected to this domain
	var forest_edges = get_domain_forest_edges(domain, game_state)
	
	# Check if there are any forests without harvest emoji
	for edge_id in forest_edges:
		var edge = game_state.grid.edges[edge_id]
		var structures = edge.get("structures", [])
		
		# Check if this forest doesn't have harvest emoji
		var has_harvest = false
		for structure in structures:
			if structure.get("type", "") == "harvest":
				has_harvest = true
				break
		
		if not has_harvest:
			return true  # Found at least one forest without harvest
	
	return false  # All forests already have harvest

# Check if fish can be used on a domain
func can_use_fish_on_domain(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Check if domain already has fish upgrade (can only be used once)
	if domain.get("has_fish_upgrade", false):
		return false
	
	# Check if domain has any water edges (block fish for dry domains)
	var water_edges = get_domain_water_edges(domain, game_state)
	if water_edges.size() == 0:
		return false  # Domain is dry, block fish
	
	return true  # Domain has water, allow fish

# Check if market can be used on a domain
func can_use_market_on_domain(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Check if domain already has market upgrade (can only be used once)
	if domain.get("has_market_upgrade", false):
		return false
	
	return true  # Domain can have market

# Check if hamlet can be used on a domain
func can_use_hamlet_on_domain(domain, game_state: Dictionary) -> bool:
	if not domain:
		return false
	
	# Get all grassland edges connected to this domain
	var grassland_edges = get_domain_grassland_edges(domain, game_state)
	
	# Check if there are any grasslands without hamlet structures
	for edge_id in grassland_edges:
		var edge = game_state.grid.edges[edge_id]
		var structures = edge.get("structures", [])
		
		# Check if this grassland doesn't have hamlet structure
		var has_hamlet = false
		for structure in structures:
			if structure.get("type", "") == "hamlet":
				has_hamlet = true
				break
		
		if not has_hamlet:
			return true  # Found at least one grassland without hamlet
	
	return false  # All grasslands already have hamlet or no grasslands

# Get all forest edges connected to a domain
func get_domain_forest_edges(domain, game_state: Dictionary) -> Array:
	var forest_edges = []
	
	if not ("grid" in game_state):
		return forest_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return forest_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# 1. Radial forest edges (center to neighbors)
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 1:  # 1 = FOREST
			forest_edges.append(edge_id)
	
	# 2. Perimeter forest edges (neighbor to neighbor)
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 1:  # 1 = FOREST
						forest_edges.append(edge_id)
					break
	
	return forest_edges

# Get all water edges connected to a domain
func get_domain_water_edges(domain, game_state: Dictionary) -> Array:
	var water_edges = []
	
	if not ("grid" in game_state):
		return water_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return water_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# 1. Radial water edges (center to neighbors)
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 3:  # 3 = WATER
			water_edges.append(edge_id)
	
	# 2. Perimeter water edges (neighbor to neighbor)
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 3:  # 3 = WATER
						water_edges.append(edge_id)
					break
	
	return water_edges

# Get all grassland edges connected to a domain
func get_domain_grassland_edges(domain, game_state: Dictionary) -> Array:
	var grassland_edges = []
	
	if not ("grid" in game_state):
		return grassland_edges
	
	# Find the domain center point
	var domain_center_point = null
	for point_id in game_state.grid.points:
		var point = game_state.grid.points[point_id]
		if point.position.equals(domain.center_position):
			domain_center_point = point
			break
	
	if not domain_center_point:
		return grassland_edges
	
	# Get neighbor points
	var neighbor_points = []
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		var other_point_id = edge.point_b_id if edge.point_a_id == domain_center_point.id else edge.point_a_id
		if other_point_id in game_state.grid.points:
			neighbor_points.append(game_state.grid.points[other_point_id])
	
	# 1. Radial grassland edges (center to neighbors)
	for edge_id in domain_center_point.connected_edges:
		var edge = game_state.grid.edges[edge_id]
		if edge.get("terrain_type", 0) == 0:  # 0 = FIELD/GRASSLAND
			grassland_edges.append(edge_id)
	
	# 2. Perimeter grassland edges (neighbor to neighbor)
	var checked_perimeter_edges = []
	for i in range(neighbor_points.size()):
		var neighbor = neighbor_points[i]
		for edge_id in neighbor.connected_edges:
			if edge_id in checked_perimeter_edges or edge_id in domain_center_point.connected_edges:
				continue
			
			var edge = game_state.grid.edges[edge_id]
			var other_point_id = edge.point_b_id if edge.point_a_id == neighbor.id else edge.point_a_id
			
			# Check if connects to another neighbor
			for j in range(neighbor_points.size()):
				if neighbor_points[j].id == other_point_id:
					checked_perimeter_edges.append(edge_id)
					if edge.get("terrain_type", 0) == 0:  # 0 = FIELD/GRASSLAND
						grassland_edges.append(edge_id)
					break
	
	return grassland_edges

# Apply harvest to a random forest in the domain
func apply_harvest_to_random_forest(domain, game_state: Dictionary):
	# Get all forest edges that don't have harvest yet
	var available_forests = []
	var forest_edges = get_domain_forest_edges(domain, game_state)
	
	for edge_id in forest_edges:
		var edge = game_state.grid.edges[edge_id]
		var structures = edge.get("structures", [])
		
		# Check if this forest doesn't have harvest emoji
		var has_harvest = false
		for structure in structures:
			if structure.get("type", "") == "harvest":
				has_harvest = true
				break
		
		if not has_harvest:
			available_forests.append(edge_id)
	
	# Select random forest and add harvest structure
	if available_forests.size() > 0:
		var random_forest_id = available_forests[randi() % available_forests.size()]
		var forest_edge = game_state.grid.edges[random_forest_id]
		
		# Initialize structures array if it doesn't exist
		if not ("structures" in forest_edge):
			forest_edge.structures = []
		
		# Add harvest structure
		var harvest_structure = {
			"type": "harvest",
			"emoji": "🧺",
			"owner_id": domain.owner_id
		}
		forest_edge.structures.append(harvest_structure)

# Apply fish upgrade to domain (no immediate power grant). Power is produced only at start of turns.
func apply_fish_to_domain(domain, game_state: Dictionary):
	# Get all water edges in the domain
	var water_edges = get_domain_water_edges(domain, game_state)
	var water_count = water_edges.size()
	
	if water_count > 0:
		# Store water count for random bonus calculation each turn
		domain.fish_water_count = water_count
		
		# Do NOT grant immediate power. Fish should only produce at the start of each turn.
		# Reset current turn fish bonus display/state to 0 on installation.
		domain.current_fish_bonus = 0
		# Clear any fish emoji positions until the next turn applies a bonus.
		domain.fish_emoji_positions = []

# Apply market bonus to domain
func apply_market_to_domain(domain, game_state: Dictionary):
	# Get power generated this turn (power_per_turn)
	var power_generated_this_turn = domain.get("power_per_turn", 0)
	
	# Duplicate the power generated this turn
	var market_bonus = power_generated_this_turn
	domain.power += market_bonus
	
	# Store market bonus for display/tracking
	domain.current_market_bonus = market_bonus
	
	# Add domain to global market network for power sharing
	if not ("market_domains" in game_state):
		game_state.market_domains = []
	
	# Add this domain to the market network if not already there
	var domain_id = domain.get("id", -1)
	if domain_id != -1 and domain_id not in game_state.market_domains:
		game_state.market_domains.append(domain_id)
	
	print("[MARKET] Domain ", domain_id, " joined market network. Bonus: ", market_bonus, " power")

# Generate fixed emoji positions for initial fish application
func generate_initial_fish_emoji_positions(domain, fish_bonus: int):
	# Use same logic as turn service to ensure consistency
	var domain_id = domain.get("id", 1)
	var water_count = domain.get("fish_water_count", 0)
	
	if water_count > 0 and fish_bonus > 0:
		# Create deterministic sequence based on domain ID and current bonus
		var rng = RandomNumberGenerator.new()
		rng.seed = domain_id * 1000 + fish_bonus  # Same seed logic as turn service
		
		# Generate fixed positions for this bonus amount
		var productive_positions = []
		for i in range(min(fish_bonus, water_count)):
			productive_positions.append(rng.randi() % water_count)
		
		# Remove duplicates and ensure we have exactly fish_bonus positions
		var unique_positions = []
		for pos in productive_positions:
			if pos not in unique_positions:
				unique_positions.append(pos)
		
		# If we need more positions due to duplicates, add remaining ones
		while unique_positions.size() < fish_bonus and unique_positions.size() < water_count:
			for i in range(water_count):
				if i not in unique_positions:
					unique_positions.append(i)
					if unique_positions.size() >= fish_bonus:
						break
		
		# Store the fixed positions in the domain
		domain.fish_emoji_positions = unique_positions.slice(0, fish_bonus)

# Apply hamlet to a random grassland in the domain
func apply_hamlet_to_random_grassland(domain, game_state: Dictionary):
	# Get all grassland edges that don't have hamlet yet
	var available_grasslands = []
	var grassland_edges = get_domain_grassland_edges(domain, game_state)
	
	for edge_id in grassland_edges:
		var edge = game_state.grid.edges[edge_id]
		var structures = edge.get("structures", [])
		
		# Check if this grassland doesn't have hamlet structure
		var has_hamlet = false
		for structure in structures:
			if structure.get("type", "") == "hamlet":
				has_hamlet = true
				break
		
		if not has_hamlet:
			available_grasslands.append(edge_id)
	
	# Select random grassland and add hamlet structure
	if available_grasslands.size() > 0:
		var random_grassland_id = available_grasslands[randi() % available_grasslands.size()]
		var grassland_edge = game_state.grid.edges[random_grassland_id]
		
		# Initialize structures array if it doesn't exist
		if not ("structures" in grassland_edge):
			grassland_edge.structures = []
		
		# Add hamlet structure
		var hamlet_structure = {
			"type": "hamlet",
			"emoji": "🏡",
			"owner_id": domain.owner_id
		}
		grassland_edge.structures.append(hamlet_structure)

# Handle harvest unavailable (show explanation)
func _on_harvest_unavailable(dialog):
	# Close current dialog
	dialog_manager.clear_current_dialog()
	dialog.queue_free()
	
	# Wait a frame before showing explanation
	await main_node.get_tree().process_frame
	
	# Show explanation dialog
	var explanation_dialog = AcceptDialog.new()
	explanation_dialog.title = "Harvest Unavailable"
	explanation_dialog.dialog_text = "All forests in this domain already have harvest 🧺. You cannot use Harvest upgrade on this domain anymore."
	
	# Apply styling
	GameDialogStrings.apply_dialog_style(explanation_dialog)
	
	# Add to scene tree and show
	main_node.add_child(explanation_dialog)
	dialog_manager.current_dialog = explanation_dialog
	GameDialogStrings.center_dialog(explanation_dialog)
	
	# Connect OK button to close
	explanation_dialog.get_ok_button().pressed.connect(_on_explanation_closed.bind(explanation_dialog))

# Handle market upgrade
func _on_market_upgrade(dialog, domain, game_state: Dictionary):
	# Execute MARKET upgrade: UP + duplicate power generated this turn + enable power sharing
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Execute base upgrade
		domain.power -= domain_level
		domain.level += 1
		
		# MARKET bonus: duplicate power generated this turn
		apply_market_to_domain(domain, game_state)
		
		# Mark domain as having market upgrade (can only be used once)
		domain.has_market_upgrade = true
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle fish unavailable (show explanation)
func _on_fish_unavailable(dialog):
	# Close current dialog
	dialog_manager.clear_current_dialog()
	dialog.queue_free()
	
	# Wait a frame before showing explanation
	await main_node.get_tree().process_frame
	
	# Show explanation dialog
	var explanation_dialog = AcceptDialog.new()
	explanation_dialog.title = "Fish Unavailable"
	explanation_dialog.dialog_text = "This domain is dry (no water bodies) or already has Fish upgrade. Fish can only be used once per domain and requires water edges."
	
	# Apply styling
	GameDialogStrings.apply_dialog_style(explanation_dialog)
	
	# Add to scene tree and show
	main_node.add_child(explanation_dialog)
	dialog_manager.current_dialog = explanation_dialog
	GameDialogStrings.center_dialog(explanation_dialog)
	
	# Connect OK button to close
	explanation_dialog.get_ok_button().pressed.connect(_on_explanation_closed.bind(explanation_dialog))

# Handle market unavailable (show explanation)
func _on_market_unavailable(dialog):
	# Close current dialog
	dialog_manager.clear_current_dialog()
	dialog.queue_free()
	
	# Wait a frame before showing explanation
	await main_node.get_tree().process_frame
	
	# Show explanation dialog
	var explanation_dialog = AcceptDialog.new()
	explanation_dialog.title = "Market Unavailable"
	explanation_dialog.dialog_text = "This domain already has Market upgrade. Market can only be used once per domain."
	
	# Apply styling
	GameDialogStrings.apply_dialog_style(explanation_dialog)
	
	# Add to scene tree and show
	main_node.add_child(explanation_dialog)
	dialog_manager.current_dialog = explanation_dialog
	GameDialogStrings.center_dialog(explanation_dialog)
	
	# Connect OK button to close
	explanation_dialog.get_ok_button().pressed.connect(_on_explanation_closed.bind(explanation_dialog))

# Handle hamlet upgrade
func _on_hamlet_upgrade(dialog, domain, game_state: Dictionary):
	# Execute HAMLET upgrade: UP + add hamlet to random grassland + increase power generation
	var domain_level = domain.get("level", 1)
	var domain_power = domain.get("power", 1)
	
	# Check if player has enough power
	if domain_power >= domain_level:
		# Execute base upgrade
		domain.power -= domain_level
		domain.level += 1
		
		# HAMLET bonus: add hamlet structure to random grassland
		apply_hamlet_to_random_grassland(domain, game_state)
		
		# Increase domain power generation
		var power_per_turn = domain.get("power_per_turn", 0)
		domain.power_per_turn = power_per_turn + 1
		
		# Trigger redraw to update display
		main_node.queue_redraw()
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle hamlet unavailable (show explanation)
func _on_hamlet_unavailable(dialog):
	# Close current dialog
	dialog_manager.clear_current_dialog()
	dialog.queue_free()
	
	# Wait a frame before showing explanation
	await main_node.get_tree().process_frame
	
	# Show explanation dialog
	var explanation_dialog = AcceptDialog.new()
	explanation_dialog.title = "Hamlet Unavailable"
	explanation_dialog.dialog_text = "All grasslands in this domain already have hamlet structures 🏡. You cannot use Hamlet upgrade on this domain anymore."
	
	# Apply styling
	GameDialogStrings.apply_dialog_style(explanation_dialog)
	
	# Add to scene tree and show
	main_node.add_child(explanation_dialog)
	dialog_manager.current_dialog = explanation_dialog
	GameDialogStrings.center_dialog(explanation_dialog)
	
	# Connect OK button to close
	explanation_dialog.get_ok_button().pressed.connect(_on_explanation_closed.bind(explanation_dialog))

# Handle explanation dialog close
func _on_explanation_closed(dialog):
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Cleanup method
func cleanup():
	main_node = null
	dialog_manager = null
	technology_manager = null
	unit_manager = null