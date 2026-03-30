# res://src/systems/entities/MapEntity.gd
class_name MapEntity
extends Node2D

## Propriedades base que toda entidade no mapa deve possuir.
## O uso de 'MapEntity' como tipo no GridManager/InputHandler evita o uso de .get()

# --- PROPRIEDADES DE ESTADO ---

@export var owner_id: int = -1
@export var grid_pos: Vector2 = Vector2.ZERO:
	set(v):
		# Aplicamos snap automático em qualquer tentativa de alteração da posição de grid
		grid_pos = v.snapped(Vector2(0.1, 0.1))

@export var entity_color: Color = Color.WHITE

# --- CICLO DE VIDA ---

func _ready() -> void:
	# Adicionamos a uma tag de grupo para buscas rápidas e performáticas
	add_to_group("map_entities")
	_apply_visuals()

# --- MÉTODOS PÚBLICOS (CONTRATOS) ---

## Configuração inicial da entidade. 
## Substitui a necessidade de inicialização manual em múltiplos pontos.
func setup(p_world_pos: Vector2, p_grid_pos: Vector2, p_color: Color, p_owner_id: int) -> void:
	self.global_position = p_world_pos
	self.grid_pos = p_grid_pos
	self.entity_color = p_color
	self.owner_id = p_owner_id
	
	# Se a entidade já estiver na árvore, aplica os visuais imediatamente
	if is_inside_tree():
		_apply_visuals()

## Helper para verificar propriedade de dono de forma legível
func is_owned_by(p_id: int) -> bool:
	return owner_id == p_id

## Exporta os dados da entidade para persistência ou comunicação de rede
func get_entity_data() -> Dictionary:
	return {
		"class": get_script().get_global_name() if get_script().get_global_name() else "MapEntity",
		"owner": owner_id,
		"grid_pos": grid_pos,
		"color": entity_color,
		"global_pos": global_position
	}

# --- MÉTODOS VIRTUAIS (Overrides obrigatórios ou opcionais) ---

## Define como a entidade se parece. 
## Vagabond.gd usará Label/Sprites, Domain.gd usará polígonos.
func _apply_visuals() -> void:
	# Implementação base vazia para evitar erros se chamada acidentalmente
	pass

## Interface para o sistema de Visibilidade/Fog of War.
## Implementada na base para que o VisibilityManager possa iterar sobre
## qualquer MapEntity sem verificar 'has_method'.
func update_fow_visibility(_lit_nodes: Array, _instant: bool = false) -> void:
	# Por padrão, entidades base podem ser sempre visíveis ou ignorar FOW
	pass