## GameConfig - Configurações centralizadas do jogo V&V
## Responsabilidade: Centralizar todas as configurações e constantes do jogo
##
## ✅ REFATORAÇÃO: Constantes extraídas do main_game.gd
## 🎯 Objetivo: Configuração centralizada e fácil manutenção

class_name GameConfig
extends RefCounted

# Importar sistema de configuração
const Config = preload("res://scripts/core/config.gd")

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

## Obter configurações de movimento
static func get_max_adjacent_distance() -> float:
	return Config.get_setting("game", "max_adjacent_distance", 38.0)

static func get_click_tolerance() -> float:
	return Config.get_setting("game", "click_tolerance", 30.0)

## Obter configurações de zoom
static func get_zoom_factor() -> float:
	return Config.get_setting("render", "zoom_factor", 1.3)

static func get_min_zoom() -> float:
	return Config.get_setting("render", "min_zoom", 0.3)

static func get_max_zoom() -> float:
	return Config.get_setting("render", "max_zoom", 5.0)

## Obter configurações de domínios
static func get_position_tolerance() -> float:
	return Config.get_setting("game", "position_tolerance", 10.0)

static func get_min_domain_distance() -> float:
	return Config.get_setting("game", "min_domain_distance", 76.0)

## Obter configurações de performance
static func get_max_units_per_player() -> int:
	return Config.get_setting("game", "max_units_per_player", 50)

static func get_max_domains_per_player() -> int:
	return Config.get_setting("game", "max_domains_per_player", 20)

static func get_object_pool_initial_size() -> int:
	return Config.get_setting("performance", "object_pool_initial_size", 100)

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