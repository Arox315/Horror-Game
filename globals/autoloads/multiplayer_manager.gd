extends Node

signal client_connected(peer_id: int)

const SERVER_PORT: int = 42069
const SERVER_IP: String = "localhost"

var player_names: Dictionary = {}
var ready_clients: Dictionary = {}


func _ready() -> void:
	multiplayer.allow_object_decoding = true
	var sync := MultiplayerSynchronizer.new()
	var config := SceneReplicationConfig.new()
	config.add_property(^":player_names")
	sync.name = "PlayerDataSync"
	sync.replication_config = config
	add_child(sync)


func create_lobby(nickname: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	#_connect_signals()
	#multiplayer.peer_connected.connect(_spawn_player)
	#multiplayer.peer_disconnected.connect(_delete_player)
	player_names[1] = nickname
	ready_clients[1] = true
	
	print("Lobby created!")


func join_lobby(nickname: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	peer.create_client(SERVER_IP,SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected.bind(peer.get_unique_id(), nickname))
	
	print("Joined lobby!")


func _on_server_disconnected() -> void:
	print("Lobby has been disbanded.")
	terminate_connection()


func _on_connected(peer_id: int, nickname: String):
	_register_player_name.rpc(peer_id, nickname)
	#set_client_ready.rpc(peer_id)


@rpc("reliable", "any_peer", "call_local")
func set_client_ready(peer_id) -> void:
	ready_clients[peer_id] = true


@rpc("reliable", "any_peer", "call_local")
func set_client_not_ready(peer_id) -> void:
	ready_clients[peer_id] = false


func all_clients_ready() -> bool:
	for value in ready_clients.values():
		if not value:
			return false
	return true



@rpc("any_peer","call_local")
func _register_player_name(peer_id: int, nickname: String) -> void:
	player_names[peer_id] = nickname
	
	#call_deferred("emit_signal","client_connected", peer_id)
	await  get_tree().physics_frame
	client_connected.emit(peer_id)


func load_lobby() -> void:
	print("Loading lobby...")
	SceneManager.start_loading_scene(SceneManager.scene_id.LOBBY)
	#SceneManager.load_scene()


func terminate_connection() -> void:
	print("Connection terminated. Loading main menu...")
	SceneManager.start_loading_scene(SceneManager.scene_id.MAIN_MENU)
	multiplayer.multiplayer_peer = null
	_disconnect_signals()


@rpc("reliable", "authority", "call_local")
func load_new_scene_from_id(id: int) -> void:
	get_tree().call_deferred("change_scene_to_packed", Utilities.STAGES[id])


func _disconnect_signals() -> void:
	if multiplayer.server_disconnected.has_connections():
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
