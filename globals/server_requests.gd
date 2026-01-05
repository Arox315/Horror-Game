extends Node


# ----- Node deletion -----

## Sends a request to the server to delete the [param node].
func send_delete_request(node: Node) -> void:
	if multiplayer.is_server():
		_request_delete_server.rpc(1, node.get_path())
	else:
		_request_delete.rpc_id(1, node.get_path())


@rpc("reliable", "any_peer", "call_local")
func _request_delete(node_path: NodePath) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_delete_server.rpc(sender_id, node_path)


@rpc("reliable", "any_peer", "call_local")
func _request_delete_server(sender_id: int, node_path: NodePath) -> void:
	if not Utilities.get_player_by_peer_id(sender_id): return # Basic check if the player sending the request exists
	# More potential validation...
	var node = get_node_or_null(node_path)
	if node: node.queue_free()
