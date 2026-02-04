class_name GameManager
extends Node

@export var main_scene: Node = null: set = _set_main_scene

@onready var loading_screen: LoadingScreen = $LoadingScreen


func _set_main_scene(new_scene) -> void:
	main_scene = new_scene


@rpc("reliable", "any_peer", "call_local")
func update_synchronizers() -> void:
	for loaded_peer_id in MultiplayerManager.loaded_peers.keys():
		for sync: MultiplayerSynchronizer in get_tree().get_nodes_in_group("Synchronizers"):
			sync.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_IDLE
			sync.set_visibility_for(loaded_peer_id, true)


@rpc("reliable", "any_peer", "call_local")
func disable_synchronizers() -> void:
	for loaded_peer_id in MultiplayerManager.loaded_peers.keys():
		for sync: MultiplayerSynchronizer in get_tree().get_nodes_in_group("Synchronizers"):
			sync.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE
			sync.set_visibility_for(loaded_peer_id, false)
