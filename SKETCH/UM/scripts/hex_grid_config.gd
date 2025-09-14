## HexGridConfig
## Simple configuration class for hex grid
class_name HexGridConfig
extends RefCounted

signal config_changed(property_name: String, old_value, new_value)

var grid_width: int = 25
var grid_height: int = 18
var hex_size: float = 35.0
var hex_color: Color = Color.WHITE
var border_color: Color = Color.BLACK
var border_width: float = 2.0
var dot_radius: float = 6.0
var dot_color: Color = Color.WHITE
var dot_star_size: float = 3.0
var diamond_width: float = 35.0
var diamond_height: float = 60.0
var diamond_color: Color = Color.GREEN
var global_rotation_degrees: float = 30.0
var enable_culling: bool = true
var culling_margin: float = 100.0
var max_cache_size: int = 10000

func set_grid_width(value: int) -> void:
	var old = grid_width
	grid_width = value
	config_changed.emit("grid_width", old, value)

func set_grid_height(value: int) -> void:
	var old = grid_height
	grid_height = value
	config_changed.emit("grid_height", old, value)

func set_hex_size(value: float) -> void:
	var old = hex_size
	hex_size = value
	config_changed.emit("hex_size", old, value)

func set_hex_color(value: Color) -> void:
	hex_color = value

func set_border_color(value: Color) -> void:
	border_color = value

func set_border_width(value: float) -> void:
	border_width = value

func set_dot_radius(value: float) -> void:
	dot_radius = value

func set_dot_color(value: Color) -> void:
	dot_color = value

func set_dot_star_size(value: float) -> void:
	dot_star_size = value

func set_diamond_width(value: float) -> void:
	diamond_width = value

func set_diamond_height(value: float) -> void:
	diamond_height = value

func set_diamond_color(value: Color) -> void:
	diamond_color = value

func set_global_rotation_degrees(value: float) -> void:
	global_rotation_degrees = value

func set_enable_culling(value: bool) -> void:
	enable_culling = value

func set_culling_margin(value: float) -> void:
	culling_margin = value

func set_max_cache_size(value: int) -> void:
	max_cache_size = value

func to_dict() -> Dictionary:
	return {
		"grid_width": grid_width,
		"grid_height": grid_height,
		"hex_size": hex_size
	}

func from_dict(data: Dictionary) -> void:
	if data.has("grid_width"):
		set_grid_width(data.grid_width)
	if data.has("grid_height"):
		set_grid_height(data.grid_height)
	if data.has("hex_size"):
		set_hex_size(data.hex_size)