## SharedGameState - Versão Ultra-Limpa
## Estado compartilhado sem logs desnecessários

class_name SharedGameStateClean
extends RefCounted

## Componentes compartilhados
var hex_grid = null
var star_mapper = null
var parent_node = null

## Regras globais
var movement_rules: Dictionary = {
	"max_distance": 38.0,
	"blocked_terrains": [Color(0.0, 1.0, 1.0), Color(0.4, 0.4, 0.4)],  # Água e montanha
	"allow_diagonal": true
}

## Configurações do mapa
var map_config: Dictionary = {
	"domain_count_to_width": {
		6: 13, 5: 11, 4: 9, 3: 7, 2: 5
	}
}

## Sistema de turnos global
var turn_manager: TurnManager

## Inicializar estado compartilhado
func _init():
	turn_manager = TurnManager.new()

## Configurar componentes compartilhados
func setup(grid, mapper, node):
	hex_grid = grid
	star_mapper = mapper
	parent_node = node

## Verificar se movimento é válido globalmente
func is_movement_valid(from_star_id: int, to_star_id: int) -> bool:
	if not hex_grid or not hex_grid.cache:
		return false
	
	var dot_positions = hex_grid.get_dot_positions()
	if from_star_id >= dot_positions.size() or to_star_id >= dot_positions.size():
		return false
	
	var from_pos = dot_positions[from_star_id]
	var to_pos = dot_positions[to_star_id]
	var distance = from_pos.distance_to(to_pos)
	
	# Verificar distância máxima
	if distance > movement_rules.max_distance:
		return false
	
	# Verificar terreno bloqueado
	var terrain_color = _get_terrain_between_stars(from_star_id, to_star_id)
	if terrain_color in movement_rules.blocked_terrains:
		return false
	
	return true

## Obter cor do terreno entre duas estrelas
func _get_terrain_between_stars(from_star_id: int, to_star_id: int) -> Color:
	if not hex_grid or not hex_grid.cache:
		return Color.WHITE
	
	var diamond_colors = hex_grid.cache.get_diamond_colors()
	var connections = hex_grid.cache.get_connections()
	
	# Procurar pela conexão específica
	for i in range(connections.size()):
		var connection = connections[i]
		if (connection.index_a == from_star_id and connection.index_b == to_star_id) or \
		   (connection.index_a == to_star_id and connection.index_b == from_star_id):
			if i < diamond_colors.size():
				return diamond_colors[i]
	
	# Terreno livre por padrão
	return Color(0.0, 1.0, 0.0, 1.0)  # Verde claro

## Obter estrelas adjacentes a uma posição
func get_adjacent_stars(star_id: int) -> Array[int]:
	if not hex_grid:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	if star_id >= dot_positions.size():
		return []
	
	var star_pos = dot_positions[star_id]
	var adjacent_stars: Array[int] = []
	
	for i in range(dot_positions.size()):
		if i == star_id:
			continue
		
		var distance = star_pos.distance_to(dot_positions[i])
		if distance <= movement_rules.max_distance and distance > 5.0:
			adjacent_stars.append(i)
	
	return adjacent_stars

## Verificar se uma estrela está ocupada
func is_star_occupied(star_id: int, all_units: Array) -> bool:
	for unit in all_units:
		if unit.get_current_star_id() == star_id:
			return true
	return false

## Obter largura do mapa baseada na quantidade de domínios
func get_map_width_for_domains(domain_count: int) -> int:
	return map_config.domain_count_to_width.get(domain_count, 7)

## Calcular centro do tabuleiro
func get_board_center() -> Vector2:
	if not hex_grid:
		return Vector2.ZERO
	
	var dot_positions = hex_grid.get_dot_positions()
	if dot_positions.size() == 0:
		return Vector2.ZERO
	
	var center = Vector2.ZERO
	for pos in dot_positions:
		center += pos
	center /= dot_positions.size()
	
	return center

## Encontrar estrelas mais distantes do centro
func find_farthest_stars(count: int) -> Array:
	if not hex_grid:
		return []
	
	var dot_positions = hex_grid.get_dot_positions()
	var center = get_board_center()
	
	var star_distances = []
	for i in range(dot_positions.size()):
		var distance = center.distance_to(dot_positions[i])
		star_distances.append({"id": i, "distance": distance, "pos": dot_positions[i]})
	
	star_distances.sort_custom(func(a, b): return a.distance > b.distance)
	return star_distances.slice(0, min(count, star_distances.size()))

## Limpeza do estado compartilhado
func cleanup():
	if turn_manager and is_instance_valid(turn_manager):
		turn_manager.cleanup()
		turn_manager = null
	
	hex_grid = null
	star_mapper = null
	parent_node = null

## TurnManager - Gerenciador de Turnos Simples
class TurnManager:
	var current_turn: int = 1
	var current_player: int = 1
	var total_players: int = 0
	
	func setup(player_count: int):
		total_players = player_count
		current_turn = 1
		current_player = 1
	
	func next_turn():
		current_player += 1
		if current_player > total_players:
			current_player = 1
			current_turn += 1
	
	func get_current_player() -> int:
		return current_player
	
	func get_current_turn() -> int:
		return current_turn
	
	func cleanup():
		pass