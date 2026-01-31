extends Control

@onready var nickname_panel: LineEdit = $Wrapper/NicknamePanel

func _on_host_btn_pressed() -> void:
	var nickname = nickname_panel.text if nickname_panel.text else "Host"
	MultiplayerManager.create_server(nickname)
	MultiplayerManager.load_lobby()


func _on_join_btn_pressed() -> void:
	var nickname = nickname_panel.text if nickname_panel.text else "Player"
	MultiplayerManager.join_server(nickname)
