# res://src/systems/turn/TurnManager.gd
extends Node

signal turn_started(player_data: Dictionary)
signal turn_ended(player_id: int) # Novo sinal para processar ganhos de fim de turno

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
var player_starting_positions: Dictionary = {} 

var _is_transitioning: bool = false

func setup(p_player_count: int) -> void:
	total_players = clamp(p_player_count, 1, COLOR_OPTIONS.size())
	current_player_index = 0
	turn_number = 1
	player_starting_positions.clear() 
	_is_transitioning = false
	_assign_random_colors()

func _assign_random_colors() -> void:
	var keys = COLOR_OPTIONS.keys()
	keys.shuffle() 
	player_colors = keys.slice(0, total_players)
	print("[TurnManager] Jogadores inicializados: ", player_colors)

func register_player_start_position(p_id: int, p_pos: Vector2) -> void:
	player_starting_positions[p_id] = p_pos

func start_first_turn() -> void:
	_announce_turn()

## Chamado pelo botão "End Turn" na UI
func next_turn() -> void:
	if _is_transitioning: return
	_is_transitioning = true
	
	# 1. EMITE FIM DE TURNO PARA O JOGADOR ATUAL
	# É aqui que os Managers de Domínio e Vagabonds devem agir
	var outgoing_player_id = current_player_index
	print("[TurnManager] Finalizando turno do Player: ", outgoing_player_id)
	
	turn_ended.emit(outgoing_player_id)
	if is_instance_valid(Signals):
		Signals.turn_ended.emit(outgoing_player_id) 
	
	# 2. ATUALIZA O ESTADO PARA O PRÓXIMO
	current_player_index = (current_player_index + 1) % total_players
	
	if current_player_index == 0:
		turn_number += 1
	
	# 3. ANUNCIA O INÍCIO DO PRÓXIMO
	_announce_turn()
	
	get_tree().create_timer(0.5).timeout.connect(func(): _is_transitioning = false)

func _announce_turn() -> void:
	if player_colors.is_empty():
		_assign_random_colors()

	var color_name = player_colors[current_player_index]
	var p_color = COLOR_OPTIONS[color_name]
	var p_pos = player_starting_positions.get(current_player_index, Vector2.ZERO)
	
	var player_data = {
		"id": current_player_index,
		"name": color_name,
		"color": p_color,
		"round": turn_number,
		"camera_pos": p_pos 
	}
	
	print("[TurnManager] Próximo turno: ", player_data.name, " (ID: ", player_data.id, ")")
	
	turn_started.emit(player_data)
	
	if is_instance_valid(Signals):
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