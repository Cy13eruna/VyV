# res://src/multiplayer/NetworkManager.gd
extends Node

const DEFAULT_PORT = 12345
const DEFAULT_IP = "127.0.0.1"

func _ready() -> void:
	# Check terminal arguments (e.g., godot -- --server)
	var args = OS.get_cmdline_args()
	
	if "--server" in args:
		host_game()
	elif "--client" in args:
		join_game()

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, 4) # Maximum 4 players
	if error != OK:
		print("Network: Error creating server: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Network: Server started on port ", DEFAULT_PORT)

func join_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	if error != OK:
		print("Network: Error connecting to server: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Network: Attempting to connect to ", DEFAULT_IP)