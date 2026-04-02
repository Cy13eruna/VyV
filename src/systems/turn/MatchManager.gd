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
		if main_ref.domain_manager and main_ref.domain_manager.has_method("set_painter"):
			main_ref.domain_manager.set_painter(grid.painter)
	
	# 3. Configuração ÚNICA de Turnos (Sorteia as cores aqui)
	if turn.has_method("setup"):
		turn.setup(player_count)
	
	# 4. Inicia sequência de spawn (Usa as cores sorteadas acima)
	_spawn_sequence(player_count)

func _get_map_radius(player_count: int) -> int:
	return {2: 10, 3: 12, 4: 14, 6: 18}.get(player_count, 12)

func _spawn_sequence(player_count: int) -> void:
	# Aguarda um frame para garantir que os nós do Grid estão prontos na árvore
	await main_ref.get_tree().process_frame
	
	var d_mgr = main_ref.domain_manager
	var v_mgr = main_ref.vagabond_manager
	var g_mgr = main_ref.grid_manager
	var t_mgr = main_ref.turn_manager

	# Cria os domínios usando as cores já definidas no TurnManager
	if d_mgr and d_mgr.has_method("spawn_domains"):
		d_mgr.spawn_domains(player_count, g_mgr, v_mgr, t_mgr)
	
	# Sincroniza estado visual inicial
	if main_ref.has_method("_update_game_visibility"):
		main_ref._update_game_visibility(true)
	
	if main_ref.has_method("_setup_hud"):
		main_ref._setup_hud()

	# FINALIZAÇÃO CRÍTICA:
	# Agora que o mapa existe e as cores estão batendo, disparar o Turno 1.
	# Chamamos _announce_turn ou start_first_turn para não resetar o setup()
	if t_mgr:
		print("[MatchManager] Tudo pronto. Disparando início da partida.")
		if t_mgr.has_method("start_first_turn"):
			t_mgr.start_first_turn()
		elif t_mgr.has_method("_announce_turn"):
			t_mgr._announce_turn()