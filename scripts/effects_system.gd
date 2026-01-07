extends Node


func send_remove_effect_request(target: Node3D, effect_id: int) -> void:
	if multiplayer.is_server():
		_request_remove_effect_server(1, target.get_path(), effect_id)
	else:
		_request_remove_effect.rpc_id(1, target.get_path(), effect_id)


@rpc("reliable", "any_peer", "call_local")
func _request_remove_effect(target_path: NodePath, effect_id: int) -> void:
	if not multiplayer.is_server(): return
	
	var target_peer_id: int = multiplayer.get_remote_sender_id()
	_request_remove_effect_server(target_peer_id, target_path, effect_id)


func _request_remove_effect_server(target_peer_id: int, target_path: NodePath, effect_id:int) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	if target.get_multiplayer_authority() != target_peer_id: return
	
	var ec = target.get_node_or_null("EffectsComponent") as EffectsComponent
	if ec: ec.remove_effect_server(effect_id)


func send_add_effect_request(target: Node3D, effect_id: int) -> void:
	if multiplayer.is_server():
		_request_add_effect_server(1, target.get_path(), effect_id)
	else:
		_request_add_effect.rpc_id(1, target.get_path(), effect_id)


@rpc("reliable", "any_peer", "call_local")
func _request_add_effect(target_path: NodePath, effect_id: int) -> void:
	if not multiplayer.is_server(): return
	
	var target_peer_id: int = multiplayer.get_remote_sender_id()
	_request_add_effect_server(target_peer_id, target_path, effect_id)


func _request_add_effect_server(target_peer_id: int, target_path: NodePath, effect_id: int) -> void:
	if not EffectsTable.TABLE.get(effect_id): return
	
	var target = get_node_or_null(target_path)
	if not target: return
	
	if target.get_multiplayer_authority() != target_peer_id: return
	
	var ec = target.get_node_or_null("EffectsComponent") as EffectsComponent
	if ec: ec.add_effect(effect_id)
