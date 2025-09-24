## GameConfig - Configurações centralizadas do jogo V&V
## Responsabilidade: Centralizar todas as configurações e constantes do jogo
##
## ✅ REFATORAÇÃO: Constantes extraídas do main_game.gd
## 🎯 Objetivo: Configuração centralizada e fácil manutenção

class_name GameConfig
extends RefCounted

## Configurações de mapa dinâmico
const DOMAIN_COUNT_TO_MAP_WIDTH = {
	6: 13,
	5: 11,
	4: 9,
	3: 7,
	2: 5
}

## Cores disponíveis para domínios/teams
const TEAM_COLORS = [
	Color(0, 0, 1),      # Azul RGB
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho RGB
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]

## Configurações de movimento
const MAX_ADJACENT_DISTANCE = 38.0
const CLICK_TOLERANCE = 30.0

## Configurações de zoom
const ZOOM_FACTOR = 1.3
const MIN_ZOOM = 0.3
const MAX_ZOOM = 5.0

## Configurações de domínios
const POSITION_TOLERANCE = 10.0
const MIN_DOMAIN_DISTANCE = 76.0

## Configurações de performance
const MAX_UNITS_PER_PLAYER = 50
const MAX_DOMAINS_PER_PLAYER = 20
const OBJECT_POOL_INITIAL_SIZE = 100

## Obter largura do mapa baseado no número de domínios
static func get_map_width(domain_count: int) -> int:
	return DOMAIN_COUNT_TO_MAP_WIDTH.get(domain_count, 13)

## Obter cor do team baseado no índice
static func get_team_color(team_index: int) -> Color:
	return TEAM_COLORS[team_index % TEAM_COLORS.size()]

## Obter zoom inicial baseado no número de domínios
static func get_initial_zoom(domain_count: int) -> float:
	var map_width = get_map_width(domain_count)
	
	if map_width <= 5:
		return 2.0
	elif map_width <= 7:
		return 1.6
	elif map_width <= 9:
		return 1.3
	elif map_width <= 11:
		return 1.1
	else:
		return 0.9

## Validar configurações do jogo
static func validate_domain_count(count: int) -> int:
	return clamp(count, 2, 6)

## Obter configurações de performance baseado no número de domínios
static func get_performance_settings(domain_count: int) -> Dictionary:
	var map_width = get_map_width(domain_count)
	
	return {
		"max_stars": map_width * map_width,
		"max_units": domain_count * 10,
		"max_domains": domain_count,
		"pool_size": max(100, domain_count * 20)
	}