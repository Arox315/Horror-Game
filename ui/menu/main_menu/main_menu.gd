extends Control

@onready var nickname_panel: LineEdit = $Wrapper/NicknamePanel


func _ready() -> void:
	if MultiplayerManager.is_valid_multiplayer_connection():
		await get_tree().physics_frame
		var game_manager = get_tree().current_scene
		game_manager.update_synchronizers.rpc()


func _on_host_btn_pressed() -> void:
	var nickname = nickname_panel.text if nickname_panel.text else "Host"
	MultiplayerManager.create_server(nickname)


func _on_join_btn_pressed() -> void:
	var nickname = nickname_panel.text if nickname_panel.text else "Player"
	MultiplayerManager.join_server(nickname)
