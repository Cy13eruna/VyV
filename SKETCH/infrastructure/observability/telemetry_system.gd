# 🔬 TELEMETRY SYSTEM
# Purpose: Real-time performance monitoring and metrics collection
# Layer: Infrastructure/Observability

extends RefCounted

class_name TelemetrySystem

# Metric types
enum MetricType {
	COUNTER,
	GAUGE,
	HISTOGRAM,
	TIMER
}

# Metric data structure
class Metric:
	var name: String
	var type: MetricType
	var value: float = 0.0
	var timestamp: float
	var tags: Dictionary = {}
	var samples: Array = []
	var min_value: float = INF
	var max_value: float = -INF
	var sum_value: float = 0.0
	var count: int = 0
	
	func _init(metric_name: String, metric_type: MetricType):
		name = metric_name
		type = metric_type
		timestamp = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second

# Performance counters
class PerformanceCounter:
	var start_time: float
	var end_time: float
	var duration: float
	var name: String
	
	func _init(counter_name: String):
		name = counter_name
		start_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	func stop() -> float:
		end_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		duration = end_time - start_time
		return duration

# Telemetry state
var metrics: Dictionary = {}
var active_counters: Dictionary = {}
var collection_interval: float = 1.0
var max_samples_per_metric: int = 100
var is_enabled: bool = true

# System metrics
var fps_history: Array = []
var memory_history: Array = []
var frame_time_history: Array = []

# Game-specific metrics
var game_metrics: Dictionary = {
	"units_moved": 0,
	"turns_completed": 0,
	"pathfinding_calls": 0,
	"ai_decisions": 0,
	"network_messages": 0,
	"save_operations": 0,
	"load_operations": 0
}

# Initialize telemetry system
func _init():
	_setup_core_metrics()

# Setup core performance metrics
func _setup_core_metrics():
	create_metric("fps", MetricType.GAUGE)
	create_metric("frame_time_ms", MetricType.GAUGE)
	create_metric("memory_usage_mb", MetricType.GAUGE)
	create_metric("draw_calls", MetricType.COUNTER)
	create_metric("active_objects", MetricType.GAUGE)
	
	# Game-specific metrics
	create_metric("units_moved_total", MetricType.COUNTER)
	create_metric("turns_completed_total", MetricType.COUNTER)
	create_metric("pathfinding_duration_ms", MetricType.HISTOGRAM)
	create_metric("ai_decision_duration_ms", MetricType.HISTOGRAM)
	create_metric("network_latency_ms", MetricType.HISTOGRAM)

# Create new metric
func create_metric(name: String, type: MetricType, tags: Dictionary = {}) -> void:
	var metric = Metric.new(name, type)
	metric.tags = tags
	metrics[name] = metric

# Record metric value
func record_metric(name: String, value: float, tags: Dictionary = {}) -> void:
	if not is_enabled or name not in metrics:
		return
	
	var metric = metrics[name]
	var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
	
	match metric.type:
		MetricType.COUNTER:
			metric.value += value
			metric.sum_value += value
		MetricType.GAUGE:
			metric.value = value
		MetricType.HISTOGRAM, MetricType.TIMER:
			metric.samples.append({"value": value, "timestamp": current_time})
			if metric.samples.size() > max_samples_per_metric:
				metric.samples.pop_front()
			
			metric.min_value = min(metric.min_value, value)
			metric.max_value = max(metric.max_value, value)
			metric.sum_value += value
			metric.count += 1
	
	metric.timestamp = current_time

# Increment counter
func increment_counter(name: String, amount: float = 1.0) -> void:
	record_metric(name, amount)

# Set gauge value
func set_gauge(name: String, value: float) -> void:
	record_metric(name, value)

# Start performance timer
func start_timer(name: String) -> String:
	var timer_id = "%s_%d" % [name, Time.get_time_dict_from_system().hour * 3600000 + Time.get_time_dict_from_system().minute * 60000 + Time.get_time_dict_from_system().second * 1000]
	var counter = PerformanceCounter.new(name)
	active_counters[timer_id] = counter
	return timer_id

# Stop performance timer
func stop_timer(timer_id: String) -> float:
	if timer_id not in active_counters:
		return 0.0
	
	var counter = active_counters[timer_id]
	var duration = counter.stop()
	active_counters.erase(timer_id)
	
	# Record duration as histogram
	var metric_name = counter.name + "_duration_ms"
	record_metric(metric_name, duration * 1000.0)
	
	return duration

# Collect system metrics
func collect_system_metrics() -> void:
	if not is_enabled:
		return
	
	# FPS
	var fps = Engine.get_frames_per_second()
	set_gauge("fps", fps)
	fps_history.append(fps)
	if fps_history.size() > max_samples_per_metric:
		fps_history.pop_front()
	
	# Frame time
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	set_gauge("frame_time_ms", frame_time)
	frame_time_history.append(frame_time)
	if frame_time_history.size() > max_samples_per_metric:
		frame_time_history.pop_front()
	
	# Memory usage
	var memory_usage = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	set_gauge("memory_usage_mb", memory_usage)
	memory_history.append(memory_usage)
	if memory_history.size() > max_samples_per_metric:
		memory_history.pop_front()
	
	# Draw calls
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	set_gauge("draw_calls", draw_calls)

# Record game event
func record_game_event(event_name: String, data: Dictionary = {}) -> void:
	match event_name:
		"unit_moved":
			increment_counter("units_moved_total")
			game_metrics.units_moved += 1
		"turn_completed":
			increment_counter("turns_completed_total")
			game_metrics.turns_completed += 1
		"pathfinding_executed":
			game_metrics.pathfinding_calls += 1
			if "duration" in data:
				record_metric("pathfinding_duration_ms", data.duration)
		"ai_decision_made":
			game_metrics.ai_decisions += 1
			if "duration" in data:
				record_metric("ai_decision_duration_ms", data.duration)
		"network_message_sent":
			game_metrics.network_messages += 1
			if "latency" in data:
				record_metric("network_latency_ms", data.latency)
		"game_saved":
			game_metrics.save_operations += 1
		"game_loaded":
			game_metrics.load_operations += 1

# Get metric statistics
func get_metric_stats(name: String) -> Dictionary:
	if name not in metrics:
		return {}
	
	var metric = metrics[name]
	var stats = {
		"name": metric.name,
		"type": MetricType.keys()[metric.type],
		"current_value": metric.value,
		"timestamp": metric.timestamp
	}
	
	if metric.type == MetricType.HISTOGRAM or metric.type == MetricType.TIMER:
		if metric.count > 0:
			stats["min"] = metric.min_value
			stats["max"] = metric.max_value
			stats["avg"] = metric.sum_value / metric.count
			stats["count"] = metric.count
			stats["sum"] = metric.sum_value
		
		# Calculate percentiles
		if metric.samples.size() > 0:
			var sorted_samples = metric.samples.duplicate()
			sorted_samples.sort_custom(func(a, b): return a.value < b.value)
			
			var p50_idx = int(sorted_samples.size() * 0.5)
			var p95_idx = int(sorted_samples.size() * 0.95)
			var p99_idx = int(sorted_samples.size() * 0.99)
			
			stats["p50"] = sorted_samples[p50_idx].value if p50_idx < sorted_samples.size() else 0
			stats["p95"] = sorted_samples[p95_idx].value if p95_idx < sorted_samples.size() else 0
			stats["p99"] = sorted_samples[p99_idx].value if p99_idx < sorted_samples.size() else 0
	
	return stats

# Get all metrics summary
func get_metrics_summary() -> Dictionary:
	var summary = {
		"system_metrics": {},
		"game_metrics": game_metrics.duplicate(),
		"performance_summary": {},
		"alerts": []
	}
	
	# System metrics
	for metric_name in ["fps", "frame_time_ms", "memory_usage_mb"]:
		if metric_name in metrics:
			summary.system_metrics[metric_name] = get_metric_stats(metric_name)
	
	# Performance summary
	summary.performance_summary = {
		"avg_fps": _calculate_average(fps_history),
		"avg_frame_time": _calculate_average(frame_time_history),
		"avg_memory": _calculate_average(memory_history),
		"active_timers": active_counters.size()
	}
	
	# Generate alerts
	summary.alerts = _generate_performance_alerts()
	
	return summary

# Generate performance alerts
func _generate_performance_alerts() -> Array:
	var alerts = []
	
	# FPS alerts
	var avg_fps = _calculate_average(fps_history)
	if avg_fps < 30:
		alerts.append({
			"type": "performance",
			"severity": "high",
			"message": "Low FPS detected: %.1f" % avg_fps
		})
	elif avg_fps < 45:
		alerts.append({
			"type": "performance",
			"severity": "medium",
			"message": "Moderate FPS: %.1f" % avg_fps
		})
	
	# Memory alerts
	var avg_memory = _calculate_average(memory_history)
	if avg_memory > 500:  # 500MB
		alerts.append({
			"type": "memory",
			"severity": "high",
			"message": "High memory usage: %.1f MB" % avg_memory
		})
	elif avg_memory > 200:  # 200MB
		alerts.append({
			"type": "memory",
			"severity": "medium",
			"message": "Elevated memory usage: %.1f MB" % avg_memory
		})
	
	# Frame time alerts
	var avg_frame_time = _calculate_average(frame_time_history)
	if avg_frame_time > 33.3:  # > 30 FPS
		alerts.append({
			"type": "performance",
			"severity": "medium",
			"message": "High frame time: %.1f ms" % avg_frame_time
		})
	
	return alerts

# Export metrics to JSON
func export_metrics() -> String:
	var export_data = {
		"timestamp": Time.get_time_dict_from_system(),
		"metrics": {},
		"summary": get_metrics_summary()
	}
	
	for metric_name in metrics:
		export_data.metrics[metric_name] = get_metric_stats(metric_name)
	
	return JSON.stringify(export_data, "\t")

# Reset all metrics
func reset_metrics() -> void:
	for metric_name in metrics:
		var metric = metrics[metric_name]
		metric.value = 0.0
		metric.samples.clear()
		metric.min_value = INF
		metric.max_value = -INF
		metric.sum_value = 0.0
		metric.count = 0
	
	fps_history.clear()
	memory_history.clear()
	frame_time_history.clear()
	
	for key in game_metrics:
		game_metrics[key] = 0

# Helper functions
func _calculate_average(array: Array) -> float:
	if array.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	
	return sum / array.size()

# Enable/disable telemetry
func set_enabled(enabled: bool) -> void:
	is_enabled = enabled

# Get telemetry status
func get_status() -> Dictionary:
	return {
		"enabled": is_enabled,
		"metrics_count": metrics.size(),
		"active_timers": active_counters.size(),
		"collection_interval": collection_interval,
		"max_samples": max_samples_per_metric
	}