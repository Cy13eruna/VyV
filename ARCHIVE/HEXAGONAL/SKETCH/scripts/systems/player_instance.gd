## PlayerInstance - Instância Individual de Jogador
## Cada jogador tem sua própria instância isolada para evitar conflitos
## Preparado para sistema multiplayer online

class_name PlayerInstance
extends RefCounted

## Sinais da instância do jogador
signal unit_created(unit_id: int)
signal unit_moved(unit_id: int, from_star: int, to_star: int)
signal domain_created(domain_id: int)
signal visibility_changed()

## Identificação do jogador
var player_id: int
var team_color: Color
var player_name: String

## Entidades do jogador
var units: Array[Unit] = []
var domains: Array[Domain] = []

## Sistema de visibilidade individual
var fog_of_war: FogOfWar
var visible_stars: Array[int] = []
var visible_diamonds: Array[int] = []

## Estado do jogador
var actions_remaining: int = 1
var is_active_turn: bool = false

## Referências compartilhadas (somente leitura)
var shared_hex_grid = null
var shared_star_mapper = null

## Inicializar instância do jogador
func _init(id: int, color: Color, name: String = ""):
	player_id = id
	team_color = color
	player_name = name if name != "" else "Jogador " + str(id)
	
	# Criar sistema de fog of war individual
	fog_of_war = FogOfWar.new()

## Configurar referências compartilhadas
func setup_shared_references(hex_grid, star_mapper):
	shared_hex_grid = hex_grid
	shared_star_mapper = star_mapper
	
	if fog_of_war:
		fog_of_war.setup_references(hex_grid, self)

## Criar unidade para este jogador
func create_unit(star_id: int = -1) -> Unit:
	var unit = Unit.new()
	unit.setup_references(shared_hex_grid, shared_star_mapper)
	unit.set_team(player_id, team_color)
	
	if star_id >= 0:
		unit.position_at_star(star_id)
	
	units.append(unit)
	unit_created.emit(unit.get_unit_id())
	
	return unit

## Criar domínio para este jogador
func create_domain(center_star_id: int) -> Domain:
	var domain = Domain.new()
	domain.setup_references(shared_hex_grid, shared_star_mapper)
	domain.set_color(team_color)
	domain.set_owner(player_id)
	
	if domain.create_at_star(center_star_id, shared_hex_grid):
		domains.append(domain)
		domain_created.emit(domain.get_domain_id())
		return domain
	
	return null

## Mover unidade (com validações de turno)
func move_unit(unit: Unit, target_star_id: int) -> bool:
	if not is_active_turn:
		return false
	
	if not unit in units:
		return false
	
	if actions_remaining <= 0:
		return false
	
	var from_star = unit.get_current_star_id()
	if unit.move_to_star(target_star_id):
		actions_remaining -= 1
		unit_moved.emit(unit.get_unit_id(), from_star, target_star_id)
		_update_visibility()
		return true
	
	return false

## Atualizar visibilidade baseada nas entidades do jogador
func _update_visibility():
	if not fog_of_war:
		return
	
	# Atualizar fog of war baseado nas unidades e domínios deste jogador
	fog_of_war.update_visibility_for_player(domains, units)
	
	# Obter áreas visíveis
	visible_stars = fog_of_war.get_visible_stars(player_id)
	visible_diamonds = fog_of_war.get_visible_diamonds(player_id)
	
	visibility_changed.emit()

## Iniciar turno do jogador
func start_turn():
	is_active_turn = true
	actions_remaining = 1
	
	# Reset de ações das unidades
	for unit in units:
		unit.reset_actions()

## Finalizar turno do jogador
func end_turn():
	is_active_turn = false
	actions_remaining = 0

## Verificar se estrela é visível para este jogador
func is_star_visible(star_id: int) -> bool:
	if not fog_of_war or not fog_of_war.fog_enabled:
		return true
	return star_id in visible_stars

## Verificar se diamante é visível para este jogador
func is_diamond_visible(diamond_id: int) -> bool:
	if not fog_of_war or not fog_of_war.fog_enabled:
		return true
	return diamond_id in visible_diamonds

## Obter unidades visíveis (incluindo próprias e adversárias visíveis)
func get_visible_units(all_units: Array) -> Array:
	var visible_units = []
	
	for unit in all_units:
		# Sempre ver próprias unidades
		if unit in units:
			visible_units.append(unit)
		# Ver unidades adversárias apenas se estiverem em área visível
		elif is_star_visible(unit.get_current_star_id()):
			visible_units.append(unit)
	
	return visible_units

## Obter domínios visíveis (incluindo próprios e adversários visíveis)
func get_visible_domains(all_domains: Array) -> Array:
	var visible_domains = []
	
	for domain in all_domains:
		# Sempre ver próprios domínios
		if domain in domains:
			visible_domains.append(domain)
		# Ver domínios adversários apenas se estiverem em área visível
		elif is_star_visible(domain.get_center_star_id()):
			visible_domains.append(domain)
	
	return visible_domains

## Obter estatísticas do jogador
func get_stats() -> Dictionary:
	return {
		"player_id": player_id,
		"player_name": player_name,
		"team_color": team_color,
		"units_count": units.size(),
		"domains_count": domains.size(),
		"visible_stars_count": visible_stars.size(),
		"visible_diamonds_count": visible_diamonds.size(),
		"is_active_turn": is_active_turn,
		"actions_remaining": actions_remaining
	}

## Limpeza da instância
func cleanup():
	# Limpar unidades
	for unit in units:
		if is_instance_valid(unit):
			unit.cleanup()
	units.clear()
	
	# Limpar domínios
	for domain in domains:
		if is_instance_valid(domain):
			domain.cleanup()
	domains.clear()
	
	# Limpar fog of war
	if fog_of_war and is_instance_valid(fog_of_war):
		fog_of_war.cleanup()
		fog_of_war = null
	
	# Limpar referências
	shared_hex_grid = null
	shared_star_mapper = null
	visible_stars.clear()
	visible_diamonds.clear()