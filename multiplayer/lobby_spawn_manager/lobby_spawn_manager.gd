class_name LobbySpawnManager
extends Node

var connected_player_banner_scene: PackedScene = preload("uid://csixnn6wfsgjd")
var connected_players: VBoxContainer

var connected_peers: Array[int]

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	MultiplayerManager.client_connected.connect(_on_client_connected)
	
	connected_players = get_parent().get_node("%ConnectedPlayers")
	
	_add_connected_player_banner()


#func _process(_delta: float) -> void:
	#if connected_peers.is_empty(): return
	#for peer in connected_peers:
		#if MultiplayerManager.ready_clients.get(peer, false):
			#_add_connected_player_banner(peer)
			#connected_peers.pop_at(connected_peers.find(peer))


func _on_peer_connected(peer_id: int) -> void:
	print("Player: %s connected!" % peer_id)
	#connected_peers.append(peer_id)
	_add_connected_player_banner(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Player: %s disconnected!" % peer_id)
	_delete_connected_player_banner(peer_id)


func _on_client_connected(peer_id: int) -> void:
	connected_players.get_node(str(peer_id)).text = MultiplayerManager.player_names[peer_id]


func _add_connected_player_banner(peer_id: int = 1) -> void:
	var connected_player_banner = connected_player_banner_scene.instantiate()
	connected_player_banner.name = str(peer_id)
	connected_player_banner.text = MultiplayerManager.player_names.get(peer_id, "Connecting player...")
	connected_player_banner.set_multiplayer_authority(1)
	connected_players.add_child(connected_player_banner)


func _delete_connected_player_banner(peer_id: int) -> void:
	if not connected_players.has_node(str(peer_id)): return
	connected_players.get_node(str(peer_id)).queue_free()
