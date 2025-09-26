## SimpleHexGridRenderer - Renderer Simples
## RESET: Implementação gradual conforme i.txt

class_name SimpleHexGridRenderer
extends RefCounted

# Importar sistema de logging
const Logger = preload("res://scripts/core/logger.gd")

## Component references
var _config
var _cache
var _geometry

## Game manager reference
var game_manager_ref = null

## Star highlight system reference
var star_highlight_system_ref = null

## Terreno revelado (posições que têm estrelas ou hexágonos visíveis)
var revealed_terrain: Dictionary = {}

## Renderer properties for compatibility
var enable_lod: bool = false
var max_elements_per_frame: int = 10000
var culling_enabled: bool = true
var layer_visibility: Dictionary = {}
var render_stats: Dictionary = {}

## Initialize renderer
func _init():
	pass

## Setup renderer with dependencies
func setup_renderer(config, cache, geometry):
	_config = config
	_cache = cache
	_geometry = geometry

## Set game manager reference
func set_game_manager(game_manager) -> void:
	game_manager_ref = game_manager
	_update_revealed_terrain()
	print("🔗 GameManager conectado ao renderer")

## Set star highlight system reference
func set_star_highlight_system(highlight_system) -> void:
	star_highlight_system_ref = highlight_system
	print("✨ StarHighlightSystem conectado ao renderer")

## Set layer visibility (compatibility method)
func set_layer_visibility(layer: int, visible: bool) -> void:
	layer_visibility[layer] = visible

## Set culling enabled (compatibility method)
func set_culling_enabled(enabled: bool) -> void:
	culling_enabled = enabled

## Optimize for performance (compatibility method)
func optimize_for_performance(target_fps: float) -> void:
	# Simple optimization: enable LOD if target FPS is high
	if target_fps >= 60.0:
		enable_lod = true
		max_elements_per_frame = 5000

## Get render stats (compatibility method)
func get_render_stats() -> Dictionary:
	return {
		"elements_rendered": 0,
		"elements_culled": 0,
		"fog_of_war_active": game_manager_ref != null
	}

## Render complete grid to a CanvasItem
func render_grid(canvas_item: CanvasItem, camera_transform: Transform2D = Transform2D()) -> void:
	# Render diamonds (losangos)
	_render_diamonds(canvas_item)
	
	# Render stars (estrelas)
	_render_stars(canvas_item)

## Render diamond connections - RENDERIZAR TODOS
func _render_diamonds(canvas_item: CanvasItem) -> void:
	var diamond_geometry = _cache.get_diamond_geometry()
	var diamond_colors = _cache.get_diamond_colors()
	
	var rendered_count = 0
	
	for i in range(diamond_geometry.size()):
		var geometry = diamond_geometry[i]
		
		# Renderizar todos os losangos
		var color = diamond_colors[i] if i < diamond_colors.size() else Color.GREEN
		canvas_item.draw_colored_polygon(geometry, color)
		rendered_count += 1
	
	print("🏰 LOSANGOS RENDERIZADOS: %d (total: %d)" % [rendered_count, diamond_geometry.size()])

## Render star decorations - RENDERIZAR TODAS COM HIGHLIGHT
func _render_stars(canvas_item: CanvasItem) -> void:
	var star_geometry = _cache.get_star_geometry()
	var dot_positions = _cache.get_dot_positions()
	
	var rendered_count = 0
	
	# DEBUG: Mostrar primeiras 3 estrelas do renderer
	if dot_positions.size() > 0:
		print("⭐ DEBUG: Primeiras 3 estrelas do renderer:")
		for i in range(min(3, dot_positions.size())):
			print("⭐   Estrela %d: %s" % [i, str(dot_positions[i])])
	
	for i in range(star_geometry.size()):
		var geometry = star_geometry[i]
		
		# Renderizar estrela com highlight se necessário
		var star_color = Color(1.0, 1.0, 1.0, 1.0)  # Branco puro
		
		# Verificar se esta estrela deve brilhar
		if star_highlight_system_ref and star_highlight_system_ref.is_star_highlighted(i):
			star_color = star_highlight_system_ref.get_highlight_color_for_star(i)
			print("✨ RENDERER: Destacando estrela %d na posição %s" % [i, str(dot_positions[i]) if i < dot_positions.size() else "FORA DO RANGE"])
			# Desenhar círculo de destaque maior
			if i < dot_positions.size():
				var star_pos = dot_positions[i]
				var highlight_radius = star_highlight_system_ref.get_highlight_radius_for_star(i, 8.0)
				canvas_item.draw_circle(star_pos, highlight_radius, star_color)
			else:
				canvas_item.draw_colored_polygon(geometry, star_color)
		else:
			canvas_item.draw_colored_polygon(geometry, star_color)
		
		rendered_count += 1
	
	print("⭐ ESTRELAS RENDERIZADAS: %d (total: %d)" % [rendered_count, star_geometry.size()])
	
	# Atualizar terreno revelado
	_update_revealed_terrain()

## Atualizar terreno revelado baseado nos elementos visíveis
func _update_revealed_terrain() -> void:
	# Não limpar mais automaticamente - manter terreno revelado por cliques
	print("🗺️ TERRENO REVELADO: %d posições" % revealed_terrain.size())

## Verificar se uma posição está em terreno revelado
func is_terrain_revealed(position: Vector2) -> bool:
	# Verificar se a posição está próxima de algum terreno revelado
	for revealed_pos in revealed_terrain.keys():
		if position.distance_to(revealed_pos) < 50.0:  # Tolerância aumentada para melhor cobertura
			return true
	return false

## Obter todas as posições de terreno revelado
func get_revealed_terrain_positions() -> Array:
	return revealed_terrain.keys()

## Revelar terreno em uma posição (por clique do mouse)
func reveal_terrain_at(position: Vector2) -> void:
	revealed_terrain[position] = true
	print("✨ TERRENO REVELADO em %s (total: %d posições)" % [position, revealed_terrain.size()])
	
	# Forçar atualização visual dos domínios e unidades
	_notify_terrain_revealed()

## Notificar que terreno foi revelado (forçar atualização visual)
func _notify_terrain_revealed() -> void:
	# Emitir sinal para que domínios e unidades atualizem sua visibilidade
	if game_manager_ref and game_manager_ref.has_method("update_visibility_for_revealed_terrain"):
		game_manager_ref.update_visibility_for_revealed_terrain()
	else:
		print("🔄 Terreno revelado - domínios e unidades devem atualizar visibilidade")

