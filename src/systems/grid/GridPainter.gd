# res://src/systems/grid/GridPainter.gd
extends Node2D

var tile_size: float = 64.0
var grid_data = null

# Mudamos de hover_node para uma lista de nós alcançáveis
var reachable_nodes: Array = [] 

func setup(p_data, p_size: float) -> void:
	grid_data = p_data
	tile_size = p_size
	queue_redraw()

## Chamado pelo GridManager para destacar onde o Vagabond pode ir
func update_reachable(new_nodes: Array) -> void:
	reachable_nodes = new_nodes
	queue_redraw()

func _draw() -> void:
	if not grid_data:
		return

	# 1. DESENHAR ARESTAS (Edges)
	for edge_key in grid_data.edges.keys():
		var points = _parse_edge_key(edge_key)
		if points.size() == 2:
			# Linhas pretas padrão do grid
			draw_line(points[0], points[1], Color(0, 0, 0, 0.4), 1.5)

	# 2. DESENHAR NÓDULOS (Nodes)
	for node_pos in grid_data.nodes.keys():
		draw_circle(node_pos, 3.0, Color.BLACK)
	
	# 3. DESTAQUE DE MOVIMENTAÇÃO (Reachable)
	# Desativamos o Hover e agora desenhamos os destinos possíveis
	for reach_pos in reachable_nodes:
		# Um brilho suave branco no fundo
		draw_circle(reach_pos, 8.0, Color(1, 1, 1, 0.4)) 
		# Um aro nítido indicando interatividade
		draw_arc(reach_pos, 12.0, 0, TAU, 16, Color.WHITE, 2.0)

# Função auxiliar para extrair os Vector2 da string da chave da aresta
func _parse_edge_key(key: String) -> Array[Vector2]:
	var parts = key.replace("(", "").replace(")", "").split("_")
	if parts.size() == 2:
		var p1_raw = parts[0].split(",")
		var p2_raw = parts[1].split(",")
		if p1_raw.size() >= 2 and p2_raw.size() >= 2:
			return [
				Vector2(float(p1_raw[0]), float(p1_raw[1])),
				Vector2(float(p2_raw[0]), float(p2_raw[1]))
			]
	return []