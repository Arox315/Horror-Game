extends Node
## The ServerRequests provide methods that send requests from clients to the server to perform actions

# ----- Scene Node deletion -----

## Sends a request to the server to delete the [param node].
## [br][b]Note[/b]: This request can delete either scene nodes or spawned nodes.
## For deleting spawned nodes it is recomended to use [method Node.queue_free] instead of this request.
## [color=yellow]Deleteing scene nodes will cause desync issues on late-join clients[/color].
## @experimental
func send_delete_request(node: Node) -> void:
	var node_path: NodePath = node.get_path()
	if node_path.is_empty(): return

	if multiplayer.is_server():
		_request_delete_server.rpc(1, node_path)
	else:
		_request_delete.rpc_id(1, node_path)


@rpc("reliable", "any_peer", "call_local")
func _request_delete(node_path: NodePath) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_delete_server.rpc(sender_id, node_path)


@rpc("reliable", "any_peer", "call_local")
func _request_delete_server(sender_id: int, node_path: NodePath) -> void:
	if not multiplayer.is_server(): return
	if not Utilities.get_player_by_peer_id(sender_id): return # Basic check if the player sending the request exists
	# More potential validation...
	var node = get_node_or_null(node_path)
	if node: node.queue_free()


# ----- Effect requests -----

## Sends a request to the server to remove an effect from the [param target] 
func send_remove_effect_request(target: Node3D, effect_id: int) -> void:
	if not target: return
	if multiplayer.is_server():
		_request_remove_effect_server(1, target.get_path(), effect_id)
	else:
		_request_remove_effect.rpc_id(1, target.get_path(), effect_id)


@rpc("reliable", "any_peer", "call_local")
func _request_remove_effect(target_path: NodePath, effect_id: int) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_remove_effect_server(sender_id, target_path, effect_id)


func _request_remove_effect_server(_sender_id: int, target_path: NodePath, effect_id:int) -> void:
	if not multiplayer.is_server(): return
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id: return
	
	var ec = target.get_node_or_null("EffectsComponent") as EffectsComponent
	if ec: ec.remove_effect(effect_id)


## Sends a request to the server to add an effect to the [param target] 
func send_add_effect_request(target: Node3D, effect_id: int) -> void:
	if not target: return
	if multiplayer.is_server():
		_request_add_effect_server(1, target.get_path(), effect_id)
	else:
		_request_add_effect.rpc_id(1, target.get_path(), effect_id)


@rpc("reliable", "any_peer", "call_local")
func _request_add_effect(target_path: NodePath, effect_id: int) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_add_effect_server(sender_id, target_path, effect_id)


func _request_add_effect_server(_sender_id: int, target_path: NodePath, effect_id: int) -> void:
	if not multiplayer.is_server(): return
	if not EffectsTable.TABLE.get(effect_id): return
	
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id: return
	
	var ec = target.get_node_or_null("EffectsComponent") as EffectsComponent
	if ec: ec.add_effect(effect_id)
