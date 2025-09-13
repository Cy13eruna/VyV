## HexGridConfig
## 
## Manages configuration and validation for the hexagonal grid system.
## Provides centralized configuration management with input validation,
## default values, and change detection for performance optimization.
##
## @author: V&V Game Studio
## @version: 2.0

class_name HexGridConfig
extends RefCounted

## Configuration change signal - emitted when any configuration value changes
signal config_changed(property_name: String, old_value, new_value)

## Grid dimensions
var grid_width: int = 25 : set = set_grid_width
var grid_height: int = 18 : set = set_grid_height

## Hexagon properties
var hex_size: float = 35.0 : set = set_hex_size
var hex_color: Color = Color.WHITE : set = set_hex_color
var border_color: Color = Color.BLACK : set = set_border_color
var border_width: float = 2.0 : set = set_border_width

## Dot/Star properties
var dot_radius: float = 6.0 : set = set_dot_radius
var dot_color: Color = Color.WHITE : set = set_dot_color
var dot_star_size: float = 3.0 : set = set_dot_star_size

## Diamond properties
var diamond_width: float = 35.0 : set = set_diamond_width
var diamond_height: float = 60.0 : set = set_diamond_height
var diamond_color: Color = Color.GREEN : set = set_diamond_color

## Global transformation
var global_rotation_degrees: float = 30.0 : set = set_global_rotation_degrees

## Performance settings
var enable_culling: bool = true : set = set_enable_culling
var culling_margin: float = 100.0 : set = set_culling_margin
var max_cache_size: int = 10000 : set = set_max_cache_size

## Color distribution ratios for diamonds
var diamond_color_ratios: Dictionary = {
	Color(0.0, 1.0, 0.0, 1.0): 1.0/3.0,  # Light green - 1/3
	Color(0.0, 0.494, 0.0, 1.0): 1.0/6.0,  # Dark green - 1/6
	Color(0.0, 1.0, 1.0, 1.0): 1.0/6.0,  # Cyan - 1/6
	Color(0.4, 0.4, 0.4, 1.0): 1.0/6.0   # Gray - 1/6
}

## Validation constraints
const MIN_GRID_SIZE: int = 1
const MAX_GRID_SIZE: int = 200
const MIN_HEX_SIZE: float = 5.0
const MAX_HEX_SIZE: float = 200.0
const MIN_DOT_RADIUS: float = 1.0
const MAX_DOT_RADIUS: float = 50.0
const MIN_BORDER_WIDTH: float = 0.0
const MAX_BORDER_WIDTH: float = 20.0

## Internal state tracking
var _is_dirty: bool = true
var _last_hash: int = 0

## Initialize configuration with default values
func _init():
	_calculate_hash()
	_is_dirty = false

## Check if configuration has changed since last check
func is_dirty() -> bool:
	return _is_dirty

## Mark configuration as clean (called after processing changes)
func mark_clean() -> void:
	_is_dirty = false
	_last_hash = _calculate_hash()

## Get total estimated number of diamonds for color distribution
func get_estimated_diamond_count() -> int:
	return grid_width * grid_height * 7  # Approximation based on connections

## Generate color array based on ratios and total count
func generate_diamond_colors(total_count: int) -> Array[Color]:
	var colors: Array[Color] = []
	
	for color in diamond_color_ratios:
		var ratio = diamond_color_ratios[color]
		var count = int(total_count * ratio)
		for i in range(count):
			colors.append(color)
	
	# Fill remaining slots with the most common color if needed
	while colors.size() < total_count:
		colors.append(Color(0.0, 1.0, 0.0, 1.0))  # Light green
	
	colors.shuffle()
	return colors

## Validate and set grid width
func set_grid_width(value: int) -> void:
	var old_value = grid_width
	grid_width = clampi(value, MIN_GRID_SIZE, MAX_GRID_SIZE)
	if grid_width != old_value:
		_mark_dirty()
		config_changed.emit("grid_width", old_value, grid_width)

## Validate and set grid height
func set_grid_height(value: int) -> void:
	var old_value = grid_height
	grid_height = clampi(value, MIN_GRID_SIZE, MAX_GRID_SIZE)
	if grid_height != old_value:
		_mark_dirty()
		config_changed.emit("grid_height", old_value, grid_height)

## Validate and set hex size
func set_hex_size(value: float) -> void:
	var old_value = hex_size
	hex_size = clampf(value, MIN_HEX_SIZE, MAX_HEX_SIZE)
	if not is_equal_approx(hex_size, old_value):
		_mark_dirty()
		config_changed.emit("hex_size", old_value, hex_size)

## Set hex color
func set_hex_color(value: Color) -> void:
	var old_value = hex_color
	hex_color = value
	if hex_color != old_value:
		_mark_dirty()
		config_changed.emit("hex_color", old_value, hex_color)

## Set border color
func set_border_color(value: Color) -> void:
	var old_value = border_color
	border_color = value
	if border_color != old_value:
		_mark_dirty()
		config_changed.emit("border_color", old_value, border_color)

## Validate and set border width
func set_border_width(value: float) -> void:
	var old_value = border_width
	border_width = clampf(value, MIN_BORDER_WIDTH, MAX_BORDER_WIDTH)
	if not is_equal_approx(border_width, old_value):
		_mark_dirty()
		config_changed.emit("border_width", old_value, border_width)

## Validate and set dot radius
func set_dot_radius(value: float) -> void:
	var old_value = dot_radius
	dot_radius = clampf(value, MIN_DOT_RADIUS, MAX_DOT_RADIUS)
	if not is_equal_approx(dot_radius, old_value):
		_mark_dirty()
		config_changed.emit("dot_radius", old_value, dot_radius)

## Set dot color
func set_dot_color(value: Color) -> void:
	var old_value = dot_color
	dot_color = value
	if dot_color != old_value:
		_mark_dirty()
		config_changed.emit("dot_color", old_value, dot_color)

## Validate and set dot star size
func set_dot_star_size(value: float) -> void:
	var old_value = dot_star_size
	dot_star_size = clampf(value, 1.0, dot_radius)
	if not is_equal_approx(dot_star_size, old_value):
		_mark_dirty()
		config_changed.emit("dot_star_size", old_value, dot_star_size)

## Validate and set diamond width
func set_diamond_width(value: float) -> void:
	var old_value = diamond_width
	diamond_width = clampf(value, 1.0, 200.0)
	if not is_equal_approx(diamond_width, old_value):
		_mark_dirty()
		config_changed.emit("diamond_width", old_value, diamond_width)

## Validate and set diamond height
func set_diamond_height(value: float) -> void:
	var old_value = diamond_height
	diamond_height = clampf(value, 1.0, 200.0)
	if not is_equal_approx(diamond_height, old_value):
		_mark_dirty()
		config_changed.emit("diamond_height", old_value, diamond_height)

## Set diamond color
func set_diamond_color(value: Color) -> void:
	var old_value = diamond_color
	diamond_color = value
	if diamond_color != old_value:
		_mark_dirty()
		config_changed.emit("diamond_color", old_value, diamond_color)

## Validate and set global rotation
func set_global_rotation_degrees(value: float) -> void:
	var old_value = global_rotation_degrees
	global_rotation_degrees = fmod(value, 360.0)
	if not is_equal_approx(global_rotation_degrees, old_value):
		_mark_dirty()
		config_changed.emit("global_rotation_degrees", old_value, global_rotation_degrees)

## Set culling enabled state
func set_enable_culling(value: bool) -> void:
	var old_value = enable_culling
	enable_culling = value
	if enable_culling != old_value:
		_mark_dirty()
		config_changed.emit("enable_culling", old_value, enable_culling)

## Validate and set culling margin
func set_culling_margin(value: float) -> void:
	var old_value = culling_margin
	culling_margin = clampf(value, 0.0, 1000.0)
	if not is_equal_approx(culling_margin, old_value):
		_mark_dirty()
		config_changed.emit("culling_margin", old_value, culling_margin)

## Validate and set max cache size
func set_max_cache_size(value: int) -> void:
	var old_value = max_cache_size
	max_cache_size = clampi(value, 100, 100000)
	if max_cache_size != old_value:
		_mark_dirty()
		config_changed.emit("max_cache_size", old_value, max_cache_size)

## Mark configuration as dirty (internal use)
func _mark_dirty() -> void:
	_is_dirty = true

## Calculate hash of current configuration for change detection
func _calculate_hash() -> int:
	var hash_string = str(grid_width) + str(grid_height) + str(hex_size) + \
					  str(hex_color) + str(border_color) + str(border_width) + \
					  str(dot_radius) + str(dot_color) + str(dot_star_size) + \
					  str(diamond_width) + str(diamond_height) + str(diamond_color) + \
					  str(global_rotation_degrees) + str(enable_culling) + \
					  str(culling_margin) + str(max_cache_size)
	return hash_string.hash()

## Get configuration as dictionary for serialization
func to_dict() -> Dictionary:
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"hex_size": hex_size,
		"hex_color": hex_color,
		"border_color": border_color,
		"border_width": border_width,
		"dot_radius": dot_radius,
		"dot_color": dot_color,
		"dot_star_size": dot_star_size,
		"diamond_width": diamond_width,
		"diamond_height": diamond_height,
		"diamond_color": diamond_color,
		"global_rotation_degrees": global_rotation_degrees,
		"enable_culling": enable_culling,
		"culling_margin": culling_margin,
		"max_cache_size": max_cache_size
	}

## Load configuration from dictionary
func from_dict(data: Dictionary) -> void:
	if data.has("grid_width"): set_grid_width(data.grid_width)
	if data.has("grid_height"): set_grid_height(data.grid_height)
	if data.has("hex_size"): set_hex_size(data.hex_size)
	if data.has("hex_color"): set_hex_color(data.hex_color)
	if data.has("border_color"): set_border_color(data.border_color)
	if data.has("border_width"): set_border_width(data.border_width)
	if data.has("dot_radius"): set_dot_radius(data.dot_radius)
	if data.has("dot_color"): set_dot_color(data.dot_color)
	if data.has("dot_star_size"): set_dot_star_size(data.dot_star_size)
	if data.has("diamond_width"): set_diamond_width(data.diamond_width)
	if data.has("diamond_height"): set_diamond_height(data.diamond_height)
	if data.has("diamond_color"): set_diamond_color(data.diamond_color)
	if data.has("global_rotation_degrees"): set_global_rotation_degrees(data.global_rotation_degrees)
	if data.has("enable_culling"): set_enable_culling(data.enable_culling)
	if data.has("culling_margin"): set_culling_margin(data.culling_margin)
	if data.has("max_cache_size"): set_max_cache_size(data.max_cache_size)