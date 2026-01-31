class_name LobbySpawnManager
extends Node

var lobby: Lobby

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	MultiplayerManager.peer_loaded.connect(_on_peer_loaded)
	lobby = get_parent()


func _on_peer_connected(peer_id: int) -> void:
	print("[%s] Player: %s connected!" % [self, peer_id])
	# send current scene id to connected client
	MultiplayerManager.set_server_current_scene.rpc_id(peer_id, MultiplayerManager.server_current_scene_id)
	# add connected clinet to the players list
	lobby.add_connected_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[%s] Player: %s disconnected!" % [self, peer_id])
	# delete the clinet from the player list for all connected clients
	lobby.delete_connected_player.rpc(peer_id)
	# delete disconnected player data (ready status, loaded status, nickname)
	MultiplayerManager.delete_peer_data(peer_id)


func _on_peer_loaded(peer_id: int) -> void:
	print("[%s] loading data for peer: %s" % [self, peer_id])
	await get_tree().physics_frame
	# load already connected players for the joined client
	lobby.add_already_connected_players.rpc_id(peer_id, peer_id)
	# add joined clinet to the playerts list for all connected clients
	lobby.add_connected_player.rpc(peer_id)
	# send update name of joined client to all connected clients
	lobby.update_connected_player_name.rpc(peer_id)
