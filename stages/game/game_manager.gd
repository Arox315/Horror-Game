class_name GameManager
extends Node

@export var current_scene: Node = null: set = _set_current_scene
 

func _ready() -> void:
	for sync: MultiplayerSynchronizer in get_tree().get_nodes_in_group("Synchronizers"):
		sync.set_visibility_for(0, true)


func _set_current_scene(new_scene) -> void:
	current_scene = new_scene


@rpc("reliable", "any_peer")
func set_synchronizers() -> void:
	for sync: MultiplayerSynchronizer in get_tree().get_nodes_in_group("Synchronizers"):
		sync.set_visibility_for(0, true)
