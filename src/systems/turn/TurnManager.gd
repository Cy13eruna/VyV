# res://src/systems/turn/TurnManager.gd
extends Node

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
var player_colors: Array = []

func setup(p_player_count: int) -> void:
	total_players = clamp(p_player_count, 1, COLOR_OPTIONS.size())
	current_player_index = 0
	turn_number = 1
	
	_assign_random_colors()
	
	print("TurnManager: Iniciado com ", total_players, " jogadores.")
	_announce_turn()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle()
	
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
	# --- NOVO: Reset de AP via VagabondManager ---
	# Buscamos o gerente de unidades para resetar os pontos de ação do jogador da vez
	var vagabond_manager = get_tree().root.find_child("VagabondManager", true, false)
	if vagabond_manager and vagabond_manager.has_method("reset_aps_for_player"):
		vagabond_manager.reset_aps_for_player(current_player_index)

	var color_name = player_colors[current_player_index]
	var player_data = {
		"id": current_player_index,
		"display_id": current_player_index + 1,
		"name": color_name,
		"color": COLOR_OPTIONS[color_name],
		"round": turn_number
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