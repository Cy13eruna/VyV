# res://src/systems/turn/MatchManager.gd
extends RefCounted

var main_ref: Node

func _init(p_main: Node) -> void:
	main_ref = p_main

## Orquestra a criação completa de uma partida
func setup_game(player_count: int) -> void:
	var grid = main_ref.grid_manager
	var terrain = main_ref.terrain_manager
	var turn = main_ref.turn_manager
	var vagabond = main_ref.vagabond_manager

	# 1. Definição de escala
	var radius = _get_map_radius(player_count)
	
	# 2. Configuração do Tabuleiro e Terreno
	grid.setup_map(radius)
	terrain.generate_random_terrain(grid.data)
	
	if grid.painter:
		grid.painter.terrain_ref = terrain
	
	# 3. Configuração de Turnos
	turn.setup(player_count)
	
	# 4. Spawn de Jogadores (Aguardamos um frame para o grid estar pronto)
	_spawn_sequence(player_count, radius)

func _get_map_radius(player_count: int) -> int:
	return {2: 8, 3: 10, 4: 12, 6: 14}.get(player_count, 10)

func _spawn_sequence(player_count: int, radius: int) -> void:
	await main_ref.get_tree().process_frame
	
	if main_ref.vagabond_manager:
		main_ref.vagabond_manager.spawn_players(
			player_count, 
			main_ref.turn_manager, 
			radius
		)
	
	# Inicializa a neblina após o spawn
	main_ref._update_game_visibility(true)
	main_ref._setup_hud()