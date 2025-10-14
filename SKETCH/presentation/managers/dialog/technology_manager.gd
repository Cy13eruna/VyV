# 🔬 TECHNOLOGY MANAGER
# Purpose: Technology system management and UI
# Layer: Presentation Manager

extends RefCounted
class_name TechnologyManager

# Import dependencies
const GameDialogStrings = preload("res://presentation/constants/game_dialog_strings.gd")

# References
var main_node: Node2D
var dialog_manager

# Dialog management
var current_details_dialog = null  # Track current details dialog

# Technology system
var player_technologies: Dictionary = {}  # player_id -> [tech_names]
var pending_upgrade_domain = null  # Domain waiting for upgrade after tech selection

# Show technology selection screen
func show_technology_selection(player_id: int):
	# Check if there's already a dialog open
	if dialog_manager.has_open_dialog():
		return
	
	# Create custom dialog for technology selection
	var dialog = AcceptDialog.new()
	dialog.title = "Choose Technology"
	dialog.dialog_text = "Select a technology to research:"
	
	# Apply universal dialog styling
	GameDialogStrings.apply_dialog_style(dialog)
	
	# Hide default OK button
	dialog.get_ok_button().visible = false
	
	# Create main container
	var main_container = VBoxContainer.new()
	
	# Create circular technology layout
	var tech_container = Control.new()
	tech_container.custom_minimum_size = Vector2(400, 400)
	
	# Available technologies - EXPANDED TREE
	# Base technologies (Tier 1)
	var base_techs = [
		{"name": "settler", "emoji": "🚩", "display": "Settler", "tier": 1},
		{"name": "harvest", "emoji": "🧺", "display": "Harvest", "tier": 1},
		{"name": "healer", "emoji": "♥", "display": "Healer", "tier": 1},
		{"name": "fighter", "emoji": "🗡", "display": "Fighter", "tier": 1},
		{"name": "fish", "emoji": "🎣", "display": "Fish", "tier": 1}
	]
	
	# Advanced technologies (Tier 2) - Each base tech branches into two
	var advanced_techs = [
		# Settler branches
		{"name": "rider", "emoji": "🐎", "display": "Rider", "tier": 2, "requires": "settler"},
		{"name": "market", "emoji": "🤝🏻", "display": "Market", "tier": 2, "requires": "settler"},
		# Harvest branches
		{"name": "climber", "emoji": "⛰", "display": "Climber", "tier": 2, "requires": "harvest"},
		{"name": "hamlet", "emoji": "🏘", "display": "Hamlet", "tier": 2, "requires": "harvest"},
		# Healer branches
		{"name": "shaman", "emoji": "🪽", "display": "Shaman", "tier": 2, "requires": "healer"},
		{"name": "guardian", "emoji": "🛡", "display": "Guardian", "tier": 2, "requires": "healer"},
		# Fighter branches
		{"name": "warrior", "emoji": "🪓", "display": "Warrior", "tier": 2, "requires": "fighter"},
		{"name": "archer", "emoji": "🏹", "display": "Archer", "tier": 2, "requires": "fighter"},
		# Fish branches
		{"name": "sailor", "emoji": "〰", "display": "Sailor", "tier": 2, "requires": "fish"},
		{"name": "whale", "emoji": "🐋", "display": "Whale", "tier": 2, "requires": "fish"}
	]
	
	# Combine all available technologies
	var available_techs = base_techs + advanced_techs
	
	# Get player's existing technologies
	var player_techs = player_technologies.get(player_id, [])
	
	# Create center VAGABOND
	var center_container = VBoxContainer.new()
	center_container.position = Vector2(175, 175)  # Center of 400x400
	center_container.size = Vector2(50, 50)
	
	var center_emoji = Label.new()
	center_emoji.text = "🚶🏻‍♀️"
	center_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_emoji.add_theme_font_size_override("font_size", 24)
	
	var center_label = Label.new()
	center_label.text = "VAGABOND"
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 10)
	
	center_container.add_child(center_emoji)
	center_container.add_child(center_label)
	tech_container.add_child(center_container)
	
	# Create technology buttons in two-tier circular layout
	var center_pos = Vector2(200, 200)
	
	# Store positions for drawing connections
	var tech_positions = {}
	
	# Tier 1 (Base technologies) - Inner circle
	var tier1_radius = 80
	for i in range(base_techs.size()):
		var tech = base_techs[i]
		var angle = (i * 2 * PI) / base_techs.size() - PI/2  # Start from top
		var pos = center_pos + Vector2(cos(angle), sin(angle)) * tier1_radius
		tech_positions[tech.name] = pos
		
		_create_technology_button(tech_container, tech, pos, player_techs, dialog, player_id)
	
	# Tier 2 (Advanced technologies) - Outer circle
	var tier2_radius = 150
	for i in range(advanced_techs.size()):
		var tech = advanced_techs[i]
		var angle = (i * 2 * PI) / advanced_techs.size() - PI/2  # Start from top
		var pos = center_pos + Vector2(cos(angle), sin(angle)) * tier2_radius
		tech_positions[tech.name] = pos
		
		_create_technology_button(tech_container, tech, pos, player_techs, dialog, player_id)
	
	# Draw dependency lines
	_draw_technology_connections(tech_container, tech_positions, advanced_techs, player_techs)
	
	# Note: Cancel button removed - using default X button
	
	# Add components to main container
	main_container.add_child(tech_container)
	
	# Add main container to dialog
	dialog.add_child(main_container)
	
	# Add to scene tree and show
	main_node.add_child(dialog)
	dialog_manager.current_dialog = dialog  # Track current dialog
	# Show dialog with universal centering
	GameDialogStrings.center_dialog(dialog)
	
	# Note: Cancel button removed - using default X button

# Show technology selection screen with domain upgrade
func show_technology_selection_with_upgrade(player_id: int, domain):
	# Store domain for later upgrade
	pending_upgrade_domain = domain
	
	# Show regular technology selection
	show_technology_selection(player_id)

# Handle technology button click (show details first)
func _on_technology_clicked(parent_dialog, player_id: int, tech: Dictionary):
	# Show technology details dialog with upgrade option
	_show_technology_details(parent_dialog, player_id, tech, false)

# Show technology details (for viewing obtained or blocked techs)
func _on_technology_details(tech: Dictionary, is_obtained: bool):
	# Show technology details dialog without upgrade option
	# is_obtained = true for obtained techs, false for blocked techs
	_show_technology_details(null, -1, tech, is_obtained)

# Show detailed technology information dialog
func _show_technology_details(parent_dialog, player_id: int, tech: Dictionary, is_obtained: bool):
	# Close any existing details dialog first
	if current_details_dialog:
		current_details_dialog.queue_free()
		current_details_dialog = null
	
	# Note: Removed dialog conflict checking - let the local tracking handle it
	# The current_details_dialog cleanup above ensures no conflicts
	
	# Create technology details dialog as a regular Window (not AcceptDialog)
	var details_dialog = Window.new()
	details_dialog.title = "%s %s Technology" % [tech.emoji, tech.display]
	details_dialog.size = Vector2(450, 300)
	details_dialog.unresizable = true
	details_dialog.transient = false  # Prevent exclusive child issues
	current_details_dialog = details_dialog  # Track the dialog
	
	# Apply basic styling
	details_dialog.add_theme_color_override("title_color", Color.WHITE)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 15)
	
	# Technology header
	var header_container = HBoxContainer.new()
	
	var tech_emoji = Label.new()
	tech_emoji.text = tech.emoji
	tech_emoji.add_theme_font_size_override("font_size", 32)
	
	var tech_title = Label.new()
	tech_title.text = tech.display
	tech_title.add_theme_font_size_override("font_size", 24)
	tech_title.add_theme_color_override("font_color", Color.WHITE)
	
	header_container.add_child(tech_emoji)
	header_container.add_child(tech_title)
	main_container.add_child(header_container)
	
	# Technology description
	var description_label = RichTextLabel.new()
	description_label.custom_minimum_size = Vector2(400, 150)
	description_label.bbcode_enabled = true
	description_label.text = _get_technology_description(tech)
	main_container.add_child(description_label)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Determine if this is an available technology (can be upgraded)
	var is_available = player_id != -1 and _is_technology_available(tech, player_technologies.get(player_id, []))
	
	if not is_obtained and is_available:
		# Upgrade button (only for available technologies)
		var upgrade_button = Button.new()
		upgrade_button.text = "UPGRADE"
		upgrade_button.add_theme_font_size_override("font_size", 16)
		GameDialogStrings.apply_button_style(upgrade_button)
		upgrade_button.pressed.connect(_on_upgrade_confirmed.bind(details_dialog, parent_dialog, player_id, tech.name))
		button_container.add_child(upgrade_button)
	elif not is_obtained and not is_available:
		# Blocked technology - show requirement info
		var requirement_label = Label.new()
		var required_tech = tech.get("requires", "")
		if required_tech != "":
			requirement_label.text = "Requires: %s Technology" % required_tech.capitalize()
		else:
			requirement_label.text = "Prerequisites not met"
		requirement_label.add_theme_font_size_override("font_size", 14)
		requirement_label.add_theme_color_override("font_color", Color.ORANGE)
		requirement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_container.add_child(requirement_label)
	
	# Close button (always available)
	var close_button = Button.new()
	if is_obtained:
		close_button.text = "CLOSE"
	elif is_available:
		close_button.text = "CANCEL"
	else:
		close_button.text = "CLOSE"
	close_button.add_theme_font_size_override("font_size", 16)
	GameDialogStrings.apply_button_style(close_button)
	close_button.pressed.connect(_on_details_closed.bind(details_dialog))
	button_container.add_child(close_button)
	
	main_container.add_child(button_container)
	
	# Add main container to dialog
	details_dialog.add_child(main_container)
	
	# Add to scene tree and show
	main_node.add_child(details_dialog)
	
	# Note: Don't register with dialog_manager to avoid conflicts
	# The technology details dialog is managed locally
	
	# Center dialog manually
	var screen_size = DisplayServer.screen_get_size()
	var dialog_pos = (screen_size - details_dialog.size) / 2
	details_dialog.position = Vector2i(dialog_pos)
	
	# Connect close signal
	details_dialog.close_requested.connect(_on_details_closed.bind(details_dialog))
	
	# Show the dialog
	details_dialog.show()

# Handle upgrade confirmation
func _on_upgrade_confirmed(details_dialog, parent_dialog, player_id: int, tech_name: String):
	# Clear local reference and close details dialog
	current_details_dialog = null
	details_dialog.queue_free()
	
	# Proceed with technology selection
	_on_technology_selected(parent_dialog, player_id, tech_name)

# Handle details dialog close
func _on_details_closed(details_dialog):
	# Clear local reference and close dialog
	current_details_dialog = null
	details_dialog.queue_free()

# Handle technology selection (after confirmation)
func _on_technology_selected(dialog, player_id: int, tech_name: String):
	# Execute domain upgrade if there's a pending upgrade
	if pending_upgrade_domain:
		var domain = pending_upgrade_domain
		var domain_level = domain.get("level", 1)
		
		# Execute base upgrade (consume power and increase level)
		domain.power -= domain_level
		domain.level += 1
		
		# Clear pending upgrade
		pending_upgrade_domain = null
	
	# Add technology to player's list
	if player_id not in player_technologies:
		player_technologies[player_id] = []
	
	player_technologies[player_id].append(tech_name)
	
	# Apply technology effects
	_apply_technology_effects(player_id, tech_name)
	
	# Close dialog
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Handle technology selection cancellation
func _on_technology_canceled(dialog):
	# Clear pending upgrade if cancelled
	pending_upgrade_domain = null
	
	dialog_manager.clear_current_dialog()
	dialog.queue_free()

# Get player's technologies
func get_player_technologies(player_id: int) -> Array:
	return player_technologies.get(player_id, [])

# Check if player has specific technology
func has_technology(player_id: int, tech_name: String) -> bool:
	var player_techs = player_technologies.get(player_id, [])
	return tech_name in player_techs

# Helper function to create technology buttons
func _create_technology_button(container: Control, tech: Dictionary, pos: Vector2, player_techs: Array, dialog: AcceptDialog, player_id: int):
	# Create technology button container
	var tech_button_container = VBoxContainer.new()
	tech_button_container.position = pos - Vector2(30, 30)
	tech_button_container.size = Vector2(60, 60)
	
	# Create technology button
	var tech_button = Button.new()
	tech_button.text = "%s\n%s" % [tech.emoji, tech.display]
	tech_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Apply black text styling
	GameDialogStrings.apply_button_style(tech_button)
	
	# Check if technology is already obtained
	var is_obtained = tech.name in player_techs
	
	# Check if technology is available (prerequisites met)
	var is_available = _is_technology_available(tech, player_techs)
	
	if is_obtained:
		tech_button.disabled = true
		tech_button.modulate = Color(0.5, 0.5, 0.5, 1.0)  # Gray out
	elif not is_available:
		# Keep button enabled for information viewing, but show visual indication
		tech_button.modulate = Color(0.8, 0.4, 0.4, 1.0)  # Red tint for unavailable
	
	# Create label
	var tech_label = Label.new()
	tech_label.text = tech.display
	tech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tech_label.add_theme_font_size_override("font_size", 8)
	
	tech_button_container.add_child(tech_button)
	tech_button_container.add_child(tech_label)
	container.add_child(tech_button_container)
	
	# Connect button signal - Allow clicking on all technologies for information
	if not is_obtained and is_available:
		# Available technology - show details with upgrade option
		tech_button.pressed.connect(_on_technology_clicked.bind(dialog, player_id, tech))
	elif is_obtained:
		# Obtained technology - show details without upgrade option
		tech_button.pressed.connect(_on_technology_details.bind(tech, true))
	else:
		# Blocked technology - show details without upgrade option
		tech_button.pressed.connect(_on_technology_details.bind(tech, false))

# Draw connection lines between technologies and their dependencies
func _draw_technology_connections(container: Control, tech_positions: Dictionary, advanced_techs: Array, player_techs: Array):
	# Create visual connection lines using ColorRect elements
	for tech in advanced_techs:
		var required_tech = tech.get("requires", "")
		if required_tech != "" and required_tech in tech_positions and tech.name in tech_positions:
			var start_pos = tech_positions[required_tech]
			var end_pos = tech_positions[tech.name]
			
			# Determine line color based on technology status
			var line_color = _get_connection_line_color(tech, required_tech, player_techs)
			
			# Create connection line using ColorRect
			_create_connection_line(container, start_pos, end_pos, line_color)
			
			# Create arrow indicator
			_create_arrow_indicator(container, start_pos, end_pos, line_color)

# Create a visual connection line between two points
func _create_connection_line(container: Control, start_pos: Vector2, end_pos: Vector2, color: Color):
	# Calculate line properties
	var line_vector = end_pos - start_pos
	var line_length = line_vector.length()
	var line_angle = line_vector.angle()
	
	# Create ColorRect for the line
	var line_rect = ColorRect.new()
	line_rect.color = color
	line_rect.size = Vector2(line_length, 2)  # 2px thick line
	line_rect.position = start_pos - Vector2(0, 1)  # Center the line
	line_rect.rotation = line_angle
	line_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to container (behind buttons)
	container.add_child(line_rect)
	container.move_child(line_rect, 0)

# Create arrow indicator at the end of connection
func _create_arrow_indicator(container: Control, start_pos: Vector2, end_pos: Vector2, color: Color):
	# Calculate arrow position (offset from button edge)
	var direction = (end_pos - start_pos).normalized()
	var arrow_pos = end_pos - direction * 25  # Offset from button
	
	# Create arrow using a simple triangle (Label with arrow character)
	var arrow_label = Label.new()
	arrow_label.text = "▶"  # Arrow character
	arrow_label.add_theme_color_override("font_color", color)
	arrow_label.add_theme_font_size_override("font_size", 12)
	arrow_label.position = arrow_pos - Vector2(6, 6)  # Center the arrow
	arrow_label.rotation = (end_pos - start_pos).angle()
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to container
	container.add_child(arrow_label)
	container.move_child(arrow_label, 1)  # Behind buttons but above lines

# Get detailed description for a technology
func _get_technology_description(tech: Dictionary) -> String:
	var tech_name = tech.name
	var tier = tech.get("tier", 1)
	var requires = tech.get("requires", "")
	
	# Build description with BBCode formatting
	var description = ""
	
	# Tier and prerequisite info
	if tier == 1:
		description += "[b]Tier 1 Technology[/b]\n"
		description += "Base technology - No prerequisites\n\n"
	else:
		description += "[b]Tier 2 Technology[/b]\n"
		if requires != "":
			description += "Requires: %s Technology\n" % requires.capitalize()
			description += "You must research %s first to unlock this technology.\n\n" % requires.capitalize()
		else:
			description += "Prerequisites not clearly defined\n\n"
	
	# Technology-specific descriptions
	match tech_name:
		# Tier 1 Technologies
		"settler":
			description += "[b]Settlement Action Unlock[/b]\n"
			description += "Unlocks SETTLE action for units. Allows establishing new domains.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: SETTLE action for all units\n"
			description += "• Usage: Unit uses SETTLE action at desired location\n"
			description += "• Cost: 1 power from unit's natal domain\n"
			description += "• Restrictions: Not on map border, max 1 shared position with existing domains"
		
		"harvest":
			description += "[b]Domain Harvest Upgrade Unlock[/b]\n"
			description += "Unlocks HARVEST upgrade option for domains. Enhances power generation.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: HARVEST upgrade option in domain upgrade menu\n"
			description += "• Effect: +1 power generation per turn + places 🧺 on random forest\n"
			description += "• Cost: Domain level power to upgrade\n"
			description += "• Requirement: Domain must have connected forest edges"
		
		"healer":
			description += "[b]Healer Training Unlock[/b]\n"
			description += "Unlocks HEALER training for units. Enables healing capabilities.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: HEALER training option at domain stars\n"
			description += "• Training cost: Unit level power from natal domain\n"
			description += "• Healer ability: HEAL action on adjacent units (including enemies)\n"
			description += "• Heal effect: Restores 1 health to injured units"
		
		"fighter":
			description += "[b]Fighter Training Unlock[/b]\n"
			description += "Unlocks FIGHTER training for units. Enables combat capabilities.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: FIGHTER training option at domain stars\n"
			description += "• Training cost: Unit level power from natal domain\n"
			description += "• Fighter ability: ATTACK action on enemy units\n"
			description += "• Attack effect: Deals 1 damage to target unit"
		
		"fish":
			description += "[b]Domain Fish Upgrade Unlock[/b]\n"
			description += "Unlocks FISH upgrade option for coastal domains. Provides variable power generation.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: FISH upgrade option in domain upgrade menu\n"
			description += "• Effect: Random power (0 to water edge count) each turn\n"
			description += "• Cost: Domain level power to upgrade\n"
			description += "• Restrictions: Requires water edges, one use per domain"
		
		# Tier 2 Technologies (Placeholders with future descriptions)
		"rider":
			description += "[b]Rider Training Unlock[/b]\n"
			description += "Unlocks RIDER training for units. Enables double actions per turn.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: RIDER training option at domain stars\n"
			description += "• Training cost: Unit level power from natal domain\n"
			description += "• Rider ability: 2 actions per turn instead of 1\n"
			description += "• Visual indicator: 🐎 emoji appears at unit base"
		
		"market":
			description += "[b]Domain Market Upgrade Unlock[/b]\n"
			description += "Unlocks MARKET upgrade option for domains. Enables power sharing and duplication.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: MARKET upgrade option in domain upgrade menu\n"
			description += "• Effect: Duplicates power generated that turn + enables power sharing\n"
			description += "• Power sharing: All market domains share power reserves globally\n"
			description += "• Restrictions: One use per domain, works across all players"
		
		"climber":
			description += "[b]Climber Training Unlock[/b]\n"
			description += "Unlocks CLIMBER training for units. Enables mountain traversal for all actions.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: CLIMBER training option at domain stars\n"
			description += "• Training cost: Unit level power from natal domain\n"
			description += "• Climber ability: Can move, heal, attack through mountains\n"
			description += "• Visual indicator: 🧗 emoji appears at unit base"
		
		"hamlet":
			description += "[b]Domain Hamlet Upgrade Unlock[/b]\n"
			description += "Unlocks HAMLET upgrade option for domains. Enhances power generation from grasslands.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: HAMLET upgrade option in domain upgrade menu\n"
			description += "• Effect: Builds hamlet structures on grassland edges\n"
			description += "• Cost: Domain level power to upgrade\n"
			description += "• Power bonus: +1 power per turn per grassland edge with hamlet"
		
		"shaman":
			description += "[b]Shaman Training Unlock[/b]\n"
			description += "Unlocks SHAMAN training for units. Enables mind control of adjacent enemies.\n\n"
			description += "[b]Mechanics:[/b]\n"
			description += "• Unlocks: SHAMAN training option at domain stars\n"
			description += "• Training cost: Unit level power from natal domain\n"
			description += "• Shaman ability: Convert adjacent enemy units to your control\n"
			description += "• Converted units: Keep natal domain but obey new controller\n"
			description += "• Range rules: Blocked by mountains/water, free within domains\n"
			description += "• Visual indicator: 🕊 emoji appears above converted units"
		
		"guardian":
			description += "[b]Defensive Matrix System[/b]\n"
			description += "[i]Implementation Pending[/i] Advanced protection algorithms and damage mitigation protocols.\n\n"
			description += "[b]Planned Mechanics:[/b]\n"
			description += "• Passive ability: SHIELD → -50% incoming damage\n"
			description += "• Active ability: PROTECT → Absorb damage for adjacent allies\n"
			description += "• Domain defense: +2 defensive rating for controlled territories\n"
			description += "• Counter-attack: 25% chance to reflect damage to attacker"
		
		"warrior":
			description += "[b]Close-Quarters Combat Optimization[/b]\n"
			description += "[i]Implementation Pending[/i] Advanced melee combat algorithms with proximity-based damage scaling.\n\n"
			description += "[b]Planned Mechanics:[/b]\n"
			description += "• Damage bonus: +50% melee attack damage\n"
			description += "• Special ability: CHARGE → Move + attack in single action\n"
			description += "• Berserker mode: +100% damage when health < 50%\n"
			description += "• Multi-target: Can attack up to 2 adjacent enemies per turn"
		
		"archer":
			description += "[b]Projectile Trajectory System[/b]\n"
			description += "[i]Implementation Pending[/i] Long-range combat algorithms with ballistic calculation optimization.\n\n"
			description += "[b]Planned Mechanics:[/b]\n"
			description += "• Attack range: 3-hex maximum distance\n"
			description += "• Precision bonus: +35% accuracy, +25% critical hit chance\n"
			description += "• Special ability: VOLLEY → Attack all enemies in target area\n"
			description += "• Siege mode: Can target and damage domain structures"
		
		"sailor":
			description += "[b]Aquatic Navigation Protocol[/b]\n"
			description += "[i]Implementation Pending[/i] Water-based movement algorithms and maritime logistics optimization.\n\n"
			description += "[b]Planned Mechanics:[/b]\n"
			description += "• Water movement: Units can traverse water hexes\n"
			description += "• Movement bonus: +1 hex range when moving on water\n"
			description += "• Transport ability: Can carry 1 additional unit across water\n"
			description += "• Exploration: Reveals fog of war in 2-hex radius on water"
		
		"whale":
			description += "[b]Deep Ocean Exploitation System[/b]\n"
			description += "[i]Implementation Pending[/i] Advanced marine resource extraction with deep-water optimization algorithms.\n\n"
			description += "[b]Planned Mechanics:[/b]\n"
			description += "• Resource extraction: HUNT → +3 power from deep water hexes\n"
			description += "• Range requirement: Must be 2+ hexes from shore\n"
			description += "• Efficiency bonus: 150% yield compared to coastal fishing\n"
			description += "• Special resource: Generates rare materials for advanced upgrades"
		
		_:
			description += "[b]Unknown Technology[/b]\n"
			description += "No information available for this technology."
	
	return description

# Get color for connection lines based on technology status
func _get_connection_line_color(tech: Dictionary, required_tech: String, player_techs: Array) -> Color:
	var has_prerequisite = required_tech in player_techs
	var has_tech = tech.name in player_techs
	
	if has_tech:
		# Technology is obtained - green line
		return Color(0.2, 0.8, 0.2, 0.8)
	elif has_prerequisite:
		# Prerequisite met, technology available - blue line
		return Color(0.2, 0.5, 1.0, 0.8)
	else:
		# Prerequisite not met - gray line
		return Color(0.5, 0.5, 0.5, 0.5)

# Check if technology is available (prerequisites met)
func _is_technology_available(tech: Dictionary, player_techs: Array) -> bool:
	# Tier 1 technologies are always available
	if tech.get("tier", 1) == 1:
		return true
	
	# Tier 2 technologies require their prerequisite
	var required_tech = tech.get("requires", "")
	if required_tech != "":
		return required_tech in player_techs
	
	return true

# Apply technology effects
func _apply_technology_effects(player_id: int, tech_name: String):
	match tech_name:
		# Tier 1 Technologies
		"settler":
			_apply_settler_technology(player_id)
		"harvest":
			_apply_harvest_technology(player_id)
		"healer":
			_apply_healer_technology(player_id)
		"fighter":
			_apply_fighter_technology(player_id)
		"fish":
			_apply_fish_technology(player_id)
		# Tier 2 Technologies (Placeholders)
		"rider":
			_apply_rider_technology(player_id)
		"market":
			_apply_market_technology(player_id)
		"climber":
			_apply_climber_technology(player_id)
		"hamlet":
			_apply_hamlet_technology(player_id)
		"shaman":
			_apply_shaman_technology(player_id)
		"guardian":
			_apply_guardian_technology(player_id)
		"warrior":
			_apply_warrior_technology(player_id)
		"archer":
			_apply_archer_technology(player_id)
		"sailor":
			_apply_sailor_technology(player_id)
		"whale":
			_apply_whale_technology(player_id)

# Apply Settler technology effects
func _apply_settler_technology(player_id: int):
	# Settler technology is automatically valid to all units of the team
	# The effects are applied when rendering/checking units
	# No immediate action needed as it's a passive ability
	pass

# Apply Harvest technology effects
func _apply_harvest_technology(player_id: int):
	# Harvest technology unlocks the Harvest upgrade option for domains
	# The effects are applied when the player chooses Harvest upgrade
	# No immediate action needed as it's an upgrade option
	pass

# Apply Healer technology effects
func _apply_healer_technology(player_id: int):
	# Healer technology unlocks healing abilities for units
	# The effects are applied when units use healing actions
	# No immediate action needed as it's a passive ability
	pass

# Apply Fighter technology effects
func _apply_fighter_technology(player_id: int):
	# Fighter technology unlocks combat abilities for units
	# The effects are applied when units engage in combat
	# No immediate action needed as it's a passive ability
	pass

# Apply Fish technology effects
func _apply_fish_technology(player_id: int):
	# Fish technology unlocks the Fish upgrade option for domains
	# The effects are applied when the player chooses Fish upgrade
	# No immediate action needed as it's an upgrade option
	pass

# ========================================
# TIER 2 TECHNOLOGY PLACEHOLDERS
# ========================================

# Apply Rider technology effects (Settler branch)
func _apply_rider_technology(player_id: int):
	# Rider technology unlocks rider training for units
	# The effects are applied when units are trained as riders
	# No immediate action needed as it's a training option
	print("[TECH] Player %d acquired Rider technology 🐎 - Rider training now available" % player_id)

# Apply Market technology effects (Settler branch)
func _apply_market_technology(player_id: int):
	# Market technology unlocks market upgrade for domains
	# The effects are applied when domains are upgraded with market
	# No immediate action needed as it's an upgrade option
	print("[TECH] Player %d acquired Market technology 🤝🏻 - Market upgrade now available" % player_id)

# Apply Climber technology effects (Harvest branch)
func _apply_climber_technology(player_id: int):
	# Climber technology unlocks climber training for units
	# The effects are applied when units are trained as climbers
	# No immediate action needed as it's a training option
	print("[TECH] Player %d acquired Climber technology 🧗 - Climber training now available" % player_id)

# Apply Hamlet technology effects (Harvest branch)
func _apply_hamlet_technology(player_id: int):
	# Hamlet technology unlocks hamlet upgrade for domains
	# The effects are applied when domains are upgraded with hamlet
	# No immediate action needed as it's an upgrade option
	print("[TECH] Player %d acquired Hamlet technology 🏡 - Hamlet upgrade now available" % player_id)

# Apply Shaman technology effects (Healer branch)
func _apply_shaman_technology(player_id: int):
	# TODO: Implement Shaman effects - Spiritual/magical abilities
	# Placeholder: Units gain spiritual powers
	print("[TECH] Player %d acquired Shaman technology 🪽" % player_id)
	pass

# Apply Guardian technology effects (Healer branch)
func _apply_guardian_technology(player_id: int):
	# TODO: Implement Guardian effects - Defensive bonuses
	# Placeholder: Units gain protective abilities
	print("[TECH] Player %d acquired Guardian technology 🛡" % player_id)
	pass

# Apply Warrior technology effects (Fighter branch)
func _apply_warrior_technology(player_id: int):
	# TODO: Implement Warrior effects - Melee combat bonuses
	# Placeholder: Units gain enhanced melee combat
	print("[TECH] Player %d acquired Warrior technology 🪓" % player_id)
	pass

# Apply Archer technology effects (Fighter branch)
func _apply_archer_technology(player_id: int):
	# TODO: Implement Archer effects - Ranged combat abilities
	# Placeholder: Units gain ranged attack capabilities
	print("[TECH] Player %d acquired Archer technology 🏹" % player_id)
	pass

# Apply Sailor technology effects (Fish branch)
func _apply_sailor_technology(player_id: int):
	# TODO: Implement Sailor effects - Naval/water abilities
	# Placeholder: Units gain water traversal abilities
	print("[TECH] Player %d acquired Sailor technology 〰" % player_id)
	pass

# Apply Whale technology effects (Fish branch)
func _apply_whale_technology(player_id: int):
	# TODO: Implement Whale effects - Marine resource bonuses
	# Placeholder: Enhanced marine resource gathering
	print("[TECH] Player %d acquired Whale technology 🐋" % player_id)
	pass