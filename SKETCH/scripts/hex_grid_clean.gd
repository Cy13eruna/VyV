## HexGrid v2.1 - Clean Version
## Sistema de grid hexagonal com logs limpos e otimizados

extends Node2D
class_name HexGridClean

# Preload component classes (versões limpas)
const HexGridConfig = preload("res://scripts/hex_grid_config.gd")
const HexGridGeometry = preload("res://scripts/hex_grid_geometry_clean.gd")
const HexGridCache = preload("res://scripts/hex_grid_cache_clean.gd")
const HexGridRenderer = preload("res://scripts/hex_grid_renderer.gd")

## Grid system events
signal grid_initialized()
signal grid_updated()

## Exported configuration properties
@export_group("Grid Dimensions")
@export var grid_width: int = 25 : set = set_grid_width
@export var grid_height: int = 18 : set = set_grid_height

@export_group("Hexagon Properties")
@export var hex_size: float = 35.0 : set = set_hex_size
@export var hex_color: Color = Color.WHITE : set = set_hex_color
@export var border_color: Color = Color.BLACK : set = set_border_color
@export var border_width: float = 2.0 : set = set_border_width

@export_group("Star Properties")
@export var dot_radius: float = 6.0 : set = set_dot_radius
@export var dot_color: Color = Color.WHITE : set = set_dot_color
@export var dot_star_size: float = 3.0 : set = set_dot_star_size

@export_group("Diamond Properties")
@export var diamond_width: float = 35.0 : set = set_diamond_width
@export var diamond_height: float = 60.0 : set = set_diamond_height
@export var diamond_color: Color = Color.GREEN : set = set_diamond_color

@export_group("Performance")
@export var enable_culling: bool = true : set = set_enable_culling
@export var show_debug_info: bool = false : set = set_show_debug_info

## Component system
var config
var geometry
var cache
var renderer

## State management
var is_initialized: bool = false
var needs_redraw: bool = true

## Initialize the grid system
func _ready() -> void:
	_initialize_components()
	_setup_grid()
	_connect_signals()
	_center_grid_on_screen()
	
	cache.build_cache()
	is_initialized = true
	grid_initialized.emit()

## Main drawing function
func _draw() -> void:
	if not is_initialized or not renderer:
		return
	
	var camera_transform = get_global_transform()
	renderer.render_grid(self, camera_transform)
	needs_redraw = false

## Force redraw of the grid
func redraw_grid() -> void:
	needs_redraw = true
	queue_redraw()

## Property setters
func set_grid_width(value: int) -> void:
	grid_width = value
	if config: config.set_grid_width(value)

func set_grid_height(value: int) -> void:
	grid_height = value
	if config: config.set_grid_height(value)

func set_hex_size(value: float) -> void:
	hex_size = value
	if config: config.set_hex_size(value)

func set_hex_color(value: Color) -> void:
	hex_color = value
	if config: config.set_hex_color(value)

func set_border_color(value: Color) -> void:
	border_color = value
	if config: config.set_border_color(value)

func set_border_width(value: float) -> void:
	border_width = value
	if config: config.set_border_width(value)

func set_dot_radius(value: float) -> void:
	dot_radius = value
	if config: config.set_dot_radius(value)

func set_dot_color(value: Color) -> void:
	dot_color = value
	if config: config.set_dot_color(value)

func set_dot_star_size(value: float) -> void:
	dot_star_size = value
	if config: config.set_dot_star_size(value)

func set_diamond_width(value: float) -> void:
	diamond_width = value
	if config: config.set_diamond_width(value)

func set_diamond_height(value: float) -> void:
	diamond_height = value
	if config: config.set_diamond_height(value)

func set_diamond_color(value: Color) -> void:
	diamond_color = value
	if config: config.set_diamond_color(value)

func set_enable_culling(value: bool) -> void:
	enable_culling = value
	if config: config.set_enable_culling(value)
	if renderer: renderer.set_culling_enabled(value)

func set_show_debug_info(value: bool) -> void:
	show_debug_info = value
	if renderer: 
		renderer.set_layer_visibility(5, value)
		redraw_grid()

## Initialize components
func _initialize_components() -> void:
	config = HexGridConfig.new()
	geometry = HexGridGeometry.new()
	cache = HexGridCache.new()
	cache.setup_cache(config, geometry)
	renderer = HexGridRenderer.new()
	renderer.setup_renderer(config, cache, geometry)

## Setup initial configuration
func _setup_grid() -> void:
	config.set_grid_width(grid_width)
	config.set_grid_height(grid_height)
	config.set_hex_size(hex_size)
	config.set_hex_color(hex_color)
	config.set_border_color(border_color)
	config.set_border_width(border_width)
	config.set_dot_radius(dot_radius)
	config.set_dot_color(dot_color)
	config.set_dot_star_size(dot_star_size)
	config.set_diamond_width(diamond_width)
	config.set_diamond_height(diamond_height)
	config.set_diamond_color(diamond_color)
	config.set_enable_culling(enable_culling)
	
	renderer.set_layer_visibility(5, show_debug_info)

## Connect signals
func _connect_signals() -> void:
	config.config_changed.connect(_on_config_changed)
	cache.cache_invalidated.connect(_on_cache_invalidated)
	cache.cache_rebuilt.connect(_on_cache_rebuilt)

## Handle configuration changes
func _on_config_changed(property_name: String, old_value, new_value) -> void:
	redraw_grid()
	grid_updated.emit()

## Handle cache invalidation
func _on_cache_invalidated() -> void:
	redraw_grid()

## Handle cache rebuild
func _on_cache_rebuilt(cache_size: int) -> void:
	redraw_grid()

## Center grid on screen
func _center_grid_on_screen() -> void:
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	var screen_center = viewport_size / 2.0
	
	position = screen_center
	
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.position = screen_center
		
		# Calculate zoom to fit grid
		var hex_radius = grid_width
		var hex_size_pixels = hex_size
		var hexagon_width = hex_size_pixels * 1.732 * (hex_radius * 2 - 1)
		var hexagon_height = hex_size_pixels * 2.0 * 0.75 * (hex_radius * 2 - 1)
		
		var margin = 1.2
		var zoom_x = viewport_size.x / (hexagon_width * margin)
		var zoom_y = viewport_size.y / (hexagon_height * margin)
		var zoom_factor = min(zoom_x, zoom_y)
		
		zoom_factor = clampf(zoom_factor, 0.1, 2.0)
		camera.zoom = Vector2(zoom_factor, zoom_factor)

## Get dot positions for external use
func get_dot_positions() -> Array[Vector2]:
	if not is_initialized or not cache:
		return []
	return cache.get_dot_positions()

## Get hex positions for external use
func get_hex_positions() -> Array[Vector2]:
	if not is_initialized or not cache:
		return []
	return cache.get_hex_positions()

## Check if grid is ready
func is_grid_ready() -> bool:
	return is_initialized and cache != null and cache.is_valid()

## Rebuild the grid
func rebuild_grid() -> void:
	if cache:
		cache.build_cache(true)
	redraw_grid()
	_center_grid_on_screen()

## Clean up resources
func _exit_tree() -> void:
	if config and config.config_changed.is_connected(_on_config_changed):
		config.config_changed.disconnect(_on_config_changed)
	if cache:
		if cache.cache_invalidated.is_connected(_on_cache_invalidated):
			cache.cache_invalidated.disconnect(_on_cache_invalidated)
		if cache.cache_rebuilt.is_connected(_on_cache_rebuilt):
			cache.cache_rebuilt.disconnect(_on_cache_rebuilt)