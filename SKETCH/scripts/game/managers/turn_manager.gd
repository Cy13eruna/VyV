## TurnManager - Sistema de Gerenciamento de Turnos
## Extraído do main_game.gd para seguir princípios SOLID
## Responsabilidade única: Gerenciar turnos e teams

class_name TurnManager
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Sinais do sistema de turnos
signal turn_started(team_index: int, turn_number: int)
signal turn_ended(team_index: int, turn_number: int)
signal team_changed(old_team_index: int, new_team_index: int)
signal game_started()
signal game_ended()

## Estado do sistema de turnos
var teams: Array = []
var current_team_index: int = 0
var current_turn: int = 1
var game_started_flag: bool = false

## Cores e nomes disponíveis para teams
var team_colors: Array[Color] = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]
var team_names: Array[String] = ["Azul", "Laranja", "Vermelho", "Roxo", "Amarelo", "Ciano"]

## Inicializar sistema de turnos
func initialize() -> void:
	teams.clear()
	current_team_index = 0
	current_turn = 1
	game_started_flag = false
	Logger.info("Sistema de turnos inicializado", "TurnManager")

## Configurar teams baseado em unidades e domínios
func setup_teams(all_units: Array, all_domains: Array) -> void:
	teams.clear()
	
	# Agrupar por cores das unidades
	var color_groups = {}
	
	for unit in all_units:
		if not unit.visual_node:
			continue
			
		var unit_color = unit.visual_node.modulate
		# Verificar se a cor não é branca (cor padrão)
		if unit_color == Color.WHITE or unit_color.a < 0.5:
			continue
			
		var color_key = _color_to_key(unit_color)
		
		if not color_groups.has(color_key):
			color_groups[color_key] = {
				"color": unit_color,
				"units": [],
				"domains": []
			}
		
		color_groups[color_key].units.append(unit)
		Logger.debug("Unidade adicionada ao grupo %s" % color_key, "TurnManager")
	
	# Associar domínios aos grupos de cor
	for domain in all_domains:
		var domain_color = domain.line_color
		var color_key = _color_to_key(domain_color)
		
		if color_groups.has(color_key):
			color_groups[color_key].domains.append(domain)
	
	# Criar teams baseado nos grupos de cor
	var team_index = 0
	for color_key in color_groups.keys():
		var group = color_groups[color_key]
		var team_name = team_names[team_index] if team_index < team_names.size() else "Team " + str(team_index + 1)
		
		var new_team = {
			"id": team_index,
			"name": team_name,
			"color": group.color,
			"domains": group.domains,
			"units": group.units,
			"is_active": false
		}
		teams.append(new_team)
		team_index += 1
	
	Logger.info("Teams criados: %d" % teams.size(), "TurnManager")
	for team in teams:
		Logger.debug("Team %s: %d unidades, %d domínios" % [team.name, team.units.size(), team.domains.size()], "TurnManager")

## Iniciar primeiro turno
func start_game() -> void:
	if teams.size() == 0:
		Logger.error("Não é possível iniciar jogo sem teams", "TurnManager")
		return
	
	current_team_index = 0
	current_turn = 1
	game_started_flag = true
	
	_activate_team_turn(current_team_index)
	game_started.emit()
	Logger.info("Jogo iniciado - Primeiro turno", "TurnManager")

## Avançar para próximo turno
func next_turn() -> void:
	if not game_started_flag or teams.size() == 0:
		Logger.warning("Tentativa de avançar turno sem jogo ativo", "TurnManager")
		return
	
	var old_team_index = current_team_index
	
	# Finalizar turno atual
	turn_ended.emit(current_team_index, current_turn)
	
	# Avançar para próximo team
	current_team_index = (current_team_index + 1) % teams.size()
	
	# Se voltou ao primeiro team, incrementar turno
	if current_team_index == 0:
		current_turn += 1
	
	# Ativar próximo team
	_activate_team_turn(current_team_index)
	
	# Emitir sinais
	team_changed.emit(old_team_index, current_team_index)
	turn_started.emit(current_team_index, current_turn)
	
	Logger.info("Turno %d - Team %s ativo" % [current_turn, get_current_team().name], "TurnManager")

## Ativar turno de um team específico
func _activate_team_turn(team_index: int) -> void:
	# Desativar todos os teams
	for team in teams:
		team.is_active = false
	
	# Ativar team atual
	if team_index < teams.size():
		var active_team = teams[team_index]
		active_team.is_active = true
		
		# Reset de ações das unidades do team
		for unit in active_team.units:
			unit.reset_actions()

## Verificar se unidade pertence ao team atual
func is_unit_from_current_team(unit) -> bool:
	if teams.size() == 0:
		return false
	
	var current_team = teams[current_team_index]
	return unit in current_team.units

## Verificar se unidade pode agir
func can_unit_act(unit) -> bool:
	if teams.size() == 0:
		return false
	
	var current_team = teams[current_team_index]
	if not current_team.is_active:
		return false
	
	# Verificar se unidade pertence ao team atual e tem ações
	return unit in current_team.units and unit.actions_remaining > 0

## Obter team atual
func get_current_team() -> Dictionary:
	if teams.size() == 0 or current_team_index >= teams.size():
		return {}
	return teams[current_team_index]

## Obter todos os teams
func get_all_teams() -> Array:
	return teams.duplicate()

## Obter informações do turno atual
func get_turn_info() -> Dictionary:
	return {
		"current_turn": current_turn,
		"current_team_index": current_team_index,
		"current_team": get_current_team(),
		"total_teams": teams.size(),
		"game_started": game_started_flag
	}

## Finalizar jogo
func end_game() -> void:
	game_started_flag = false
	game_ended.emit()
	Logger.info("Jogo finalizado", "TurnManager")

## Converter cor para chave string
func _color_to_key(color: Color) -> String:
	return "%.2f_%.2f_%.2f" % [color.r, color.g, color.b]

## Comparar cores (com tolerância para pequenas diferenças)
func _colors_are_equal(color1: Color, color2: Color, tolerance: float = 0.1) -> bool:
	return (
		abs(color1.r - color2.r) < tolerance and
		abs(color1.g - color2.g) < tolerance and
		abs(color1.b - color2.b) < tolerance
	)