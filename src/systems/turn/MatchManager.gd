# res://src/systems/turn/MatchManager.gd
extends RefCounted

var main_ref: Node

# Regra de Negócio: Poder com que cada capital começa a partida
const STARTING_POWER: int = 1 

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
	
	# 3. Configuração ÚNICA de Turnos
	if turn.has_method("setup"):
		turn.setup(player_count)
	
	# 4. Inicia sequência de spawn
	_spawn_sequence(player_count)

func _get_map_radius(player_count: int) -> int:
	return {2: 10, 3: 12, 4: 14, 6: 18}.get(player_count, 12)

func _spawn_sequence(player_count: int) -> void:
	# Aguarda um frame para garantir que os nós do Grid estão prontos
	await main_ref.get_tree().process_frame
	
	var d_mgr = main_ref.domain_manager
	var v_mgr = main_ref.vagabond_manager
	var g_mgr = main_ref.grid_manager
	var t_mgr = main_ref.turn_manager

	# 1. Criação dos Domínios
	if d_mgr and d_mgr.has_method("spawn_domains"):
		d_mgr.spawn_domains(player_count, g_mgr, v_mgr, t_mgr)
		
		# 2. INICIALIZAÇÃO DE ESTADO (Poder Inicial)
		# Agora o MatchManager percorre as instâncias criadas e define o poder.
		for domain in d_mgr.domain_instances:
			if is_instance_valid(domain):
				domain.set("power", STARTING_POWER)
				
				# Notifica o domínio para atualizar barras de progresso/UI se necessário
				if domain.has_method("_refresh_all"):
					domain._refresh_all()
					
				print("[MatchManager] P%d Capital em %s inicializada com %d poder." % [
					domain.get("owner_id"), 
					domain.get("grid_pos"), 
					STARTING_POWER
				])
	
	# Sincroniza estado visual inicial
	if main_ref.has_method("_update_game_visibility"):
		main_ref._update_game_visibility(true)
	
	if main_ref.has_method("_setup_hud"):
		main_ref._setup_hud()

	# FINALIZAÇÃO: Inicia o fluxo de turnos
	if t_mgr:
		print("[MatchManager] Setup concluído. Disparando início da partida.")
		if t_mgr.has_method("start_first_turn"):
			t_mgr.start_first_turn()
		elif t_mgr.has_method("_announce_turn"):
			t_mgr._announce_turn()