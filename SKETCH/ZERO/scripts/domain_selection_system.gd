## DomainSelectionSystem
## 
## Sistema de seleção de domínios (hexágonos) para Vagabonds & Valleys
## Gerencia seleção, highlight e interação com domínios do grid hexagonal
##
## @author: V&V Game Studio
## @version: 1.0 - GAME READY

class_name DomainSelectionSystem
extends RefCounted

## Signals para comunicação com outros sistemas
signal domain_selected(domain_index: int, hex_position: Vector2)
signal domain_deselected(domain_index: int)
signal domain_hovered(domain_index: int, hex_position: Vector2)
signal domain_unhovered(domain_index: int)

## Estado de seleção
var selected_domain_index: int = -1
var hovered_domain_index: int = -1
var is_selection_enabled: bool = true

## Referências aos componentes do grid
var _hex_grid: HexGridV2Enhanced
var _cache: HexGridCache
var _geometry: HexGridGeometry

## Configurações visuais
var selection_color: Color = Color(1.0, 1.0, 0.0, 0.8)  # Amarelo para seleção
var hover_color: Color = Color(0.8, 0.8, 1.0, 0.6)     # Azul claro para hover
var selection_border_width: float = 4.0
var hover_border_width: float = 2.0

## Sistema de visibilidade (preparação para fog of war)
var visible_domains: Array[bool] = []
var explored_domains: Array[bool] = []

## Initialize selection system
func _init(hex_grid: HexGridV2Enhanced = null):
	if hex_grid:
		setup_selection_system(hex_grid)

## Setup selection system with hex grid reference
func setup_selection_system(hex_grid: HexGridV2Enhanced) -> void:
	_hex_grid = hex_grid
	_cache = hex_grid.cache
	_geometry = hex_grid.geometry
	
	# Initialize visibility arrays
	_initialize_visibility_system()
	
	print("DomainSelectionSystem: Initialized with %d domains" % get_domain_count())

## Initialize visibility system for fog of war
func _initialize_visibility_system() -> void:
	var domain_count = get_domain_count()
	visible_domains.clear()
	explored_domains.clear()
	
	# Por enquanto, todos os domínios são visíveis (sem fog of war)
	for i in range(domain_count):
		visible_domains.append(true)
		explored_domains.append(true)

## Get total number of domains (hexagons)
func get_domain_count() -> int:
	if not _cache:
		return 0
	return _cache.get_hex_positions().size()

## Handle mouse click for domain selection
func handle_mouse_click(mouse_position: Vector2) -> bool:
	if not is_selection_enabled:
		return false
	
	var domain_index = get_domain_at_position(mouse_position)
	
	if domain_index >= 0 and is_domain_visible(domain_index):
		select_domain(domain_index)
		return true
	else:
		deselect_domain()
		return false

## Handle mouse movement for domain hovering
func handle_mouse_hover(mouse_position: Vector2) -> void:
	if not is_selection_enabled:
		return
	
	var domain_index = get_domain_at_position(mouse_position)
	
	if domain_index != hovered_domain_index:
		# Unhover previous domain
		if hovered_domain_index >= 0:
			domain_unhovered.emit(hovered_domain_index)
		
		# Hover new domain
		hovered_domain_index = domain_index
		if domain_index >= 0 and is_domain_visible(domain_index):
			var hex_position = get_domain_position(domain_index)
			domain_hovered.emit(domain_index, hex_position)

## Get domain index at world position
func get_domain_at_position(world_position: Vector2) -> int:
	if not _hex_grid:
		return -1
	
	return _hex_grid.get_hexagon_at_position(world_position)

## Get domain position by index
func get_domain_position(domain_index: int) -> Vector2:
	if not _cache or domain_index < 0:
		return Vector2.ZERO
	
	var hex_positions = _cache.get_hex_positions()
	if domain_index >= hex_positions.size():
		return Vector2.ZERO
	
	return hex_positions[domain_index]

## Select a domain
func select_domain(domain_index: int) -> void:
	if domain_index == selected_domain_index:
		return  # Already selected
	
	# Deselect previous domain
	if selected_domain_index >= 0:
		domain_deselected.emit(selected_domain_index)
	
	# Select new domain
	selected_domain_index = domain_index
	var hex_position = get_domain_position(domain_index)
	domain_selected.emit(domain_index, hex_position)
	
	print("Domain selected: #%d at %s" % [domain_index, hex_position])

## Deselect current domain
func deselect_domain() -> void:
	if selected_domain_index >= 0:
		domain_deselected.emit(selected_domain_index)
		print("Domain deselected: #%d" % selected_domain_index)
		selected_domain_index = -1

## Check if domain is visible (fog of war)
func is_domain_visible(domain_index: int) -> bool:
	if domain_index < 0 or domain_index >= visible_domains.size():
		return false
	return visible_domains[domain_index]

## Check if domain is explored (fog of war)
func is_domain_explored(domain_index: int) -> bool:
	if domain_index < 0 or domain_index >= explored_domains.size():
		return false
	return explored_domains[domain_index]

## Set domain visibility (for fog of war system)
func set_domain_visibility(domain_index: int, visible: bool) -> void:
	if domain_index >= 0 and domain_index < visible_domains.size():
		visible_domains[domain_index] = visible
		if visible:
			explored_domains[domain_index] = true

## Set domain exploration status
func set_domain_explored(domain_index: int, explored: bool) -> void:
	if domain_index >= 0 and domain_index < explored_domains.size():
		explored_domains[domain_index] = explored

## Get selected domain index
func get_selected_domain() -> int:
	return selected_domain_index

## Get hovered domain index
func get_hovered_domain() -> int:
	return hovered_domain_index

## Check if selection is enabled
func is_selection_active() -> bool:
	return is_selection_enabled

## Enable/disable selection
func set_selection_enabled(enabled: bool) -> void:
	is_selection_enabled = enabled
	if not enabled:
		deselect_domain()
		hovered_domain_index = -1

## Get domain info for UI display
func get_domain_info(domain_index: int) -> Dictionary:
	if domain_index < 0 or not is_domain_visible(domain_index):
		return {}
	
	var position = get_domain_position(domain_index)
	return {
		"index": domain_index,
		"position": position,
		"visible": is_domain_visible(domain_index),
		"explored": is_domain_explored(domain_index),
		"selected": domain_index == selected_domain_index,
		"hovered": domain_index == hovered_domain_index
	}

## Get all visible domains
func get_visible_domains() -> Array[int]:
	var visible_list: Array[int] = []
	for i in range(visible_domains.size()):
		if visible_domains[i]:
			visible_list.append(i)
	return visible_list

## Get selection statistics
func get_selection_stats() -> Dictionary:
	return {
		"total_domains": get_domain_count(),
		"visible_domains": get_visible_domains().size(),
		"explored_domains": explored_domains.count(true),
		"selected_domain": selected_domain_index,
		"hovered_domain": hovered_domain_index,
		"selection_enabled": is_selection_enabled
	}