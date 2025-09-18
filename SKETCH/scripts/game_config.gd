## GameConfig - Configuração Centralizada do Jogo V&V
## Centraliza todos os valores configuráveis do jogo

class_name GameConfig
extends Resource

## Configurações de Movimento
@export_group("Movement")
@export var max_adjacent_distance: float = 38.0
@export var click_tolerance: float = 30.0
@export var movement_validation_enabled: bool = true

## Configurações Visuais
@export_group("Visual")
@export var unit_font_size: int = 14
@export var unit_offset_x: float = 0.5
@export var unit_offset_y: float = 1.1
@export var star_highlight_size: float = 6.0
@export var star_inner_radius: float = 3.0

## Configurações de Domínio
@export_group("Domain")
@export var domain_line_width: float = 2.0
@export var domain_dash_length: float = 8.0
@export var domain_gap_length: float = 4.0
@export var domain_position_tolerance: float = 10.0

## Configurações de Jogo
@export_group("Game Rules")
@export var max_units_per_player: int = 10
@export var max_domains_per_player: int = 5
@export var max_actions_per_turn: int = 1

## Configurações de Terreno
@export_group("Terrain")
@export var water_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var mountain_color: Color = Color(0.4, 0.4, 0.4, 1.0)
@export var field_color: Color = Color(0.0, 1.0, 0.0, 1.0)

## Singleton instance
static var instance: GameConfig

## Get singleton instance
static func get_instance() -> GameConfig:
	if not instance:
		instance = GameConfig.new()
	return instance

## Validate configuration values
func validate() -> bool:
	return max_adjacent_distance > 0 and click_tolerance > 0 and unit_font_size > 0