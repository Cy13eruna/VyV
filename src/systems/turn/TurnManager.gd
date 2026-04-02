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
# 📸 NOVA VARIÁVEL: Armazena a posição da capital de cada jogador
var player_starting_positions: Dictionary = {} 

func setup(p_player_count: int) -> void:
	total_players = clamp(p_player_count, 1, COLOR_OPTIONS.size())
	current_player_index = 0
	turn_number = 1
	player_starting_positions.clear() # Limpa posições de partidas anteriores
	_assign_random_colors()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle() 
	player_colors = keys.slice(0, total_players)
	print("[TurnManager] Jogadores inicializados: ", player_colors)

# Chamado pelo DomainManager durante o spawn das capitais
func register_player_start_position(p_id: int, p_pos: Vector2) -> void:
	player_starting_positions[p_id] = p_pos
	print("[TurnManager] Posição inicial registrada para Player ", p_id, ": ", p_pos)

func start_first_turn() -> void:
	_announce_turn()

func next_turn() -> void:
	current_player_index = (current_player_index + 1) % total_players
	if current_player_index == 0:
		turn_number += 1
	_announce_turn()

func _announce_turn() -> void:
	if player_colors.is_empty():
		_assign_random_colors()

	var color_name = player_colors[current_player_index]
	var p_color = COLOR_OPTIONS[color_name]
	
	# Buscamos a posição da câmera para este jogador
	var p_pos = player_starting_positions.get(current_player_index, Vector2.ZERO)
	
	var player_data = {
		"id": current_player_index,
		"name": color_name,
		"color": p_color,
		"round": turn_number,
		"camera_pos": p_pos # Injetamos a posição nos dados do turno
	}
	
	print("[TurnManager] Vez de: ", player_data.name, " (ID: ", player_data.id, ")")
	
	turn_started.emit(player_data)
	
	if is_instance_valid(Signals):
		# O sinal global agora também pode passar a posição se você desejar, 
		# mas manteremos a assinatura para não quebrar outros sistemas.
		Signals.turn_started.emit(player_data.id, player_data.color, turn_number)

# --- GETTERS ---

func get_current_id() -> int:
	return current_player_index

func get_current_start_pos() -> Vector2:
	return player_starting_positions.get(current_player_index, Vector2.ZERO)

func get_player_color_by_id(id: int) -> Color:
	if id >= 0 and id < player_colors.size():
		var color_name = player_colors[id]
		return COLOR_OPTIONS.get(color_name, Color.WHITE)
	return Color.WHITE

func get_player_name_by_id(id: int) -> String:
	if id >= 0 and id < player_colors.size():
		return player_colors[id]
	return "UNKNOWN"