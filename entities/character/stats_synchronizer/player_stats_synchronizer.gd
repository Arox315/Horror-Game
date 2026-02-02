extends Node


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	var sync := MultiplayerSynchronizer.new()
	var config := SceneReplicationConfig.new()
	config.add_property(^"..:current_speed")
	config.add_property(^"..:JUMP_VELOCITY")
	sync.name = "StatsSync"
	sync.replication_config = config
	sync.add_to_group("Synchronizers")
	add_child(sync)
