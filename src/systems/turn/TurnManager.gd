# res://src/systems/turn/TurnManager.gd
extends Node

# Agora emite um dicionário com os dados do jogador (nome, cor, etc)
signal turn_started(player_data: Dictionary)

# Configuração das cores disponíveis
const COLOR_OPTIONS = {
	"Green": Color.GREEN,
	"Yellow": Color.YELLOW,
	"Red": Color.RED,
	"Purple": Color.PURPLE,
	"Cyan": Color.CYAN,
	"Magenta": Color.MAGENTA
}

var total_players: int = 0
var current_player_index: int = 0
var turn_number: int = 1

# Lista de nomes de cores atribuídas aos jogadores nesta partida
var player_colors: Array = []

func setup(p_player_count: int) -> void:
	total_players = p_player_count
	current_player_index = 0
	turn_number = 1
	
	_assign_random_colors()
	print("TurnManager: Iniciado com ", total_players, " jogadores. Cores: ", player_colors)
	
	# Aciona a intermissão para o primeiro jogador
	_announce_turn()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle() # Embaralha as cores disponíveis
	
	player_colors.clear()
	for i in range(total_players):
		player_colors.append(keys[i])

func next_turn() -> void:
	current_player_index = (current_player_index + 1) % total_players
	
	if current_player_index == 0:
		turn_number += 1
		print("--- Rodada ", turn_number, " ---")
	
	_announce_turn()

func _announce_turn() -> void:
	var color_name = player_colors[current_player_index]
	
	var data = {
		"name": color_name,
		"color": COLOR_OPTIONS[color_name],
		"index": current_player_index + 1
	}
	
	print("TurnManager: Vez do Jogador ", color_name)
	turn_started.emit(data)

func get_current_player_name() -> String:
	return player_colors[current_player_index]

func get_current_player_color() -> Color:
	var color_name = player_colors[current_player_index]
	return COLOR_OPTIONS[color_name]