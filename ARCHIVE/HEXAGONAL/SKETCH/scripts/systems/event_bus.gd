## EventBus - Sistema de eventos centralizado
## Desacopla comunicação entre sistemas

extends Node

## Sinais de Unidade
signal unit_created(unit_data: Dictionary)
signal unit_destroyed(unit_id: int)
signal unit_moved(unit_id: int, from_star: int, to_star: int)
signal unit_positioned(star_id: int)
signal unit_state_changed(unit_id: int, new_state: int)

## Sinais de Domínio
signal domain_created(domain_data: Dictionary)
signal domain_destroyed(domain_id: int)
signal domain_owner_changed(domain_id: int, new_owner: int)

## Sinais de Jogo
signal game_state_changed(new_state: String)
signal turn_started(player_id: int)
signal turn_ended(player_id: int)
signal player_action(player_id: int, action_type: String, data: Dictionary)

## Sinais de Input
signal star_clicked(star_id: int, button: int)
signal unit_selected(unit_id: int)
signal unit_deselected(unit_id: int)

## Sinais de Sistema
signal system_error(error_message: String)
signal system_warning(warning_message: String)
signal system_info(info_message: String)

## Singleton access
static var instance: EventBus

func _ready():
	instance = self
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

## Get singleton instance
static func get_instance() -> EventBus:
	return instance

## Emit unit events
static func emit_unit_created(unit_data: Dictionary):
	if instance: instance.unit_created.emit(unit_data)

static func emit_unit_moved(unit_id: int, from_star: int, to_star: int):
	if instance: instance.unit_moved.emit(unit_id, from_star, to_star)

static func emit_unit_selected(unit_id: int):
	if instance: instance.unit_selected.emit(unit_id)

static func emit_unit_deselected(unit_id: int):
	if instance: instance.unit_deselected.emit(unit_id)

## Emit domain events
static func emit_domain_created(domain_data: Dictionary):
	if instance: instance.domain_created.emit(domain_data)

## Emit game events
static func emit_game_state_changed(new_state: String):
	if instance: instance.game_state_changed.emit(new_state)

static func emit_turn_started(player_id: int):
	if instance: instance.turn_started.emit(player_id)

static func emit_turn_ended(player_id: int):
	if instance: instance.turn_ended.emit(player_id)

static func emit_star_clicked(star_id: int, button: int):
	if instance: instance.star_clicked.emit(star_id, button)

## Emit system messages
static func emit_error(message: String):
	if instance: instance.system_error.emit(message)
	print("ERROR: " + message)

static func emit_warning(message: String):
	if instance: instance.system_warning.emit(message)
	print("WARNING: " + message)

static func emit_info(message: String):
	if instance: instance.system_info.emit(message)
	print("INFO: " + message)