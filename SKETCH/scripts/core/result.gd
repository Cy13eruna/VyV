## Result<T> - Sistema de Error Handling Robusto
## Implementa padrão Result para operações que podem falhar
## Evita exceptions e força tratamento explícito de erros

class_name Result
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Tipos de resultado
enum ResultType {
	SUCCESS,
	ERROR
}

## Propriedades do resultado
var type: ResultType
var value = null
var error_message: String = ""
var error_code: int = 0
var error_details: Dictionary = {}

## Criar resultado de sucesso
static func success(value = null) -> Result:
	var result = Result.new()
	result.type = ResultType.SUCCESS
	result.value = value
	return result

## Criar resultado de erro
static func error(message: String, code: int = -1, details: Dictionary = {}) -> Result:
	var result = Result.new()
	result.type = ResultType.ERROR
	result.error_message = message
	result.error_code = code
	result.error_details = details
	Logger.error("Result error: %s (code: %d)" % [message, code], "Result")
	return result

## Verificar se é sucesso
func is_success() -> bool:
	return type == ResultType.SUCCESS

## Verificar se é erro
func is_error() -> bool:
	return type == ResultType.ERROR

## Obter valor (apenas se sucesso)
func get_value():
	if is_success():
		return value
	Logger.warning("Tentativa de obter valor de Result com erro: %s" % error_message, "Result")
	return null

## Obter valor ou padrão
func get_value_or(default_value):
	if is_success():
		return value
	return default_value

## Obter mensagem de erro
func get_error() -> String:
	return error_message

## Obter código de erro
func get_error_code() -> int:
	return error_code

## Obter detalhes do erro
func get_error_details() -> Dictionary:
	return error_details

## Mapear valor se sucesso
func map(callback: Callable) -> Result:
	if is_success():
		var new_value = callback.call(value)
		return Result.success(new_value)
	return self

## Mapear erro se erro
func map_error(callback: Callable) -> Result:
	if is_error():
		var new_error = callback.call(error_message, error_code, error_details)
		if new_error is Result:
			return new_error
		return Result.error(str(new_error))
	return self

## Executar callback se sucesso
func on_success(callback: Callable) -> Result:
	if is_success():
		callback.call(value)
	return self

## Executar callback se erro
func on_error(callback: Callable) -> Result:
	if is_error():
		callback.call(error_message, error_code, error_details)
	return self

## Combinar com outro Result
func and_then(callback: Callable) -> Result:
	if is_success():
		var next_result = callback.call(value)
		if next_result is Result:
			return next_result
		return Result.success(next_result)
	return self

## Ou então (fallback)
func or_else(callback: Callable) -> Result:
	if is_error():
		var fallback_result = callback.call(error_message, error_code, error_details)
		if fallback_result is Result:
			return fallback_result
		return Result.success(fallback_result)
	return self

## Converter para string
func to_string() -> String:
	if is_success():
		return "Success(%s)" % str(value)
	return "Error(%s, code: %d)" % [error_message, error_code]

## Unwrap (obter valor ou falhar)
func unwrap():
	if is_success():
		return value
	Logger.error("Result unwrap failed: %s" % error_message, "Result")
	assert(false, "Result unwrap failed: " + error_message)
	return null

## Unwrap com mensagem customizada
func expect(message: String):
	if is_success():
		return value
	Logger.error("Result expect failed: %s - %s" % [message, error_message], "Result")
	assert(false, message + " - " + error_message)
	return null

## Validar valor com predicado
static func validate(value, predicate: Callable, error_msg: String = "Validation failed") -> Result:
	if predicate.call(value):
		return Result.success(value)
	return Result.error(error_msg)

## Tentar executar operação que pode falhar
static func try_call(callback: Callable, error_msg: String = "Operation failed") -> Result:
	try:
		var result = callback.call()
		return Result.success(result)
	except:
		return Result.error(error_msg)

## Combinar múltiplos Results
static func combine(results: Array) -> Result:
	var values = []
	for result in results:
		if result is Result:
			if result.is_error():
				return result  # Retorna primeiro erro encontrado
			values.append(result.get_value())
		else:
			values.append(result)
	return Result.success(values)

## Executar operação em todos os elementos de um array
static func map_array(array: Array, callback: Callable) -> Result:
	var results = []
	for item in array:
		var result = callback.call(item)
		if result is Result:
			if result.is_error():
				return result  # Retorna primeiro erro
			results.append(result.get_value())
		else:
			results.append(result)
	return Result.success(results)

## Filtrar array com predicado que retorna Result
static func filter_array(array: Array, predicate: Callable) -> Result:
	var filtered = []
	for item in array:
		var result = predicate.call(item)
		if result is Result:
			if result.is_error():
				return result
			if result.get_value():
				filtered.append(item)
		elif result:
			filtered.append(item)
	return Result.success(filtered)

## Encontrar primeiro elemento que satisfaz predicado
static func find_first(array: Array, predicate: Callable) -> Result:
	for item in array:
		var result = predicate.call(item)
		if result is Result:
			if result.is_error():
				return result
			if result.get_value():
				return Result.success(item)
		elif result:
			return Result.success(item)
	return Result.error("No item found matching predicate")

## Operações de arquivo com Result
class FileOps:
	## Ler arquivo
	static func read_file(path: String) -> Result:
		if not FileAccess.file_exists(path):
			return Result.error("File not found: " + path, 404)
		
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			return Result.error("Failed to open file: " + path, 403)
		
		var content = file.get_as_text()
		file.close()
		
		return Result.success(content)
	
	## Escrever arquivo
	static func write_file(path: String, content: String) -> Result:
		var file = FileAccess.open(path, FileAccess.WRITE)
		if not file:
			return Result.error("Failed to create file: " + path, 403)
		
		file.store_string(content)
		file.close()
		
		return Result.success(true)
	
	## Ler JSON
	static func read_json(path: String) -> Result:
		var file_result = read_file(path)
		if file_result.is_error():
			return file_result
		
		var json = JSON.new()
		var parse_result = json.parse(file_result.get_value())
		
		if parse_result != OK:
			return Result.error("Failed to parse JSON: " + path, parse_result)
		
		return Result.success(json.data)
	
	## Escrever JSON
	static func write_json(path: String, data) -> Result:
		var json_text = JSON.stringify(data, "\t")
		return write_file(path, json_text)

## Operações de validação comuns
class Validators:
	## Validar não nulo
	static func not_null(value, field_name: String = "value") -> Result:
		if value == null:
			return Result.error("%s cannot be null" % field_name)
		return Result.success(value)
	
	## Validar não vazio
	static func not_empty(value, field_name: String = "value") -> Result:
		if value == null or (value is String and value.is_empty()) or (value is Array and value.is_empty()):
			return Result.error("%s cannot be empty" % field_name)
		return Result.success(value)
	
	## Validar range numérico
	static func in_range(value: float, min_val: float, max_val: float, field_name: String = "value") -> Result:
		if value < min_val or value > max_val:
			return Result.error("%s must be between %f and %f" % [field_name, min_val, max_val])
		return Result.success(value)
	
	## Validar tipo
	static func is_type(value, expected_type, field_name: String = "value") -> Result:
		if not value is expected_type:
			return Result.error("%s must be of type %s" % [field_name, str(expected_type)])
		return Result.success(value)
	
	## Validar ID válido
	static func valid_id(id, field_name: String = "id") -> Result:
		if id == null or (id is String and id.is_empty()) or (id is int and id < 0):
			return Result.error("%s must be a valid identifier" % field_name)
		return Result.success(id)

## Operações de rede com Result
class NetworkOps:
	## Fazer requisição HTTP (simulado)
	static func http_get(url: String) -> Result:
		# Simulação - em implementação real usaria HTTPRequest
		if url.is_empty():
			return Result.error("URL cannot be empty", 400)
		
		if not url.begins_with("http"):
			return Result.error("Invalid URL format", 400)
		
		# Simular sucesso
		return Result.success({"status": "ok", "data": "response_data"})
	
	## Fazer POST (simulado)
	static func http_post(url: String, data: Dictionary) -> Result:
		if url.is_empty():
			return Result.error("URL cannot be empty", 400)
		
		if data.is_empty():
			return Result.error("POST data cannot be empty", 400)
		
		# Simular sucesso
		return Result.success({"status": "created", "id": randi()})

## Exemplo de uso em comentários:
## 
## # Operação simples
## var result = some_operation()
## if result.is_success():
##     print("Success: ", result.get_value())
## else:
##     print("Error: ", result.get_error())
## 
## # Encadeamento
## var final_result = some_operation()
##     .and_then(func(value): return another_operation(value))
##     .map(func(value): return value * 2)
##     .on_error(func(error, code, details): print("Failed: ", error))
## 
## # Validação
## var validated = Result.validate(user_input, func(x): return x > 0, "Value must be positive")
##     .and_then(func(value): return process_value(value))
##     .get_value_or("default")