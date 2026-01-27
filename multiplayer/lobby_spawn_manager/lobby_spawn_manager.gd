class_name LobbySpawnManager
extends Node


var connected_players: VBoxContainer
var lobby: Lobby

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	MultiplayerManager.client_joined.connect(_on_client_joined)
	
	lobby = get_parent()
	connected_players = get_parent().get_node("%ConnectedPlayers")
	

func _on_peer_connected(peer_id: int) -> void:
	print("Player: %s connected!" % peer_id)
	lobby.add_connected_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Player: %s disconnected!" % peer_id)
	lobby.delete_connected_player.rpc(peer_id)
	MultiplayerManager._delete_player_name(peer_id)
	MultiplayerManager._delete_ready_peer(peer_id)


func _on_client_joined(peer_id: int) -> void:
	print("loading data for peer: %s" % peer_id)
	await get_tree().physics_frame
	# load already connected players for peer
	lobby.add_already_connected_players.rpc_id(peer_id, peer_id)
	
	# send add player to all connected peers
	lobby.add_connected_player.rpc(peer_id)
	# send update name to all peers
	lobby.update_connected_player_name.rpc(peer_id)
	
	pass
