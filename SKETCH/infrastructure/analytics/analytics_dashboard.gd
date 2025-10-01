# 📈 ANALYTICS DASHBOARD
# Purpose: Visual analytics dashboard for real-time monitoring
# Layer: Infrastructure/Analytics

extends RefCounted

class_name AnalyticsDashboard

# Dashboard state
var debug_system
var analytics_system
var dashboard_enabled: bool = false
var current_tab: String = "overview"
var refresh_rate: float = 1.0
var last_refresh: float = 0.0

# Dashboard tabs
var available_tabs: Array = ["overview", "performance", "gameplay", "balance", "debug"]

# Chart data
var fps_chart_data: Array = []
var memory_chart_data: Array = []
var events_chart_data: Dictionary = {}

# Initialize dashboard
func _init():
	# Don't initialize systems here to avoid circular dependencies
	# They will be set externally
	pass

# Render dashboard
func render_dashboard(canvas: CanvasItem, font: Font, screen_size: Vector2) -> void:
	if not dashboard_enabled or not font:
		return
	
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	if current_time - last_refresh > refresh_rate:
		_refresh_data()
		last_refresh = current_time
	
	# Dashboard background
	var dashboard_rect = Rect2(50, 50, screen_size.x - 100, screen_size.y - 100)
	canvas.draw_rect(dashboard_rect, Color(0, 0, 0, 0.95))
	canvas.draw_rect(dashboard_rect, Color.CYAN, false, 2.0)
	
	# Title
	canvas.draw_string(font, Vector2(70, 80), "📈 ANALYTICS DASHBOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.CYAN)
	
	# Tab navigation
	_render_tab_navigation(canvas, font, Vector2(70, 100))
	
	# Tab content
	match current_tab:
		"overview":
			_render_overview_tab(canvas, font, Vector2(70, 140), Vector2(screen_size.x - 140, screen_size.y - 200))
		"performance":
			_render_performance_tab(canvas, font, Vector2(70, 140), Vector2(screen_size.x - 140, screen_size.y - 200))
		"gameplay":
			_render_gameplay_tab(canvas, font, Vector2(70, 140), Vector2(screen_size.x - 140, screen_size.y - 200))
		"balance":
			_render_balance_tab(canvas, font, Vector2(70, 140), Vector2(screen_size.x - 140, screen_size.y - 200))
		"debug":
			_render_debug_tab(canvas, font, Vector2(70, 140), Vector2(screen_size.x - 140, screen_size.y - 200))
	
	# Instructions
	canvas.draw_string(font, Vector2(70, screen_size.y - 80), "F6: Toggle Dashboard | TAB: Switch Tabs | ESC: Close", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.LIGHT_GRAY)

func _render_tab_navigation(canvas: CanvasItem, font: Font, position: Vector2) -> void:
	var tab_width = 120
	var x_offset = 0
	
	for tab in available_tabs:
		var tab_rect = Rect2(position.x + x_offset, position.y, tab_width, 30)
		var tab_color = Color.CYAN if tab == current_tab else Color.GRAY
		var text_color = Color.BLACK if tab == current_tab else Color.WHITE
		
		canvas.draw_rect(tab_rect, tab_color)
		canvas.draw_rect(tab_rect, Color.WHITE, false, 1.0)
		
		var tab_text = tab.capitalize()
		canvas.draw_string(font, Vector2(position.x + x_offset + 10, position.y + 20), tab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)
		
		x_offset += tab_width + 5

func _render_overview_tab(canvas: CanvasItem, font: Font, position: Vector2, size: Vector2) -> void:
	var y_offset = 0
	
	# Current session info
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "📊 CURRENT SESSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 25
	
	if analytics_system.current_session:
		var session = analytics_system.current_session
		var duration = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second - session.start_time
		
		var session_info = [
			"Session ID: %s" % session.session_id,
			"Duration: %.1f seconds" % duration,
			"Players: %d" % session.player_count,
			"Total Turns: %d" % session.total_turns,
			"Events Recorded: %d" % session.events.size()
		]
		
		for info in session_info:
			canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			y_offset += 15
	else:
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "No active session", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
		y_offset += 15
	
	y_offset += 20
	
	# Performance overview
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "⚡ PERFORMANCE OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 25
	
	var perf_metrics = analytics_system.performance_metrics
	var perf_info = [
		"Average FPS: %.1f" % perf_metrics.avg_fps,
		"Frame Time: %.2f ms" % perf_metrics.avg_frame_time,
		"Memory Usage: %.1f MB" % perf_metrics.memory_usage,
		"Frame Drops: %d" % perf_metrics.frame_drops
	]
	
	for info in perf_info:
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
	
	y_offset += 20
	
	# Recent events
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "📝 RECENT EVENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 25
	
	var recent_events = analytics_system.events_buffer.slice(max(0, analytics_system.events_buffer.size() - 8), analytics_system.events_buffer.size())
	for event in recent_events:
		var event_text = "[%s] %s (Player %d)" % [AnalyticsSystem.EventType.keys()[event.event_type], event.data, event.player_id]
		if event_text.length() > 60:
			event_text = event_text.substr(0, 57) + "..."
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), event_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.LIGHT_GRAY)
		y_offset += 12

func _render_performance_tab(canvas: CanvasItem, font: Font, position: Vector2, size: Vector2) -> void:
	var y_offset = 0
	
	# Performance metrics
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "⚡ PERFORMANCE METRICS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 30
	
	# FPS Chart
	_render_line_chart(canvas, position + Vector2(0, y_offset), Vector2(400, 120), fps_chart_data, "FPS", Color.GREEN, 0, 60)
	y_offset += 140
	
	# Memory Chart
	_render_line_chart(canvas, position + Vector2(0, y_offset), Vector2(400, 120), memory_chart_data, "Memory (MB)", Color.BLUE, 0, 500)
	y_offset += 140
	
	# Performance recommendations
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "💡 RECOMMENDATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	y_offset += 25
	
	var report = analytics_system.get_performance_report()
	for recommendation in report.recommendations:
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "• " + recommendation, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		y_offset += 15

func _render_gameplay_tab(canvas: CanvasItem, font: Font, position: Vector2, size: Vector2) -> void:
	var y_offset = 0
	
	# Gameplay statistics
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "🎮 GAMEPLAY STATISTICS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 30
	
	# Event distribution chart
	if not events_chart_data.is_empty():
		_render_bar_chart(canvas, position + Vector2(0, y_offset), Vector2(500, 200), events_chart_data, "Event Distribution")
		y_offset += 220
	
	# Player statistics
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "👥 PLAYER STATISTICS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	y_offset += 25
	
	for player_id in range(1, 3):  # Assuming 2 players
		var player_analytics = analytics_system.get_player_analytics(player_id)
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "Player %d:" % player_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.CYAN)
		y_offset += 15
		
		var player_info = [
			"  Games Played: %d" % player_analytics.total_games,
			"  Wins: %d" % player_analytics.wins,
			"  Avg Actions/Turn: %.1f" % player_analytics.avg_actions_per_turn
		]
		
		for info in player_info:
			canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
			y_offset += 13
		
		y_offset += 10

func _render_balance_tab(canvas: CanvasItem, font: Font, position: Vector2, size: Vector2) -> void:
	var y_offset = 0
	
	# Game balance report
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "⚖️ GAME BALANCE REPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 30
	
	var balance_report = analytics_system.get_game_balance_report()
	
	var balance_info = [
		"Total Games Analyzed: %d" % balance_report.total_games,
		"Average Game Duration: %.1f seconds" % balance_report.average_game_duration
	]
	
	for info in balance_info:
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
	
	y_offset += 20
	
	# Win distribution
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "🏆 WIN DISTRIBUTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	y_offset += 25
	
	for player_id in balance_report.win_distribution:
		var wins = balance_report.win_distribution[player_id]
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "Player %s: %d wins" % [player_id, wins], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
	
	y_offset += 20
	
	# Balance issues
	if not balance_report.balance_issues.is_empty():
		canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "⚠️ BALANCE ISSUES", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
		y_offset += 25
		
		for issue in balance_report.balance_issues:
			canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "• " + issue, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.ORANGE)
			y_offset += 15

func _render_debug_tab(canvas: CanvasItem, font: Font, position: Vector2, size: Vector2) -> void:
	var y_offset = 0
	
	# Debug system status
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "🐛 DEBUG SYSTEM STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
	y_offset += 30
	
	var debug_stats = debug_system.get_debug_stats()
	var debug_info = [
		"Debug Level: %s" % debug_stats.debug_level,
		"Total Entries: %d" % debug_stats.total_entries,
		"Performance Tracking: %s" % ("ON" if debug_stats.performance_tracking else "OFF")
	]
	
	for info in debug_info:
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		y_offset += 15
	
	y_offset += 20
	
	# Debug entries by level
	canvas.draw_string(font, Vector2(position.x, position.y + y_offset), "📊 ENTRIES BY LEVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	y_offset += 25
	
	for level in debug_stats.entries_by_level:
		var count = debug_stats.entries_by_level[level]
		var color = Color.WHITE
		match level:
			"ERROR":
				color = Color.RED
			"WARN":
				color = Color.YELLOW
			"DEBUG":
				color = Color.CYAN
		
		canvas.draw_string(font, Vector2(position.x + 20, position.y + y_offset), "%s: %d" % [level, count], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		y_offset += 15

# Chart rendering methods
func _render_line_chart(canvas: CanvasItem, position: Vector2, size: Vector2, data: Array, title: String, color: Color, min_val: float, max_val: float) -> void:
	# Chart background
	canvas.draw_rect(Rect2(position, size), Color(0.1, 0.1, 0.1, 0.8))
	canvas.draw_rect(Rect2(position, size), Color.WHITE, false, 1.0)
	
	# Title
	canvas.draw_string(ThemeDB.fallback_font, position + Vector2(10, 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	if data.size() < 2:
		return
	
	# Draw data points
	for i in range(1, data.size()):
		var x1 = position.x + (i - 1) * size.x / data.size()
		var x2 = position.x + i * size.x / data.size()
		
		var y1 = position.y + size.y - (data[i - 1] - min_val) / (max_val - min_val) * size.y
		var y2 = position.y + size.y - (data[i] - min_val) / (max_val - min_val) * size.y
		
		canvas.draw_line(Vector2(x1, y1), Vector2(x2, y2), color, 2.0)

func _render_bar_chart(canvas: CanvasItem, position: Vector2, size: Vector2, data: Dictionary, title: String) -> void:
	# Chart background
	canvas.draw_rect(Rect2(position, size), Color(0.1, 0.1, 0.1, 0.8))
	canvas.draw_rect(Rect2(position, size), Color.WHITE, false, 1.0)
	
	# Title
	canvas.draw_string(ThemeDB.fallback_font, position + Vector2(10, 20), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	
	if data.is_empty():
		return
	
	var max_value = 0
	for key in data:
		max_value = max(max_value, data[key])
	
	if max_value == 0:
		return
	
	var bar_width = size.x / data.size()
	var x_offset = 0
	
	for key in data:
		var value = data[key]
		var bar_height = (value / float(max_value)) * (size.y - 40)
		
		var bar_rect = Rect2(position.x + x_offset, position.y + size.y - bar_height, bar_width - 2, bar_height)
		canvas.draw_rect(bar_rect, Color.CYAN)
		
		# Label
		canvas.draw_string(ThemeDB.fallback_font, Vector2(position.x + x_offset, position.y + size.y + 15), str(key), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		
		x_offset += bar_width

# Dashboard controls
func toggle_dashboard() -> void:
	dashboard_enabled = not dashboard_enabled
	if debug_system:
		debug_system.info(debug_system.DebugCategory.GENERAL, "Analytics dashboard toggled: %s" % dashboard_enabled)

func switch_tab() -> void:
	var current_index = available_tabs.find(current_tab)
	current_index = (current_index + 1) % available_tabs.size()
	current_tab = available_tabs[current_index]
	if debug_system:
		debug_system.info(debug_system.DebugCategory.GENERAL, "Dashboard tab switched to: %s" % current_tab)

func set_tab(tab_name: String) -> void:
	if tab_name in available_tabs:
		current_tab = tab_name

# Data refresh
func _refresh_data() -> void:
	# Update FPS chart data
	var current_fps = Engine.get_frames_per_second()
	fps_chart_data.append(current_fps)
	if fps_chart_data.size() > 60:  # Keep last 60 samples
		fps_chart_data.pop_front()
	
	# Update memory chart data
	var current_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	memory_chart_data.append(current_memory)
	if memory_chart_data.size() > 60:
		memory_chart_data.pop_front()
	
	# Update events chart data
	if analytics_system:
		events_chart_data.clear()
		for event in analytics_system.events_buffer:
			# Use string representation instead of enum
			var event_type = str(event.event_type)
			if event_type not in events_chart_data:
				events_chart_data[event_type] = 0
			events_chart_data[event_type] += 1
		
		# Track performance sample
		analytics_system.track_performance_sample(current_fps, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, current_memory)