extends Node

signal peer_loaded(peer_id: int)
signal all_peers_ready
signal server_scene_received

const SERVER_PORT: int = 42069
const SERVER_IP: String = "localhost"

var player_names: Dictionary[int, String] = {}
var ready_peers: Dictionary[int,bool] = {}
var loaded_peers: Dictionary[int, bool] = {}

var server_current_scene_id: int = 0
var game_manager: GameManager


func _ready() -> void:
	multiplayer.allow_object_decoding = true
	var sync := MultiplayerSynchronizer.new()
	var config := SceneReplicationConfig.new()
	config.add_property(^":player_names")
	config.add_property(^":ready_peers")
	config.add_property(^":loaded_peers")
	sync.name = "PlayerDataSync"
	sync.replication_config = config
	add_child(sync)
	
	game_manager = get_tree().current_scene


func create_server(nickname: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	player_names[1] = nickname
	
	print("[%s] Server created!" % self)


func join_server(nickname: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	peer.create_client(SERVER_IP,SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server.bind(peer.get_unique_id(), nickname))
	
	_connect_to_server()
	print("[%s] Joining to the server..." % self)


func load_lobby() -> void:
	print("[%s] Loading lobby..." % self)
	SceneManager.start_loading_scene(SceneManager.scene_id.LOBBY, false)


func terminate_connection() -> void:
	print("[%s] Connection terminated. Loading main menu..." % self)
	if multiplayer.multiplayer_peer.get_connection_status() == multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		delete_peer_data.rpc(multiplayer.multiplayer_peer.get_unique_id())
	
	ready_peers.clear()
	player_names.clear()
	loaded_peers.clear()
	
	SceneManager.start_loading_scene(SceneManager.scene_id.MAIN_MENU)
	multiplayer.multiplayer_peer = null
	_disconnect_signals()


@rpc("reliable", "any_peer")
func client_loaded() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0: 
		sender_id = 1
	
	loaded_peers[sender_id] = true
	if sender_id != 1: 
		peer_loaded.emit(sender_id)
	
	print("[%s] Client %s loaded." % [self, sender_id])


@rpc("reliable", "any_peer")
func client_ready() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0: 	 #called outside rpc (host)
		sender_id = 1
	
	ready_peers[sender_id] = true
	if _all_clients_ready():
		ServerRequests.send_emit_signal_global_request(self, all_peers_ready)
	
	print("[%s] Client %s ready." % [self, sender_id])


@rpc("reliable", "any_peer")
func set_clinet_not_ready() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0: #called outside rpc (host)
		sender_id = 1
	ready_peers[sender_id] = false


@rpc("reliable", "any_peer", "call_local")
func set_server_current_scene(new_scene_id: int) -> void:
	server_current_scene_id = new_scene_id
	server_scene_received.emit()


func _connect_to_server() -> void:
	game_manager.loading_screen.start_connecting_to_server()


func _all_clients_ready() -> bool:
	for ready_peer_id in ready_peers.keys():
		if not ready_peers[ready_peer_id]: 
			return false
	return true


@rpc("reliable", "any_peer")
func delete_peer_data(peer_id: int) -> void:
	player_names.erase(peer_id)
	ready_peers.erase(peer_id)
	loaded_peers.erase(peer_id)


func _on_server_disconnected() -> void:
	print("[%s] Lobby has been disbanded." % self)
	terminate_connection()


func _on_connected_to_server(peer_id: int, nickname: String):
	_register_player_name.rpc_id(1, peer_id, nickname)


@rpc("reliable", "any_peer")
func _register_player_name(peer_id: int, nickname: String) -> void:
	print("[%s] Player name: %s registered." % [self, nickname])
	player_names[peer_id] = nickname
	await get_tree().physics_frame


func _disconnect_signals() -> void:
	if multiplayer.server_disconnected.has_connections():
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
