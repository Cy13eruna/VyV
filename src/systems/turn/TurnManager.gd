# res://src/systems/turn/TurnManager.gd
extends Node

# Sinal robusto que carrega todo o estado necessário para o início de um turno
signal turn_started(player_data: Dictionary)

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

# Armazena os nomes das cores (chaves do COLOR_OPTIONS) para cada ID de jogador
var player_colors: Array = []

func setup(p_player_count: int) -> void:
	# Garante que não excedemos o limite de cores definidas
	total_players = clamp(p_player_count, 1, COLOR_OPTIONS.size())
	current_player_index = 0
	turn_number = 1
	
	_assign_random_colors()
	
	print("TurnManager: Iniciado com ", total_players, " jogadores.")
	_announce_turn()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle() # Embaralha para que P1 nem sempre seja Green
	
	player_colors.clear()
	for i in range(total_players):
		player_colors.append(keys[i])

func next_turn() -> void:
	current_player_index = (current_player_index + 1) % total_players
	
	if current_player_index == 0:
		turn_number += 1
		print("\n--- RODADA ", turn_number, " ---")
	
	_announce_turn()

func _announce_turn() -> void:
	var color_name = player_colors[current_player_index]
	
	# Criamos o "Data Transfer Object" (DTO) para o sinal
	var player_data = {
		"id": current_player_index,        # ID lógico (0, 1, 2...)
		"display_id": current_player_index + 1, # ID para humanos (1, 2, 3...)
		"name": color_name,                # Nome da cor/facção
		"color": COLOR_OPTIONS[color_name], # Objeto Color real
		"round": turn_number               # Rodada atual
	}
	
	print("TurnManager: Vez do Jogador ", player_data.name, " (P", player_data.display_id, ")")
	turn_started.emit(player_data)

# --- GETTERS AUXILIARES ---

func get_current_player_color() -> Color:
	var color_name = player_colors[current_player_index]
	return COLOR_OPTIONS[color_name]

func get_player_color_by_id(id: int) -> Color:
	if id >= 0 and id < player_colors.size():
		return COLOR_OPTIONS[player_colors[id]]
	return Color.WHITE