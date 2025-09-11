extends Node2D

# Hexagonal positions
var hex_nodes = []
var player1_node = 0  # First node
var player2_node = 47  # Last node (8x6 = 48 nodes, index 47)
var selected_player = 0
var current_turn = 1
var blocked_paths = {}  # Dictionary to store which paths are blocked

func _ready():
	print("HexGame READY - starting hexagonal game")
	
	# Force window to be visible and focused
	get_window().grab_focus()
	get_window().move_to_center()
	
	# Generate hexagonal grid
	generate_hex_grid()
	queue_redraw()

func generate_hex_grid():
	var board_width = 8  # Back to original
	var board_height = 6
	var hex_size = 52.5  # 1.5x zoom (35 * 1.5)
	
	# Calculate grid bounds for centering
	var grid_width = hex_size * sqrt(3.0) * (board_width - 1) + hex_size * sqrt(3.0) / 2.0
	var grid_height = hex_size * 3.0 / 2.0 * (board_height - 1) + hex_size
	
	# Center the grid in viewport
	var viewport_size = get_viewport_rect().size
	var offset_x = (viewport_size.x - grid_width) / 2.0
	var offset_y = (viewport_size.y - grid_height) / 2.0
	
	# Flat-top hexagons (horizontal orientation) - centered
	for row in range(board_height):
		for col in range(board_width):
			var x = hex_size * (sqrt(3.0) * col + sqrt(3.0)/2.0 * (row & 1)) + offset_x
			var y = hex_size * (3.0/2.0 * row) + offset_y
			hex_nodes.append(Vector2(x, y))
	
	# Generate random blocked paths (50% of all paths)
	generate_random_blocked_paths()
	
	print("Generated ", hex_nodes.size(), " hex nodes with random blocked paths")

func get_hex_neighbors(node_idx: int) -> Array:
	var board_width = 8  # Back to original
	var board_height = 6
	var col = node_idx % board_width
	var row = node_idx / board_width
	var neighbors = []
	
	# Flat-top hex neighbors (6 directions)
	var directions = []
	if row % 2 == 0:  # Even row
		directions = [[-1,-1], [0,-1], [-1,0], [1,0], [-1,1], [0,1]]
	else:  # Odd row
		directions = [[0,-1], [1,-1], [-1,0], [1,0], [0,1], [1,1]]
	
	for dir in directions:
		var new_col = col + dir[0]
		var new_row = row + dir[1]
		if new_col >= 0 and new_col < board_width and new_row >= 0 and new_row < board_height:
			neighbors.append(new_row * board_width + new_col)
	
	return neighbors

func _draw():
	# White background - always full viewport
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color.WHITE)
	
	# Draw paths first
	for i in range(hex_nodes.size()):
		var pos = hex_nodes[i]
		var neighbors = get_hex_neighbors(i)
		for neighbor_idx in neighbors:
			if neighbor_idx > i and neighbor_idx < hex_nodes.size():  # Avoid duplicate lines
				var path_key = get_path_key(i, neighbor_idx)
				var gray_color = Color(0.8, 0.8, 0.8)  # Gray for open paths
				var white_color = Color.WHITE           # White for blocked paths
				
				if blocked_paths.has(path_key):
					# Draw blocked path as white diamond
					draw_diamond_path_simple(pos, hex_nodes[neighbor_idx], white_color)
				else:
					# Draw open path as gray diamond
					draw_diamond_path_simple(pos, hex_nodes[neighbor_idx], gray_color)
	
	# Draw nodes
	for i in range(hex_nodes.size()):
		var pos = hex_nodes[i]
		draw_circle(pos, 8, Color.BLACK)
	
	# Draw players
	draw_circle(hex_nodes[player1_node], 15, Color.MAGENTA)
	draw_circle(hex_nodes[player2_node], 15, Color.GREEN)
	
	# Draw selection
	if selected_player == 1:
		draw_circle(hex_nodes[player1_node], 18, Color.YELLOW, false, 3)
	elif selected_player == 2:
		draw_circle(hex_nodes[player2_node], 18, Color.YELLOW, false, 3)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(pos: Vector2):
	
	# Find closest node
	var closest_node = -1
	var closest_distance = 999999.0
	for i in range(hex_nodes.size()):
		var distance = pos.distance_to(hex_nodes[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_node = i
	
	if closest_distance > 30:
		return
	
	# Check if clicking on player 1
	if closest_node == player1_node:
		if current_turn == 1:
			selected_player = 1
	
	# Check if clicking on player 2
	elif closest_node == player2_node:
		if current_turn == 2:
			selected_player = 2
	
	# Check if moving selected player
	elif selected_player > 0:
		var current_node = player1_node if selected_player == 1 else player2_node
		var neighbors = get_hex_neighbors(current_node)
		
		if closest_node in neighbors and closest_node != player1_node and closest_node != player2_node:
			# Check if path is blocked
			var path_key = get_path_key(current_node, closest_node)
			if not blocked_paths.has(path_key):
				if selected_player == 1:
					player1_node = closest_node
					current_turn = 2
				elif selected_player == 2:
					player2_node = closest_node
					current_turn = 1
				selected_player = 0
	
	queue_redraw()

func draw_diamond_path_simple(from: Vector2, to: Vector2, fill_color: Color):
	# Create diamond shape that fits within triangular areas
	var center = (from + to) / 2.0
	var direction = (to - from).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var distance = from.distance_to(to)
	# CORRECTED: Triangles have vertices at node CENTERS (confirmed by Ezert)
	# For equilateral triangle with side = distance:
	# - Height = distance * sqrt(3) / 2
	# - Distance from vertex to centroid = (2/3) * height = distance * sqrt(3) / 3
	# - Diamond width = distance from centroid to opposite side = distance / (2 * sqrt(3))
	var diamond_width = distance / (2.0 * sqrt(3.0))
	
	# Diamond vertices with sharp points exactly at node centers
	var outer_vertices = PackedVector2Array()
	outer_vertices.append(from)  # Sharp point exactly at 'from' node center
	outer_vertices.append(center + perpendicular * diamond_width)
	outer_vertices.append(to)    # Sharp point exactly at 'to' node center
	outer_vertices.append(center - perpendicular * diamond_width)
	
	# Draw diamond without margin - clean solid color
	draw_colored_polygon(outer_vertices, fill_color)

func generate_random_blocked_paths():
	# Collect all possible paths
	var all_paths = []
	for i in range(hex_nodes.size()):
		var neighbors = get_hex_neighbors(i)
		for neighbor_idx in neighbors:
			if neighbor_idx > i:  # Avoid duplicates
				all_paths.append([i, neighbor_idx])
	
	# Randomly block 50% of paths
	var paths_to_block = all_paths.size() / 2
	all_paths.shuffle()  # Randomize order
	
	for i in range(paths_to_block):
		var path = all_paths[i]
		var path_key = get_path_key(path[0], path[1])
		blocked_paths[path_key] = true
	
	print("Blocked ", blocked_paths.size(), " out of ", all_paths.size(), " paths")

func get_path_key(node1: int, node2: int) -> String:
	# Create consistent key for path regardless of direction
	var min_node = min(node1, node2)
	var max_node = max(node1, node2)
	return str(min_node) + "-" + str(max_node)