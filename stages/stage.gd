extends Node3D


func _ready() -> void:
	if multiplayer.is_server():
		var spawn_manager_scene = preload("uid://dkix426nuv2tl")
		var spawn_manager = spawn_manager_scene.instantiate()
		add_child(spawn_manager)
