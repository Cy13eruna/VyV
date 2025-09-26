## SimpleFogOfWar - Implementação Simples de Fog of War
## Apenas domínios fornecem visibilidade: 7 estrelas + 12 losangos
## Cada team tem sua própria fog of war

class_name SimpleFogOfWar
extends RefCounted

## Verificar se estrela é visível baseado nos domínios
static func is_star_visible(star_id: int, domains: Array, dot_positions: Array) -> bool:
	if star_id >= dot_positions.size():
		return false
	
	var star_pos = dot_positions[star_id]
	
	# Debug: log primeira verificação
	if star_id == 0:
		print("🔍 FOG DEBUG: Verificando visibilidade de %d estrelas com %d domínios" % [dot_positions.size(), domains.size()])
	
	# Verificar se a estrela está dentro da visibilidade de algum domínio
	for domain in domains:
		if _is_star_in_domain_visibility(star_pos, domain, dot_positions):
			return true
	
	return false

## Verificar se hexágono é visível baseado nos domínios
static func is_hex_visible(hex_pos: Vector2, domains: Array) -> bool:
	# Verificar se o hex está dentro da visibilidade de algum domínio
	for domain in domains:
		if _is_hex_in_domain_visibility(hex_pos, domain):
			return true
	
	return false

## Verificar se estrela está na visibilidade do domínio (7 estrelas)
static func _is_star_in_domain_visibility(star_pos: Vector2, domain, dot_positions: Array) -> bool:
	# Obter posição central do domínio
	var domain_center_id = domain.get_center_star_id()
	
	if domain_center_id < 0 or domain_center_id >= dot_positions.size():
		return false
	
	var domain_center = dot_positions[domain_center_id]
	
	# Verificar se é a estrela central
	if star_pos.distance_to(domain_center) < 5.0:
		return true
	
	# Verificar se é uma das 6 estrelas adjacentes
	var distance = star_pos.distance_to(domain_center)
	var is_visible = distance <= 40.0  # Distância de adjacência
	
	# Debug: log algumas verificações
	if domain_center_id == 0 and distance <= 50.0:  # Log apenas para o primeiro domínio e estrelas próximas
		print("🔍 Estrela dist=%.1f do centro domínio %d: %s" % [distance, domain_center_id, "VISÍVEL" if is_visible else "OCULTA"])
	
	return is_visible

## Verificar se hex está na visibilidade do domínio (12 losangos)
static func _is_hex_in_domain_visibility(hex_pos: Vector2, domain) -> bool:
	# Obter vértices do domínio (12 losangos)
	var domain_vertices = domain.get_vertices()
	
	# Debug: log primeira verificação
	if domain.get_center_star_id() == 0:  # Log apenas para o primeiro domínio
		print("🔍 Domínio %d tem %d vértices" % [domain.get_center_star_id(), domain_vertices.size()])
	
	# Verificar se o hex é um dos vértices do domínio
	for vertex in domain_vertices:
		if hex_pos.distance_to(vertex) < 15.0:  # Tolerância para posição
			return true
	
	return false