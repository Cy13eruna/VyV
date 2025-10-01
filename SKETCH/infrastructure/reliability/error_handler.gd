# 🛡️ ERROR HANDLER
# Purpose: Comprehensive error handling and recovery system
# Layer: Infrastructure/Reliability

extends RefCounted

class_name ErrorHandler

# Error severity levels
enum ErrorSeverity {
	LOW,        # Minor issues, continue operation
	MEDIUM,     # Significant issues, degrade gracefully
	HIGH,       # Major issues, attempt recovery
	CRITICAL    # System-threatening, emergency procedures
}

# Error categories
enum ErrorCategory {
	VALIDATION,
	NETWORK,
	PERSISTENCE,
	RENDERING,
	GAME_LOGIC,
	PERFORMANCE,
	SYSTEM,
	USER_INPUT
}

# Error recovery strategies
enum RecoveryStrategy {
	IGNORE,
	RETRY,
	FALLBACK,
	RESET_COMPONENT,
	RESTART_SYSTEM,
	EMERGENCY_SAVE
}

# Error information structure
class ErrorInfo:
	var id: String
	var timestamp: String
	var severity: ErrorSeverity
	var category: ErrorCategory
	var message: String
	var context: Dictionary
	var stack_trace: Array
	var recovery_strategy: RecoveryStrategy
	var recovery_attempted: bool = false
	var recovery_successful: bool = false
	var occurrence_count: int = 1
	
	func _init(error_message: String, error_severity: ErrorSeverity, error_category: ErrorCategory):
		var time_dict = Time.get_time_dict_from_system()
		id = "ERR_%d%02d%02d_%02d%02d%02d_%d" % [
			time_dict.year, time_dict.month, time_dict.day,
			time_dict.hour, time_dict.minute, time_dict.second,
			randi() % 1000
		]
		timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
			time_dict.year, time_dict.month, time_dict.day,
			time_dict.hour, time_dict.minute, time_dict.second
		]
		message = error_message
		severity = error_severity
		category = error_category
		stack_trace = get_stack()
		recovery_strategy = _determine_recovery_strategy()
	
	func _determine_recovery_strategy() -> RecoveryStrategy:
		match severity:
			ErrorSeverity.LOW:
				return RecoveryStrategy.IGNORE
			ErrorSeverity.MEDIUM:
				match category:
					ErrorCategory.NETWORK:
						return RecoveryStrategy.RETRY
					ErrorCategory.RENDERING:
						return RecoveryStrategy.FALLBACK
					_:
						return RecoveryStrategy.FALLBACK
			ErrorSeverity.HIGH:
				match category:
					ErrorCategory.PERSISTENCE:
						return RecoveryStrategy.EMERGENCY_SAVE
					ErrorCategory.GAME_LOGIC:
						return RecoveryStrategy.RESET_COMPONENT
					_:
						return RecoveryStrategy.RETRY
			ErrorSeverity.CRITICAL:
				return RecoveryStrategy.EMERGENCY_SAVE
		
		return RecoveryStrategy.IGNORE

# Validation result structure
class ValidationResult:
	var is_valid: bool = true
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var field_errors: Dictionary = {}
	
	func add_error(message: String, field: String = "") -> void:
		is_valid = false
		errors.append(message)
		if field != "":
			if field not in field_errors:
				field_errors[field] = []
			field_errors[field].append(message)
	
	func add_warning(message: String) -> void:
		warnings.append(message)
	
	func has_errors() -> bool:
		return not is_valid
	
	func get_summary() -> String:
		if is_valid:
			return "Validation passed"
		
		var summary = "Validation failed: "
		summary += str(errors.size()) + " error(s)"
		if warnings.size() > 0:
			summary += ", " + str(warnings.size()) + " warning(s)"
		return summary

# Circuit breaker for preventing cascading failures
class CircuitBreaker:
	var name: String
	var failure_threshold: int = 5
	var recovery_timeout: float = 30.0
	var failure_count: int = 0
	var last_failure_time: float = 0.0
	var state: String = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
	
	func _init(breaker_name: String, threshold: int = 5, timeout: float = 30.0):
		name = breaker_name
		failure_threshold = threshold
		recovery_timeout = timeout
	
	func call_protected(callable: Callable):
		if state == "OPEN":
			var current_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
			if current_time - last_failure_time > recovery_timeout:
				state = "HALF_OPEN"
			else:
				return {"success": false, "error": "Circuit breaker is OPEN"}
		
		try:
			var result = callable.call()
			_on_success()
			return {"success": true, "result": result}
		except:
			_on_failure()
			return {"success": false, "error": "Operation failed"}
	
	func _on_success() -> void:
		failure_count = 0
		state = "CLOSED"
	
	func _on_failure() -> void:
		failure_count += 1
		last_failure_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		
		if failure_count >= failure_threshold:
			state = "OPEN"

# Error handler state
var error_history: Array[ErrorInfo] = []
var error_counts: Dictionary = {}
var circuit_breakers: Dictionary = {}
var recovery_handlers: Dictionary = {}
var max_error_history: int = 1000
var logging_system
var telemetry_system

# Initialize error handler
func _init(logger = null, telemetry = null):
	logging_system = logger
	telemetry_system = telemetry
	_setup_default_recovery_handlers()

# Handle error with automatic recovery
func handle_error(message: String, severity: ErrorSeverity, category: ErrorCategory, context: Dictionary = {}) -> ErrorInfo:
	var error_info = ErrorInfo.new(message, severity, category)
	error_info.context = context
	
	# Track error occurrence
	var error_key = "%s_%s" % [ErrorCategory.keys()[category], message.hash()]
	if error_key in error_counts:
		error_counts[error_key] += 1
		error_info.occurrence_count = error_counts[error_key]
	else:
		error_counts[error_key] = 1
	
	# Add to history
	error_history.append(error_info)
	if error_history.size() > max_error_history:
		error_history.pop_front()
	
	# Log error
	if logging_system:
		var logger = logging_system.get_logger("ErrorHandler")
		match severity:
			ErrorSeverity.LOW:
				logger.debug("Error handled: " + message, context)
			ErrorSeverity.MEDIUM:
				logger.warn("Error handled: " + message, context)
			ErrorSeverity.HIGH:
				logger.error("Error handled: " + message, context)
			ErrorSeverity.CRITICAL:
				logger.fatal("Critical error: " + message, context)
	
	# Record telemetry
	if telemetry_system:
		telemetry_system.increment_counter("errors_total")
		telemetry_system.increment_counter("errors_" + ErrorSeverity.keys()[severity].to_lower())
		telemetry_system.increment_counter("errors_" + ErrorCategory.keys()[category].to_lower())
	
	# Attempt recovery
	_attempt_recovery(error_info)
	
	return error_info

# Attempt error recovery
func _attempt_recovery(error_info: ErrorInfo) -> void:
	if error_info.recovery_attempted:
		return
	
	error_info.recovery_attempted = true
	var strategy = error_info.recovery_strategy
	
	match strategy:
		RecoveryStrategy.IGNORE:
			error_info.recovery_successful = true
		
		RecoveryStrategy.RETRY:
			# Implement retry logic based on context
			error_info.recovery_successful = _retry_operation(error_info)
		
		RecoveryStrategy.FALLBACK:
			error_info.recovery_successful = _execute_fallback(error_info)
		
		RecoveryStrategy.RESET_COMPONENT:
			error_info.recovery_successful = _reset_component(error_info)
		
		RecoveryStrategy.RESTART_SYSTEM:
			error_info.recovery_successful = _restart_system(error_info)
		
		RecoveryStrategy.EMERGENCY_SAVE:
			error_info.recovery_successful = _emergency_save(error_info)
	
	if logging_system:
		var logger = logging_system.get_logger("ErrorHandler")
		if error_info.recovery_successful:
			logger.info("Recovery successful for error: " + error_info.id)
		else:
			logger.error("Recovery failed for error: " + error_info.id)

# Validation methods
func validate_game_state(game_state: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	# Validate required keys
	var required_keys = ["grid", "players", "units", "turn_data"]
	for key in required_keys:
		if key not in game_state:
			result.add_error("Missing required key: " + key, key)
	
	if result.has_errors():
		return result
	
	# Validate grid
	var grid_validation = validate_grid(game_state.grid)
	if grid_validation.has_errors():
		for error in grid_validation.errors:
			result.add_error("Grid validation: " + error, "grid")
	
	# Validate players
	var players_validation = validate_players(game_state.players)
	if players_validation.has_errors():
		for error in players_validation.errors:
			result.add_error("Players validation: " + error, "players")
	
	# Validate units
	var units_validation = validate_units(game_state.units, game_state.players)
	if units_validation.has_errors():
		for error in units_validation.errors:
			result.add_error("Units validation: " + error, "units")
	
	return result

func validate_grid(grid_data: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	if not ("points" in grid_data and "edges" in grid_data):
		result.add_error("Grid missing points or edges")
		return result
	
	if grid_data.points.size() == 0:
		result.add_warning("Grid has no points")
	
	if grid_data.edges.size() == 0:
		result.add_warning("Grid has no edges")
	
	# Validate point structure
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		if not ("position" in point and "coordinate" in point):
			result.add_error("Point %s missing required fields" % point_id)
	
	return result

func validate_players(players_data: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	if players_data.size() == 0:
		result.add_error("No players defined")
		return result
	
	for player_id in players_data:
		var player = players_data[player_id]
		if not player:
			result.add_error("Player %s is null" % player_id)
		elif not ("id" in player and "name" in player):
			result.add_error("Player %s missing required fields" % player_id)
	
	return result

func validate_units(units_data: Dictionary, players_data: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	for unit_id in units_data:
		var unit = units_data[unit_id]
		if not unit:
			result.add_error("Unit %s is null" % unit_id)
		elif not ("owner_id" in unit):
			result.add_error("Unit %s missing owner_id" % unit_id)
		elif unit.owner_id not in players_data:
			result.add_error("Unit %s has invalid owner_id" % unit_id)
	
	return result

# Input validation
func validate_input(input_data, validation_rules: Dictionary) -> ValidationResult:
	var result = ValidationResult.new()
	
	for field in validation_rules:
		var rules = validation_rules[field]
		var value = input_data.get(field) if input_data is Dictionary else null
		
		# Required field check
		if "required" in rules and rules.required and (value == null or value == ""):
			result.add_error("Field is required", field)
			continue
		
		if value == null:
			continue
		
		# Type validation
		if "type" in rules:
			if not _validate_type(value, rules.type):
				result.add_error("Invalid type, expected " + str(rules.type), field)
		
		# Range validation
		if "min" in rules and value < rules.min:
			result.add_error("Value below minimum: " + str(rules.min), field)
		
		if "max" in rules and value > rules.max:
			result.add_error("Value above maximum: " + str(rules.max), field)
		
		# Custom validation
		if "validator" in rules and rules.validator is Callable:
			if not rules.validator.call(value):
				result.add_error("Custom validation failed", field)
	
	return result

# Circuit breaker management
func get_circuit_breaker(name: String, threshold: int = 5, timeout: float = 30.0) -> CircuitBreaker:
	if name not in circuit_breakers:
		circuit_breakers[name] = CircuitBreaker.new(name, threshold, timeout)
	return circuit_breakers[name]

# Recovery handlers
func _setup_default_recovery_handlers() -> void:
	recovery_handlers["network_timeout"] = func(): return _handle_network_timeout()
	recovery_handlers["save_failure"] = func(): return _handle_save_failure()
	recovery_handlers["rendering_error"] = func(): return _handle_rendering_error()

func _retry_operation(error_info: ErrorInfo) -> bool:
	# Implement retry logic based on error context
	return false

func _execute_fallback(error_info: ErrorInfo) -> bool:
	# Implement fallback mechanisms
	return false

func _reset_component(error_info: ErrorInfo) -> bool:
	# Reset specific component based on error category
	return false

func _restart_system(error_info: ErrorInfo) -> bool:
	# Restart entire system (last resort)
	return false

func _emergency_save(error_info: ErrorInfo) -> bool:
	# Attempt to save game state before potential crash
	return false

func _handle_network_timeout() -> bool:
	return false

func _handle_save_failure() -> bool:
	return false

func _handle_rendering_error() -> bool:
	return false

func _validate_type(value, expected_type) -> bool:
	match expected_type:
		"string":
			return value is String
		"int":
			return value is int
		"float":
			return value is float
		"bool":
			return value is bool
		"array":
			return value is Array
		"dictionary":
			return value is Dictionary
		_:
			return true

# Get error statistics
func get_error_stats() -> Dictionary:
	var stats = {
		"total_errors": error_history.size(),
		"errors_by_severity": {},
		"errors_by_category": {},
		"recent_errors": [],
		"circuit_breakers": {}
	}
	
	# Count by severity and category
	for severity in ErrorSeverity.values():
		stats.errors_by_severity[ErrorSeverity.keys()[severity]] = 0
	
	for category in ErrorCategory.values():
		stats.errors_by_category[ErrorCategory.keys()[category]] = 0
	
	for error in error_history:
		stats.errors_by_severity[ErrorSeverity.keys()[error.severity]] += 1
		stats.errors_by_category[ErrorCategory.keys()[error.category]] += 1
	
	# Recent errors (last 10)
	var recent_count = min(10, error_history.size())
	for i in range(error_history.size() - recent_count, error_history.size()):
		stats.recent_errors.append({
			"id": error_history[i].id,
			"message": error_history[i].message,
			"severity": ErrorSeverity.keys()[error_history[i].severity],
			"timestamp": error_history[i].timestamp
		})
	
	# Circuit breaker status
	for name in circuit_breakers:
		var breaker = circuit_breakers[name]
		stats.circuit_breakers[name] = {
			"state": breaker.state,
			"failure_count": breaker.failure_count
		}
	
	return stats