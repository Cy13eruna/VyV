# res://src/systems/grid/GridSelector.gd
extends RefCounted

# O objeto selecionado no momento (Vagabond)
var unit: Node2D = null

# Lista de posições Vector2 (grid_pos) que a unidade pode alcançar
var reachable_nodes: Array = []

# Limpa o estado de seleção e remove o brilho visual
func clear() -> void:
	if is_instance_valid(unit) and unit.has_method("set_highlight"):
		unit.set_highlight(false)
	
	unit = null
	reachable_nodes = []

# Define uma nova seleção
func select(p_unit: Node2D, neighbors: Array) -> void:
	clear() # Garante que a seleção anterior foi limpa
	unit = p_unit
	reachable_nodes = neighbors
	
	if unit.has_method("set_highlight"):
		unit.set_highlight(true)

# Verifica se temos algo selecionado
func is_active() -> bool:
	return is_instance_valid(unit)