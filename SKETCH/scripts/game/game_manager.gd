class_name GameManager
extends RefCounted

const Logger = preload("res://scripts/core/logger.gd")
const ResultClass = preload("res://scripts/core/result.gd")
const Unit = preload("res://scripts/entities/unit.gd")
const SharedGameState = preload("res://scripts/systems/shared_game_state.gd")

signal unit_created(unit)
signal domain_created(domain)

var units = []
var domains = []
var hex_grid_ref = null
var star_mapper_ref = null
var parent_node_ref = null
var max_units_per_player: int = 50
var current_player_id: int = 1

# Sistemas de validação
var shared_game_state: SharedGameState

func _init():
	max_units_per_player = 50

func setup_references(hex_grid, star_mapper, parent_node) -> ResultClass:
	if not hex_grid:
		return ResultClass.error("hex_grid cannot be null")
	if not star_mapper:
		return ResultClass.error("star_mapper cannot be null")
	if not parent_node:
		return ResultClass.error("parent_node cannot be null")
	
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	parent_node_ref = parent_node
	
	# Inicializar sistemas de validação
	shared_game_state = SharedGameState.new()
	shared_game_state.setup(hex_grid, star_mapper, parent_node)
	
	Logger.debug("Referencias e sistemas de terreno configurados", "GameManager")
	return ResultClass.success(true)

func create_unit(star_id: int = -1) -> ResultClass:
	if not hex_grid_ref or not star_mapper_ref or not parent_node_ref:
		return ResultClass.error("Referencias nao configuradas")
	
	var unit = Unit.new()
	var setup_result = unit.setup_references(hex_grid_ref, star_mapper_ref)
	if not setup_result:
		return ResultClass.error("Falha ao configurar referencias da unidade")
	
	var visual_result = unit.create_visual(parent_node_ref)
	if not visual_result:
		unit.cleanup()
		return ResultClass.error("Falha ao criar visual da unidade")
	
	# Posicionar unidade na estrela se especificada
	if star_id >= 0:
		var position_result = unit.position_at_star(star_id)
		if not position_result:
			unit.cleanup()
			return ResultClass.error("Falha ao posicionar unidade na estrela %d" % star_id)
	
	units.append(unit)
	unit_created.emit(unit)
	Logger.debug("Unidade criada e posicionada na estrela %d" % star_id, "GameManager")
	return ResultClass.success(unit)

func create_domain(center_star_id: int):
	if not hex_grid_ref or not star_mapper_ref:
		return null
	
	var DomainClass = load("res://scripts/entities/domain.gd")
	var domain = DomainClass.new()
	domain.setup_references(hex_grid_ref, star_mapper_ref)
	
	if not domain.create_at_star(center_star_id, parent_node_ref):
		domain.cleanup()
		return null
	
	domain.set_legacy_owner(current_player_id)
	domains.append(domain)
	domain_created.emit(domain)
	return domain

func get_all_units():
	return units.duplicate()

func get_all_domains():
	return domains.duplicate()

func get_unit_at_star(star_id: int):
	for unit in units:
		if unit.get_current_star_id() == star_id:
			return unit
	return null

func spawn_domain_with_unit(center_star_id: int):
	var domain = create_domain(center_star_id)
	if not domain:
		return null
	
	var unit_result = create_unit(center_star_id)
	if unit_result.is_error():
		return domain
	
	var unit = unit_result.get_value()
	return {"domain": domain, "unit": unit}

func spawn_domain_with_unit_colored(center_star_id: int, color: Color):
	var domain = create_domain(center_star_id)
	if not domain:
		return null
	
	domain.set_color(color)
	
	var unit_result = create_unit(center_star_id)
	if unit_result.is_error():
		return domain
	
	var unit = unit_result.get_value()
	unit.set_color(color)
	return {"domain": domain, "unit": unit}

func clear_all_units() -> void:
	for unit in units:
		unit.cleanup()
	units.clear()
	print("🧹 GameManager: todas as unidades limpas")

func clear_all_domains() -> void:
	for domain in domains:
		domain.cleanup()
	domains.clear()
	print("🧹 GameManager: todos os domínios limpos")

func clear_all_entities() -> void:
	clear_all_units()
	clear_all_domains()
	print("🧹 GameManager: todas as entidades limpas")

func get_valid_adjacent_stars(unit) -> Array:
	if not unit or not hex_grid_ref or not star_mapper_ref:
		return []
	
	var current_star_id = unit.get_current_star_id()
	if current_star_id < 0:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	if current_star_id >= dot_positions.size():
		return []
	
	var current_pos = dot_positions[current_star_id]
	var valid_stars = []
	var max_adjacent_distance = 38.0  # Valor padrão para adjacência
	
	# Encontrar estrelas adjacentes e validar terreno
	for i in range(dot_positions.size()):
		if i != current_star_id:
			var distance = current_pos.distance_to(dot_positions[i])
			if distance <= max_adjacent_distance:
				# Verificar se movimento não é bloqueado por terreno
				var is_blocked = false
				
				# Usar SharedGameState para validação de terreno
				if shared_game_state:
					is_blocked = not shared_game_state.is_movement_valid(current_star_id, i)
				
				# Verificar se estrela está ocupada por outra unidade
				var occupying_unit = get_unit_at_star(i)
				var is_occupied = occupying_unit != null and occupying_unit != unit
				
				# Adicionar apenas se não bloqueado e não ocupado
				if not is_blocked and not is_occupied:
					valid_stars.append(i)
	
	Logger.debug("Unidade na estrela %d tem %d estrelas válidas (com validação de terreno)" % [current_star_id, valid_stars.size()], "GameManager")
	return valid_stars

func move_unit_to_star(unit, target_star_id: int) -> bool:
	if not unit or not hex_grid_ref or not star_mapper_ref:
		return false
	
	# Verificar se a estrela de destino é válida
	var dot_positions = hex_grid_ref.get_dot_positions()
	if target_star_id < 0 or target_star_id >= dot_positions.size():
		Logger.warning("Estrela de destino inválida: %d" % target_star_id, "GameManager")
		return false
	
	# Verificar se a unidade pode se mover para a estrela (inclui validação de terreno)
	var valid_stars = get_valid_adjacent_stars(unit)
	if target_star_id not in valid_stars:
		var current_star_id = unit.get_current_star_id()
		
		# Verificar motivo específico da falha
		var is_blocked_by_terrain = false
		if shared_game_state:
			is_blocked_by_terrain = not shared_game_state.is_movement_valid(current_star_id, target_star_id)
		
		var occupying_unit = get_unit_at_star(target_star_id)
		var is_occupied = occupying_unit != null and occupying_unit != unit
		
		if is_blocked_by_terrain:
			Logger.warning("Movimento bloqueado por terreno (água/montanha) da estrela %d para %d" % [current_star_id, target_star_id], "GameManager")
		elif is_occupied:
			Logger.warning("Estrela %d já está ocupada por outra unidade" % target_star_id, "GameManager")
		else:
			Logger.warning("Estrela %d não é adjacente à posição atual da unidade" % target_star_id, "GameManager")
		return false
	
	# Executar movimento
	var old_star_id = unit.get_current_star_id()
	if unit.move_to_star(target_star_id):
		Logger.debug("Unidade movida da estrela %d para %d" % [old_star_id, target_star_id], "GameManager")
		return true
	else:
		Logger.warning("Falha ao mover unidade para estrela %d" % target_star_id, "GameManager")
		return false