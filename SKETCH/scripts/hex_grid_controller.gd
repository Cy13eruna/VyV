## HexGridController
## 
## Interactive controller for demonstrating enhanced hex grid features
## Provides keyboard and mouse controls for testing performance improvements
##
## @author: V&V Game Studio
## @version: 2.1 - ENHANCED

extends Node2D
class_name HexGridController

## Reference to the hex grid
@export var hex_grid: HexGridV2Enhanced

## Control state
var is_debug_enabled: bool = false
var current_grid_size: int = 25
var zoom_speed: float = 0.1
var pan_speed: float = 300.0

## Camera reference
@onready var camera: Camera2D = $Camera2D

## Performance monitoring
var performance_stats_timer: float = 0.0
var stats_update_interval: float = 1.0  # Update stats every second

func _ready() -> void:
	if not hex_grid:
		hex_grid = $HexGridV2Enhanced
	
	if hex_grid:
		hex_grid.performance_warning.connect(_on_performance_warning)
		print("HexGridController: Connected to enhanced hex grid")
	
	_print_controls()

func _process(delta: float) -> void:
	_handle_camera_movement(delta)
	_update_performance_stats(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_keyboard_input(event)
	elif event is InputEventMouseButton:
		_handle_mouse_input(event)
	elif event is InputEventMouseMotion and Input.is_action_pressed("ui_select"):
		_handle_mouse_drag(event)

## Handle keyboard controls
func _handle_keyboard_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_D:
			_toggle_debug()
		KEY_C:
			_toggle_culling()
		KEY_H:
			_toggle_hexagons()
		KEY_R:
			_reset_grid()
		KEY_P:
			_print_performance_stats()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_set_grid_size_preset(event.keycode - KEY_0)
		KEY_PLUS, KEY_EQUAL:
			_increase_grid_size()
		KEY_MINUS:
			_decrease_grid_size()
		KEY_F:
			_force_performance_optimization()
		KEY_L:
			_toggle_lod()

## Handle mouse controls
func _handle_mouse_input(event: InputEventMouseButton) -> void:
	if not hex_grid:
		return
	
	if event.pressed:
		var world_pos = camera.get_global_mouse_position()
		
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_hex_click(world_pos)
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_out()

## Handle mouse dragging for panning
func _handle_mouse_drag(event: InputEventMouseMotion) -> void:
	if camera:
		camera.global_position -= event.relative / camera.zoom

## Handle camera movement with WASD
func _handle_camera_movement(delta: float) -> void:
	if not camera:
		return
	
	var movement = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement.x += 1
	if Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement.y += 1
	
	if movement != Vector2.ZERO:
		camera.global_position += movement.normalized() * pan_speed * delta / camera.zoom.x

## Toggle debug information
func _toggle_debug() -> void:
	is_debug_enabled = !is_debug_enabled
	if hex_grid:
		hex_grid.show_debug_info = is_debug_enabled
	print("Debug info: %s" % ("ON" if is_debug_enabled else "OFF"))

## Toggle culling system
func _toggle_culling() -> void:
	if hex_grid:
		hex_grid.enable_culling = !hex_grid.enable_culling
		print("Culling: %s" % ("ON" if hex_grid.enable_culling else "OFF"))

## Toggle hexagon outlines
func _toggle_hexagons() -> void:
	if hex_grid and hex_grid.renderer:
		var current_visibility = hex_grid.renderer.get_layer_visibility(HexGridRendererEnhanced.RenderLayer.HEXAGONS)
		hex_grid.set_layer_visibility(HexGridRendererEnhanced.RenderLayer.HEXAGONS, !current_visibility)
		print("Hexagon outlines: %s" % ("ON" if !current_visibility else "OFF"))

## Reset grid to default settings
func _reset_grid() -> void:
	if hex_grid:
		hex_grid.grid_width = 25
		hex_grid.grid_height = 18
		hex_grid.hex_size = 35.0
		hex_grid.global_rotation_degrees = 30.0
		current_grid_size = 25
		print("Grid reset to default settings")

## Print current performance statistics
func _print_performance_stats() -> void:
	if not hex_grid:
		return
	
	var stats = hex_grid.get_grid_stats()
	var render_stats = stats.get("render_stats", {})
	
	print("=== PERFORMANCE STATS ===")
	print("Grid Size: %dx%d (%d hexagons)" % [stats.grid_size.x, stats.grid_size.y, stats.total_hexagons])
	print("Diamonds Rendered: %d" % render_stats.get("diamonds_rendered", 0))
	print("Stars Rendered: %d" % render_stats.get("stars_rendered", 0))
	print("Elements Culled: %d" % render_stats.get("culled_elements", 0))
	print("Draw Calls: %d" % render_stats.get("total_draw_calls", 0))
	print("Render Time: %.2f ms" % render_stats.get("last_render_time_ms", 0.0))
	print("Memory Usage: %.2f MB" % stats.get("memory_usage_mb", 0.0))
	print("Average Frame Time: %.2f ms" % hex_grid.get_average_frame_time())
	print("========================")

## Set grid size based on preset
func _set_grid_size_preset(preset: int) -> void:
	if not hex_grid:
		return
	
	var sizes = {
		1: 10,   # Small
		2: 25,   # Medium
		3: 50,   # Large
		4: 75,   # Very Large
		5: 100   # Extreme
	}
	
	if preset in sizes:
		var size = sizes[preset]
		hex_grid.grid_width = size
		hex_grid.grid_height = size
		current_grid_size = size
		print("Grid size set to: %dx%d" % [size, size])

## Increase grid size
func _increase_grid_size() -> void:
	if hex_grid:
		current_grid_size = min(current_grid_size + 5, 200)
		hex_grid.grid_width = current_grid_size
		hex_grid.grid_height = current_grid_size
		print("Grid size increased to: %dx%d" % [current_grid_size, current_grid_size])

## Decrease grid size
func _decrease_grid_size() -> void:
	if hex_grid:
		current_grid_size = max(current_grid_size - 5, 5)
		hex_grid.grid_width = current_grid_size
		hex_grid.grid_height = current_grid_size
		print("Grid size decreased to: %dx%d" % [current_grid_size, current_grid_size])

## Force performance optimization
func _force_performance_optimization() -> void:
	if hex_grid:
		hex_grid.optimize_performance()
		print("Performance optimization forced")

## Toggle Level of Detail
func _toggle_lod() -> void:
	if hex_grid and hex_grid.renderer:
		hex_grid.renderer.enable_lod = !hex_grid.renderer.enable_lod
		print("Level of Detail: %s" % ("ON" if hex_grid.renderer.enable_lod else "OFF"))

## Handle hex click for interaction
func _handle_hex_click(world_pos: Vector2) -> void:
	var hex_index = hex_grid.get_hexagon_at_position(world_pos)
	var dot_index = hex_grid.get_dot_at_position(world_pos)
	
	if hex_index >= 0:
		print("Clicked hexagon #%d at %s" % [hex_index, world_pos])
	elif dot_index >= 0:
		print("Clicked dot #%d at %s" % [dot_index, world_pos])
	else:
		print("Clicked empty space at %s" % world_pos)

## Zoom in
func _zoom_in() -> void:
	if camera:
		camera.zoom *= (1.0 + zoom_speed)
		camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(10.0, 10.0))

## Zoom out
func _zoom_out() -> void:
	if camera:
		camera.zoom *= (1.0 - zoom_speed)
		camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(10.0, 10.0))

## Update performance statistics display
func _update_performance_stats(delta: float) -> void:
	performance_stats_timer += delta
	
	if performance_stats_timer >= stats_update_interval and is_debug_enabled:
		performance_stats_timer = 0.0
		# Could update UI here if we had one
		pass

## Handle performance warnings
func _on_performance_warning(message: String) -> void:
	print("⚠️ PERFORMANCE WARNING: %s" % message)

## Print available controls
func _print_controls() -> void:
	print("=== HEX GRID ENHANCED CONTROLS ===")
	print("D - Toggle debug info")
	print("C - Toggle culling")
	print("H - Toggle hexagon outlines")
	print("R - Reset grid")
	print("P - Print performance stats")
	print("1-5 - Grid size presets (10, 25, 50, 75, 100)")
	print("+/- - Increase/decrease grid size")
	print("F - Force performance optimization")
	print("L - Toggle Level of Detail")
	print("WASD - Move camera")
	print("Mouse wheel - Zoom")
	print("Left click - Interact with hexagons")
	print("====================================")