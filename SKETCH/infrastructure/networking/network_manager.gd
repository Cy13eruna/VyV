# 🌐 NETWORK MANAGER
# Purpose: Client-server networking for multiplayer
# Layer: Infrastructure/Networking

extends RefCounted

class_name NetworkManager

signal player_connected(player_id: int)
signal player_disconnected(player_id: int)
signal game_state_received(state: Dictionary)
signal command_received(command: Dictionary)

# Network configuration
var is_server: bool = false
var is_client: bool = false
var server_port: int = 7777
var max_players: int = 8

# Network state
var connected_players: Dictionary = {}
var local_player_id: int = -1
var network_peer: MultiplayerPeer

# Command queue for lag compensation
var command_queue: Array = []
var last_processed_tick: int = 0
var current_tick: int = 0

# Initialize as server
func start_server(port: int = 7777) -> bool:
	server_port = port
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	
	if error != OK:
		print("❌ Failed to start server on port %d" % port)
		return false
	
	network_peer = peer
	multiplayer.multiplayer_peer = peer
	is_server = true
	local_player_id = 1
	
	# Connect server signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	print("✅ Server started on port %d" % port)
	return true

# Connect to server as client
func connect_to_server(address: String, port: int = 7777) -> bool:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		print("❌ Failed to connect to %s:%d" % [address, port])
		return false
	
	network_peer = peer
	multiplayer.multiplayer_peer = peer
	is_client = true
	
	# Connect client signals
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("🔄 Connecting to %s:%d..." % [address, port])
	return true

# Disconnect from network
func disconnect_network() -> void:
	if network_peer:
		network_peer.close()
		network_peer = null
	
	multiplayer.multiplayer_peer = null
	is_server = false
	is_client = false
	connected_players.clear()
	
	print("🔌 Disconnected from network")

# Send command to all players
@rpc("any_peer", "call_local", "reliable")
func send_command(command: Dictionary) -> void:
	command["tick"] = current_tick
	command["sender_id"] = multiplayer.get_remote_sender_id()
	
	if is_server:
		# Server validates and broadcasts
		if _validate_command(command):
			command_queue.append(command)
			_broadcast_command.rpc(command)
	else:
		# Client sends to server for validation
		_receive_command.rpc_id(1, command)

# Broadcast validated command (server only)
@rpc("authority", "call_local", "reliable")
func _broadcast_command(command: Dictionary) -> void:
	command_received.emit(command)

# Receive command on server for validation
@rpc("any_peer", "call_remote", "reliable")
func _receive_command(command: Dictionary) -> void:
	if is_server and _validate_command(command):
		command_queue.append(command)
		_broadcast_command.rpc(command)

# Send game state (server only)
@rpc("authority", "call_remote", "reliable")
func send_game_state(state: Dictionary) -> void:
	if is_server:
		_receive_game_state.rpc(state)

# Receive game state (clients only)
@rpc("authority", "call_local", "reliable")
func _receive_game_state(state: Dictionary) -> void:
	game_state_received.emit(state)

# Process network tick
func process_tick() -> void:
	current_tick += 1
	
	if is_server:
		_process_command_queue()

# Validate command (server-side)
func _validate_command(command: Dictionary) -> bool:
	# Basic validation - extend as needed
	if not ("type" in command and "sender_id" in command):
		return false
	
	var sender_id = command.sender_id
	if sender_id not in connected_players and sender_id != 1:
		return false
	
	return true

# Process queued commands (server only)
func _process_command_queue() -> void:
	if not is_server:
		return
	
	# Sort commands by tick
	command_queue.sort_custom(func(a, b): return a.tick < b.tick)
	
	# Process commands up to current tick
	var processed = []
	for command in command_queue:
		if command.tick <= current_tick:
			# Process command
			processed.append(command)
		else:
			break
	
	# Remove processed commands
	for command in processed:
		command_queue.erase(command)
	
	last_processed_tick = current_tick

# Network event handlers
func _on_player_connected(id: int) -> void:
	connected_players[id] = {
		"id": id,
		"connected_at": Time.get_unix_time_from_system()
	}
	
	print("👤 Player %d connected" % id)
	player_connected.emit(id)

func _on_player_disconnected(id: int) -> void:
	if id in connected_players:
		connected_players.erase(id)
	
	print("👤 Player %d disconnected" % id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	local_player_id = multiplayer.get_unique_id()
	print("✅ Connected to server as player %d" % local_player_id)

func _on_connection_failed() -> void:
	print("❌ Failed to connect to server")

func _on_server_disconnected() -> void:
	print("🔌 Server disconnected")
	disconnect_network()

# Get network statistics
func get_network_stats() -> Dictionary:
	return {
		"is_server": is_server,
		"is_client": is_client,
		"connected_players": connected_players.size(),
		"local_player_id": local_player_id,
		"current_tick": current_tick,
		"command_queue_size": command_queue.size(),
		"last_processed_tick": last_processed_tick
	}