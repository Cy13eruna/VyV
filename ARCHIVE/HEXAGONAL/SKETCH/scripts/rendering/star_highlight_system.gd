## StarHighlightSystem - Sistema de Destaque de Estrelas
## Usa sistema de locomocao existente para destacar estrelas adjacentes

class_name StarHighlightSystem
extends RefCounted

# Referências
var hex_grid_ref = null
var game_manager_ref = null

# Estado do highlight
var highlighted_stars: Array[int] = []
var highlight_color: Color = Color.YELLOW
var highlight_radius_multiplier: float = 1.2  # Reduzido para círculos menores
var current_midpoint: Vector2 = Vector2.ZERO
var current_midpoint_id: String = ""
var has_midpoint_highlight: bool = false

# Unidade virtual para usar sistema de locomocao
var virtual_unit = null

# Sinais
signal stars_highlighted(star_ids: Array)
signal stars_unhighlighted()

## Inicializar sistema
func _init():
	pass

## Configurar referências
func setup_references(hex_grid, game_manager) -> void:
	hex_grid_ref = hex_grid
	game_manager_ref = game_manager
	
	# Criar unidade virtual para usar sistema de locomocao
	_create_virtual_unit()

## SISTEMA DE DETECÇÃO DE LOSANGO: mouse_on_diamond_detection
## Detecta quando o mouse está sobre um losango e destaca seu centro
func process_mouse_movement(mouse_position: Vector2) -> void:
	if not hex_grid_ref:
		return
	
	# Detectar as duas estrelas mais próximas do cursor
	var two_nearest_stars = _get_two_nearest_stars_under_cursor()
	if two_nearest_stars.size() < 2:
		# Não há duas estrelas, remover highlight
		if has_midpoint_highlight:
			_unhighlight_stars()
		return
	
	# Calcular ponto médio entre as duas estrelas
	var star_a_pos = two_nearest_stars[0].position
	var star_b_pos = two_nearest_stars[1].position
	var midpoint = (star_a_pos + star_b_pos) / 2.0
	
	print("✨ HOVER: Ponto médio entre estrelas %d e %d em %s" % [two_nearest_stars[0].star_id, two_nearest_stars[1].star_id, str(midpoint)])
	
	# Definir ponto médio e forçar redesenho
	current_midpoint = midpoint
	has_midpoint_highlight = true
	highlighted_stars.clear()  # Limpar estrelas destacadas
	
	# Forçar redesenho
	if hex_grid_ref:
		hex_grid_ref.redraw_grid()

## Adicionar estrela virtual no ponto médio
func _add_virtual_star_at_midpoint(midpoint_pos: Vector2) -> void:
	# Adicionar posição virtual ao hex_grid temporariamente
	if hex_grid_ref and hex_grid_ref.has_method("add_virtual_dot"):
		hex_grid_ref.add_virtual_dot(-1, midpoint_pos)
	else:
		# Fallback: armazenar localmente
		current_midpoint = midpoint_pos
		has_midpoint_highlight = true

## Destacar ponto médio
func _highlight_midpoint(midpoint_pos: Vector2, midpoint_id: String) -> void:
	# Limpar highlights anteriores
	_unhighlight_stars()
	
	# Definir novo ponto médio
	current_midpoint = midpoint_pos
	current_midpoint_id = midpoint_id
	has_midpoint_highlight = true
	
	# Solicitar redesenho
	if hex_grid_ref:
		hex_grid_ref.redraw_grid()

## Destacar estrelas específicas
func _highlight_stars(star_ids: Array, diamond_id: String) -> void:
	highlighted_stars.clear()
	for star_id in star_ids:
		highlighted_stars.append(star_id as int)
	
	# Emitir sinal para que outros sistemas possam reagir
	stars_highlighted.emit(star_ids)
	
	# Forçar redesenho do grid para mostrar highlight
	if hex_grid_ref:
		hex_grid_ref.redraw_grid()

## Remover highlight de todas as estrelas e midpoint
func _unhighlight_stars() -> void:
	highlighted_stars.clear()
	has_midpoint_highlight = false
	current_midpoint = Vector2.ZERO
	current_midpoint_id = ""
	if hex_grid_ref:
		hex_grid_ref.redraw_grid()

## Verificar se uma estrela está destacada
func is_star_highlighted(star_id: int) -> bool:
	return star_id in highlighted_stars

## Obter cor de highlight para uma estrela
func get_highlight_color_for_star(star_id: int) -> Color:
	if is_star_highlighted(star_id):
		return highlight_color
	return Color.WHITE  # Cor padrão

## Obter raio de highlight para uma estrela
func get_highlight_radius_for_star(star_id: int, base_radius: float) -> float:
	if is_star_highlighted(star_id):
		return base_radius * highlight_radius_multiplier
	return base_radius

## Obter estrelas destacadas
func get_highlighted_stars() -> Array[int]:
	return highlighted_stars.duplicate()

## Obter ponto médio atual
func get_current_midpoint() -> Dictionary:
	if has_midpoint_highlight:
		return {
			"position": current_midpoint,
			"id": current_midpoint_id,
			"active": true
		}
	else:
		return {"active": false}

## Definir cor de highlight
func set_highlight_color(color: Color) -> void:
	highlight_color = color

## Definir multiplicador de raio
func set_highlight_radius_multiplier(multiplier: float) -> void:
	highlight_radius_multiplier = multiplier

## Criar unidade virtual para usar sistema de locomocao
func _create_virtual_unit() -> void:
	# Criar classe simples que simula uma unidade
	virtual_unit = VirtualUnit.new()
	
	print("🤖 Unidade virtual criada para sistema de locomocao")

# Classe interna para simular uma unidade
class VirtualUnit:
	var current_star_id: int = -1
	var actions_remaining: int = 1
	var origin_domain_id: int = -1
	
	func get_current_star_id() -> int:
		return current_star_id
	
	func can_act() -> bool:
		return true
	
	func get_origin_domain_for_power_check() -> int:
		return -1

## Obter as duas estrelas mais próximas do cursor
func _get_two_nearest_stars_under_cursor() -> Array:
	if not hex_grid_ref:
		return []
	
	var mouse_pos = hex_grid_ref.get_global_mouse_position()
	var hex_grid_pos = hex_grid_ref.to_local(mouse_pos)
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	# Criar array de estrelas com distâncias e posições
	var star_distances = []
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = hex_grid_pos.distance_to(star_pos)
		star_distances.append({
			"star_id": i, 
			"distance": distance,
			"position": star_pos
		})
	
	# Ordenar por distância (mais próxima primeiro)
	star_distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Retornar as duas mais próximas (se existirem)
	var result = []
	if star_distances.size() >= 1:
		result.append(star_distances[0])  # Primeira mais próxima
	if star_distances.size() >= 2:
		result.append(star_distances[1])  # Segunda mais próxima
	
	return result

## Verificar se dois arrays são iguais
func _arrays_equal(array1: Array[int], array2: Array) -> bool:
	if array1.size() != array2.size():
		return false
	
	for i in range(array1.size()):
		if array1[i] != (array2[i] as int):
			return false
	
	return true

## Obter informações de debug
func get_debug_info() -> Dictionary:
	return {
		"highlighted_stars": highlighted_stars,
		"highlight_color": highlight_color,
		"highlight_radius_multiplier": highlight_radius_multiplier,
		"has_references": hex_grid_ref != null and game_manager_ref != null
	}