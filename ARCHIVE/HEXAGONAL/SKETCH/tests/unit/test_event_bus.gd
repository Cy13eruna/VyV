## Testes unitários para EventBus
extends RefCounted

const TestFramework = preload("res://tests/test_framework.gd")

## Variáveis para capturar eventos
static var captured_events: Array = []
static var last_event_data: Dictionary = {}

## Executar todos os testes do EventBus
static func run_all_tests() -> void:
	TestFramework.start_test_suite("EventBus")
	
	TestFramework.run_test("test_eventbus_singleton", test_eventbus_singleton)
	TestFramework.run_test("test_unit_events", test_unit_events)
	TestFramework.run_test("test_game_events", test_game_events)
	TestFramework.run_test("test_system_messages", test_system_messages)
	
	TestFramework.end_test_suite()

## Teste: EventBus singleton
static func test_eventbus_singleton() -> void:
	var instance = EventBus.get_instance()
	TestFramework.assert_not_null(instance, "EventBus instance deve existir")
	TestFramework.assert_instance_of(instance, Node, "EventBus deve ser um Node")

## Teste: Eventos de unidade
static func test_unit_events() -> void:
	_reset_captured_events()
	
	# Conectar aos sinais
	var instance = EventBus.get_instance()
	if instance:
		if not instance.unit_created.is_connected(_on_unit_created):
			instance.unit_created.connect(_on_unit_created)
		if not instance.unit_moved.is_connected(_on_unit_moved):
			instance.unit_moved.connect(_on_unit_moved)
		if not instance.unit_selected.is_connected(_on_unit_selected):
			instance.unit_selected.connect(_on_unit_selected)
	
	# Emitir eventos
	EventBus.emit_unit_created({\"unit_id\": 123, \"type\": \"test\"})\n	EventBus.emit_unit_moved(123, 1, 2)\n	EventBus.emit_unit_selected(123)\n	\n	# Aguardar um frame para sinais serem processados\n	await Engine.get_main_loop().process_frame\n	\n	# Verificar se eventos foram capturados\n	TestFramework.assert_true(captured_events.has(\"unit_created\"), \"Evento unit_created deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"unit_moved\"), \"Evento unit_moved deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"unit_selected\"), \"Evento unit_selected deve ser capturado\")\n\n## Teste: Eventos de jogo\nstatic func test_game_events() -> void:\n	_reset_captured_events()\n	\n	# Conectar aos sinais\n	var instance = EventBus.get_instance()\n	if instance:\n		if not instance.game_state_changed.is_connected(_on_game_state_changed):\n			instance.game_state_changed.connect(_on_game_state_changed)\n		if not instance.turn_started.is_connected(_on_turn_started):\n			instance.turn_started.connect(_on_turn_started)\n		if not instance.turn_ended.is_connected(_on_turn_ended):\n			instance.turn_ended.connect(_on_turn_ended)\n	\n	# Emitir eventos\n	EventBus.emit_game_state_changed(\"playing\")\n	EventBus.emit_turn_started(1)\n	EventBus.emit_turn_ended(1)\n	\n	# Aguardar processamento\n	await Engine.get_main_loop().process_frame\n	\n	# Verificar eventos\n	TestFramework.assert_true(captured_events.has(\"game_state_changed\"), \"Evento game_state_changed deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"turn_started\"), \"Evento turn_started deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"turn_ended\"), \"Evento turn_ended deve ser capturado\")\n\n## Teste: Mensagens do sistema\nstatic func test_system_messages() -> void:\n	_reset_captured_events()\n	\n	# Conectar aos sinais\n	var instance = EventBus.get_instance()\n	if instance:\n		if not instance.system_error.is_connected(_on_system_error):\n			instance.system_error.connect(_on_system_error)\n		if not instance.system_warning.is_connected(_on_system_warning):\n			instance.system_warning.connect(_on_system_warning)\n		if not instance.system_info.is_connected(_on_system_info):\n			instance.system_info.connect(_on_system_info)\n	\n	# Emitir mensagens\n	EventBus.emit_error(\"Test error\")\n	EventBus.emit_warning(\"Test warning\")\n	EventBus.emit_info(\"Test info\")\n	\n	# Aguardar processamento\n	await Engine.get_main_loop().process_frame\n	\n	# Verificar mensagens\n	TestFramework.assert_true(captured_events.has(\"system_error\"), \"Evento system_error deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"system_warning\"), \"Evento system_warning deve ser capturado\")\n	TestFramework.assert_true(captured_events.has(\"system_info\"), \"Evento system_info deve ser capturado\")\n\n## Utilitários\n\nstatic func _reset_captured_events() -> void:\n	captured_events.clear()\n	last_event_data.clear()\n\n## Callbacks para capturar eventos\n\nstatic func _on_unit_created(unit_data: Dictionary) -> void:\n	captured_events.append(\"unit_created\")\n	last_event_data[\"unit_created\"] = unit_data\n\nstatic func _on_unit_moved(unit_id: int, from_star: int, to_star: int) -> void:\n	captured_events.append(\"unit_moved\")\n	last_event_data[\"unit_moved\"] = {\"unit_id\": unit_id, \"from\": from_star, \"to\": to_star}\n\nstatic func _on_unit_selected(unit_id: int) -> void:\n	captured_events.append(\"unit_selected\")\n	last_event_data[\"unit_selected\"] = {\"unit_id\": unit_id}\n\nstatic func _on_game_state_changed(new_state: String) -> void:\n	captured_events.append(\"game_state_changed\")\n	last_event_data[\"game_state_changed\"] = {\"state\": new_state}\n\nstatic func _on_turn_started(player_id: int) -> void:\n	captured_events.append(\"turn_started\")\n	last_event_data[\"turn_started\"] = {\"player_id\": player_id}\n\nstatic func _on_turn_ended(player_id: int) -> void:\n	captured_events.append(\"turn_ended\")\n	last_event_data[\"turn_ended\"] = {\"player_id\": player_id}\n\nstatic func _on_system_error(message: String) -> void:\n	captured_events.append(\"system_error\")\n	last_event_data[\"system_error\"] = {\"message\": message}\n\nstatic func _on_system_warning(message: String) -> void:\n	captured_events.append(\"system_warning\")\n	last_event_data[\"system_warning\"] = {\"message\": message}\n\nstatic func _on_system_info(message: String) -> void:\n	captured_events.append(\"system_info\")\n	last_event_data[\"system_info\"] = {\"message\": message}"