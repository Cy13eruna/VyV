## FogOfWar - Versão Ultra-Limpa
## Sistema de fog of war sem logs desnecessários

class_name FogOfWarClean
extends RefCounted

signal visibility_updated()

var fog_enabled: bool = true
var debug_mode: bool = false

var hex_grid_ref = null
var player_instance_ref = null

var team_visibility: Dictionary = {}
var visibility_cache: Dictionary = {}

func setup_references(hex_grid, player_instance):
	hex_grid_ref = hex_grid
	player_instance_ref = player_instance

func set_fog_enabled(enabled: bool):
	fog_enabled = enabled
	if enabled:
		update_visibility_for_all_teams()
	else:
		_update_visibility_immediate()

func update_visibility_for_all_teams():
	if not fog_enabled:
		return
	
	_calculate_visibility_for_all_teams()
	visibility_updated.emit()

func update_visibility_for_player(domains: Array, units: Array):
	if not fog_enabled:
		return
	
	var team_id = player_instance_ref.player_id if player_instance_ref else 1
	_calculate_visibility_for_team(team_id, domains, units)

func get_visible_stars(team_id: int) -> Array[int]:
	if not fog_enabled:
		return _get_all_star_ids()
	
	return team_visibility.get(team_id, {}).get("stars", [])

func get_visible_diamonds(team_id: int) -> Array[int]:
	if not fog_enabled:
		return _get_all_diamond_ids()
	
	return team_visibility.get(team_id, {}).get("diamonds", [])

func is_star_visible(star_id: int, team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	var visible_stars = get_visible_stars(team_id)
	return star_id in visible_stars

func is_diamond_visible(diamond_id: int, team_id: int) -> bool:
	if not fog_enabled:
		return true
	
	var visible_diamonds = get_visible_diamonds(team_id)
	return diamond_id in visible_diamonds

func set_debug_mode(enabled: bool):
	debug_mode = enabled

func invalidate_visibility_cache():
	visibility_cache.clear()

func cleanup():
	hex_grid_ref = null
	player_instance_ref = null
	team_visibility.clear()
	visibility_cache.clear()

func _calculate_visibility_for_all_teams():
	# Implementação simplificada - todos os times veem tudo por enquanto
	pass

func _update_visibility_immediate():
	# Implementação simplificada
	pass

func _calculate_visibility_for_team(team_id: int, domains: Array, units: Array):
	var visible_stars = []
	var visible_diamonds = []
	
	# Adicionar visibilidade dos domínios
	for domain in domains:
		if is_instance_valid(domain):
			visible_stars.append(domain.get_center_star_id())
			visible_stars.append_array(domain.get_vertices())
	
	# Adicionar visibilidade das unidades
	for unit in units:
		if is_instance_valid(unit) and unit.is_positioned():
			visible_stars.append(unit.get_current_star_id())
			visible_stars.append_array(_get_adjacent_stars(unit.get_current_star_id()))
	
	# Remover duplicatas
	visible_stars = _remove_duplicates(visible_stars)
	
	# Armazenar visibilidade
	if not team_visibility.has(team_id):
		team_visibility[team_id] = {}
	
	team_visibility[team_id]["stars"] = visible_stars
	team_visibility[team_id]["diamonds"] = visible_diamonds

func _get_adjacent_stars(star_id: int) -> Array[int]:
	if not hex_grid_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	if star_id >= dot_positions.size():
		return []
	
	var star_pos = dot_positions[star_id]
	var adjacent = []
	var max_distance = 38.0
	
	for i in range(dot_positions.size()):
		if i != star_id:
			var distance = star_pos.distance_to(dot_positions[i])
			if distance <= max_distance:
				adjacent.append(i)
	
	return adjacent

func _get_all_star_ids() -> Array[int]:
	if not hex_grid_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	var all_stars = []
	for i in range(dot_positions.size()):
		all_stars.append(i)
	
	return all_stars

func _get_all_diamond_ids() -> Array[int]:
	# Implementação simplificada
	return []

func _remove_duplicates(array: Array) -> Array:
	var unique = []
	for item in array:
		if not item in unique:
			unique.append(item)
	return unique