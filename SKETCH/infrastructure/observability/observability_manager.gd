# 🔍 OBSERVABILITY MANAGER
# Purpose: Centralized management of telemetry, logging, and error handling
# Layer: Infrastructure/Observability

extends RefCounted

class_name ObservabilityManager

# System components
var telemetry_system
var logging_system
var error_handler

# Component loggers
var component_loggers: Dictionary = {}

# Singleton instance
static var instance: ObservabilityManager

# Initialize observability manager
func _init():
	if instance == null:
		instance = self
	
	# Initialize systems with dynamic loading
	var LoggingSystem = load("res://infrastructure/observability/logging_system.gd")
	var TelemetrySystem = load("res://infrastructure/observability/telemetry_system.gd")
	var ErrorHandler = load("res://infrastructure/reliability/error_handler.gd")
	
	logging_system = LoggingSystem.new()
	telemetry_system = TelemetrySystem.new()
	error_handler = ErrorHandler.new(logging_system, telemetry_system)
	
	# Create component-specific loggers
	component_loggers = logging_system.create_component_loggers()
	
	# Setup telemetry collection
	_setup_telemetry_collection()
	
	print("🔍 Observability Manager initialized")

# Get singleton instance
static func get_instance():
	if instance == null:
		instance = ObservabilityManager.new()
	return instance

# Setup automatic telemetry collection
func _setup_telemetry_collection() -> void:
	# Start periodic system metrics collection
	var timer = Timer.new()
	timer.wait_time = 1.0  # Collect every second
	timer.timeout.connect(_collect_periodic_metrics)
	timer.autostart = true
	# Note: In real implementation, add timer to scene tree

# Collect periodic metrics
func _collect_periodic_metrics() -> void:
	telemetry_system.collect_system_metrics()

# Get logger for specific component
func get_logger(component: String):
	if component in component_loggers:
		return component_loggers[component]
	
	# Create new logger if not exists
	var logger = logging_system.get_logger(component)
	component_loggers[component] = logger
	return logger

# Record telemetry metric
func record_metric(name: String, value: float, tags: Dictionary = {}) -> void:
	telemetry_system.record_metric(name, value, tags)

# Start performance timer
func start_timer(name: String) -> String:
	return telemetry_system.start_timer(name)

# Stop performance timer
func stop_timer(timer_id: String) -> float:
	return telemetry_system.stop_timer(timer_id)

# Handle error with full observability
func handle_error(message: String, severity, category, context: Dictionary = {}):
	return error_handler.handle_error(message, severity, category, context)

# Record game event with telemetry and logging
func record_game_event(event_name: String, data: Dictionary = {}) -> void:
	# Record in telemetry
	telemetry_system.record_game_event(event_name, data)
	
	# Log the event
	var logger = get_logger("game.events")
	logger.info("Game event: " + event_name, data)

# Validate with error handling
func validate_with_handling(data, validation_rules: Dictionary, component: String = "validation"):
	var result = error_handler.validate_input(data, validation_rules)
	
	if result.has_errors():
		var logger = get_logger(component)
		logger.warn("Validation failed: " + result.get_summary(), {
			"errors": result.errors,
			"warnings": result.warnings
		})
		
		# Record validation failure metric
		telemetry_system.increment_counter("validation_failures_total")
	
	return result

# Get comprehensive system status
func get_system_status() -> Dictionary:
	return {
		"telemetry": telemetry_system.get_status(),
		"logging": logging_system.get_stats(),
		"errors": error_handler.get_error_stats(),
		"metrics_summary": telemetry_system.get_metrics_summary()
	}

# Performance monitoring wrapper
func monitor_performance(operation_name: String, callable: Callable):
	var timer_id = start_timer(operation_name)
	var logger = get_logger("performance")
	
	logger.debug("Starting operation: " + operation_name)
	
	var result
	var error_occurred = false
	
	# Execute operation with error handling
	result = callable.call()
	# Note: Godot doesn't have try/catch, so we'll handle errors differently
	
	var duration = stop_timer(timer_id)
	
	if error_occurred:
		logger.error("Operation failed: " + operation_name, {"duration_ms": duration * 1000})
		telemetry_system.increment_counter("operations_failed_total")
	else:
		logger.debug("Operation completed: " + operation_name, {"duration_ms": duration * 1000})
		telemetry_system.increment_counter("operations_completed_total")
	
	return result

# Circuit breaker wrapper
func with_circuit_breaker(breaker_name: String, callable: Callable):
	var breaker = error_handler.get_circuit_breaker(breaker_name)
	var logger = get_logger("circuit_breaker")
	
	var result = breaker.call_protected(callable)
	
	if not result.success:
		logger.warn("Circuit breaker triggered: " + breaker_name, {"error": result.error})
		telemetry_system.increment_counter("circuit_breaker_trips_total")
	
	return result

# Export all observability data
func export_observability_data() -> Dictionary:
	return {
		"timestamp": Time.get_time_dict_from_system(),
		"telemetry": telemetry_system.export_metrics(),
		"errors": error_handler.get_error_stats(),
		"logging": logging_system.get_stats(),
		"system_status": get_system_status()
	}

# Health check
func health_check() -> Dictionary:
	var health = {
		"status": "healthy",
		"checks": {},
		"alerts": []
	}
	
	# Check telemetry system
	var telemetry_status = telemetry_system.get_status()
	health.checks["telemetry"] = {
		"status": "healthy" if telemetry_status.enabled else "degraded",
		"metrics_count": telemetry_status.metrics_count
	}
	
	# Check logging system
	var logging_status = logging_system.get_stats()
	health.checks["logging"] = {
		"status": "healthy" if logging_status.enabled else "degraded",
		"loggers_count": logging_status.loggers_count
	}
	
	# Check error rates
	var error_stats = error_handler.get_error_stats()
	var recent_critical_errors = 0
	for error in error_stats.recent_errors:
		if error.severity == "CRITICAL":
			recent_critical_errors += 1
	
	health.checks["errors"] = {
		"status": "healthy" if recent_critical_errors == 0 else "critical",
		"recent_critical_errors": recent_critical_errors
	}
	
	# Get performance alerts
	var metrics_summary = telemetry_system.get_metrics_summary()
	if "alerts" in metrics_summary:
		health.alerts.append_array(metrics_summary.alerts)
	
	# Determine overall status
	for check_name in health.checks:
		var check = health.checks[check_name]
		if check.status == "critical":
			health.status = "critical"
			break
		elif check.status == "degraded" and health.status == "healthy":
			health.status = "degraded"
	
	return health

# Shutdown observability systems
func shutdown() -> void:
	var logger = get_logger("system")
	logger.info("Shutting down observability systems")
	
	# Flush all logs
	logging_system.flush()
	
	# Export final metrics
	var final_export = export_observability_data()
	logger.info("Final observability export completed", {"data_size": str(final_export).length()})
	
	print("🔍 Observability Manager shutdown complete")