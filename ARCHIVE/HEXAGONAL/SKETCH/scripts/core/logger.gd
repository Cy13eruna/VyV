## Logger - Sistema de Logging Condicional Otimizado
## Executa logs apenas quando necessário para máxima performance

class_name Logger
extends RefCounted

## Níveis de log
enum Level {
	ERROR = 0,
	WARNING = 1,
	INFO = 2,
	DEBUG = 3
}

## Configurações estáticas
static var current_level: Level = Level.ERROR  # Produção: apenas erros
static var debug_mode: bool = false
static var log_to_file: bool = false
static var log_file_path: String = "user://game.log"

## Configurar nível de log
static func set_level(level: Level) -> void:
	current_level = level

## Ativar/desativar modo debug
static func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	if enabled:
		current_level = Level.DEBUG
	else:
		current_level = Level.ERROR

## Log de erro (sempre executa)
static func error(message: String, context: String = "") -> void:
	_log(Level.ERROR, message, context)

## Log de warning (apenas se level >= WARNING)
static func warning(message: String, context: String = "") -> void:
	if current_level >= Level.WARNING:
		_log(Level.WARNING, message, context)

## Log de info (apenas se level >= INFO)
static func info(message: String, context: String = "") -> void:
	if current_level >= Level.INFO:
		_log(Level.INFO, message, context)

## Log de debug (apenas se level >= DEBUG)
static func debug(message: String, context: String = "") -> void:
	if current_level >= Level.DEBUG:
		_log(Level.DEBUG, message, context)

## Função interna de log
static func _log(level: Level, message: String, context: String = "") -> void:
	var level_str = _level_to_string(level)
	var timestamp = Time.get_datetime_string_from_system()
	var full_message = "[%s] %s: %s" % [timestamp, level_str, message]
	
	if context != "":
		full_message += " (%s)" % context
	
	# Output para console
	print(full_message)
	
	# Output para arquivo se habilitado
	if log_to_file:
		_write_to_file(full_message)

## Converter nível para string
static func _level_to_string(level: Level) -> String:
	match level:
		Level.ERROR:
			return "ERROR"
		Level.WARNING:
			return "WARN"
		Level.INFO:
			return "INFO"
		Level.DEBUG:
			return "DEBUG"
		_:
			return "UNKNOWN"

## Escrever para arquivo
static func _write_to_file(message: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_line(message)
		file.close()

## Configurar a partir de settings do projeto
static func configure_from_project_settings() -> void:
	# Verificar se está em debug
	if OS.is_debug_build():
		set_debug_mode(true)
	else:
		set_debug_mode(false)
	
	# Configurações personalizadas
	if ProjectSettings.has_setting("logging/level"):
		var level_value = ProjectSettings.get_setting("logging/level", 0)
		set_level(level_value as Level)
	
	if ProjectSettings.has_setting("logging/log_to_file"):
		log_to_file = ProjectSettings.get_setting("logging/log_to_file", false)

## Inicialização automática
static func _static_init() -> void:
	configure_from_project_settings()