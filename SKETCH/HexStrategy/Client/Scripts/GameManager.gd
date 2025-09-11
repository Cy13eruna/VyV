extends Node2D

@export var board_width: int = 8
@export var board_height: int = 6
@export var hex_size: float = 35.0

var game_board: Dictionary = {}
var players: Array = []
var current_player_index: int = 0
var selected_unit: Dictionary = {}

# Colors for game entities
var board_color: Color = Color.WHITE
var node_color: Color = Color.BLACK
var path_color: Color = Color.LIGHT_GRAY

func _ready():
	print("GameManager _ready called")
	initialize_game()
	print("Game initialized, forcing redraw...")
	queue_redraw()
	call_deferred("queue_redraw")
	
	# Test click detection
	print("Testing click detection...")
	print("Board has ", game_board.nodes.size(), " nodes")
	if game_board.nodes.size() > 0:
		print("First node position: ", game_board.nodes[0].position)
		print("Last node position: ", game_board.nodes[-1].position)
		print("Player 1 unit at: ", players[0].units[0].current_node.position)
		print("Player 2 unit at: ", players[1].units[0].current_node.position)

func initialize_game():
	# Create players
	players.append({
		"id": 0,
		"name": "Player 1", 
		"color": Color.RED,
		"units": []
	})
	players.append({
		"id": 1,
		"name": "Player 2",
		"color": Color.BLUE, 
		"units": []
	})
	
	# Create board
	game_board = {
		"width": board_width,
		"height": board_height,
		"nodes": [],
		"paths": [],
		"domains": []
	}
	
	generate_hexagonal_grid()
	create_domains()
	spawn_initial_units()
	
	print("Game initialized with hexagonal board")

func generate_hexagonal_grid():
	var node_id = 0
	
	# Generate hexagonal grid nodes
	for row in range(board_height):
		for col in range(board_width):
			var position = hex_to_pixel(col, row)
			var node = {
				"id": node_id,
				"position": position,
				"paths": [],
				"occupying_unit": {},
				"controlling_player": {}
			}
			game_board.nodes.append(node)
			node_id += 1
	
	# Create paths between adjacent nodes
	create_hexagonal_paths()

func hex_to_pixel(col: int, row: int) -> Vector2:
	var x = hex_size * (3.0 / 2.0 * col) + 200
	var y = hex_size * (sqrt(3.0) * (row + 0.5 * (col & 1))) + 150
	return Vector2(x, y)

func create_hexagonal_paths():
	var path_id = 0
	
	# Create paths for each node to its 6 neighbors
	for i in range(game_board.nodes.size()):
		var node = game_board.nodes[i]
		var col = i % board_width
		var row = i / board_width
		
		# Get 6 hexagonal neighbors
		var neighbors = get_hex_neighbors(col, row)
		
		for neighbor_pos in neighbors:
			var neighbor_col = neighbor_pos.x
			var neighbor_row = neighbor_pos.y
			
			if neighbor_col >= 0 and neighbor_col < board_width and neighbor_row >= 0 and neighbor_row < board_height:
				var neighbor_index = neighbor_row * board_width + neighbor_col
				if neighbor_index < game_board.nodes.size():
					var neighbor = game_board.nodes[neighbor_index]
					
					# Avoid duplicate paths
					var path_exists = false
					for existing_path in game_board.paths:
						if (existing_path.from_node == node and existing_path.to_node == neighbor) or (existing_path.from_node == neighbor and existing_path.to_node == node):
							path_exists = true
							break
					
					if not path_exists:
						var path = {
							"id": path_id,
							"from_node": node,
							"to_node": neighbor,
							"is_blocked": false
						}
						game_board.paths.append(path)
						node.paths.append(path)
						neighbor.paths.append(path)
						path_id += 1

func get_hex_neighbors(col: int, row: int) -> Array:
	var neighbors = []
	
	if col % 2 == 0: # Even column
		neighbors = [
			Vector2i(col + 1, row),     # Right
			Vector2i(col + 1, row - 1), # Top-right
			Vector2i(col, row - 1),     # Top-left
			Vector2i(col - 1, row),     # Left
			Vector2i(col - 1, row - 1), # Bottom-left
			Vector2i(col, row + 1)      # Bottom-right
		]
	else: # Odd column
		neighbors = [
			Vector2i(col + 1, row),     # Right
			Vector2i(col + 1, row + 1), # Top-right
			Vector2i(col, row - 1),     # Top-left
			Vector2i(col - 1, row),     # Left
			Vector2i(col - 1, row + 1), # Bottom-left
			Vector2i(col, row + 1)      # Bottom-right
		]
	
	return neighbors

func get_node_at(col: int, row: int):
	if col < 0 or col >= board_width or row < 0 or row >= board_height:
		return null
	
	var index = row * board_width + col
	if index < game_board.nodes.size():
		return game_board.nodes[index]
	return null

func create_domains():
	var domain_id = 0
	
	for center_node in game_board.nodes:
		var domain = {
			"id": domain_id,
			"center_node": center_node,
			"adjacent_nodes": [],
			"domain_paths": [],
			"controlling_player": {}
		}
		
		# Add adjacent nodes to domain
		for path in center_node.paths:
			domain.adjacent_nodes.append(path.to_node)
			domain.domain_paths.append(path)
		
		game_board.domains.append(domain)
		domain_id += 1

func spawn_initial_units():
	# Spawn units for each player at opposite corners
	var player1_start_node = game_board.nodes[0]
	var player2_start_node = game_board.nodes[game_board.nodes.size() - 1]
	
	var unit1 = {
		"id": 0,
		"owner": players[0],
		"current_node": player1_start_node,
		"type": "Basic",
		"movement_range": 1
	}
	
	var unit2 = {
		"id": 1,
		"owner": players[1],
		"current_node": player2_start_node,
		"type": "Basic",
		"movement_range": 1
	}
	
	players[0].units.append(unit1)
	players[1].units.append(unit2)
	
	player1_start_node.occupying_unit = unit1
	player2_start_node.occupying_unit = unit2

func _draw():
	draw_board()
	draw_nodes()
	draw_paths()
	draw_units()

func draw_board():
	# Draw board background
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), board_color)
	print("GameManager _draw called - board drawn")
	
	# Debug: Print board info (only once)
	if game_board.nodes.size() > 0 and not has_meta("debug_printed"):
		print("Drawing ", game_board.nodes.size(), " nodes, ", game_board.paths.size(), " paths")
		set_meta("debug_printed", true)

func draw_nodes():
	for node in game_board.nodes:
		draw_circle(node.position, 8, node_color)

func draw_paths():
	for path in game_board.paths:
		draw_line(path.from_node.position, path.to_node.position, path_color, 2)

func draw_units():
	for player in players:
		for unit in player.units:
			# Draw unit
			draw_circle(unit.current_node.position, 15, player.color)
			# Draw selection highlight
			if unit == selected_unit:
				draw_circle(unit.current_node.position, 18, Color.YELLOW, false, 3)
			# Draw click area for debugging
			draw_circle(unit.current_node.position, 80, Color.TRANSPARENT, false, 1)
			# Draw unit info
			var font = ThemeDB.fallback_font
			draw_string(font, unit.current_node.position + Vector2(-10, -25), "P" + str(player.id + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _unhandled_input(event):
	print("GameManager unhandled input: ", event)
	if event is InputEventMouseButton:
		print("GameManager mouse button - pressed: ", event.pressed, " position: ", event.position)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("GameManager left click at: ", event.position)
			handle_mouse_click(event.position)
			get_viewport().set_input_as_handled()

func handle_mouse_click(click_position: Vector2):
	print("=== CLICK DEBUG ===")
	print("Click position: ", click_position)
	print("Current player: ", current_player_index + 1)
	print("Selected unit: ", selected_unit)
	
	var clicked_node = get_node_at_position(click_position)
	if clicked_node == null:
		print("No node found at click position")
		return
	
	print("Clicked node ", clicked_node.id, " at position ", clicked_node.position)
	print("Node has unit: ", not clicked_node.occupying_unit.is_empty())
	if not clicked_node.occupying_unit.is_empty():
		print("Unit owner: ", clicked_node.occupying_unit.owner.name)
	
	if selected_unit.is_empty():
		# Select unit if clicking on current player's unit
		if not clicked_node.occupying_unit.is_empty():
			print("Found unit on node")
			if clicked_node.occupying_unit.owner == players[current_player_index]:
				selected_unit = clicked_node.occupying_unit
				print("✅ SELECTED unit ", selected_unit.id, " for player ", current_player_index + 1)
			else:
				print("❌ Cannot select opponent's unit")
		else:
			print("No unit on this node")
	else:
		# Try to move selected unit
		print("Trying to move unit ", selected_unit.id, " to node ", clicked_node.id)
		if can_move_unit(selected_unit, clicked_node):
			move_unit(selected_unit, clicked_node)
			print("✅ UNIT MOVED successfully")
			selected_unit = {}
			next_turn()
		else:
			print("❌ Cannot move to this position")
			# Check if clicking on own unit to reselect
			if not clicked_node.occupying_unit.is_empty() and clicked_node.occupying_unit.owner == players[current_player_index]:
				selected_unit = clicked_node.occupying_unit
				print("✅ RESELECTED unit ", selected_unit.id)
			else:
				selected_unit = {}
				print("Deselected unit")
	
	print("=== END CLICK DEBUG ===")
	queue_redraw()

func get_node_at_position(position: Vector2):
	var closest_node = null
	var closest_distance = 999999.0
	
	print("Searching for node near ", position)
	# Show only closest 3 nodes for readability
	var distances = []
	for i in range(game_board.nodes.size()):
		var node = game_board.nodes[i]
		var distance = node.position.distance_to(position)
		distances.append({"node": node, "distance": distance, "index": i})
	
	# Sort by distance
	distances.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Show closest 3
	for i in range(min(3, distances.size())):
		var data = distances[i]
		print("Node ", data.index, " at ", data.node.position, " distance: ", data.distance)
	
	# Check if closest is within range
	if distances.size() > 0 and distances[0].distance < 80:
		closest_node = distances[0].node
		closest_distance = distances[0].distance
		print("✅ Found closest node ", closest_node.id, " at distance ", closest_distance)
	else:
		print("❌ No node found within 80px radius")
	
	return closest_node

func can_move_unit(unit: Dictionary, target_node: Dictionary) -> bool:
	if not target_node.occupying_unit.is_empty():
		print("Target node occupied")
		return false
	
	# Check if target is adjacent
	for path in unit.current_node.paths:
		if (path.to_node == target_node or path.from_node == target_node) and not path.is_blocked:
			print("Valid move found")
			return true
	
	print("No valid path to target")
	return false

func move_unit(unit: Dictionary, target_node: Dictionary):
	unit.current_node.occupying_unit = {}
	unit.current_node = target_node
	target_node.occupying_unit = unit
	
	print("Unit ", unit.id, " moved to node ", target_node.id)

func next_turn():
	current_player_index = (current_player_index + 1) % players.size()
	print("Turn: Player ", current_player_index + 1)