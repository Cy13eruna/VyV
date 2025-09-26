## FogOfWarSimple - Implementação Direta e Simples
## Conforme especificação: apenas áreas dos domínios são visíveis
## 7 estrelas + 12 losangos por domínio

class_name FogOfWarSimple
extends RefCounted

## Verificar se uma estrela deve ser renderizada
static func should_render_star(star_id: int, star_positions: Array, domains: Array) -> bool:
	if domains.is_empty():
		return true  # Se não há domínios, renderizar tudo
	
	if star_id >= star_positions.size():
		return false
	
	var star_pos = star_positions[star_id]
	
	# Verificar se a estrela está dentro da área de algum domínio
	for domain in domains:
		if _is_star_in_domain_area(star_pos, domain, star_positions):
			return true
	
	return false

## Verificar se um hexágono deve ser renderizado
static func should_render_hex(hex_pos: Vector2, domains: Array) -> bool:
	if domains.is_empty():
		return true  # Se não há domínios, renderizar tudo
	
	# Verificar se o hex está dentro da área de algum domínio
	for domain in domains:
		if _is_hex_in_domain_area(hex_pos, domain):
			return true
	
	return false

## Verificar se estrela está na área do domínio (7 estrelas: 1 central + 6 adjacentes)
static func _is_star_in_domain_area(star_pos: Vector2, domain, star_positions: Array) -> bool:
	var center_star_id = domain.get_center_star_id()
	
	if center_star_id < 0 or center_star_id >= star_positions.size():
		return false
	
	var domain_center = star_positions[center_star_id]
	var distance = star_pos.distance_to(domain_center)
	
	# Estrela central (distância muito pequena)
	if distance < 5.0:
		return true
	
	# Estrelas adjacentes (distância até 40 unidades)
	return distance <= 40.0

## Verificar se hex está na área do domínio (12 losangos: vértices do hexágono)
static func _is_hex_in_domain_area(hex_pos: Vector2, domain) -> bool:
	var domain_vertices = domain.get_vertices()
	
	# Verificar se o hex está próximo de algum vértice do domínio
	for vertex in domain_vertices:
		if hex_pos.distance_to(vertex) < 20.0:  # Tolerância aumentada
			return true
	
	# Também verificar se está próximo do centro do domínio
	var center_pos = domain.get_center_position()
	if hex_pos.distance_to(center_pos) < 25.0:
		return true
	
	return false

## Debug: contar elementos visíveis
static func count_visible_elements(star_positions: Array, hex_positions: Array, domains: Array) -> Dictionary:
	var visible_stars = 0
	var visible_hexs = 0
	
	for i in range(star_positions.size()):
		if should_render_star(i, star_positions, domains):
			visible_stars += 1
	
	for hex_pos in hex_positions:
		if should_render_hex(hex_pos, domains):
			visible_hexs += 1
	
	return {
		"visible_stars": visible_stars,
		"total_stars": star_positions.size(),
		"visible_hexs": visible_hexs,
		"total_hexs": hex_positions.size(),
		"domains": domains.size()
	}