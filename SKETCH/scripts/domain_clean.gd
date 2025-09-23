## Domain - Versão Ultra-Limpa
## Sistema de domínios sem logs desnecessários

class_name DomainClean
extends RefCounted

signal domain_created(domain_id: int)
signal domain_destroyed(domain_id: int)

var domain_id: int
var center_star_id: int = -1
var vertices: Array[int] = []
var owner_id: int = -1
var domain_color: Color = Color.WHITE
var visual_node: Node2D = null

var hex_grid_ref = null
var star_mapper_ref = null

func _init():
	domain_id = randi()

func setup_references(hex_grid, star_mapper):
	hex_grid_ref = hex_grid
	star_mapper_ref = star_mapper

func create_at_star(star_id: int, hex_grid) -> bool:
	if not _is_valid_star_id(star_id):
		return false
	
	center_star_id = star_id
	vertices = _find_adjacent_vertices(star_id)
	
	if vertices.size() < 6:
		return false
	
	if not _create_visual():
		return false
	
	domain_created.emit(domain_id)
	return true

func check_edge_sharing(existing_domains: Array) -> bool:
	for existing_domain in existing_domains:
		if _shares_edges_with(existing_domain):
			return true
	return false

func set_owner(new_owner_id: int):
	var old_owner = owner_id
	owner_id = new_owner_id

func set_color(new_color: Color):
	domain_color = new_color
	if visual_node:
		visual_node.queue_redraw()

func get_domain_id() -> int:
	return domain_id

func get_center_star_id() -> int:
	return center_star_id

func get_vertices() -> Array[int]:
	return vertices.duplicate()

func get_owner_id() -> int:
	return owner_id

func get_color() -> Color:
	return domain_color

func destroy():
	if visual_node and is_instance_valid(visual_node):
		if visual_node.get_parent():
			visual_node.get_parent().remove_child(visual_node)
		visual_node.queue_free()
		visual_node = null
	
	domain_destroyed.emit(domain_id)

func cleanup():
	destroy()
	hex_grid_ref = null
	star_mapper_ref = null

func _is_valid_star_id(star_id: int) -> bool:
	if not star_mapper_ref:
		return false
	
	if star_id < 0 or star_id >= star_mapper_ref.get_star_count():
		return false
	
	return true

func _find_adjacent_vertices(star_id: int) -> Array[int]:
	if not hex_grid_ref:
		return []
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	if star_id >= dot_positions.size():
		return []
	
	var center_pos = dot_positions[star_id]
	var adjacent_vertices: Array[int] = []
	var max_distance = 38.0
	
	for i in range(dot_positions.size()):
		if i == star_id:
			continue
		
		var distance = center_pos.distance_to(dot_positions[i])
		if distance <= max_distance:
			adjacent_vertices.append(i)
	
	# Limitar a 6 vértices mais próximos
	if adjacent_vertices.size() > 6:
		adjacent_vertices.sort_custom(func(a, b): 
			var dist_a = center_pos.distance_to(dot_positions[a])
			var dist_b = center_pos.distance_to(dot_positions[b])
			return dist_a < dist_b
		)
		var limited_vertices: Array[int] = []
		for i in range(min(6, adjacent_vertices.size())):
			limited_vertices.append(adjacent_vertices[i])
		adjacent_vertices = limited_vertices
	
	return adjacent_vertices

func _create_visual() -> bool:
	if not hex_grid_ref:
		return false
	
	visual_node = Node2D.new()
	visual_node.z_index = 10
	visual_node.draw.connect(_draw_domain)
	hex_grid_ref.add_child(visual_node)
	
	return true

func _shares_edges_with(other_domain) -> bool:
	if not other_domain or other_domain == self:
		return false
	
	var other_vertices = other_domain.get_vertices()
	var shared_vertices = []
	
	for vertex in vertices:
		if vertex in other_vertices:
			shared_vertices.append(vertex)
	
	# Se compartilham 2 ou mais vértices, compartilham uma aresta
	return shared_vertices.size() >= 2

func _draw_domain():
	if not visual_node or not hex_grid_ref:
		return
	
	var dot_positions = hex_grid_ref.get_dot_positions()
	
	# Desenhar hexágono do domínio
	if vertices.size() >= 6:
		var points = PackedVector2Array()
		for vertex_id in vertices:
			if vertex_id < dot_positions.size():
				var vertex_pos = dot_positions[vertex_id]
				var center_pos = dot_positions[center_star_id]
				var relative_pos = vertex_pos - center_pos
				points.append(relative_pos)
		
		if points.size() >= 3:
			visual_node.draw_colored_polygon(points, Color(domain_color.r, domain_color.g, domain_color.b, 0.3))
			visual_node.draw_polyline(points + [points[0]], domain_color, 2.0)