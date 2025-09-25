class_name Result
extends RefCounted

const Logger = preload("res://scripts/core/logger.gd")

enum ResultType {
	SUCCESS,
	ERROR
}

var type: ResultType
var value = null
var error_message: String = ""
var error_code: int = 0
var error_details: Dictionary = {}

func _init(result_type: ResultType = ResultType.SUCCESS, result_value = null, error_msg: String = "", code: int = 0):
	type = result_type
	value = result_value
	error_message = error_msg
	error_code = code

static func success(value = null):
	var result_instance = load("res://scripts/core/result.gd").new()
	result_instance.type = ResultType.SUCCESS
	result_instance.value = value
	return result_instance

static func error(message: String, code: int = -1, details: Dictionary = {}):
	var result_instance = load("res://scripts/core/result.gd").new()
	result_instance.type = ResultType.ERROR
	result_instance.value = null
	result_instance.error_message = message
	result_instance.error_code = code
	result_instance.error_details = details
	Logger.error("Result error: %s (code: %d)" % [message, code], "Result")
	return result_instance

func is_success() -> bool:
	return type == ResultType.SUCCESS

func is_error() -> bool:
	return type == ResultType.ERROR

func get_value():
	if is_success():
		return value
	Logger.warning("Tentativa de obter valor de Result com erro: %s" % error_message, "Result")
	return null

func get_value_or(default_value):
	if is_success():
		return value
	return default_value

func get_error() -> String:
	return error_message

func get_error_code() -> int:
	return error_code

func get_error_details() -> Dictionary:
	return error_details

func map(callback: Callable):
	if is_success():
		var new_value = callback.call(value)
		var result_instance = load("res://scripts/core/result.gd").new()
		result_instance.type = ResultType.SUCCESS
		result_instance.value = new_value
		return result_instance
	return self

func and_then(callback: Callable):
	if is_success():
		var next_result = callback.call(value)
		if next_result.has_method("is_success"):
			return next_result
		var result_instance = load("res://scripts/core/result.gd").new()
		result_instance.type = ResultType.SUCCESS
		result_instance.value = next_result
		return result_instance
	return self

func to_result_string() -> String:
	if is_success():
		return "Success(%s)" % str(value)
	return "Error(%s, code: %d)" % [error_message, error_code]

static func validate(value, predicate: Callable, error_msg: String = "Validation failed"):
	if predicate.call(value):
		var result_instance = load("res://scripts/core/result.gd").new()
		result_instance.type = ResultType.SUCCESS
		result_instance.value = value
		return result_instance
	var error_result = load("res://scripts/core/result.gd").new()
	error_result.type = ResultType.ERROR
	error_result.error_message = error_msg
	return error_result

static func combine(results: Array):
	var values = []
	for result in results:
		if result.has_method("is_success"):
			if result.is_error():
				return result
			values.append(result.get_value())
		else:
			values.append(result)
	var success_result = load("res://scripts/core/result.gd").new()
	success_result.type = ResultType.SUCCESS
	success_result.value = values
	return success_result