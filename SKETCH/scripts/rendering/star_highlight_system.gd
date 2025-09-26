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
var highlight_radius_multiplier: float = 1.5

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

## Processar movimento do mouse para destacar estrela sob cursor
func process_mouse_movement(mouse_position: Vector2) -> void:
	if not hex_grid_ref:
		return
	
	# SIMPLES: Detectar apenas a estrela sob o cursor
	var nearest_star_data = _get_nearest_star_under_cursor()
	if nearest_star_data.star_id == -1:
		# Não há estrela sob o cursor, remover highlight
		if not highlighted_stars.is_empty():
			_unhighlight_stars()
		return
	
	# Destacar apenas a estrela sob o mouse
	var stars_to_highlight = [nearest_star_data.star_id]
	
	print("✨ HOVER: Estrela %d sob o mouse" % nearest_star_data.star_id)
	
	# Se mudou o highlight, atualizar
	if not _arrays_equal(highlighted_stars, stars_to_highlight):
		_highlight_stars(stars_to_highlight, "star_%d" % nearest_star_data.star_id)

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

## Remover highlight das estrelas
func _unhighlight_stars() -> void:
	if highlighted_stars.is_empty():
		return
	
	highlighted_stars.clear()
	
	# Emitir sinal
	stars_unhighlighted.emit()
	
	# Forçar redesenho do grid
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

## Obter estrelas atualmente destacadas
func get_highlighted_stars() -> Array[int]:
	return highlighted_stars.duplicate()

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

## Obter estrela mais próxima sob o cursor (baseado em star_click_demo.gd)
func _get_nearest_star_under_cursor() -> Dictionary:
	if not hex_grid_ref:
		return {"star_id": -1}
	
	var mouse_pos = hex_grid_ref.get_global_mouse_position()
	var hex_grid_pos = hex_grid_ref.to_local(mouse_pos)
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	var closest_star = -1
	var closest_distance = 999999.0
	var max_distance = 30.0  # Tolerância para detectar estrela
	
	for i in range(dot_positions.size()):
		var star_pos = dot_positions[i]
		var distance = hex_grid_pos.distance_to(star_pos)
		
		if distance < closest_distance and distance <= max_distance:
			closest_distance = distance
			closest_star = i
	
	return {"star_id": closest_star, "distance": closest_distance}

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