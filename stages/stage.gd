extends Node3D


func _ready() -> void:
	if multiplayer.is_server():
		var spawn_manager_scene = preload("uid://dkix426nuv2tl")
		var spawn_manager = spawn_manager_scene.instantiate()
		add_child(spawn_manager)
	
	if MultiplayerManager.is_valid_multiplayer_connection():
		await get_tree().physics_frame
		var game_manager = get_tree().current_scene
		game_manager.update_synchronizers.rpc()
