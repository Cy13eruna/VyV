# 🔌 PLUGIN SYSTEM
# Purpose: Modding and extensibility framework
# Layer: Infrastructure/Modding

extends RefCounted

class_name PluginSystem

# Plugin interface
class Plugin:
	var plugin_id: String
	var plugin_name: String
	var version: String
	var author: String
	var description: String
	var dependencies: Array = []
	var is_enabled: bool = false
	var is_loaded: bool = false
	var plugin_script
	
	func _init(id: String):
		plugin_id = id

# Plugin manager state
var loaded_plugins: Dictionary = {}
var plugin_directory: String = "user://plugins/"
var enabled_plugins: Array = []

# Plugin hooks
signal plugin_loaded(plugin_id: String)
signal plugin_unloaded(plugin_id: String)
signal plugin_enabled(plugin_id: String)
signal plugin_disabled(plugin_id: String)

# Game hooks for plugins
var game_hooks: Dictionary = {
	"game_initialized": [],
	"turn_started": [],
	"turn_ended": [],
	"unit_moved": [],
	"unit_created": [],
	"unit_destroyed": [],
	"game_ended": [],
	"before_save": [],
	"after_load": []
}

# Initialize plugin system
func _init():
	_ensure_plugin_directory()
	_load_plugin_config()

# Load all plugins from directory
func load_all_plugins() -> void:
	print("🔌 Loading plugins from: %s" % plugin_directory)
	
	var dir = DirAccess.open(plugin_directory)
	if dir == null:
		print("❌ Failed to open plugin directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			_load_plugin(file_name)
		file_name = dir.get_next()
	
	print("✅ Plugin loading complete. Loaded: %d plugins" % loaded_plugins.size())

# Load specific plugin
func _load_plugin(plugin_id: String) -> bool:
	var plugin_path = plugin_directory + plugin_id + "/"
	var manifest_path = plugin_path + "plugin.json"
	
	# Check if manifest exists
	if not FileAccess.file_exists(manifest_path):
		print("⚠️ Plugin manifest not found: %s" % plugin_id)
		return false
	
	# Load manifest
	var manifest = _load_plugin_manifest(manifest_path)
	if manifest == null:
		print("❌ Failed to load plugin manifest: %s" % plugin_id)
		return false
	
	# Create plugin instance
	var plugin = Plugin.new(plugin_id)
	plugin.plugin_name = manifest.get("name", plugin_id)
	plugin.version = manifest.get("version", "1.0")
	plugin.author = manifest.get("author", "Unknown")
	plugin.description = manifest.get("description", "")
	plugin.dependencies = manifest.get("dependencies", [])
	
	# Load plugin script
	var script_path = plugin_path + manifest.get("main_script", "main.gd")
	if FileAccess.file_exists(script_path):
		var script = load(script_path)
		if script:
			plugin.plugin_script = script.new()
			plugin.is_loaded = true
		else:
			print("❌ Failed to load plugin script: %s" % script_path)
			return false
	
	loaded_plugins[plugin_id] = plugin
	plugin_loaded.emit(plugin_id)
	
	print("✅ Plugin loaded: %s v%s" % [plugin.plugin_name, plugin.version])
	return true

# Enable plugin
func enable_plugin(plugin_id: String) -> bool:
	if plugin_id not in loaded_plugins:
		print("❌ Plugin not loaded: %s" % plugin_id)
		return false
	
	var plugin = loaded_plugins[plugin_id]
	
	# Check dependencies
	for dep in plugin.dependencies:
		if dep not in enabled_plugins:
			print("❌ Plugin dependency not enabled: %s requires %s" % [plugin_id, dep])
			return false
	
	# Enable plugin
	if plugin.plugin_script and plugin.plugin_script.has_method("on_enable"):
		plugin.plugin_script.on_enable()
	
	plugin.is_enabled = true
	if plugin_id not in enabled_plugins:
		enabled_plugins.append(plugin_id)
	
	plugin_enabled.emit(plugin_id)
	print("✅ Plugin enabled: %s" % plugin.plugin_name)
	return true

# Disable plugin
func disable_plugin(plugin_id: String) -> bool:
	if plugin_id not in loaded_plugins:
		return false
	
	var plugin = loaded_plugins[plugin_id]
	
	# Check if other plugins depend on this one
	for other_id in enabled_plugins:
		var other_plugin = loaded_plugins[other_id]
		if plugin_id in other_plugin.dependencies:
			print("❌ Cannot disable plugin: %s is required by %s" % [plugin_id, other_id])
			return false
	
	# Disable plugin
	if plugin.plugin_script and plugin.plugin_script.has_method("on_disable"):
		plugin.plugin_script.on_disable()
	
	plugin.is_enabled = false
	enabled_plugins.erase(plugin_id)
	
	plugin_disabled.emit(plugin_id)
	print("🔌 Plugin disabled: %s" % plugin.plugin_name)
	return true

# Unload plugin
func unload_plugin(plugin_id: String) -> bool:
	if plugin_id in enabled_plugins:
		disable_plugin(plugin_id)
	
	if plugin_id in loaded_plugins:
		var plugin = loaded_plugins[plugin_id]
		
		if plugin.plugin_script and plugin.plugin_script.has_method("on_unload"):
			plugin.plugin_script.on_unload()
		
		loaded_plugins.erase(plugin_id)
		plugin_unloaded.emit(plugin_id)
		
		print("🔌 Plugin unloaded: %s" % plugin.plugin_name)
		return true
	
	return false

# Register hook listener
func register_hook(hook_name: String, plugin_id: String, callback: Callable) -> void:
	if hook_name not in game_hooks:
		game_hooks[hook_name] = []
	
	game_hooks[hook_name].append({
		"plugin_id": plugin_id,
		"callback": callback
	})

# Trigger hook
func trigger_hook(hook_name: String, data: Dictionary = {}) -> void:
	if hook_name not in game_hooks:
		return
	
	for hook in game_hooks[hook_name]:
		var plugin_id = hook.plugin_id
		if plugin_id in enabled_plugins:
			var callback = hook.callback
			if callback.is_valid():
				callback.call(data)

# Get plugin info
func get_plugin_info(plugin_id: String) -> Dictionary:
	if plugin_id not in loaded_plugins:
		return {}
	
	var plugin = loaded_plugins[plugin_id]
	return {
		"id": plugin.plugin_id,
		"name": plugin.plugin_name,
		"version": plugin.version,
		"author": plugin.author,
		"description": plugin.description,
		"dependencies": plugin.dependencies,
		"is_enabled": plugin.is_enabled,
		"is_loaded": plugin.is_loaded
	}

# Get all plugins
func get_all_plugins() -> Array:
	var plugins = []
	for plugin_id in loaded_plugins:
		plugins.append(get_plugin_info(plugin_id))
	return plugins

# Save plugin configuration
func save_plugin_config() -> void:
	var config = {
		"enabled_plugins": enabled_plugins
	}
	
	var config_path = plugin_directory + "config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(config))
		file.close()

# Load plugin configuration
func _load_plugin_config() -> void:
	var config_path = plugin_directory + "config.json"
	
	if not FileAccess.file_exists(config_path):
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result == OK and "enabled_plugins" in json.data:
		enabled_plugins = json.data.enabled_plugins

# Load plugin manifest
func _load_plugin_manifest(manifest_path: String) -> Dictionary:
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result == OK:
		return json.data
	
	return {}

# Ensure plugin directory exists
func _ensure_plugin_directory() -> void:
	if not DirAccess.dir_exists_absolute(plugin_directory):
		DirAccess.open("user://").make_dir_recursive(plugin_directory)

# Create example plugin
func create_example_plugin() -> void:
	var example_path = plugin_directory + "example_plugin/"
	var dir = DirAccess.open("user://")
	dir.make_dir_recursive(example_path)
	
	# Create manifest
	var manifest = {
		"name": "Example Plugin",
		"version": "1.0",
		"author": "V&V Team",
		"description": "An example plugin demonstrating the plugin system",
		"main_script": "main.gd",
		"dependencies": []
	}
	
	var manifest_file = FileAccess.open(example_path + "plugin.json", FileAccess.WRITE)
	if manifest_file:
		manifest_file.store_string(JSON.stringify(manifest, "\t"))
		manifest_file.close()
	
	# Create main script
	var script_content = '''# Example Plugin Main Script
extends RefCounted

func on_enable():
	print("🔌 Example Plugin enabled!")

func on_disable():
	print("🔌 Example Plugin disabled!")

func on_unload():
	print("🔌 Example Plugin unloaded!")
'''
	
	var script_file = FileAccess.open(example_path + "main.gd", FileAccess.WRITE)
	if script_file:
		script_file.store_string(script_content)
		script_file.close()
	
	print("✅ Example plugin created at: %s" % example_path)