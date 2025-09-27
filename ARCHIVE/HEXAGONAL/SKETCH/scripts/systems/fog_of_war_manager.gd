## FogOfWarManager - Gerenciador de Múltiplas Instâncias de Fog of War
## Coordena fog of war para todos os teams simultaneamente
## Gerencia ocultação/revelação de elementos adversários

class_name FogOfWarManager
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")
const FogOfWar = preload("res://scripts/systems/fog_of_war.gd")

## Sinais do gerenciador
signal team_visibility_updated(team_id: String)
signal enemy_visibility_changed(team_id: String, enemy_type: String, enemy_id: int, visible: bool)

## Estado do gerenciador
var team_fog_instances: Dictionary = {}  # team_id -> FogOfWar
var current_active_team: String = ""
var fog_enabled: bool = true

## Referências do sistema
var hex_grid_ref = null
var star_mapper_ref = null
var game_manager_ref = null
var turn_manager_ref = null

## Cache de visibilidade para performance
var visibility_cache: Dictionary = {}  # team_id -> visibility_data
var cache_dirty: bool = true

## Inicializar gerenciador
func initialize(hex_grid, star_mapper, game_manager, turn_manager = null) -> void:
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper
	game_manager_ref = game_manager
	turn_manager_ref = turn_manager
	
	team_fog_instances.clear()
	visibility_cache.clear()
	cache_dirty = true
	
	Logger.info("FogOfWarManager inicializado", "FogOfWarManager")

## Criar instância de fog of war para um team
func create_team_fog(team_id: String) -> void:
	if team_fog_instances.has(team_id):
		Logger.warning("Fog of war já existe para team %s" % team_id, "FogOfWarManager")
		return
	
	var fog_instance = FogOfWar.new()
	fog_instance.initialize(team_id, hex_grid_ref, star_mapper_ref, game_manager_ref)
	
	# Conectar sinais
	fog_instance.visibility_changed.connect(_on_team_visibility_changed)
	fog_instance.enemy_revealed.connect(_on_enemy_revealed)
	fog_instance.enemy_hidden.connect(_on_enemy_hidden)
	
	team_fog_instances[team_id] = fog_instance
	cache_dirty = true
	
	Logger.info("Fog of war criada para team %s" % team_id, "FogOfWarManager")

## Remover instância de fog of war de um team
func remove_team_fog(team_id: String) -> void:
	if not team_fog_instances.has(team_id):
		return
	
	var fog_instance = team_fog_instances[team_id]
	fog_instance.clear()
	team_fog_instances.erase(team_id)
	
	if visibility_cache.has(team_id):
		visibility_cache.erase(team_id)
	
	cache_dirty = true
	Logger.info("Fog of war removida para team %s" % team_id, "FogOfWarManager")

## Configurar teams baseado no TurnManager
func setup_teams_from_turn_manager() -> void:
	if not turn_manager_ref:
		Logger.warning("TurnManager não disponível para configurar teams", "FogOfWarManager")
		return
	
	var teams = turn_manager_ref.get_all_teams()
	for team in teams:
		var team_id = "team_" + str(team.id)
		create_team_fog(team_id)
	
	Logger.info("Teams configurados: %d instâncias de fog of war" % team_fog_instances.size(), "FogOfWarManager")

## Atualizar fog of war para todos os teams
func update_all_teams() -> void:
	if not fog_enabled:
		return
	
	if not turn_manager_ref:
		Logger.warning("TurnManager não disponível para atualizar fog of war", "FogOfWarManager")
		return
	
	var teams = turn_manager_ref.get_all_teams()
	for team in teams:
		var team_id = "team_" + str(team.id)
		if team_fog_instances.has(team_id):
			var fog_instance = team_fog_instances[team_id]
			fog_instance.update_visibility(team.units, team.domains)
	
	cache_dirty = true
	Logger.debug("Fog of war atualizada para todos os teams", "FogOfWarManager")

## Atualizar fog of war para um team específico
func update_team_fog(team_id: String) -> void:
	if not fog_enabled or not team_fog_instances.has(team_id):
		return
	
	if not turn_manager_ref:
		return
	
	var teams = turn_manager_ref.get_all_teams()
	for team in teams:
		var current_team_id = "team_" + str(team.id)
		if current_team_id == team_id:
			var fog_instance = team_fog_instances[team_id]
			fog_instance.update_visibility(team.units, team.domains)
			break
	
	cache_dirty = true

## Definir team ativo (para renderização)
func set_active_team(team_id: String) -> void:
	if current_active_team != team_id:
		current_active_team = team_id
		Logger.debug("Team ativo alterado para %s" % team_id, "FogOfWarManager")

## Verificar se estrela está visível para o team ativo
func is_star_visible_for_active_team(star_id: int) -> bool:
	if not fog_enabled or current_active_team.is_empty():
		return true
	
	if not team_fog_instances.has(current_active_team):
		return true
	
	return team_fog_instances[current_active_team].is_star_visible(star_id)

## Verificar se posição está visível para o team ativo
func is_position_visible_for_active_team(position: Vector2) -> bool:
	if not fog_enabled or current_active_team.is_empty():
		return true
	
	if not team_fog_instances.has(current_active_team):
		return true
	
	return team_fog_instances[current_active_team].is_hex_visible(position)

## Verificar se inimigo está revelado para o team ativo
func is_enemy_revealed_for_active_team(enemy_type: String, enemy_id: int) -> bool:
	if not fog_enabled or current_active_team.is_empty():
		return true
	
	if not team_fog_instances.has(current_active_team):
		return true
	
	return team_fog_instances[current_active_team].is_enemy_revealed(enemy_type, enemy_id)

## Verificar se unidade deve ser visível para o team ativo
func should_unit_be_visible(unit) -> bool:
	if not fog_enabled:
		return true
	
	# Unidades do próprio team sempre visíveis
	if _is_unit_from_active_team(unit):
		return true
	
	# Unidades inimigas só visíveis se reveladas
	return is_enemy_revealed_for_active_team("unit", unit.unit_id)

## Verificar se domínio deve ser visível para o team ativo
func should_domain_be_visible(domain) -> bool:
	if not fog_enabled:
		return true
	
	# Domínios do próprio team sempre visíveis
	if _is_domain_from_active_team(domain):
		return true
	
	# Domínios inimigos só visíveis se revelados
	return is_enemy_revealed_for_active_team("domain", domain.get_domain_id())

## Verificar se unidade pertence ao team ativo
func _is_unit_from_active_team(unit) -> bool:
	if not turn_manager_ref or current_active_team.is_empty():
		return true
	
	var current_team = turn_manager_ref.get_current_team()
	if current_team.is_empty():
		return true
	
	return unit in current_team.units

## Verificar se domínio pertence ao team ativo
func _is_domain_from_active_team(domain) -> bool:
	if not turn_manager_ref or current_active_team.is_empty():
		return true
	
	var current_team = turn_manager_ref.get_current_team()
	if current_team.is_empty():
		return true
	
	return domain in current_team.domains

## Ativar/desativar fog of war
func set_fog_enabled(enabled: bool) -> void:
	if fog_enabled != enabled:
		fog_enabled = enabled
		cache_dirty = true
		Logger.info("Fog of war %s" % ("ativada" if enabled else "desativada"), "FogOfWarManager")

## Obter estatísticas de todos os teams
func get_all_stats() -> Dictionary:
	var stats = {
		"fog_enabled": fog_enabled,
		"active_team": current_active_team,
		"total_teams": team_fog_instances.size(),
		"teams": {}
	}
	
	for team_id in team_fog_instances.keys():
		stats.teams[team_id] = team_fog_instances[team_id].get_stats()
	
	return stats

## Imprimir relatório de fog of war
func print_fog_report() -> void:
	print("\n🌫️ === RELATÓRIO DE FOG OF WAR ===")
	print("📊 Status: %s" % ("Ativada" if fog_enabled else "Desativada"))
	print("👥 Team ativo: %s" % current_active_team)
	print("🎯 Teams configurados: %d" % team_fog_instances.size())
	
	if fog_enabled:
		for team_id in team_fog_instances.keys():
			var stats = team_fog_instances[team_id].get_stats()
			var active_marker = " (ATIVO)" if team_id == current_active_team else ""
			print("\n🏴 %s%s:" % [team_id, active_marker])
			print("   👁️ Estrelas visíveis: %d" % stats.visible_stars)
			print("   🔷 Hexágonos visíveis: %d" % stats.visible_hexes)
			print("   👤 Unidades inimigas reveladas: %d" % stats.enemy_units)
			print("   🏰 Domínios inimigos revelados: %d" % stats.enemy_domains)
	
	print("=== FIM DO RELATÓRIO DE FOG OF WAR ===\n")

## Callbacks de sinais
func _on_team_visibility_changed(team_id: String, visible_positions: Array) -> void:
	if visibility_cache.has(team_id):
		visibility_cache[team_id] = visible_positions
	cache_dirty = true
	team_visibility_updated.emit(team_id)

func _on_enemy_revealed(team_id: String, enemy_type: String, enemy_id: int) -> void:
	enemy_visibility_changed.emit(team_id, enemy_type, enemy_id, true)
	Logger.debug("Inimigo revelado para %s: %s %d" % [team_id, enemy_type, enemy_id], "FogOfWarManager")

func _on_enemy_hidden(team_id: String, enemy_type: String, enemy_id: int) -> void:
	enemy_visibility_changed.emit(team_id, enemy_type, enemy_id, false)
	Logger.debug("Inimigo ocultado para %s: %s %d" % [team_id, enemy_type, enemy_id], "FogOfWarManager")

## Limpar todas as instâncias
func cleanup() -> void:
	for fog_instance in team_fog_instances.values():
		fog_instance.clear()
	
	team_fog_instances.clear()
	visibility_cache.clear()
	current_active_team = ""
	
	Logger.info("FogOfWarManager limpo", "FogOfWarManager")