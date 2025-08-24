extends Control


func _on_host_button_pressed() -> void:
	hide()
	MultiplayerManager.host_game()


func _on_join_button_pressed() -> void:
	hide()
	MultiplayerManager.join_game()
