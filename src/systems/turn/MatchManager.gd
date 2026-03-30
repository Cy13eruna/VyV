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

	# 1. Definição de escala (Raio do mapa)
	var radius = _get_map_radius(player_count)
	
	# 2. Configuração do Tabuleiro e Terreno
	if grid.has_method("setup_map"):
		grid.setup_map(radius)
		
	if terrain and terrain.has_method("generate_random_terrain"):
		terrain.generate_random_terrain(grid.data)
	
	if grid.painter:
		grid.painter.terrain_ref = terrain
		
		# --- CONEXÃO CRÍTICA ---
		# Garantimos que o DomainManager saiba quem é o Painter antes do spawn
		if main_ref.domain_manager and main_ref.domain_manager.has_method("set_painter"):
			main_ref.domain_manager.set_painter(grid.painter)
	
	# 3. Configuração de Turnos
	if turn.has_method("setup"):
		turn.setup(player_count)
	
	# 4. Spawn de Jogadores (Passamos o grid_manager em vez do radius)
	_spawn_sequence(player_count)

func _get_map_radius(player_count: int) -> int:
	return {2: 10, 3: 12, 4: 14, 6: 18}.get(player_count, 12)

func _spawn_sequence(player_count: int) -> void:
	# Aguarda um frame para garantir que a Scene Tree processou o GridPainter
	await main_ref.get_tree().process_frame
	
	# Limpa domínios antigos
	if main_ref.domain_manager and main_ref.domain_manager.has_method("clear_domains"):
		main_ref.domain_manager.clear_domains()
	
	# O VagabondManager agora recebe o grid_manager para calcular world_pos e neighbors
	if main_ref.vagabond_manager:
		main_ref.vagabond_manager.spawn_players(
			player_count, 
			main_ref.turn_manager, 
			main_ref.grid_manager # CORREÇÃO: Argumento 3 agora é o Object GridManager
		)
	
	# Finaliza sincronizando o estado visual
	if main_ref.has_method("_update_game_visibility"):
		main_ref._update_game_visibility(true)
	
	if main_ref.has_method("_setup_hud"):
		main_ref._setup_hud()