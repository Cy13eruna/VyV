extends RefCounted

# O array estático define as únicas opções permitidas
const TYPES = ["Upgrade", "Trainment", "Global"]

var id: String = ""
var title: String = ""
var icon: String = ""
var description: String = ""

# Armazenamos o índice numérico. Padrão 0 (Upgrade)
var type_index: int = 0

# Função auxiliar para obter o nome do tipo como String
func get_type_name() -> String:
	if type_index >= 0 and type_index < TYPES.size():
		return TYPES[type_index]
	return "Unknown"

func execute(domain: Node2D) -> void:
	# Agora o log usa o nome vindo do array baseado no índice
	print("[%s] Executando lógica de: %s" % [get_type_name(), title])