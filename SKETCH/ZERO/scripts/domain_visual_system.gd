## DomainVisualSystem
## 
## Sistema visual para renderização de seleção e highlight de domínios
## Integra com o renderer enhanced para mostrar feedback visual
##
## @author: V&V Game Studio
## @version: 1.0 - GAME READY

class_name DomainVisualSystem
extends RefCounted

## Visual states for domains
enum DomainVisualState {
	NORMAL,
	HOVERED,
	SELECTED,
	SELECTED_HOVERED
}

## Visual configuration
var selection_color: Color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow
var hover_color: Color = Color(0.8, 0.8, 1.0, 0.6)     # Light blue
var selection_border_width: float = 4.0
var hover_border_width: float = 2.0
var pulse_speed: float = 2.0
var pulse_intensity: float = 0.3

## Component references
var _hex_grid: HexGridV2Enhanced
var _cache: HexGridCache
var _geometry: HexGridGeometry
var _selection_system: DomainSelectionSystem

## Visual state tracking
var domain_visual_states: Array[DomainVisualState] = []
var pulse_timer: float = 0.0

## Initialize visual system
func _init(hex_grid: HexGridV2Enhanced = null, selection_system: DomainSelectionSystem = null):
	if hex_grid and selection_system:
		setup_visual_system(hex_grid, selection_system)

## Setup visual system with dependencies
func setup_visual_system(hex_grid: HexGridV2Enhanced, selection_system: DomainSelectionSystem) -> void:
	_hex_grid = hex_grid
	_cache = hex_grid.cache
	_geometry = hex_grid.geometry
	_selection_system = selection_system
	
	# Initialize visual states
	_initialize_visual_states()
	
	# Connect to selection system signals
	_connect_selection_signals()
	
	print("DomainVisualSystem: Initialized with %d domains" % domain_visual_states.size())

## Initialize visual states for all domains
func _initialize_visual_states() -> void:
	domain_visual_states.clear()
	var domain_count = _selection_system.get_domain_count()
	
	for i in range(domain_count):
		domain_visual_states.append(DomainVisualState.NORMAL)

## Connect to selection system signals
func _connect_selection_signals() -> void:
	_selection_system.domain_selected.connect(_on_domain_selected)
	_selection_system.domain_deselected.connect(_on_domain_deselected)
	_selection_system.domain_hovered.connect(_on_domain_hovered)
	_selection_system.domain_unhovered.connect(_on_domain_unhovered)

## Update visual system (called each frame)
func update_visuals(delta: float) -> void:
	pulse_timer += delta * pulse_speed

## Render domain visuals
func render_domain_visuals(canvas_item: CanvasItem) -> void:
	if not _cache or not _geometry:
		return
	
	var hex_positions = _cache.get_hex_positions()
	
	for i in range(domain_visual_states.size()):
		if i >= hex_positions.size():
			break
		
		var state = domain_visual_states[i]
		if state == DomainVisualState.NORMAL:
			continue  # No special rendering needed
		
		var hex_center = hex_positions[i]
		_render_domain_highlight(canvas_item, hex_center, state, i)

## Render highlight for a specific domain
func _render_domain_highlight(canvas_item: CanvasItem, hex_center: Vector2, state: DomainVisualState, domain_index: int) -> void:
	var hex_size = _hex_grid.config.hex_size
	var vertices = _geometry.calculate_hex_vertices(hex_center, hex_size)
	
	match state:
		DomainVisualState.HOVERED:
			_draw_domain_border(canvas_item, vertices, hover_color, hover_border_width)
		
		DomainVisualState.SELECTED:
			_draw_domain_border(canvas_item, vertices, selection_color, selection_border_width)
			_draw_selection_pulse(canvas_item, hex_center, hex_size)
		
		DomainVisualState.SELECTED_HOVERED:
			_draw_domain_border(canvas_item, vertices, selection_color, selection_border_width)
			_draw_domain_border(canvas_item, vertices, hover_color, hover_border_width * 0.5)
			_draw_selection_pulse(canvas_item, hex_center, hex_size)

## Draw domain border
func _draw_domain_border(canvas_item: CanvasItem, vertices: Array[Vector2], color: Color, width: float) -> void:
	for i in range(6):
		var start = vertices[i]
		var end = vertices[(i + 1) % 6]
		canvas_item.draw_line(start, end, color, width)

## Draw selection pulse effect
func _draw_selection_pulse(canvas_item: CanvasItem, center: Vector2, base_radius: float) -> void:
	var pulse_factor = (sin(pulse_timer) * 0.5 + 0.5) * pulse_intensity + 1.0
	var pulse_radius = base_radius * pulse_factor * 0.3
	var pulse_alpha = (sin(pulse_timer * 1.5) * 0.5 + 0.5) * 0.4 + 0.2
	
	var pulse_color = Color(selection_color.r, selection_color.g, selection_color.b, pulse_alpha)
	canvas_item.draw_circle(center, pulse_radius, pulse_color)

## Handle domain selection
func _on_domain_selected(domain_index: int, hex_position: Vector2) -> void:
	_update_domain_visual_state(domain_index)

## Handle domain deselection
func _on_domain_deselected(domain_index: int) -> void:
	_update_domain_visual_state(domain_index)

## Handle domain hover
func _on_domain_hovered(domain_index: int, hex_position: Vector2) -> void:
	_update_domain_visual_state(domain_index)

## Handle domain unhover
func _on_domain_unhovered(domain_index: int) -> void:
	_update_domain_visual_state(domain_index)

## Update visual state for a domain
func _update_domain_visual_state(domain_index: int) -> void:
	if domain_index < 0 or domain_index >= domain_visual_states.size():
		return
	
	var is_selected = _selection_system.get_selected_domain() == domain_index
	var is_hovered = _selection_system.get_hovered_domain() == domain_index
	
	if is_selected and is_hovered:
		domain_visual_states[domain_index] = DomainVisualState.SELECTED_HOVERED
	elif is_selected:
		domain_visual_states[domain_index] = DomainVisualState.SELECTED
	elif is_hovered:
		domain_visual_states[domain_index] = DomainVisualState.HOVERED
	else:
		domain_visual_states[domain_index] = DomainVisualState.NORMAL

## Update all domain visual states
func update_all_visual_states() -> void:
	for i in range(domain_visual_states.size()):
		_update_domain_visual_state(i)

## Set visual configuration
func set_selection_color(color: Color) -> void:
	selection_color = color

func set_hover_color(color: Color) -> void:
	hover_color = color

func set_border_widths(selection_width: float, hover_width: float) -> void:
	selection_border_width = selection_width
	hover_border_width = hover_width

func set_pulse_settings(speed: float, intensity: float) -> void:
	pulse_speed = speed
	pulse_intensity = intensity

## Get visual statistics
func get_visual_stats() -> Dictionary:
	var stats = {
		"normal": 0,
		"hovered": 0,
		"selected": 0,
		"selected_hovered": 0
	}
	
	for state in domain_visual_states:
		match state:
			DomainVisualState.NORMAL:
				stats.normal += 1
			DomainVisualState.HOVERED:
				stats.hovered += 1
			DomainVisualState.SELECTED:
				stats.selected += 1
			DomainVisualState.SELECTED_HOVERED:
				stats.selected_hovered += 1
	
	return stats