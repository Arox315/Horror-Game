extends Node3D


func _ready() -> void:
	if multiplayer.is_server():
		var spawn_manager_scene = preload("uid://dkix426nuv2tl")
		var spawn_manager = spawn_manager_scene.instantiate()
		add_child(spawn_manager)
	
	#if not multiplayer.is_server():
		#await get_tree().create_timer(1).timeout
		#spawn_manager.client_ready.rpc_id(1)
