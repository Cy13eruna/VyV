## DomainElementsRegistry - Registro de Elementos dos Domínios
## Registra especificamente quais estrelas e losangos pertencem a cada domínio

class_name DomainElementsRegistry
extends RefCounted

## Registros de elementos por domínio
var domain_stars: Dictionary = {}  # domain_id -> Array[int] (star_ids)
var domain_hexs: Dictionary = {}   # domain_id -> Array[int] (hex_ids)

## Listas consolidadas de elementos visíveis
var visible_star_ids: Array[int] = []
var visible_hex_ids: Array[int] = []

## Registrar elementos de um domínio
func register_domain_elements(domain_id: int, star_ids: Array[int], hex_ids: Array[int]) -> void:
	domain_stars[domain_id] = star_ids.duplicate()
	domain_hexs[domain_id] = hex_ids.duplicate()
	
	print("📝 REGISTRO DOMÍNIO %d: %d estrelas, %d hexágonos" % [domain_id, star_ids.size(), hex_ids.size()])
	print("   ⭐ Estrelas: %s" % star_ids)
	print("   🔶 Hexágonos: %s" % hex_ids)
	
	_update_visible_lists()

## Atualizar listas consolidadas de elementos visíveis
func _update_visible_lists() -> void:
	visible_star_ids.clear()
	visible_hex_ids.clear()
	
	# Consolidar todas as estrelas de todos os domínios
	for domain_id in domain_stars.keys():
		for star_id in domain_stars[domain_id]:
			if star_id not in visible_star_ids:
				visible_star_ids.append(star_id)
	
	# Consolidar todos os hexágonos de todos os domínios
	for domain_id in domain_hexs.keys():
		for hex_id in domain_hexs[domain_id]:
			if hex_id not in visible_hex_ids:
				visible_hex_ids.append(hex_id)
	
	print("🔍 ELEMENTOS VISÍVEIS CONSOLIDADOS:")
	print("   ⭐ %d estrelas visíveis: %s" % [visible_star_ids.size(), visible_star_ids])
	print("   🔶 %d hexágonos visíveis: %s" % [visible_hex_ids.size(), visible_hex_ids])

## Verificar se uma estrela deve ser renderizada
func should_render_star(star_id: int) -> bool:
	return star_id in visible_star_ids

## Verificar se um hexágono deve ser renderizado
func should_render_hex(hex_id: int) -> bool:
	return hex_id in visible_hex_ids

## Limpar todos os registros
func clear_all() -> void:
	domain_stars.clear()
	domain_hexs.clear()
	visible_star_ids.clear()
	visible_hex_ids.clear()
	print("🧹 REGISTRO LIMPO: Todos os elementos removidos")

## Obter estatísticas
func get_stats() -> Dictionary:
	return {
		"domains_count": domain_stars.size(),
		"total_visible_stars": visible_star_ids.size(),
		"total_visible_hexs": visible_hex_ids.size(),
		"domain_stars": domain_stars,
		"domain_hexs": domain_hexs
	}

## Debug: imprimir todos os registros
func print_all_registrations() -> void:
	print("📋 === REGISTRO COMPLETO DE ELEMENTOS DOS DOMÍNIOS ===")
	
	for domain_id in domain_stars.keys():
		var stars = domain_stars[domain_id]
		var hexs = domain_hexs.get(domain_id, [])
		print("🏰 DOMÍNIO %d:" % domain_id)
		print("   ⭐ %d estrelas: %s" % [stars.size(), stars])
		print("   🔶 %d hexágonos: %s" % [hexs.size(), hexs])
	
	print("📊 TOTAIS:")
	print("   🏰 Domínios registrados: %d" % domain_stars.size())
	print("   ⭐ Estrelas visíveis: %d" % visible_star_ids.size())
	print("   🔶 Hexágonos visíveis: %d" % visible_hex_ids.size())
	print("=== FIM DO REGISTRO ===")