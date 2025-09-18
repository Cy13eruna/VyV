## TerrainSystem - Sistema de validação de terreno
## Centraliza lógica de terreno e movimento

class_name TerrainSystem
extends RefCounted

## Configuração
var config: GameConfig
var hex_grid_ref
var cache_ref

## Tipos de terreno
enum TerrainType {
	FIELD,      # Campo (livre)
	FOREST,     # Floresta (livre)
	WATER,      # Água (bloqueado)
	MOUNTAIN    # Montanha (bloqueado)
}

## Inicializar sistema
func _init(game_config: GameConfig = null):
	config = game_config if game_config else GameConfig.get_instance()

## Configurar referências
func setup_references(hex_grid, cache) -> void:
	hex_grid_ref = hex_grid
	cache_ref = cache

## Verificar se movimento é bloqueado por terreno
func is_movement_blocked(from_star_id: int, to_star_id: int) -> bool:
	var terrain_type = get_terrain_between_stars(from_star_id, to_star_id)
	return terrain_type == TerrainType.WATER or terrain_type == TerrainType.MOUNTAIN

## Obter tipo de terreno entre duas estrelas
func get_terrain_between_stars(from_star_id: int, to_star_id: int) -> TerrainType:
	var terrain_color = _get_terrain_color_between_stars(from_star_id, to_star_id)
	return _color_to_terrain_type(terrain_color)

## Verificar se posição é válida para spawn
func is_valid_spawn_position(star_id: int) -> bool:
	# Implementar lógica de validação de spawn
	return star_id >= 0

## Obter cor do terreno entre estrelas
func _get_terrain_color_between_stars(from_star_id: int, to_star_id: int) -> Color:
	if not hex_grid_ref or not cache_ref:
		return config.field_color
	
	var diamond_colors = cache_ref.get_diamond_colors()
	var connections = cache_ref.get_connections()
	
	# Procurar conexão específica
	for i in range(connections.size()):
		var connection = connections[i]
		if (connection.index_a == from_star_id and connection.index_b == to_star_id) or \
		   (connection.index_a == to_star_id and connection.index_b == from_star_id):
			if i < diamond_colors.size():
				return diamond_colors[i]
	
	return config.field_color

## Converter cor para tipo de terreno
func _color_to_terrain_type(color: Color) -> TerrainType:
	if color.is_equal_approx(config.water_color):
		return TerrainType.WATER
	elif color.is_equal_approx(config.mountain_color):
		return TerrainType.MOUNTAIN
	else:
		return TerrainType.FIELD

## Obter nome do tipo de terreno
func get_terrain_name(terrain_type: TerrainType) -> String:
	match terrain_type:
		TerrainType.FIELD: return "Campo"
		TerrainType.FOREST: return "Floresta"
		TerrainType.WATER: return "Água"
		TerrainType.MOUNTAIN: return "Montanha"
		_: return "Desconhecido"