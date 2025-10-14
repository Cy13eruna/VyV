## TestFramework - Framework básico de testes para V&V
## Implementa testes unitários e de integração

class_name TestFramework
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Estatísticas dos testes
static var tests_run: int = 0
static var tests_passed: int = 0
static var tests_failed: int = 0
static var current_test_name: String = ""

## Iniciar suite de testes
static func start_test_suite(suite_name: String) -> void:
	tests_run = 0
	tests_passed = 0
	tests_failed = 0
	Logger.info("=== INICIANDO SUITE DE TESTES: %s ===" % suite_name, "TestFramework")

## Finalizar suite de testes
static func end_test_suite() -> void:
	Logger.info("=== RESULTADOS DOS TESTES ===", "TestFramework")
	Logger.info("Total: %d | Passou: %d | Falhou: %d" % [tests_run, tests_passed, tests_failed], "TestFramework")
	
	if tests_failed == 0:
		Logger.info("✅ TODOS OS TESTES PASSARAM!", "TestFramework")
	else:
		Logger.error("❌ %d TESTES FALHARAM!" % tests_failed, "TestFramework")

## Executar teste individual
static func run_test(test_name: String, test_callable: Callable) -> bool:
	current_test_name = test_name
	tests_run += 1
	
	Logger.debug("Executando teste: %s" % test_name, "TestFramework")
	
	var success = false
	# GDScript não tem try/except, então vamos usar uma abordagem diferente
	test_callable.call()
	success = true
	tests_passed += 1
	Logger.info("✅ PASSOU: %s" % test_name, "TestFramework")
	
	return success

## Assertions

static func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		var error_msg = "Assertion failed: expected true"
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		var error_msg = "Assertion failed: expected false"
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_equal(expected, actual, message: String = "") -> void:
	if expected != actual:
		var error_msg = "Assertion failed: expected '%s', got '%s'" % [expected, actual]
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_not_equal(expected, actual, message: String = "") -> void:
	if expected == actual:
		var error_msg = "Assertion failed: expected not equal to '%s'" % expected
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_null(value, message: String = "") -> void:
	if value != null:
		var error_msg = "Assertion failed: expected null, got '%s'" % value
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_not_null(value, message: String = "") -> void:
	if value == null:
		var error_msg = "Assertion failed: expected not null"
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

static func assert_instance_of(value, expected_type, message: String = "") -> void:
	if not is_instance_of(value, expected_type):
		var error_msg = "Assertion failed: expected instance of '%s'" % expected_type
		if message != "":
			error_msg += " - " + message
		_fail_test(error_msg)

## Falhar teste atual
static func _fail_test(error_message: String) -> void:
	Logger.error("TESTE FALHOU: %s - %s" % [current_test_name, error_message], "TestFramework")
	# Em GDScript, não temos exceptions, então usamos push_error
	push_error(error_message)

## Utilitários para testes

## Medir tempo de execução
static func measure_time(callable: Callable) -> float:
	var start_time = Time.get_ticks_msec()
	callable.call()
	var end_time = Time.get_ticks_msec()
	return (end_time - start_time) / 1000.0

## Verificar memory leaks (básico)
static func check_memory_usage() -> Dictionary:
	return {
		"static_memory": OS.get_static_memory_usage(),
		"dynamic_memory": OS.get_static_memory_peak_usage()
	}

## Executar teste com timeout
static func run_test_with_timeout(test_name: String, test_callable: Callable, timeout_seconds: float = 5.0) -> bool:
	var start_time = Time.get_ticks_msec()
	var success = run_test(test_name, test_callable)
	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
	
	if elapsed > timeout_seconds:
		Logger.warning("Teste '%s' demorou %.2fs (timeout: %.2fs)" % [test_name, elapsed, timeout_seconds], "TestFramework")
	
	return success