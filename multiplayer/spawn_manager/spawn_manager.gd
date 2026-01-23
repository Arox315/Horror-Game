class_name SpawnManager
extends Node

var multiplayer_player_scene: PackedScene = preload("uid://c7ksecespxm2u")
var players_spawn_point: Marker3D
var current_scene : Node

var ready_peers: Dictionary = {1: false}


func _enter_tree() -> void:
	for peer in multiplayer.get_peers():
		ready_peers[peer] = false


func _ready() -> void:
	if not multiplayer.is_server():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
		
	current_scene = get_tree().current_scene
	players_spawn_point = current_scene.get_node("PlayersSpawnPoint")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	ready_peers[1] = true
	_spawn_player(1)
	
	#_spawn_player()
	#
	#await get_tree().physics_frame
	#
	#for peer in multiplayer.get_peers():
		#_spawn_player(peer)


@rpc("reliable", "any_peer")
func client_ready() -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	ready_peers[peer_id] = true
	
	if all_clients_ready(): 
		_spawn_players()


func _spawn_players() -> void:
	#_spawn_player(1)
	
	for peer in multiplayer.get_peers():
		_spawn_player(peer)


func all_clients_ready() -> bool:
	for peer_id in ready_peers.keys():
		if not ready_peers[peer_id]: 
			return false
	return true


func _on_peer_connected(peer_id: int) -> void:
	print("Player: %s connected!" % peer_id)
	ready_peers[peer_id] = false


func _on_peer_disconnected(peer_id: int) -> void:
	print("Player: %s disconnected!" % peer_id)
	_delete_player(peer_id)


func _spawn_player(peer_id: int = 1) -> void:
	if not multiplayer.is_server(): return
	
	var player_to_spawn = multiplayer_player_scene.instantiate()
	player_to_spawn.name = str(peer_id)
	player_to_spawn.transform.origin = players_spawn_point.transform.origin
	current_scene.call_deferred("add_child", player_to_spawn)


func _delete_player(peer_id: int) -> void:
	if not current_scene.has_node(str(peer_id)):
		return
	
	current_scene.get_node(str(peer_id)).queue_free()
