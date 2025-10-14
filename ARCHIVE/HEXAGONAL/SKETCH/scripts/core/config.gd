## Config - Sistema de Configuração Centralizada
## Gerencia todas as configurações do jogo de forma centralizada

class_name Config
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Configurações de Performance
static var performance_settings: Dictionary = {
	"max_fps": 60,
	"enable_culling": true,
	"culling_margin": 100.0,
	"max_elements_per_frame": 10000,
	"enable_object_pooling": true,
	"pool_warm_size": 20,
	"object_pool_initial_size": 100
}

## Configurações de Debug
static var debug_settings: Dictionary = {
	"enable_debug_mode": false,
	"log_level": Logger.Level.ERROR,
	"show_fps": false,
	"show_render_stats": false,
	"enable_debug_draw": false
}

## Configurações de Jogo
static var game_settings: Dictionary = {
	"min_players": 2,
	"max_players": 6,
	"default_players": 3,
	"turn_time_limit": 0,  # 0 = sem limite
	"enable_fog_of_war": false,
	"auto_save": true,
	"max_adjacent_distance": 38.0,
	"click_tolerance": 30.0,
	"position_tolerance": 10.0,
	"min_domain_distance": 76.0,
	"max_units_per_player": 50,
	"max_domains_per_player": 20
}

## Configurações de Renderização
static var render_settings: Dictionary = {
	"hex_size": 25.0,
	"grid_width": 8,
	"grid_height": 8,
	"render_hexagons": false,
	"render_connections": true,
	"render_stars": true,
	"render_diamonds": true,
	"zoom_factor": 1.3,
	"min_zoom": 0.3,
	"max_zoom": 5.0
}

## Configurações de UI
static var ui_settings: Dictionary = {
	"button_size": Vector2(120, 40),
	"button_margin": 10,
	"show_turn_info": true,
	"enable_tooltips": true,
	"ui_scale": 1.0
}

## Carregar configurações de arquivo
static func load_config(file_path: String = "user://config.json") -> bool:
	if not FileAccess.file_exists(file_path):
		Logger.info("Config file not found, using defaults", "Config")
		save_config(file_path)  # Criar arquivo com defaults
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		Logger.error("Failed to open config file: " + file_path, "Config")
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		Logger.error("Failed to parse config JSON", "Config")
		return false
	
	var config_data = json.data
	
	# Aplicar configurações carregadas
	if config_data.has("performance"):
		_merge_settings(performance_settings, config_data.performance)
	
	if config_data.has("debug"):
		_merge_settings(debug_settings, config_data.debug)
	
	if config_data.has("game"):
		_merge_settings(game_settings, config_data.game)
	
	if config_data.has("render"):
		_merge_settings(render_settings, config_data.render)
	
	if config_data.has("ui"):
		_merge_settings(ui_settings, config_data.ui)
	
	Logger.info("Config loaded successfully", "Config")
	return true

## Salvar configurações em arquivo
static func save_config(file_path: String = "user://config.json") -> bool:
	var config_data = {
		"performance": performance_settings,
		"debug": debug_settings,
		"game": game_settings,
		"render": render_settings,
		"ui": ui_settings
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		Logger.error("Failed to create config file: " + file_path, "Config")
		return false
	
	var json_text = JSON.stringify(config_data, "\t")
	file.store_string(json_text)
	file.close()
	
	Logger.info("Config saved successfully", "Config")
	return true

## Aplicar configurações ao sistema
static func apply_config() -> void:
	# Aplicar configurações de debug
	Logger.set_debug_mode(debug_settings.enable_debug_mode)
	Logger.set_level(debug_settings.log_level)
	
	# Aplicar configurações de performance
	Engine.max_fps = performance_settings.max_fps
	
	Logger.info("Config applied to systems", "Config")

## Obter configuração específica
static func get_setting(category: String, key: String, default_value = null):
	var settings_dict = _get_settings_dict(category)
	if settings_dict and settings_dict.has(key):
		return settings_dict[key]
	return default_value

## Definir configuração específica
static func set_setting(category: String, key: String, value) -> void:
	var settings_dict = _get_settings_dict(category)
	if settings_dict:
		settings_dict[key] = value
		Logger.debug("Setting updated: %s.%s = %s" % [category, key, str(value)], "Config")

## Resetar para configurações padrão
static func reset_to_defaults() -> void:
	performance_settings = {
		"max_fps": 60,
		"enable_culling": true,
		"culling_margin": 100.0,
		"max_elements_per_frame": 10000,
		"enable_object_pooling": true,
		"pool_warm_size": 20
	}
	
	debug_settings = {
		"enable_debug_mode": false,
		"log_level": Logger.Level.ERROR,
		"show_fps": false,
		"show_render_stats": false,
		"enable_debug_draw": false
	}
	
	game_settings = {
		"min_players": 2,
		"max_players": 6,
		"default_players": 3,
		"turn_time_limit": 0,
		"enable_fog_of_war": false,
		"auto_save": true
	}
	
	render_settings = {
		"hex_size": 25.0,
		"grid_width": 8,
		"grid_height": 8,
		"render_hexagons": false,
		"render_connections": true,
		"render_stars": true,
		"render_diamonds": true
	}
	
	ui_settings = {
		"button_size": Vector2(120, 40),
		"button_margin": 10,
		"show_turn_info": true,
		"enable_tooltips": true,
		"ui_scale": 1.0
	}
	
	Logger.info("Config reset to defaults", "Config")

## Obter dicionário de configurações por categoria
static func _get_settings_dict(category: String) -> Dictionary:
	match category:
		"performance":
			return performance_settings
		"debug":
			return debug_settings
		"game":
			return game_settings
		"render":
			return render_settings
		"ui":
			return ui_settings
		_:
			Logger.warning("Unknown config category: " + category, "Config")
			return {}

## Mesclar configurações
static func _merge_settings(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key):
			target[key] = source[key]

## Inicialização automática
static func _static_init() -> void:
	# Tentar carregar configurações na inicialização
	load_config()
	apply_config()