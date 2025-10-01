# 🐛 ADVANCED DEBUG SYSTEM
# Purpose: Comprehensive debugging tools and visualization
# Layer: Infrastructure/Debugging

extends RefCounted

class_name DebugSystem

# Debug levels
enum DebugLevel {
	NONE = 0,
	ERROR = 1,
	WARN = 2,
	INFO = 3,
	DEBUG = 4,
	TRACE = 5
}

# Debug categories
enum DebugCategory {
	GENERAL,
	GAMEPLAY,
	RENDERING,
	INPUT,
	AI,
	PERFORMANCE,
	NETWORK,
	AUDIO
}

# Debug entry structure
class DebugEntry:
	var timestamp: float
	var level: DebugLevel
	var category: DebugCategory
	var message: String
	var data: Dictionary
	var stack_trace: Array
	
	func _init(lvl: DebugLevel, cat: DebugCategory, msg: String, debug_data: Dictionary = {}):
		timestamp = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		level = lvl
		category = cat
		message = msg
		data = debug_data
		if level <= DebugLevel.ERROR:
			stack_trace = get_stack()
	
	func get_string() -> String:
		var time_str = Time.get_time_string_from_system()
		var level_str = DebugLevel.keys()[level]
		var cat_str = DebugCategory.keys()[category]
		return "[%s] %s/%s: %s" % [time_str, level_str, cat_str, message]

# Debug state
var debug_level: DebugLevel = DebugLevel.INFO
var enabled_categories: Array = []
var debug_entries: Array[DebugEntry] = []
var max_entries: int = 1000
var debug_overlay_enabled: bool = false
var performance_tracking: bool = true

# Performance tracking
var frame_times: Array = []
var memory_samples: Array = []
var fps_samples: Array = []
var max_samples: int = 300  # 5 minutes at 60fps

# Debug visualization
var debug_draw_enabled: bool = true
var show_grid_debug: bool = false
var show_unit_debug: bool = false
var show_ai_debug: bool = false
var show_performance_graph: bool = false

# Singleton instance
static var instance: DebugSystem

# Initialize debug system
func _init():
	if instance == null:
		instance = self
	
	# Enable all categories by default
	for category in DebugCategory.values():
		enabled_categories.append(category)
	
	print("🐛 Debug System initialized")

# Get singleton instance
static func get_instance():
	if instance == null:
		instance = DebugSystem.new()
	return instance

# Log debug message
func log_message(level: DebugLevel, category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	if level > debug_level or category not in enabled_categories:
		return
	
	var entry = DebugEntry.new(level, category, message, data)
	debug_entries.append(entry)
	
	# Trim entries if too many
	if debug_entries.size() > max_entries:
		debug_entries.pop_front()
	
	# Print to console based on level
	match level:
		DebugLevel.ERROR:
			print_rich("[color=red]ERROR: %s[/color]" % entry.get_string())
		DebugLevel.WARN:
			print_rich("[color=yellow]WARN: %s[/color]" % entry.get_string())
		DebugLevel.INFO:
			print("INFO: %s" % entry.get_string())
		DebugLevel.DEBUG:
			print_rich("[color=cyan]DEBUG: %s[/color]" % entry.get_string())
		DebugLevel.TRACE:
			print_rich("[color=gray]TRACE: %s[/color]" % entry.get_string())

# Convenience methods
func error(category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	log_message(DebugLevel.ERROR, category, message, data)

func warn(category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	log_message(DebugLevel.WARN, category, message, data)

func info(category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	log_message(DebugLevel.INFO, category, message, data)

func debug(category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	log_message(DebugLevel.DEBUG, category, message, data)

func trace(category: DebugCategory, message: String, data: Dictionary = {}) -> void:
	log_message(DebugLevel.TRACE, category, message, data)

# Performance tracking
func track_frame_time(frame_time: float) -> void:
	if not performance_tracking:
		return
	
	frame_times.append(frame_time)
	if frame_times.size() > max_samples:
		frame_times.pop_front()

func track_memory_usage(memory_mb: float) -> void:
	if not performance_tracking:
		return
	
	memory_samples.append(memory_mb)
	if memory_samples.size() > max_samples:
		memory_samples.pop_front()

func track_fps(fps: float) -> void:
	if not performance_tracking:
		return
	
	fps_samples.append(fps)
	if fps_samples.size() > max_samples:
		fps_samples.pop_front()

# Debug visualization methods
func render_debug_overlay(canvas: CanvasItem, font: Font) -> void:
	if not debug_overlay_enabled or not font:
		return
	
	var y_offset = 10
	
	# Performance info
	if performance_tracking:
		var fps = Engine.get_frames_per_second()
		var memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
		var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		
		canvas.draw_string(font, Vector2(10, y_offset), "🔍 DEBUG OVERLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.CYAN)
		y_offset += 20
		
		canvas.draw_string(font, Vector2(10, y_offset), "FPS: %.1f" % fps, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
		
		canvas.draw_string(font, Vector2(10, y_offset), "Frame Time: %.2f ms" % frame_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
		
		canvas.draw_string(font, Vector2(10, y_offset), "Memory: %.1f MB" % memory, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 20
		
		# Track performance
		track_frame_time(frame_time)
		track_memory_usage(memory)
		track_fps(fps)
	
	# Recent debug entries
	canvas.draw_string(font, Vector2(10, y_offset), "📝 RECENT LOGS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	y_offset += 15
	
	var recent_entries = debug_entries.slice(max(0, debug_entries.size() - 5), debug_entries.size())
	for entry in recent_entries:
		var color = _get_level_color(entry.level)
		var short_msg = entry.message
		if short_msg.length() > 50:
			short_msg = short_msg.substr(0, 47) + "..."
		
		canvas.draw_string(font, Vector2(20, y_offset), short_msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
		y_offset += 12

func render_performance_graph(canvas: CanvasItem, position: Vector2, size: Vector2) -> void:
	if not show_performance_graph or fps_samples.size() < 2:
		return
	
	# Draw background
	canvas.draw_rect(Rect2(position, size), Color(0, 0, 0, 0.8))
	canvas.draw_rect(Rect2(position, size), Color.WHITE, false, 1.0)
	
	# Draw FPS graph
	var max_fps = 60.0
	var min_fps = 0.0
	
	for i in range(1, fps_samples.size()):
		var x1 = position.x + (i - 1) * size.x / fps_samples.size()
		var x2 = position.x + i * size.x / fps_samples.size()
		
		var y1 = position.y + size.y - (fps_samples[i - 1] - min_fps) / (max_fps - min_fps) * size.y
		var y2 = position.y + size.y - (fps_samples[i] - min_fps) / (max_fps - min_fps) * size.y
		
		canvas.draw_line(Vector2(x1, y1), Vector2(x2, y2), Color.GREEN, 2.0)
	
	# Draw target FPS line
	var target_y = position.y + size.y - (60.0 - min_fps) / (max_fps - min_fps) * size.y
	canvas.draw_line(Vector2(position.x, target_y), Vector2(position.x + size.x, target_y), Color.RED, 1.0)

func render_grid_debug(canvas: CanvasItem, grid_data: Dictionary, font: Font) -> void:
	if not show_grid_debug or not font:
		return
	
	# Draw grid point IDs and coordinates
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		var pos = point.position.pixel_pos
		
		# Draw point ID
		canvas.draw_string(font, pos + Vector2(-10, -20), str(point_id), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.CYAN)
		
		# Draw hex coordinates
		var coord_text = "(%d,%d)" % [point.coordinate.q, point.coordinate.r]
		canvas.draw_string(font, pos + Vector2(-15, 35), coord_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.YELLOW)

func render_unit_debug(canvas: CanvasItem, units_data: Dictionary, font: Font) -> void:
	if not show_unit_debug or not font:
		return
	
	# Draw unit debug info
	for unit_id in units_data:
		var unit = units_data[unit_id]
		var pos = unit.position.pixel_pos
		
		# Draw unit stats
		var stats_text = "ID:%d HP:%d/%d AP:%d" % [unit_id, unit.current_health, unit.max_health, unit.actions_remaining]
		canvas.draw_string(font, pos + Vector2(-30, -40), stats_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)
		
		# Draw movement range circle
		if unit.actions_remaining > 0:
			canvas.draw_arc(pos, unit.movement_range * 30, 0, TAU, 32, Color.GREEN, 2.0)

# Debug controls
func toggle_debug_overlay() -> void:
	debug_overlay_enabled = not debug_overlay_enabled
	info(DebugCategory.GENERAL, "Debug overlay toggled: %s" % debug_overlay_enabled)

func toggle_grid_debug() -> void:
	show_grid_debug = not show_grid_debug
	info(DebugCategory.RENDERING, "Grid debug toggled: %s" % show_grid_debug)

func toggle_unit_debug() -> void:
	show_unit_debug = not show_unit_debug
	info(DebugCategory.GAMEPLAY, "Unit debug toggled: %s" % show_unit_debug)

func toggle_performance_graph() -> void:
	show_performance_graph = not show_performance_graph
	info(DebugCategory.PERFORMANCE, "Performance graph toggled: %s" % show_performance_graph)

func set_debug_level(level: DebugLevel) -> void:
	debug_level = level
	info(DebugCategory.GENERAL, "Debug level set to: %s" % DebugLevel.keys()[level])

func enable_category(category: DebugCategory) -> void:
	if category not in enabled_categories:
		enabled_categories.append(category)

func disable_category(category: DebugCategory) -> void:
	if category in enabled_categories:
		enabled_categories.erase(category)

# Export debug data
func export_debug_log() -> String:
	var export_data = {
		"timestamp": Time.get_time_dict_from_system(),
		"debug_level": DebugLevel.keys()[debug_level],
		"entries": []
	}
	
	for entry in debug_entries:
		export_data.entries.append({
			"timestamp": entry.timestamp,
			"level": DebugLevel.keys()[entry.level],
			"category": DebugCategory.keys()[entry.category],
			"message": entry.message,
			"data": entry.data
		})
	
	return JSON.stringify(export_data, "\t")

func export_performance_data() -> Dictionary:
	return {
		"fps_samples": fps_samples,
		"frame_times": frame_times,
		"memory_samples": memory_samples,
		"avg_fps": _calculate_average(fps_samples),
		"avg_frame_time": _calculate_average(frame_times),
		"avg_memory": _calculate_average(memory_samples)
	}

# Get debug statistics
func get_debug_stats() -> Dictionary:
	var stats = {
		"total_entries": debug_entries.size(),
		"entries_by_level": {},
		"entries_by_category": {},
		"debug_level": DebugLevel.keys()[debug_level],
		"enabled_categories": [],
		"performance_tracking": performance_tracking
	}
	
	# Count by level
	for level in DebugLevel.values():
		stats.entries_by_level[DebugLevel.keys()[level]] = 0
	
	for entry in debug_entries:
		stats.entries_by_level[DebugLevel.keys()[entry.level]] += 1
	
	# Count by category
	for category in DebugCategory.values():
		stats.entries_by_category[DebugCategory.keys()[category]] = 0
	
	for entry in debug_entries:
		stats.entries_by_category[DebugCategory.keys()[entry.category]] += 1
	
	# Enabled categories
	for category in enabled_categories:
		stats.enabled_categories.append(DebugCategory.keys()[category])
	
	return stats

# Helper methods
func _get_level_color(level: DebugLevel) -> Color:
	match level:
		DebugLevel.ERROR:
			return Color.RED
		DebugLevel.WARN:
			return Color.YELLOW
		DebugLevel.INFO:
			return Color.WHITE
		DebugLevel.DEBUG:
			return Color.CYAN
		DebugLevel.TRACE:
			return Color.GRAY
		_:
			return Color.WHITE

func _calculate_average(array: Array) -> float:
	if array.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	
	return sum / array.size()