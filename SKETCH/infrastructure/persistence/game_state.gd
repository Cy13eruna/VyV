# 💾 GAME STATE
# Purpose: Manage game state persistence and serialization
# Layer: Infrastructure/Persistence
# Dependencies: Core entities only

class_name GameState
extends RefCounted

static func save_game_state(game_state: Dictionary, file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("Failed to open file for writing: ", file_path)
		return false
	
	var serialized_state = _serialize_game_state(game_state)
	file.store_string(JSON.stringify(serialized_state))
	file.close()
	
	return true

static func load_game_state(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file for reading: ", file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse JSON")
		return {}
	
	return _deserialize_game_state(json.data)

static func _serialize_game_state(game_state: Dictionary) -> Dictionary:
	var serialized = {
		"grid": _serialize_grid(game_state.grid),
		"players": _serialize_players(game_state.players),
		"units": _serialize_units(game_state.units),
		"domains": _serialize_domains(game_state.domains),
		"turn_data": game_state.turn_data,
		"fog_of_war_enabled": game_state.fog_of_war_enabled
	}
	
	return serialized

static func _serialize_grid(grid_data: Dictionary) -> Dictionary:
	var serialized_points = {}
	var serialized_edges = {}
	
	for point_id in grid_data.points:
		var point = grid_data.points[point_id]
		serialized_points[str(point_id)] = {
			"id": point.id,
			"q": point.position.hex_coord.q,
			"r": point.position.hex_coord.r,
			"connected_edges": point.connected_edges,
			"is_corner": point.is_corner
		}
	
	for edge_id in grid_data.edges:
		var edge = grid_data.edges[edge_id]
		serialized_edges[str(edge_id)] = {
			"id": edge.id,
			"point_a_id": edge.point_a_id,
			"point_b_id": edge.point_b_id,
			"terrain_type": edge.terrain_type
		}
	
	return {
		"points": serialized_points,
		"edges": serialized_edges,
		"point_id_counter": grid_data.point_id_counter,
		"edge_id_counter": grid_data.edge_id_counter
	}

static func _serialize_players(players_data: Dictionary) -> Dictionary:
	var serialized = {}
	
	for player_id in players_data:
		var player = players_data[player_id]
		serialized[str(player_id)] = {
			"id": player.id,
			"name": player.name,
			"color": [player.color.r, player.color.g, player.color.b, player.color.a],
			"is_active": player.is_active,
			"is_eliminated": player.is_eliminated,
			"unit_ids": player.unit_ids,
			"domain_ids": player.domain_ids
		}
	
	return serialized

static func _serialize_units(units_data: Dictionary) -> Dictionary:
	var serialized = {}
	
	for unit_id in units_data:
		var unit = units_data[unit_id]
		serialized[str(unit_id)] = {
			"id": unit.id,
			"owner_id": unit.owner_id,
			"name": unit.name,
			"q": unit.position.hex_coord.q,
			"r": unit.position.hex_coord.r,
			"actions_remaining": unit.actions_remaining,
			"is_revealed": unit.is_revealed,
			"force_revealed": unit.force_revealed
		}
	
	return serialized

static func _serialize_domains(domains_data: Dictionary) -> Dictionary:
	var serialized = {}
	
	for domain_id in domains_data:
		var domain = domains_data[domain_id]
		serialized[str(domain_id)] = {
			"id": domain.id,
			"owner_id": domain.owner_id,
			"name": domain.name,
			"q": domain.center_position.hex_coord.q,
			"r": domain.center_position.hex_coord.r,
			"power": domain.power,
			"influence_radius": domain.influence_radius,
			"is_occupied": domain.is_occupied,
			"occupied_by_player": domain.occupied_by_player
		}
	
	return serialized

static func _deserialize_game_state(data: Dictionary) -> Dictionary:
	# Implementation would reconstruct all game objects from serialized data
	# This is a complex process that would recreate the entire game state
	# For now, return empty dictionary as placeholder
	return {}