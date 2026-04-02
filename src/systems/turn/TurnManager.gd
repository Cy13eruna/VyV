# res://src/systems/turn/TurnManager.gd
extends Node

# Sinal local (opcional, para uso interno)
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
	
	# 💡 CORREÇÃO: Removemos o call_deferred e o await.
	# Chamamos diretamente para evitar a piscada do mapa.
	# Se os outros nós foram instanciados no mesmo frame, eles já estão no grupo 'domains'.
	_announce_turn()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle() 
	player_colors = keys.slice(0, total_players)

func next_turn() -> void:
	current_player_index = (current_player_index + 1) % total_players
	
	if current_player_index == 0:
		turn_number += 1
		print("\n--- RODADA ", turn_number, " ---")
	
	# Chamada direta para resposta imediata da UI
	_announce_turn()

func _announce_turn() -> void:
	if player_colors.is_empty():
		_assign_random_colors()

	var color_name = player_colors[current_player_index]
	var p_color = COLOR_OPTIONS[color_name]
	
	var player_data = {
		"id": current_player_index,
		"display_id": current_player_index + 1,
		"name": color_name,
		"color": p_color,
		"round": turn_number
	}
	
	print("[TurnManager] Vez de: ", player_data.name, " (ID: ", player_data.id, ")")
	
	# 1. Emite sinal local
	turn_started.emit(player_data)
	
	# 2. EMISSÃO PARA O EVENTBUS
	# Importante: O DomainManager deve estar conectado a este sinal para dar o +1 inicial.
	if is_instance_valid(Signals):
		Signals.turn_started.emit(player_data.id, player_data.color, turn_number)

# --- GETTERS ---

func get_current_id() -> int:
	return current_player_index

func get_player_color_by_id(id: int) -> Color:
	if id >= 0 and id < player_colors.size():
		var color_name = player_colors[id]
		return COLOR_OPTIONS[color_name]
	return Color.WHITE