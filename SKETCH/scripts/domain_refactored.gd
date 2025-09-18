## Domain - Entidade de Domínio Refatorada do Jogo V&V
## Versão limpa com separação de responsabilidades

class_name DomainRefactored
extends IGameEntity

## Propriedades do domínio
var center_star_id: int = -1
var center_position: Vector2 = Vector2.ZERO
var vertices: Array = []
var owner_id: int = -1

## Componentes
var visual_component: DomainVisualComponent
var config: GameConfig

## Referências do sistema (injetadas via dependency injection)
var hex_grid_ref = null
var star_mapper_ref = null

## Inicializar domínio
func _init(id: int = -1, game_config: GameConfig = null):
	entity_id = id if id >= 0 else randi()
	entity_type = "Domain"
	config = game_config if game_config else GameConfig.get_instance()
	
	# Criar componente visual
	visual_component = DomainVisualComponent.new(config)
	
	# Conectar sinais do componente
	visual_component.visual_created.connect(_on_visual_created)
	visual_component.visual_destroyed.connect(_on_visual_destroyed)

## Configurar referências do sistema (Dependency Injection)
func setup_references(hex_grid, star_mapper) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	visual_component.set_hex_grid_reference(hex_grid)

## Criar domínio em uma estrela
func create_at_star(star_id: int, parent_node: Node) -> bool:
	if not _validate_star_id(star_id):
		return false
	
	# Configurar propriedades básicas
	center_star_id = star_id
	center_position = star_mapper_ref.get_star_position(star_id)
	
	# Encontrar vértices do hexágono
	vertices = _find_domain_vertices()
	
	if vertices.size() < 6:
		EventBus.emit_warning("Domain %d: could not find 6 adjacent vertices (only %d)" % [entity_id, vertices.size()])
		# Temporariamente permitir domínios com menos vértices para debug
	
	# Criar visualização
	if not visual_component.create_visual(parent_node):
		EventBus.emit_error("Domain %d: failed to create visualization" % entity_id)
		return false
	
	# Atualizar visual com vértices
	visual_component.update_vertices(vertices)
	
	entity_created.emit(entity_id)
	EventBus.emit_domain_created(get_info())
	EventBus.emit_info("Domain %d created at star %d with %d vertices" % [entity_id, center_star_id, vertices.size()])
	return true

## Verificar se domínio compartilharia lados com outros domínios
func would_share_sides_with_domains(existing_domains: Array) -> bool:
	if vertices.is_empty():
		vertices = _find_domain_vertices()
	
	EventBus.emit_info("Checking edge sharing for domain %d with %d existing domains" % [entity_id, existing_domains.size()])
	
	for existing_domain in existing_domains:
		if existing_domain == self:
			continue
		
		var existing_vertices = existing_domain.get_vertices()
		EventBus.emit_info("Comparing with domain %d (center: %d)" % [existing_domain.get_entity_id(), existing_domain.get_center_star_id()])
		
		# Verificar cada ARESTA do novo domínio
		for i in range(vertices.size()):
			var new_side_start = vertices[i]
			var new_side_end = vertices[(i + 1) % vertices.size()]
			
			# Verificar contra cada ARESTA do domínio existente
			for j in range(existing_vertices.size()):
				var existing_side_start = existing_vertices[j]
				var existing_side_end = existing_vertices[(j + 1) % existing_vertices.size()]
				
				if _are_sides_identical(new_side_start, new_side_end, existing_side_start, existing_side_end):
					EventBus.emit_warning("Domain %d: shared edge detected with domain %d" % [entity_id, existing_domain.get_entity_id()])
					return true
	
	EventBus.emit_info("No shared edges detected for domain %d (vertices can be shared)" % entity_id)
	return false

## Verificar se domínio está na estrela especificada
func is_at_star(star_id: int) -> bool:
	return center_star_id == star_id

## Obter ID da estrela central
func get_center_star_id() -> int:
	return center_star_id

## Obter posição central
func get_center_position() -> Vector2:
	return center_position

## Obter vértices do domínio
func get_vertices() -> Array:
	return vertices.duplicate()

## Obter proprietário do domínio
func get_owner_id() -> int:
	return owner_id

## Definir proprietário do domínio
func set_owner(new_owner_id: int) -> void:
	if owner_id != new_owner_id:
		var old_owner = owner_id
		owner_id = new_owner_id
		EventBus.instance.domain_owner_changed.emit(entity_id, new_owner_id)
		EventBus.emit_info("Domain %d owner changed from %d to %d" % [entity_id, old_owner, new_owner_id])

## Definir cor do domínio
func set_color(new_color: Color) -> void:
	visual_component.update_color(new_color)
	EventBus.emit_info("Domain %d color changed to %s" % [entity_id, new_color])

## Implementação da interface IGameEntity
func get_info() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_type": entity_type,
		"center_star_id": center_star_id,
		"center_position": center_position,
		"vertices_count": vertices.size(),
		"owner_id": owner_id,
		"visual_info": visual_component.get_visual_info() if visual_component else {}
	}

func cleanup() -> void:
	if visual_component:
		visual_component.cleanup()
		visual_component = null
	
	entity_destroyed.emit(entity_id)
	EventBus.emit_info("Domain %d resources cleaned up" % entity_id)

func validate() -> bool:
	return entity_id >= 0 and config != null and visual_component != null

## Encontrar vértices do domínio
func _find_domain_vertices() -> Array:
	if not star_mapper_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	var domain_vertices = []
	
	# Encontrar estrelas adjacentes
	var adjacent_positions = []
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = center_position.distance_to(star_pos)
		
		if distance > 5.0 and distance <= config.max_adjacent_distance:
			adjacent_positions.append(star_pos)
	
	# Ordenar por ângulo para formar hexágono correto
	adjacent_positions.sort_custom(func(a, b): 
		var angle_a = center_position.angle_to_point(a)
		var angle_b = center_position.angle_to_point(b)
		return angle_a < angle_b
	)
	
	# Pegar até 6 vértices
	for i in range(min(6, adjacent_positions.size())):
		domain_vertices.append(adjacent_positions[i])
	
	return domain_vertices

## Validar ID de estrela
func _validate_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		EventBus.emit_error("Domain %d: star_mapper reference not configured" % entity_id)
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		EventBus.emit_error("Domain %d: invalid star ID: %d" % [entity_id, star_id])
		return false
	
	return true

## Verificar se dois lados são idênticos
func _are_sides_identical(side1_start: Vector2, side1_end: Vector2, side2_start: Vector2, side2_end: Vector2) -> bool:
	var tolerance = config.domain_position_tolerance
	
	# Verificar se side1 == side2 (mesma direção)
	if side1_start.distance_to(side2_start) <= tolerance and side1_end.distance_to(side2_end) <= tolerance:
		return true
	
	# Verificar se side1 == side2 (direção oposta)
	if side1_start.distance_to(side2_end) <= tolerance and side1_end.distance_to(side2_start) <= tolerance:
		return true
	
	return false

## Callbacks dos componentes
func _on_visual_created(node: Node) -> void:
	EventBus.emit_info("Domain %d visual component created" % entity_id)

func _on_visual_destroyed() -> void:
	EventBus.emit_info("Domain %d visual component destroyed" % entity_id)