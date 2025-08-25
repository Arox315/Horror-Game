extends Node

const SERVER_PORT: int = 42069
const SERVER_IP: String = "localhost"

var multiplayer_player_scene: PackedScene = preload("res://entities/character/character.tscn")
var players_spawn_point: Marker3D
var current_scene : Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()


func host_game() -> void:
	players_spawn_point = get_tree().current_scene.get_node("PlayersSpawnPoint")
	current_scene = get_tree().current_scene
	
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_spawn_player)
	multiplayer.peer_disconnected.connect(_delete_player)
	
	_spawn_player()
	print_debug("Joined as host! ID: %d" % peer.get_unique_id())


func join_game() -> void:
	peer.create_client(SERVER_IP,SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	print_debug("Joined as player! ID: %d" % peer.get_unique_id())

func _spawn_player(id: int = 1) -> void:
	if not multiplayer.is_server():
		return
	
	var player_to_spawn = multiplayer_player_scene.instantiate()
	player_to_spawn.name = str(id)
	player_to_spawn.transform.origin = players_spawn_point.transform.origin
	current_scene.call_deferred("add_child", player_to_spawn)


func _delete_player(id: int) -> void:
	if not current_scene.has_node(str(id)):
		return
	
	current_scene.get_node(str(id)).queue_free()


#@rpc("any_peer","reliable")
#func request_hide_interactable_popup(peer_id: int):
	#if not multiplayer.is_server():
		#return
	##var peer_id := multiplayer.get_remote_sender_id()
	#rpc_id(peer_id,"hide_popup")
#
#
#@rpc("any_peer","reliable")
#func request_show_interactable_popup(peer_id: int):
	#if not multiplayer.is_server():
		#return
	##var peer_id := multiplayer.get_remote_sender_id()
	#print(peer_id)
	#rpc_id(peer_id,"show_popup")
