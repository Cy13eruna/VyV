## HexGridDemo
## 
## Interactive demonstration of the hexagonal grid system capabilities.
## Shows various features, performance optimizations, and configuration options.
##
## @author: V&V Game Studio
## @version: 2.0

extends Node2D
class_name HexGridDemo

## Demo grid instance
var hex_grid: HexGridV2

## Demo state
var demo_mode: int = 0
var demo_timer: float = 0.0
var auto_demo: bool = false

## UI elements (would be actual UI nodes in a real implementation)
var ui_labels: Array[String] = []

## Demo modes
enum DemoMode {
	BASIC_GRID,
	PERFORMANCE_TEST,
	LAYER_SHOWCASE,
	INTERACTIVE_MODE,
	CONFIGURATION_DEMO,
	STRESS_TEST
}

## Initialize demo
func _ready() -> void:
	_setup_demo_grid()
	_setup_ui()
	_start_demo()

## Main demo update
func _process(delta: float) -> void:
	demo_timer += delta
	
	if auto_demo and demo_timer > 5.0:  # Switch demo every 5 seconds
		_next_demo_mode()
		demo_timer = 0.0
	
	_update_demo_mode(delta)
	_update_ui()

## Handle input for interactive demo
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_next_demo_mode()
			KEY_A:
				auto_demo = !auto_demo
				print("Auto demo: ", auto_demo)
			KEY_R:
				_reset_demo()
			KEY_T:
				_run_tests()
			KEY_B:
				_run_benchmarks()
			KEY_D:
				_toggle_debug()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				demo_mode = event.keycode - KEY_1
				_apply_demo_mode()
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_mouse_click(event.position)

## Setup demo grid
func _setup_demo_grid() -> void:
	hex_grid = HexGridV2.new()
	add_child(hex_grid)
	
	# Connect signals
	hex_grid.grid_initialized.connect(_on_grid_initialized)
	hex_grid.grid_updated.connect(_on_grid_updated)
	hex_grid.performance_warning.connect(_on_performance_warning)
	
	print("HexGridDemo: Demo grid created")

## Setup UI elements
func _setup_UI() -> void:
	ui_labels = [
		"Hexagonal Grid System v2.0 Demo",
		"Controls:",
		"SPACE - Next demo mode",
		"A - Toggle auto demo",
		"R - Reset demo",
		"T - Run tests",
		"B - Run benchmarks",
		"D - Toggle debug",
		"1-6 - Select demo mode",
		"Click - Interact with grid"
	]

## Start demo sequence
func _start_demo() -> void:
	demo_mode = DemoMode.BASIC_GRID
	_apply_demo_mode()
	print("HexGridDemo: Demo started - Use SPACE to cycle through modes")

## Update current demo mode
func _update_demo_mode(delta: float) -> void:
	match demo_mode:
		DemoMode.BASIC_GRID:
			_update_basic_grid_demo(delta)
		DemoMode.PERFORMANCE_TEST:
			_update_performance_test_demo(delta)
		DemoMode.LAYER_SHOWCASE:
			_update_layer_showcase_demo(delta)
		DemoMode.INTERACTIVE_MODE:
			_update_interactive_mode_demo(delta)
		DemoMode.CONFIGURATION_DEMO:
			_update_configuration_demo(delta)
		DemoMode.STRESS_TEST:
			_update_stress_test_demo(delta)

## Apply current demo mode settings
func _apply_demo_mode() -> void:
	match demo_mode:
		DemoMode.BASIC_GRID:
			_setup_basic_grid_demo()
		DemoMode.PERFORMANCE_TEST:
			_setup_performance_test_demo()
		DemoMode.LAYER_SHOWCASE:
			_setup_layer_showcase_demo()
		DemoMode.INTERACTIVE_MODE:
			_setup_interactive_mode_demo()
		DemoMode.CONFIGURATION_DEMO:
			_setup_configuration_demo()
		DemoMode.STRESS_TEST:
			_setup_stress_test_demo()
	
	demo_timer = 0.0

## Basic grid demonstration
func _setup_basic_grid_demo() -> void:
	print("Demo Mode: Basic Grid")
	hex_grid.grid_width = 25
	hex_grid.grid_height = 18
	hex_grid.hex_size = 35.0
	hex_grid.enable_culling = true
	hex_grid.show_debug_info = false

func _update_basic_grid_demo(delta: float) -> void:
	# Gentle rotation animation
	hex_grid.global_rotation_degrees = sin(demo_timer * 0.5) * 10.0 + 30.0

## Performance test demonstration
func _setup_performance_test_demo() -> void:
	print("Demo Mode: Performance Test")
	hex_grid.grid_width = 50
	hex_grid.grid_height = 40
	hex_grid.enable_culling = true
	hex_grid.show_debug_info = true
	hex_grid.auto_optimize_performance = true

func _update_performance_test_demo(delta: float) -> void:
	# Stress test with rapid changes
	if int(demo_timer * 2) % 2 == 0:
		hex_grid.hex_size = 30.0 + sin(demo_timer * 3.0) * 10.0
	else:
		hex_grid.dot_radius = 4.0 + sin(demo_timer * 4.0) * 3.0

## Layer showcase demonstration
func _setup_layer_showcase_demo() -> void:
	print("Demo Mode: Layer Showcase")
	hex_grid.grid_width = 30
	hex_grid.grid_height = 20
	hex_grid.show_debug_info = false

func _update_layer_showcase_demo(delta: float) -> void:
	# Cycle through different layer combinations
	var cycle_time = fmod(demo_timer, 8.0)
	
	if cycle_time < 2.0:
		# Show only diamonds
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.DIAMONDS, true)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.STARS, false)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.HEXAGONS, false)
	elif cycle_time < 4.0:
		# Show only stars
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.DIAMONDS, false)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.STARS, true)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.HEXAGONS, false)
	elif cycle_time < 6.0:
		# Show only hexagons
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.DIAMONDS, false)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.STARS, false)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.HEXAGONS, true)
	else:
		# Show all layers
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.DIAMONDS, true)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.STARS, true)
		hex_grid.set_layer_visibility(HexGridRenderer.RenderLayer.HEXAGONS, true)

## Interactive mode demonstration
func _setup_interactive_mode_demo() -> void:
	print("Demo Mode: Interactive Mode - Click on hexagons!")
	hex_grid.grid_width = 20
	hex_grid.grid_height = 15
	hex_grid.show_debug_info = false

func _update_interactive_mode_demo(delta: float) -> void:
	# Interactive mode - handled by mouse clicks
	pass

## Configuration demonstration
func _setup_configuration_demo() -> void:
	print("Demo Mode: Configuration Demo")
	hex_grid.grid_width = 25
	hex_grid.grid_height = 18

func _update_configuration_demo(delta: float) -> void:
	# Animate various configuration parameters
	var t = demo_timer * 0.5
	
	hex_grid.hex_size = 30.0 + sin(t) * 15.0
	hex_grid.dot_radius = 4.0 + sin(t * 1.5) * 3.0
	hex_grid.border_width = 1.0 + sin(t * 2.0) * 2.0
	
	# Color animation
	var hue = fmod(t * 0.1, 1.0)
	hex_grid.dot_color = Color.from_hsv(hue, 0.8, 1.0)

## Stress test demonstration
func _setup_stress_test_demo() -> void:
	print("Demo Mode: Stress Test - Large Grid")
	hex_grid.grid_width = 100
	hex_grid.grid_height = 80
	hex_grid.enable_culling = true
	hex_grid.show_debug_info = true
	hex_grid.auto_optimize_performance = true

func _update_stress_test_demo(delta: float) -> void:
	# Stress test with large grid and rapid changes
	hex_grid.global_rotation_degrees = demo_timer * 10.0

## Handle mouse clicks
func _handle_mouse_click(mouse_pos: Vector2) -> void:
	if demo_mode != DemoMode.INTERACTIVE_MODE:
		return
	
	var world_pos = to_global(mouse_pos)
	var hex_index = hex_grid.get_hexagon_at_position(world_pos)
	var dot_index = hex_grid.get_dot_at_position(world_pos)
	
	if hex_index >= 0:
		print("Clicked hexagon #%d at position %s" % [hex_index, world_pos])
		# Could add visual feedback here
	elif dot_index >= 0:
		print("Clicked dot #%d at position %s" % [dot_index, world_pos])
		# Could add visual feedback here
	else:
		print("Clicked empty space at %s" % world_pos)

## Move to next demo mode
func _next_demo_mode() -> void:
	demo_mode = (demo_mode + 1) % 6
	_apply_demo_mode()
	print("Demo Mode: %d" % demo_mode)

## Reset demo to initial state
func _reset_demo() -> void:
	demo_mode = DemoMode.BASIC_GRID
	demo_timer = 0.0
	auto_demo = false
	_apply_demo_mode()
	print("Demo reset")

## Run test suite
func _run_tests() -> void:
	print("Running test suite...")
	var test_runner = HexGridTest.new()
	var results = test_runner.run_all_tests()
	
	print("Test Results:")
	print("  Total: %d" % results.summary.total_tests)
	print("  Passed: %d" % results.summary.passed_tests)
	print("  Failed: %d" % results.summary.failed_tests)
	print("  Success Rate: %.1f%%" % (results.summary.success_rate * 100.0))

## Run performance benchmarks
func _run_benchmarks() -> void:
	print("Running performance benchmarks...")
	var test_runner = HexGridTest.new()
	var results = test_runner.benchmark_performance()
	
	print("Benchmark Results:")
	for size_key in results:
		var result = results[size_key]
		print("  Grid %dx%d: %.2f ms, %d elements, %.2f MB" % [
			result.grid_size.x,
			result.grid_size.y,
			result.cache_build_time_ms,
			result.total_elements,
			result.memory_usage_bytes / (1024.0 * 1024.0)
		])

## Toggle debug information
func _toggle_debug() -> void:
	hex_grid.show_debug_info = !hex_grid.show_debug_info
	print("Debug info: ", hex_grid.show_debug_info)

## Update UI display
func _update_ui() -> void:
	# In a real implementation, this would update actual UI elements
	# For now, we'll just update the window title or print status
	pass

## Draw UI overlay
func _draw() -> void:
	# Draw demo information overlay
	var font_size = 16
	var line_height = 20
	var start_y = 10
	
	# Draw semi-transparent background
	draw_rect(Rect2(10, 10, 300, ui_labels.size() * line_height + 20), Color(0, 0, 0, 0.7))
	
	# Draw text labels (Note: This would need a font resource in a real implementation)
	for i in range(ui_labels.size()):
		var y_pos = start_y + 10 + i * line_height
		# draw_string(font, Vector2(20, y_pos), ui_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw current demo mode
	var mode_text = "Current Mode: %s" % _get_demo_mode_name(demo_mode)
	# draw_string(font, Vector2(20, start_y + ui_labels.size() * line_height + 30), mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)
	
	# Draw grid statistics
	if hex_grid and hex_grid.is_initialized:
		var stats = hex_grid.get_grid_stats()
		var stats_text = "Grid: %dx%d, Elements: %d, FPS: %.1f" % [
			stats.grid_size.x,
			stats.grid_size.y,
			stats.total_dots,
			1000.0 / max(1.0, hex_grid.get_average_frame_time())
		]
		# draw_string(font, Vector2(20, start_y + ui_labels.size() * line_height + 50), stats_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.GREEN)

## Get demo mode name
func _get_demo_mode_name(mode: int) -> String:
	match mode:
		DemoMode.BASIC_GRID: return "Basic Grid"
		DemoMode.PERFORMANCE_TEST: return "Performance Test"
		DemoMode.LAYER_SHOWCASE: return "Layer Showcase"
		DemoMode.INTERACTIVE_MODE: return "Interactive Mode"
		DemoMode.CONFIGURATION_DEMO: return "Configuration Demo"
		DemoMode.STRESS_TEST: return "Stress Test"
		_: return "Unknown"

## Signal handlers
func _on_grid_initialized() -> void:
	print("HexGridDemo: Grid initialized successfully")

func _on_grid_updated() -> void:
	print("HexGridDemo: Grid updated")

func _on_performance_warning(message: String) -> void:
	print("HexGridDemo: Performance warning - %s" % message)