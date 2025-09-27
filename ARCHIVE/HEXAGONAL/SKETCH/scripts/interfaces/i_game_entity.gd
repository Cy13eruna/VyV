## IGameEntity - Interface para entidades do jogo
## Define contrato comum para todas as entidades (Units, Domains, etc.)

class_name IGameEntity
extends RefCounted

## Propriedades obrigatórias
var entity_id: int = -1
var entity_type: String = ""
var is_active: bool = true

## Sinais obrigatórios
signal entity_created(entity_id: int)
signal entity_destroyed(entity_id: int)
signal entity_state_changed(entity_id: int, new_state)

## Métodos obrigatórios (devem ser implementados pelas classes filhas)
func get_entity_id() -> int:
	return entity_id

func get_entity_type() -> String:
	return entity_type

func get_info() -> Dictionary:
	push_error("get_info() must be implemented by subclass")
	return {}

func cleanup() -> void:
	push_error("cleanup() must be implemented by subclass")

func validate() -> bool:
	push_error("validate() must be implemented by subclass")
	return false