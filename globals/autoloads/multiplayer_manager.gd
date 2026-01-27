extends Node

signal client_joined(peer_id: int)
signal all_peers_ready

const SERVER_PORT: int = 42069
const SERVER_IP: String = "localhost"

var player_names: Dictionary[int, String] = {}
var ready_peers: Dictionary[int,bool] = {}


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
	
	player_names[1] = nickname
	
	print("Lobby created!")


func join_lobby(nickname: String) -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	peer.create_client(SERVER_IP,SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server.bind(peer.get_unique_id(), nickname))
	
	print("Joined lobby!")


func load_lobby() -> void:
	print("Loading lobby...")
	SceneManager.start_loading_scene(SceneManager.scene_id.LOBBY, false)


func terminate_connection() -> void:
	print("Connection terminated. Loading main menu...")
	if multiplayer.multiplayer_peer.get_connection_status() == multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		_delete_ready_peer.rpc(multiplayer.multiplayer_peer.get_unique_id())
		_delete_player_name.rpc(multiplayer.multiplayer_peer.get_unique_id())
		
	ready_peers.clear()
	player_names.clear()
	
	SceneManager.start_loading_scene(SceneManager.scene_id.MAIN_MENU)
	multiplayer.multiplayer_peer = null
	_disconnect_signals()


@rpc("reliable", "any_peer")
func client_ready() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if sender_id == 0: #called outside rpc (host)
		sender_id = 1
	
	ready_peers[sender_id] = true
	
	print("Client %s ready." % sender_id)
	
	if _all_clients_ready():
		ServerRequests.send_emit_signal_global_request(self, all_peers_ready)


@rpc("reliable", "any_peer")
func set_clinet_not_ready() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0: #called outside rpc (host)
		sender_id = 1
	ready_peers[sender_id] = false


func _all_clients_ready() -> bool:
	for ready_peer_id in ready_peers.keys():
		if not ready_peers[ready_peer_id]: 
			return false
	return true


@rpc("reliable", "any_peer")
func _delete_ready_peer(peer_id) -> void:
	ready_peers.erase(peer_id)


@rpc("reliable", "any_peer")
func _delete_player_name(peer_id) -> void:
	print("Deleting name for peer %s" % peer_id)
	player_names.erase(peer_id)


func _on_server_disconnected() -> void:
	print("Lobby has been disbanded.")
	terminate_connection()


func _on_connected_to_server(peer_id: int, nickname: String):
	_register_player_name.rpc(peer_id, nickname)


@rpc("reliable", "any_peer", "call_local")
func _register_player_name(peer_id: int, nickname: String) -> void:
	print("Player name: %s registered." % nickname)
	player_names[peer_id] = nickname
	await get_tree().physics_frame
	client_joined.emit(peer_id)
	


func _disconnect_signals() -> void:
	if multiplayer.server_disconnected.has_connections():
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	
	if multiplayer.connected_to_server.has_connections():
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
