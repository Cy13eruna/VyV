## GameServer - Coordenador Central do Jogo
## Gerencia múltiplas instâncias de jogadores de forma isolada
## Preparado para sistema multiplayer online

class_name GameServer
extends RefCounted

## Sinais do servidor
signal player_added(player_id: int)
signal turn_changed(current_player_id: int)
signal game_state_changed(new_state: String)

## Instâncias dos jogadores
var players: Array[PlayerInstance] = []
var current_player_index: int = 0
var current_turn: int = 1

## Estado compartilhado
var shared_state: SharedGameState
var game_state: String = "waiting"  # waiting, playing, finished

## Configurações do jogo
var max_players: int = 6
var min_players: int = 2

## Cores disponíveis para jogadores
var available_colors: Array[Color] = [
	Color(0, 0, 1),      # Azul
	Color(1, 0.5, 0),    # Laranja
	Color(1, 0, 0),      # Vermelho
	Color(0.5, 0, 1),    # Roxo
	Color(1, 1, 0),      # Amarelo
	Color(0, 1, 1)       # Ciano
]

## Inicializar servidor
func _init():
	shared_state = SharedGameState.new()

## Configurar estado compartilhado
func setup_shared_state(hex_grid, star_mapper, parent_node):
	shared_state.setup(hex_grid, star_mapper, parent_node)

## Adicionar jogador ao jogo
func add_player(player_name: String = "") -> PlayerInstance:
	if players.size() >= max_players:
		print("GameServer: Máximo de jogadores atingido")
		return null
	
	var player_id = players.size() + 1
	var color = available_colors[players.size() % available_colors.size()]
	
	var player = PlayerInstance.new(player_id, color, player_name)
	player.setup_shared_references(shared_state.hex_grid, shared_state.star_mapper)
	
	# Conectar sinais do jogador
	player.unit_created.connect(_on_player_unit_created.bind(player_id))
	player.unit_moved.connect(_on_player_unit_moved.bind(player_id))
	player.domain_created.connect(_on_player_domain_created.bind(player_id))
	player.visibility_changed.connect(_on_player_visibility_changed.bind(player_id))
	
	players.append(player)
	player_added.emit(player_id)
	
	print("GameServer: Jogador %d adicionado (%s)" % [player_id, player.player_name])
	return player

## Iniciar jogo
func start_game() -> bool:
	if players.size() < min_players:
		print("GameServer: Mínimo de %d jogadores necessário" % min_players)
		return false
	
	game_state = "playing"
	current_player_index = 0
	current_turn = 1
	
	# Iniciar turno do primeiro jogador
	_start_player_turn(current_player_index)
	
	game_state_changed.emit(game_state)
	print("GameServer: Jogo iniciado com %d jogadores" % players.size())
	return true

## Avançar para próximo turno
func next_turn():
	if game_state != "playing":
		return
	
	# Finalizar turno do jogador atual
	if current_player_index < players.size():
		players[current_player_index].end_turn()
	
	# Avançar para próximo jogador
	current_player_index = (current_player_index + 1) % players.size()
	
	# Se voltou ao primeiro jogador, incrementar turno
	if current_player_index == 0:
		current_turn += 1
	
	# Iniciar turno do próximo jogador
	_start_player_turn(current_player_index)
	
	turn_changed.emit(get_current_player().player_id)
	print("GameServer: Turno %d - Jogador %d (%s)" % [current_turn, get_current_player().player_id, get_current_player().player_name])

## Iniciar turno de um jogador específico
func _start_player_turn(player_index: int):
	if player_index < players.size():
		players[player_index].start_turn()

## Obter jogador atual
func get_current_player() -> PlayerInstance:
	if current_player_index < players.size():
		return players[current_player_index]
	return null

## Obter jogador por ID
func get_player(player_id: int) -> PlayerInstance:
	for player in players:
		if player.player_id == player_id:
			return player
	return null

## Obter todas as unidades de todos os jogadores
func get_all_units() -> Array:
	var all_units = []
	for player in players:
		all_units.append_array(player.units)
	return all_units

## Obter todos os domínios de todos os jogadores
func get_all_domains() -> Array:
	var all_domains = []
	for player in players:
		all_domains.append_array(player.domains)
	return all_domains

## Obter unidades visíveis para o jogador atual
func get_visible_units_for_current_player() -> Array:
	var current_player = get_current_player()
	if not current_player:
		return []
	
	return current_player.get_visible_units(get_all_units())

## Obter domínios visíveis para o jogador atual
func get_visible_domains_for_current_player() -> Array:
	var current_player = get_current_player()
	if not current_player:
		return []
	
	return current_player.get_visible_domains(get_all_domains())

## Mover unidade (através do jogador)
func move_unit(unit: Unit, target_star_id: int) -> bool:
	# Encontrar qual jogador possui esta unidade
	for player in players:
		if unit in player.units:
			return player.move_unit(unit, target_star_id)
	
	return false

## Verificar se é o turno de um jogador específico
func is_player_turn(player_id: int) -> bool:
	var current_player = get_current_player()
	return current_player != null and current_player.player_id == player_id

## Obter estatísticas do jogo
func get_game_stats() -> Dictionary:
	var stats = {
		"game_state": game_state,
		"current_turn": current_turn,
		"current_player_id": get_current_player().player_id if get_current_player() else -1,
		"total_players": players.size(),
		"total_units": get_all_units().size(),
		"total_domains": get_all_domains().size()
	}
	
	# Adicionar estatísticas de cada jogador
	stats["players"] = []
	for player in players:
		stats.players.append(player.get_stats())
	
	return stats

## Callbacks dos jogadores
func _on_player_unit_created(player_id: int, unit_id: int):
	print("GameServer: Jogador %d criou unidade %d" % [player_id, unit_id])

func _on_player_unit_moved(player_id: int, unit_id: int, from_star: int, to_star: int):
	print("GameServer: Jogador %d moveu unidade %d (%d→%d)" % [player_id, unit_id, from_star, to_star])

func _on_player_domain_created(player_id: int, domain_id: int):
	print("GameServer: Jogador %d criou domínio %d" % [player_id, domain_id])

func _on_player_visibility_changed(player_id: int):
	# Atualizar visibilidade pode afetar outros sistemas
	pass

## Limpeza do servidor
func cleanup():
	# Limpar todos os jogadores
	for player in players:
		if is_instance_valid(player):
			player.cleanup()
	players.clear()
	
	# Limpar estado compartilhado
	if shared_state and is_instance_valid(shared_state):
		shared_state.cleanup()
		shared_state = null
	
	game_state = "finished"