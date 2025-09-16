## HexGridTest
## 
## Test suite for validating the hexagonal grid system components.
## Provides automated testing for configuration, geometry, cache, and rendering.
##
## @author: V&V Game Studio
## @version: 2.0

extends Node
class_name HexGridTest

## Test results
var test_results: Dictionary = {}
var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

## Test components
var config: HexGridConfig
var geometry: HexGridGeometry
var cache: HexGridCache
var renderer: HexGridRenderer

## Run all tests
func run_all_tests() -> Dictionary:
	print("HexGridTest: Starting comprehensive test suite...")
	
	_reset_test_results()
	_setup_test_components()
	
	# Run test suites
	_test_config_system()
	_test_geometry_calculations()
	_test_cache_system()
	_test_renderer_system()
	_test_integration()
	
	# Generate report
	var report = _generate_test_report()
	print("HexGridTest: Test suite completed")
	print("Results: %d/%d tests passed (%.1f%%)" % [passed_tests, total_tests, (float(passed_tests) / total_tests) * 100.0])
	
	return report

## Test configuration system
func _test_config_system() -> void:
	print("Testing HexGridConfig...")
	
	# Test validation
	_run_test("Config validation - grid width", func():
		config.set_grid_width(-5)
		return config.grid_width == 1  # Should clamp to minimum
	)
	
	_run_test("Config validation - hex size", func():
		config.set_hex_size(1000.0)
		return config.hex_size == 200.0  # Should clamp to maximum
	)
	
	# Test change detection
	_run_test("Config change detection", func():
		var initial_dirty = config.is_dirty()
		config.set_grid_width(30)
		return config.is_dirty() != initial_dirty
	)
	
	# Test serialization
	_run_test("Config serialization", func():
		var original_data = config.to_dict()
		var new_config = HexGridConfig.new()
		new_config.from_dict(original_data)
		return new_config.grid_width == config.grid_width and new_config.hex_size == config.hex_size
	)
	
	# Test color generation
	_run_test("Diamond color generation", func():
		var colors = config.generate_diamond_colors(100)
		return colors.size() == 100 and colors[0] is Color
	)

## Test geometry calculations
func _test_geometry_calculations() -> void:
	print("Testing HexGridGeometry...")
	
	# Test hex position calculation
	_run_test("Hex position calculation", func():
		var positions = geometry.calculate_hex_positions(config)
		return positions.size() == config.grid_width * config.grid_height
	)
	
	# Test vertex calculation
	_run_test("Hex vertex calculation", func():
		var vertices = geometry.calculate_hex_vertices(Vector2.ZERO, 35.0)
		return vertices.size() == 6
	)
	
	# Test diamond geometry
	_run_test("Diamond geometry calculation", func():
		var diamond = geometry.calculate_diamond_geometry(Vector2.ZERO, Vector2(50, 0))
		return diamond.size() == 4
	)
	
	# Test star geometry
	_run_test("Star geometry calculation", func():
		var star = geometry.calculate_star_geometry(Vector2.ZERO, 10.0, 5.0)
		return star.size() == 12
	)
	
	# Test rotation
	_run_test("Point rotation", func():
		var original = Vector2(10, 0)
		var rotated = geometry.rotate_point_around_center(original, Vector2.ZERO, PI/2)
		return is_equal_approx(rotated.x, 0.0) and is_equal_approx(rotated.y, 10.0)
	)
	
	# Test parameter validation
	_run_test("Parameter validation", func():
		return geometry.validate_parameters(35.0, 25, 18) and not geometry.validate_parameters(-1.0, 0, 0)
	)

## Test cache system
func _test_cache_system() -> void:
	print("Testing HexGridCache...")
	
	# Test cache building
	_run_test("Cache building", func():
		cache.build_cache()
		return cache.is_valid()
	)
	
	# Test cache invalidation
	_run_test("Cache invalidation", func():
		cache.build_cache()
		cache.invalidate_cache()
		return not cache.is_valid()
	)
	
	# Test data retrieval
	_run_test("Cache data retrieval", func():
		cache.build_cache()
		var hex_positions = cache.get_hex_positions()
		var dot_positions = cache.get_dot_positions()
		return hex_positions.size() > 0 and dot_positions.size() > 0
	)
	
	# Test spatial grid
	_run_test("Spatial grid lookup", func():
		cache.build_cache()
		var dot_positions = cache.get_dot_positions()
		if dot_positions.size() > 0:
			var nearby = cache.find_nearby_dots(dot_positions[0], 50.0)
			return nearby.size() > 0
		return false
	)
	
	# Test performance stats
	_run_test("Performance statistics", func():
		cache.build_cache()
		var stats = cache.get_performance_stats()
		return stats.has("cache_hits") and stats.has("memory_usage_bytes")
	)

## Test renderer system
func _test_renderer_system() -> void:
	print("Testing HexGridRenderer...")
	
	# Test layer visibility
	_run_test("Layer visibility control", func():
		renderer.set_layer_visibility(HexGridRenderer.RenderLayer.DEBUG, true)
		return renderer.get_layer_visibility(HexGridRenderer.RenderLayer.DEBUG)
	)
	
	# Test culling
	_run_test("Culling functionality", func():
		renderer.set_culling_enabled(true, 100.0)
		return renderer.should_render_point(Vector2.ZERO)  # Should be visible at origin
	)
	
	# Test shape culling
	_run_test("Shape culling", func():
		var shape = PackedVector2Array([Vector2.ZERO, Vector2(10, 0), Vector2(5, 10)])
		return renderer.should_render_shape(shape)
	)
	
	# Test render stats
	_run_test("Render statistics", func():
		var stats = renderer.get_render_stats()
		return stats.has("diamonds_rendered") and stats.has("total_draw_calls")
	)

## Test integration between components
func _test_integration() -> void:
	print("Testing component integration...")
	
	# Test config-cache integration
	_run_test("Config-Cache integration", func():
		cache.build_cache()
		var initial_valid = cache.is_valid()
		config.set_grid_width(config.grid_width + 1)  # Change config
		return initial_valid and not cache.is_valid()  # Cache should be invalidated
	)
	
	# Test geometry-cache integration
	_run_test("Geometry-Cache integration", func():
		cache.build_cache()
		var hex_positions = cache.get_hex_positions()
		var manual_positions = geometry.calculate_hex_positions(config)
		return hex_positions.size() == manual_positions.size()
	)
	
	# Test cache-renderer integration
	_run_test("Cache-Renderer integration", func():
		cache.build_cache()
		var diamond_geometry = cache.get_diamond_geometry()
		var star_geometry = cache.get_star_geometry()
		return diamond_geometry.size() > 0 and star_geometry.size() > 0
	)

## Setup test components
func _setup_test_components() -> void:
	config = HexGridConfig.new()
	geometry = HexGridGeometry.new()
	cache = HexGridCache.new(config, geometry)
	renderer = HexGridRenderer.new(config, cache, geometry)

## Reset test results
func _reset_test_results() -> void:
	test_results.clear()
	total_tests = 0
	passed_tests = 0
	failed_tests = 0

## Run a single test
## @param test_name String: Name of the test
## @param test_func Callable: Function that returns true if test passes
func _run_test(test_name: String, test_func: Callable) -> void:
	total_tests += 1
	
	var start_time = Time.get_time_dict_from_system()
	var result = false
	var error_message = ""
	
	try:
		result = test_func.call()
	except:
		error_message = "Test threw an exception"
	
	var end_time = Time.get_time_dict_from_system()
	var duration = (end_time["unix"] - start_time["unix"]) * 1000.0
	
	if result:
		passed_tests += 1
		print("  ✓ %s (%.2f ms)" % [test_name, duration])
	else:
		failed_tests += 1
		print("  ✗ %s (%.2f ms) - %s" % [test_name, duration, error_message])
	
	test_results[test_name] = {
		"passed": result,
		"duration_ms": duration,
		"error": error_message
	}

## Generate comprehensive test report
## @return Dictionary: Test report with statistics
func _generate_test_report() -> Dictionary:
	var report = {
		"summary": {
			"total_tests": total_tests,
			"passed_tests": passed_tests,
			"failed_tests": failed_tests,
			"success_rate": float(passed_tests) / total_tests if total_tests > 0 else 0.0
		},
		"detailed_results": test_results,
		"performance": {
			"total_duration_ms": 0.0,
			"average_test_duration_ms": 0.0,
			"slowest_test": "",
			"fastest_test": ""
		}
	}
	
	# Calculate performance metrics
	var total_duration = 0.0
	var slowest_time = 0.0
	var fastest_time = INF
	var slowest_test = ""
	var fastest_test = ""
	
	for test_name in test_results:
		var duration = test_results[test_name].duration_ms
		total_duration += duration
		
		if duration > slowest_time:
			slowest_time = duration
			slowest_test = test_name
		
		if duration < fastest_time:
			fastest_time = duration
			fastest_test = test_name
	
	report.performance.total_duration_ms = total_duration
	report.performance.average_test_duration_ms = total_duration / total_tests if total_tests > 0 else 0.0
	report.performance.slowest_test = "%s (%.2f ms)" % [slowest_test, slowest_time]
	report.performance.fastest_test = "%s (%.2f ms)" % [fastest_test, fastest_time]
	
	return report

## Benchmark performance with different grid sizes
## @return Dictionary: Benchmark results
func benchmark_performance() -> Dictionary:
	print("HexGridTest: Running performance benchmarks...")
	
	var benchmark_results = {}
	var grid_sizes = [
		Vector2i(10, 10),
		Vector2i(25, 18),
		Vector2i(50, 50),
		Vector2i(100, 100)
	]
	
	for size in grid_sizes:
		print("Benchmarking grid size: %dx%d" % [size.x, size.y])
		
		# Setup
		var test_config = HexGridConfig.new()
		test_config.set_grid_width(size.x)
		test_config.set_grid_height(size.y)
		
		var test_geometry = HexGridGeometry.new()
		var test_cache = HexGridCache.new(test_config, test_geometry)
		
		# Benchmark cache building
		var start_time = Time.get_time_dict_from_system()
		test_cache.build_cache()
		var end_time = Time.get_time_dict_from_system()
		
		var cache_build_time = (end_time["unix"] - start_time["unix"]) * 1000.0
		var cache_stats = test_cache.get_performance_stats()
		
		benchmark_results[str(size)] = {
			"grid_size": size,
			"total_hexagons": size.x * size.y,
			"cache_build_time_ms": cache_build_time,
			"memory_usage_bytes": cache_stats.memory_usage_bytes,
			"total_elements": cache_stats.total_elements
		}
	
	print("HexGridTest: Performance benchmarks completed")
	return benchmark_results