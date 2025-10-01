# 📝 LOGGING SYSTEM
# Purpose: Structured logging framework with multiple levels and outputs
# Layer: Infrastructure/Observability

extends RefCounted

class_name LoggingSystem

# Log levels
enum LogLevel {
	TRACE = 0,
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5
}

# Log entry structure
class LogEntry:
	var timestamp: String
	var level: LogLevel
	var logger_name: String
	var message: String
	var context: Dictionary
	var stack_trace: Array
	var thread_id: String
	
	func _init(lvl: LogLevel, name: String, msg: String, ctx: Dictionary = {}):
		var time_dict = Time.get_time_dict_from_system()
		timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
			time_dict.year, time_dict.month, time_dict.day,
			time_dict.hour, time_dict.minute, time_dict.second
		]
		level = lvl
		logger_name = name
		message = msg
		context = ctx
		thread_id = "main"  # Godot is single-threaded by default
		
		# Capture stack trace for errors
		if level >= LogLevel.ERROR:
			stack_trace = get_stack()
	
	func to_string() -> String:
		var level_str = LogLevel.keys()[level]
		var context_str = ""
		
		if not context.is_empty():
			var ctx_parts = []
			for key in context:
				ctx_parts.append("%s=%s" % [key, context[key]])
			context_str = " [" + ", ".join(ctx_parts) + "]"
		
		return "%s [%s] %s: %s%s" % [timestamp, level_str, logger_name, message, context_str]
	
	func to_json() -> Dictionary:
		return {
			"timestamp": timestamp,
			"level": LogLevel.keys()[level],
			"logger": logger_name,
			"message": message,
			"context": context,
			"thread": thread_id,
			"stack_trace": stack_trace if stack_trace.size() > 0 else null
		}

# Logger class
class Logger:
	var name: String
	var min_level: LogLevel
	var context: Dictionary
	var logging_system: LoggingSystem
	
	func _init(logger_name: String, system: LoggingSystem, minimum_level: LogLevel = LogLevel.INFO):
		name = logger_name
		logging_system = system
		min_level = minimum_level
		context = {}
	
	func trace(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.TRACE, message, ctx)
	
	func debug(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.DEBUG, message, ctx)
	
	func info(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.INFO, message, ctx)
	
	func warn(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.WARN, message, ctx)
	
	func error(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.ERROR, message, ctx)
	
	func fatal(message: String, ctx: Dictionary = {}) -> void:
		_log(LogLevel.FATAL, message, ctx)
	
	func _log(level: LogLevel, message: String, ctx: Dictionary) -> void:
		if level < min_level:
			return
		
		# Merge logger context with message context
		var merged_context = context.duplicate()
		for key in ctx:
			merged_context[key] = ctx[key]
		
		var entry = LogEntry.new(level, name, message, merged_context)
		logging_system._write_log(entry)
	
	func with_context(ctx: Dictionary) -> Logger:
		var new_logger = Logger.new(name, logging_system, min_level)
		new_logger.context = context.duplicate()
		for key in ctx:
			new_logger.context[key] = ctx[key]
		return new_logger
	
	func set_level(level: LogLevel) -> void:
		min_level = level

# Log appender interface
class LogAppender:
	var name: String
	var min_level: LogLevel
	var formatter: LogFormatter
	
	func _init(appender_name: String, minimum_level: LogLevel = LogLevel.INFO):
		name = appender_name
		min_level = minimum_level
		formatter = LogFormatter.new()
	
	func write(entry: LogEntry) -> void:
		# Override in subclasses
		pass
	
	func should_write(entry: LogEntry) -> bool:
		return entry.level >= min_level

# Console appender
class ConsoleAppender extends LogAppender:
	func _init(minimum_level: LogLevel = LogLevel.INFO):
		super("console", minimum_level)
	
	func write(entry: LogEntry) -> void:
		if not should_write(entry):
			return
		
		var formatted = formatter.format(entry)
		
		# Use appropriate print function based on level
		match entry.level:
			LogLevel.ERROR, LogLevel.FATAL:
				print_rich("[color=red]%s[/color]" % formatted)
			LogLevel.WARN:
				print_rich("[color=yellow]%s[/color]" % formatted)
			LogLevel.DEBUG:
				print_rich("[color=gray]%s[/color]" % formatted)
			LogLevel.TRACE:
				print_rich("[color=dark_gray]%s[/color]" % formatted)
			_:
				print(formatted)

# File appender
class FileAppender extends LogAppender:
	var file_path: String
	var max_file_size: int = 10 * 1024 * 1024  # 10MB
	var max_backup_files: int = 5
	var current_file_size: int = 0
	
	func _init(path: String, minimum_level: LogLevel = LogLevel.INFO):
		super("file", minimum_level)
		file_path = path
		_ensure_log_directory()
	
	func write(entry: LogEntry) -> void:
		if not should_write(entry):
			return
		
		var formatted = formatter.format(entry) + "\n"
		
		# Check if we need to rotate the log file
		if current_file_size + formatted.length() > max_file_size:
			_rotate_log_file()
		
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.seek_end()
			file.store_string(formatted)
			current_file_size += formatted.length()
			file.close()
	
	func _ensure_log_directory() -> void:
		var dir_path = file_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.open("user://").make_dir_recursive(dir_path)
	
	func _rotate_log_file() -> void:
		# Rotate backup files
		for i in range(max_backup_files - 1, 0, -1):
			var old_backup = file_path + "." + str(i)
			var new_backup = file_path + "." + str(i + 1)
			
			if FileAccess.file_exists(old_backup):
				if i == max_backup_files - 1:
					# Delete oldest backup
					DirAccess.open("user://").remove(old_backup)
				else:
					# Rename to next backup number
					DirAccess.open("user://").rename(old_backup, new_backup)
		
		# Move current log to backup
		if FileAccess.file_exists(file_path):
			DirAccess.open("user://").rename(file_path, file_path + ".1")
		
		current_file_size = 0

# JSON appender for structured logging
class JsonAppender extends LogAppender:
	var file_path: String
	
	func _init(path: String, minimum_level: LogLevel = LogLevel.INFO):
		super("json", minimum_level)
		file_path = path
		_ensure_log_directory()
	
	func write(entry: LogEntry) -> void:
		if not should_write(entry):
			return
		
		var json_line = JSON.stringify(entry.to_json()) + "\n"
		
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.seek_end()
			file.store_string(json_line)
			file.close()
	
	func _ensure_log_directory() -> void:
		var dir_path = file_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.open("user://").make_dir_recursive(dir_path)

# Log formatter
class LogFormatter:
	var pattern: String = "{timestamp} [{level}] {logger}: {message}"
	
	func format(entry: LogEntry) -> String:
		var formatted = pattern
		formatted = formatted.replace("{timestamp}", entry.timestamp)
		formatted = formatted.replace("{level}", LogLevel.keys()[entry.level])
		formatted = formatted.replace("{logger}", entry.logger_name)
		formatted = formatted.replace("{message}", entry.message)
		
		# Add context if present
		if not entry.context.is_empty():
			var context_str = ""
			var ctx_parts = []
			for key in entry.context:
				ctx_parts.append("%s=%s" % [key, entry.context[key]])
			context_str = " [" + ", ".join(ctx_parts) + "]"
			formatted += context_str
		
		return formatted

# Main logging system
var loggers: Dictionary = {}
var appenders: Array[LogAppender] = []
var global_min_level: LogLevel = LogLevel.INFO
var is_enabled: bool = true

# Initialize logging system
func _init():
	_setup_default_appenders()

# Setup default appenders
func _setup_default_appenders() -> void:
	# Console appender for development
	add_appender(ConsoleAppender.new(LogLevel.DEBUG))
	
	# File appender for persistent logs
	add_appender(FileAppender.new("user://logs/game.log", LogLevel.INFO))
	
	# JSON appender for structured analysis
	add_appender(JsonAppender.new("user://logs/game.jsonl", LogLevel.WARN))

# Get or create logger
func get_logger(name: String, min_level: LogLevel = LogLevel.INFO) -> Logger:
	if name not in loggers:
		loggers[name] = Logger.new(name, self, min_level)
	return loggers[name]

# Add log appender
func add_appender(appender: LogAppender) -> void:
	appenders.append(appender)

# Remove log appender
func remove_appender(appender_name: String) -> void:
	for i in range(appenders.size() - 1, -1, -1):
		if appenders[i].name == appender_name:
			appenders.remove_at(i)

# Write log entry to all appenders
func _write_log(entry: LogEntry) -> void:
	if not is_enabled or entry.level < global_min_level:
		return
	
	for appender in appenders:
		appender.write(entry)

# Set global minimum log level
func set_global_level(level: LogLevel) -> void:
	global_min_level = level

# Enable/disable logging
func set_enabled(enabled: bool) -> void:
	is_enabled = enabled

# Get logging statistics
func get_stats() -> Dictionary:
	return {
		"enabled": is_enabled,
		"global_level": LogLevel.keys()[global_min_level],
		"loggers_count": loggers.size(),
		"appenders_count": appenders.size(),
		"logger_names": loggers.keys()
	}

# Flush all appenders
func flush() -> void:
	# Force write any buffered logs
	pass

# Create specialized loggers for different components
func create_component_loggers() -> Dictionary:
	var component_loggers = {}
	
	# Core layer loggers
	component_loggers["core.entities"] = get_logger("Core.Entities", LogLevel.DEBUG)
	component_loggers["core.values"] = get_logger("Core.Values", LogLevel.DEBUG)
	
	# Application layer loggers
	component_loggers["app.services"] = get_logger("App.Services", LogLevel.INFO)
	component_loggers["app.usecases"] = get_logger("App.UseCases", LogLevel.INFO)
	
	# Infrastructure layer loggers
	component_loggers["infra.input"] = get_logger("Infra.Input", LogLevel.DEBUG)
	component_loggers["infra.rendering"] = get_logger("Infra.Rendering", LogLevel.WARN)
	component_loggers["infra.persistence"] = get_logger("Infra.Persistence", LogLevel.INFO)
	component_loggers["infra.networking"] = get_logger("Infra.Networking", LogLevel.INFO)
	component_loggers["infra.ai"] = get_logger("Infra.AI", LogLevel.INFO)
	component_loggers["infra.performance"] = get_logger("Infra.Performance", LogLevel.WARN)
	
	# Presentation layer logger
	component_loggers["presentation"] = get_logger("Presentation", LogLevel.INFO)
	
	# Game-specific loggers
	component_loggers["game.turns"] = get_logger("Game.Turns", LogLevel.INFO)
	component_loggers["game.movement"] = get_logger("Game.Movement", LogLevel.DEBUG)
	component_loggers["game.combat"] = get_logger("Game.Combat", LogLevel.INFO)
	component_loggers["game.ai"] = get_logger("Game.AI", LogLevel.INFO)
	
	return component_loggers