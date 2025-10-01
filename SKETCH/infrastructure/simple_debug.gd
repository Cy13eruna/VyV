# 🐛 SIMPLE DEBUG SYSTEM
# Purpose: Basic debug functionality without complex dependencies
# Layer: Infrastructure/Debugging

extends RefCounted

class_name SimpleDebug

# Simple debug levels
enum Level {
	ERROR = 0,
	WARN = 1,
	INFO = 2,
	DEBUG = 3
}

# Static instance
static var instance: SimpleDebug

# Debug state
var debug_level: Level = Level.INFO
var debug_enabled: bool = true

# Initialize
func _init():
	if instance == null:
		instance = self

# Get singleton
static func get_instance():
	if instance == null:
		instance = SimpleDebug.new()
	return instance

# Log methods
func error(message: String) -> void:
	if debug_enabled and debug_level >= Level.ERROR:
		print("[ERROR] %s" % message)

func warn(message: String) -> void:
	if debug_enabled and debug_level >= Level.WARN:
		print("[WARN] %s" % message)

func info(message: String) -> void:
	if debug_enabled and debug_level >= Level.INFO:
		print("[INFO] %s" % message)

func debug(message: String) -> void:
	if debug_enabled and debug_level >= Level.DEBUG:
		print("[DEBUG] %s" % message)

# Toggle debug
func toggle_debug() -> void:
	debug_enabled = not debug_enabled
	print("Debug: %s" % ("ON" if debug_enabled else "OFF"))

# Set level
func set_level(level: Level) -> void:
	debug_level = level
	print("Debug level set to: %s" % Level.keys()[level])