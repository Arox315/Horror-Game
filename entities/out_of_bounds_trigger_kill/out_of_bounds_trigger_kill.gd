extends Area3D


func _on_body_entered(body: Node3D) -> void:
	ServerRequests.send_force_kill_request(body)
