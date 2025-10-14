# 🏰 DOMAIN MANAGER (REFATORADO)
# Purpose: Coordenador principal para gerenciamento de domínios
# Layer: Presentation Manager

extends RefCounted
class_name DomainManager

# Import modular components
const DomainUpgradeHandler = preload("res://presentation/managers/domain/domain_upgrade_handler.gd")
const DomainTechnologyHandler = preload("res://presentation/managers/domain/domain_technology_handler.gd")

# References
var main_node: Node2D
var dialog_manager
var technology_manager
var unit_manager  # Forward reference, will be set later

# Modular components
var upgrade_handler: DomainUpgradeHandler
var technology_handler: DomainTechnologyHandler

# Domain state
var clicked_domain_id: int = -1  # Store which domain was clicked

# Initialize with required references
func initialize(main_node_ref: Node2D, dialog_manager_ref, technology_manager_ref):
	main_node = main_node_ref
	dialog_manager = dialog_manager_ref
	technology_manager = technology_manager_ref
	
	print("[DOMAIN_MANAGER] Initializing modular components...")
	
	# Initialize modular components
	upgrade_handler = DomainUpgradeHandler.new()
	technology_handler = DomainTechnologyHandler.new()
	
	print("[DOMAIN_MANAGER] Components initialized successfully")

# Set unit manager reference (to avoid circular dependency)
func set_unit_manager(unit_manager_ref):
	unit_manager = unit_manager_ref
	
	# Initialize components with unit manager
	if upgrade_handler:
		upgrade_handler.initialize(main_node, dialog_manager, technology_manager, unit_manager)
	
	if technology_handler:
		technology_handler.initialize(technology_manager, unit_manager)
	
	print("[DOMAIN_MANAGER] Unit manager reference set and components updated")

# Check if nuclear star (domain center) is clickable
func is_nuclear_star_clickable(position, game_state: Dictionary) -> bool:
	if not technology_handler:
		return false
	
	var is_clickable = technology_handler.is_nuclear_star_clickable(position, game_state)
	if is_clickable:
		# Store which domain was clicked
		var clicked_domain = technology_handler.get_domain_at_position(position, game_state)
		if clicked_domain:
			clicked_domain_id = clicked_domain.get("id", -1)
	
	return is_clickable

# Show nuclear star dialog (upgrade system)
func show_nuclear_star_dialog(game_state: Dictionary):
	if not upgrade_handler or not technology_handler:
		print("[DOMAIN_MANAGER] ERROR: Components not initialized")
		return
	
	# Find the domain that was clicked
	var clicked_domain = _get_clicked_domain(game_state)
	if not clicked_domain:
		return
	
	# Show upgrade dialog
	upgrade_handler.show_nuclear_star_dialog(clicked_domain, game_state)
	
	# Reset clicked domain ID after showing dialog
	clicked_domain_id = -1

# Get the clicked domain
func _get_clicked_domain(game_state: Dictionary):
	if clicked_domain_id == -1 or not ("domains" in game_state):
		return null
	
	return game_state.domains.get(clicked_domain_id)

# Get player's total power from domains (delegated to technology handler)
func get_player_total_power(player_id: int, game_state: Dictionary) -> int:
	if technology_handler:
		return technology_handler.get_player_total_power(player_id, game_state)
	return 0

# Check if player has specific technology (delegated to technology handler)
func has_technology(player_id: int, tech_name: String) -> bool:
	if technology_handler:
		return technology_handler.has_technology(player_id, tech_name)
	return false

# Validate domain upgrade requirements (delegated to technology handler)
func validate_upgrade_requirements(domain, upgrade_type: String, game_state: Dictionary) -> Dictionary:
	if technology_handler:
		return technology_handler.validate_upgrade_requirements(domain, upgrade_type, game_state)
	return {"valid": false, "reason": "Technology handler not available"}

# Get upgrade cost for domain (delegated to technology handler)
func get_upgrade_cost(domain) -> int:
	if technology_handler:
		return technology_handler.get_upgrade_cost(domain)
	return 1

# Check if domain is owned by current player (delegated to technology handler)
func is_domain_owned_by_current_player(domain, game_state: Dictionary) -> bool:
	if technology_handler:
		return technology_handler.is_domain_owned_by_current_player(domain, game_state)
	return false

# Cleanup method to prevent memory leaks
func cleanup():
	# Cleanup all modules
	if upgrade_handler:
		upgrade_handler.cleanup()
		upgrade_handler = null
	
	if technology_handler:
		technology_handler.cleanup()
		technology_handler = null
	
	# Clear all references
	main_node = null
	dialog_manager = null
	technology_manager = null
	unit_manager = null
	clicked_domain_id = -1