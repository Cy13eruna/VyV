class_name GameManager
extends RefCounted

const Logger = preload("res://scripts/core/logger.gd")
const ResultClass = preload("res://scripts/core/result.gd")
const Unit = preload("res://scripts/entities/unit.gd")
const SharedGameState = preload("res://scripts/systems/shared_game_state.gd")
const NameGenerator = preload("res://scripts/core/name_generator.gd")

signal unit_created(unit)
signal domain_created(domain)

var units = []
var domains = []
var hex_grid_ref = null
var star_mapper_ref = null
var parent_node_ref = null
var max_units_per_player: int = 50
var current_player_id: int = 1

# Sistemas de validação e nomes
var shared_game_state: SharedGameState
var name_generator: NameGenerator

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
	
	# Inicializar sistemas de validação e nomes
	shared_game_state = SharedGameState.new()
	shared_game_state.setup(hex_grid, star_mapper, parent_node)
	
	name_generator = NameGenerator.new()
	
	Logger.debug("Referencias, sistemas de terreno e gerador de nomes configurados", "GameManager")
	return ResultClass.success(true)

func create_unit(star_id: int = -1) -> ResultClass:
	if not hex_grid_ref or not star_mapper_ref or not parent_node_ref:
		return ResultClass.error("Referencias nao configuradas")
	
	var unit = Unit.new()
	var setup_result = unit.setup_references(hex_grid_ref, star_mapper_ref, name_generator)
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
	domain.setup_references(hex_grid_ref, star_mapper_ref, name_generator)
	
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
	# Vincular unidade ao domínio de origem
	unit.set_origin_domain(domain.get_domain_id())
	
	# Forçar criação dos labels de nome após nomes serem gerados
	# Usar call_deferred para aguardar um frame
	if parent_node_ref:
		parent_node_ref.call_deferred("_ensure_labels_created", domain, unit)
	
	Logger.info("Domínio %s e unidade %s criados com relacionamento" % [domain.get_domain_name(), unit.get_unit_name()], "GameManager")
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
	# Vincular unidade ao domínio de origem
	unit.set_origin_domain(domain.get_domain_id())
	unit.set_color(color)
	
	# Forçar criação dos labels de nome após nomes serem gerados
	# Usar call_deferred para aguardar um frame
	if parent_node_ref:
		parent_node_ref.call_deferred("_ensure_labels_created", domain, unit)
	
	Logger.info("Domínio %s e unidade %s criados com relacionamento" % [domain.get_domain_name(), unit.get_unit_name()], "GameManager")
	return {"domain": domain, "unit": unit}

func clear_all_units() -> void:
	for unit in units:
		unit.cleanup()
	units.clear()
	Logger.info("🧹 GameManager: todas as unidades limpas", "GameManager")

func clear_all_domains() -> void:
	for domain in domains:
		domain.cleanup()
	domains.clear()
	Logger.info("🧹 GameManager: todos os domínios limpos", "GameManager")

func clear_all_entities() -> void:
	clear_all_units()
	clear_all_domains()
	Logger.info("🧹 GameManager: todas as entidades limpas", "GameManager")

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

## Mover unidade para uma estrela (sem verificação de poder - uso interno)
func move_unit_to_star(unit, target_star_id: int) -> bool:
	if not unit:
		return false
	
	# Verificar se estrela de destino é válida
	if target_star_id < 0 or target_star_id >= star_mapper_ref.get_star_count():
		Logger.error("ID de estrela inválido: %d" % target_star_id, "GameManager")
		return false
	
	# Verificar se estrela está ocupada
	var occupying_unit = get_unit_at_star(target_star_id)
	if occupying_unit and occupying_unit != unit:
		Logger.warning("Estrela %d já ocupada por outra unidade" % target_star_id, "GameManager")
		return false
	
	# Executar movimento (bypass da verificação de poder interna da unidade)
	return unit.position_at_star(target_star_id)

# ================================================================
# SISTEMA DE NOMES
# ================================================================

## Obter gerador de nomes
func get_name_generator() -> NameGenerator:
	return name_generator

## Forçar atualização visual de todos os nomes
func refresh_all_name_visuals() -> void:
	# Atualizar labels de domínios
	for domain in domains:
		if domain.has_name():
			if not domain.name_label:
				domain._create_name_label(parent_node_ref)
			else:
				domain._update_name_label_text()
				domain._update_name_label_color()
	
	# Atualizar labels de unidades
	for unit in units:
		if unit.has_name():
			if not unit.name_label:
				unit._create_name_label(parent_node_ref)
			else:
				unit._update_name_label_text()
				unit._update_name_label_color()
	
	# Aplicar melhorias estéticas
	apply_aesthetic_improvements()
	
	Logger.info("Visuais de nomes atualizados para %d domínios e %d unidades" % [domains.size(), units.size()], "GameManager")

## Obter estatísticas do sistema de nomes
func get_name_stats() -> Dictionary:
	if not name_generator:
		return {}
	return name_generator.get_stats()

## Comando para forçar recriação de todos os labels
func recreate_all_name_labels() -> void:
	# Limpar labels existentes usando cleanup das próprias entidades
	for domain in domains:
		if domain.name_label and is_instance_valid(domain.name_label):
			if domain.name_label.get_parent():
				domain.name_label.get_parent().remove_child(domain.name_label)
			# Usar o ObjectPool da entidade
			var ObjectPool = preload("res://scripts/core/object_pool.gd")
			ObjectPool.return_object("UnitLabel", domain.name_label)
			domain.name_label = null
	
	for unit in units:
		if unit.name_label and is_instance_valid(unit.name_label):
			if unit.name_label.get_parent():
				unit.name_label.get_parent().remove_child(unit.name_label)
			# Usar o ObjectPool da entidade
			var ObjectPool = preload("res://scripts/core/object_pool.gd")
			ObjectPool.return_object("UnitLabel", unit.name_label)
			unit.name_label = null
	
	# Recriar todos os labels
	refresh_all_name_visuals()
	
	Logger.info("Todos os labels de nome foram recriados", "GameManager")

## Aplicar melhorias estéticas em todos os labels
func apply_aesthetic_improvements() -> void:
	# Aplicar melhorias nos domínios
	for domain in domains:
		if domain.name_label and is_instance_valid(domain.name_label):
			# Aplicar configurações de qualidade
			domain.name_label.clip_contents = false
			domain.name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			# Atualizar tamanho da fonte
			domain.name_label.add_theme_font_size_override("font_size", 10)
	
	# Aplicar melhorias nas unidades
	for unit in units:
		if unit.name_label and is_instance_valid(unit.name_label):
			# Aplicar configurações de qualidade
			unit.name_label.clip_contents = false
			unit.name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
			# Atualizar tamanho da fonte
			unit.name_label.add_theme_font_size_override("font_size", 8)
			# Reposicionar mais próximo
			if unit.current_star_id >= 0 and star_mapper_ref and hex_grid_ref:
				var star_position = star_mapper_ref.get_star_position(unit.current_star_id)
				var global_position = hex_grid_ref.to_global(star_position)
				unit._position_name_label(global_position)
	
	Logger.info("Melhorias estéticas aplicadas em %d domínios e %d unidades" % [domains.size(), units.size()], "GameManager")

# ================================================================
# SISTEMA DE PODER
# ================================================================

## Produzir poder em todos os domínios no início do turno
func produce_power_for_all_domains() -> Dictionary:
	var power_report = {
		"total_produced": 0,
		"domains_count": 0,
		"domain_details": []
	}
	
	for domain in domains:
		var produced = domain.produce_power()
		power_report.total_produced += produced
		power_report.domains_count += 1
		power_report.domain_details.append({
			"domain_id": domain.get_domain_id(),
			"domain_name": domain.get_domain_name(),
			"power_produced": produced,
			"total_power": domain.get_power()
		})
	
	Logger.info("Poder produzido: %d total em %d domínios" % [power_report.total_produced, power_report.domains_count], "GameManager")
	
	# Forçar atualização dos displays de poder
	_update_all_power_displays()
	
	return power_report

## Verificar se unidade pode agir (tem ações e domínio tem poder)
func can_unit_act(unit) -> bool:
	if not unit or not unit.can_act():
		return false
	
	var origin_domain = get_domain_by_id(unit.get_origin_domain_for_power_check())
	if not origin_domain:
		return false
	
	return origin_domain.has_power(1)

## Tentar mover unidade (com verificação e consumo de poder)
func move_unit_to_star_with_power(unit, target_star_id: int) -> bool:
	if not unit:
		return false
	
	# Verificar se unidade pode agir
	if not can_unit_act(unit):
		Logger.warning("Unidade %s não pode agir (sem ações ou sem poder)" % unit.get_unit_name(), "GameManager")
		return false
	
	# Obter domínio de origem
	var origin_domain = get_domain_by_id(unit.get_origin_domain_for_power_check())
	if not origin_domain:
		Logger.error("Domínio de origem não encontrado para unidade %s" % unit.get_unit_name(), "GameManager")
		return false
	
	# Consumir poder do domínio
	if not origin_domain.consume_power(1):
		Logger.warning("Domínio %s não tem poder suficiente para mover %s" % [origin_domain.get_domain_name(), unit.get_unit_name()], "GameManager")
		return false
	
	# Executar movimento
	var success = move_unit_to_star(unit, target_star_id)
	if success:
		# Atualizar display do domínio
		origin_domain._update_name_label_text()
		# Reduzir ações da unidade
		unit.actions_remaining -= 1
		Logger.info("Unidade %s movida com sucesso. Domínio %s agora tem %d poder" % [unit.get_unit_name(), origin_domain.get_domain_name(), origin_domain.get_power()], "GameManager")
	else:
		# Reverter consumo de poder se movimento falhou
		origin_domain.set_power(origin_domain.get_power() + 1)
		origin_domain._update_name_label_text()
		Logger.warning("Movimento falhou, poder revertido para domínio %s" % origin_domain.get_domain_name(), "GameManager")
	
	return success

## Obter domínio por ID
func get_domain_by_id(domain_id: int):
	for domain in domains:
		if domain.get_domain_id() == domain_id:
			return domain
	return null

## Obter relatório de poder de todos os domínios
func get_power_report() -> Dictionary:
	var report = {
		"total_power": 0,
		"domains": []
	}
	
	for domain in domains:
		var domain_power = domain.get_power()
		report.total_power += domain_power
		report.domains.append({
			"id": domain.get_domain_id(),
			"name": domain.get_domain_name(),
			"power": domain_power,
			"display_text": domain.get_display_text()
		})
	
	return report

## Definir poder para um domínio (para testes)
func set_domain_power(domain_id: int, power: int) -> bool:
	var domain = get_domain_by_id(domain_id)
	if domain:
		domain.set_power(power)
		domain._update_name_label_text()
		Logger.info("Poder do domínio %s definido para %d" % [domain.get_domain_name(), power], "GameManager")
		return true
	return false

## Listar todos os domínios com nomes
func list_named_domains() -> Array:
	var named_domains = []
	for domain in domains:
		if domain.has_name():
			named_domains.append({
				"id": domain.get_domain_id(),
				"name": domain.get_domain_name(),
				"initial": domain.get_domain_initial(),
				"has_label": domain.name_label != null
			})
	return named_domains

## Listar todas as unidades com nomes
func list_named_units() -> Array:
	var named_units = []
	for unit in units:
		if unit.has_name():
			named_units.append({
				"id": unit.unit_id,
				"name": unit.get_unit_name(),
				"initial": unit.get_unit_initial(),
				"origin_domain_id": unit.get_origin_domain_id(),
				"has_label": unit.name_label != null
			})
	return named_units

## Validar todos os relacionamentos unidade-domínio
func validate_all_relationships() -> Dictionary:
	var valid_count = 0
	var invalid_count = 0
	var invalid_units = []
	
	for unit in units:
		if unit.has_name() and unit.get_origin_domain_id() != -1:
			if unit.validate_domain_relationship():
				valid_count += 1
			else:
				invalid_count += 1
				invalid_units.append({
					"unit_id": unit.unit_id,
					"unit_name": unit.get_unit_name(),
					"origin_domain_id": unit.get_origin_domain_id()
				})
	
	return {
		"valid_relationships": valid_count,
		"invalid_relationships": invalid_count,
		"invalid_units": invalid_units
	}

## Imprimir relatório de nomes
func print_names_report() -> void:
	print("\n📋 === RELATÓRIO DO SISTEMA DE NOMES ===")
	
	# Estatísticas gerais
	var stats = get_name_stats()
	print("📊 Estatísticas:")
	print("   • Iniciais usadas: %d/%d" % [stats.get("used_initials", 0), stats.get("total_initials", 26)])
	print("   • Domínios nomeados: %d" % stats.get("domains_named", 0))
	print("   • Unidades nomeadas: %d" % stats.get("units_named", 0))
	
	# Domínios
	var named_domains = list_named_domains()
	print("\n🏰 Domínios:")
	for domain_info in named_domains:
		print("   • %s (%s) - ID: %d" % [domain_info.name, domain_info.initial, domain_info.id])
	
	# Unidades
	var named_units = list_named_units()
	print("\n⚔️ Unidades:")
	for unit_info in named_units:
		print("   • %s (%s) - ID: %d - Domínio: %d" % [unit_info.name, unit_info.initial, unit_info.id, unit_info.origin_domain_id])
	
	# Validação de relacionamentos
	var validation = validate_all_relationships()
	print("\n🔗 Relacionamentos:")
	print("   • Válidos: %d" % validation.valid_relationships)
	print("   • Inválidos: %d" % validation.invalid_relationships)
	
	if validation.invalid_relationships > 0:
		print("   ⚠️ Unidades com relacionamento inválido:")
		for invalid_unit in validation.invalid_units:
			print("     - %s (ID: %d, Domínio: %d)" % [invalid_unit.unit_name, invalid_unit.unit_id, invalid_unit.origin_domain_id])
	
	print("\n=== FIM DO RELATÓRIO ===\n")

## Imprimir relatório de poder
func print_power_report() -> void:
	print("\n⚡ === RELATÓRIO DE PODER ===")
	
	var power_report = get_power_report()
	print("📊 Poder total no jogo: %d" % power_report.total_power)
	print("🏰 Domínios com poder:")
	
	for domain_info in power_report.domains:
		var status_icon = "⚡" if domain_info.power > 0 else "🚫"
		print("   %s %s - %d poder" % [status_icon, domain_info.name, domain_info.power])
	
	# Verificar unidades que podem agir
	print("\n⚔️ Unidades que podem agir:")
	var active_units = 0
	var blocked_units = 0
	
	for unit in units:
		if can_unit_act(unit):
			active_units += 1
			print("   ✅ %s (domínio: %s)" % [unit.get_unit_name(), _get_domain_name_by_id(unit.get_origin_domain_for_power_check())])
		else:
			blocked_units += 1
			var reason = "sem ações" if unit.actions_remaining <= 0 else "sem poder"
			print("   ❌ %s (%s)" % [unit.get_unit_name(), reason])
	
	print("\n📊 Resumo: %d unidades ativas, %d bloqueadas" % [active_units, blocked_units])
	print("=== FIM DO RELATÓRIO DE PODER ===\n")

## Função auxiliar para obter nome do domínio por ID
func _get_domain_name_by_id(domain_id: int) -> String:
	var domain = get_domain_by_id(domain_id)
	return domain.get_domain_name() if domain else "Desconhecido"

## Forçar atualização de todos os displays de poder
func _update_all_power_displays() -> void:
	for domain in domains:
		if domain.name_label and is_instance_valid(domain.name_label):
			domain._update_name_label_text()
	
	Logger.debug("Displays de poder atualizados para %d domínios" % domains.size(), "GameManager")

## Forçar atualização manual de displays (para debug)
func force_update_power_displays() -> void:
	_update_all_power_displays()
	Logger.info("Atualização manual de displays de poder executada", "GameManager")

## Forçar criação dos labels de nome após geração
func _ensure_name_labels_created(domain, unit) -> void:
	if not domain or not unit:
		return
	
	# Não podemos usar await em RefCounted, então vamos usar call_deferred
	# Forçar criação do label do domínio se tem nome mas não tem label
	if domain.has_name() and not domain.name_label:
		domain._create_name_label(parent_node_ref)
	
	# Forçar criação do label da unidade se tem nome mas não tem label
	if unit.has_name() and not unit.name_label:
		unit._create_name_label(parent_node_ref)
	
	Logger.debug("Labels de nome criados para domínio %s e unidade %s" % [domain.get_domain_name(), unit.get_unit_name()], "GameManager")