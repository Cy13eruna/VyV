# res://src/systems/tasks/Metrics.gd
extends Node

# Estrutura de dados centralizada
var data = {
	"global": {
		"nodes_memory": 0,
		"edges_memory": 0
	},
	"players": {} # { player_id: { stats } }
}

# Mapeamento de Biomas (Sincronizado com o Terrain/Signals)
const BIOME_MAP = {
	0: "plains",
	1: "hills",
	2: "woods",
	3: "waters"
}

func _ready() -> void:
	add_to_group("metrics_manager")
	# Pequeno delay para garantir que os Autoloads estejam prontos
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	if is_instance_valid(Signals):
		Signals.metric_memory_updated.connect(_on_memory_updated)
		Signals.metric_domain_biome_changed.connect(_on_domain_biome_changed)
		Signals.metric_travel_biome_stepped.connect(_on_travel_stepped)
		print("[Metrics] Sinais conectados com sucesso.")
	else:
		push_error("[Metrics] Erro Crítico: Autoload 'Signals' não encontrado.")

## Inicializa a estrutura do jogador com valores zerados
func register_player(player_id: int) -> void:
	if not data.players.has(player_id):
		data.players[player_id] = {
			"current_domain_distribution": {},
			"travel_history": {}
		}
		
		# Força a criação das chaves para evitar erros de leitura no Panel
		for b_name in BIOME_MAP.values():
			data.players[player_id].current_domain_distribution[b_name] = 0
			data.players[player_id].travel_history[b_name] = 0
			
		print("[Metrics] Jogador %d registrado no sistema de métricas." % player_id)
		_notify_change()

func _ensure_player(player_id: int) -> void:
	if not data.players.has(player_id):
		register_player(player_id)

# --- HANDLERS DE SINAIS ---

func _on_memory_updated(category: String, amount: int) -> void:
	if category == "nodes":
		data.global.nodes_memory = amount
	elif category == "edges":
		data.global.edges_memory = amount
	_notify_change()

func _on_domain_biome_changed(player_id: int, biome_data: Variant, is_added: bool) -> void:
	_ensure_player(player_id)
	var b_name = _translate_biome(biome_data)
	var dict = data.players[player_id].current_domain_distribution
	
	var change = 1 if is_added else -1
	dict[b_name] = max(0, dict.get(b_name, 0) + change)
	
	print("[Metrics] P%d Domínio: %s mudou para %d" % [player_id, b_name, dict[b_name]])
	_notify_change()

func _on_travel_stepped(player_id: int, biome_data: Variant) -> void:
	_ensure_player(player_id)
	var b_name = _translate_biome(biome_data)
	var dict = data.players[player_id].travel_history
	
	dict[b_name] = dict.get(b_name, 0) + 1
	
	print("[Metrics] P%d Viagem Detectada: %s (Total: %d)" % [player_id, b_name, dict[b_name]])
	_notify_change()

# --- AUXILIARES ---

## Centraliza a notificação de mudança para o Signals global
func _notify_change() -> void:
	if Signals.has_signal("metric_data_updated"):
		Signals.metric_data_updated.emit()

func _translate_biome(raw_data: Variant) -> String:
	if raw_data is int or raw_data is float:
		return BIOME_MAP.get(int(raw_data), "plains")
	
	if raw_data is String:
		var s = raw_data.to_lower().strip_edges()
		if s == "water": s = "waters" 
		if s in ["plains", "hills", "woods", "waters"]:
			return s
			
	return "plains"

func get_player_stats(player_id: int) -> Dictionary:
	return data.players.get(player_id, {})

func reset_metrics() -> void:
	data.global.nodes_memory = 0
	data.global.edges_memory = 0
	data.players.clear()
	_notify_change()