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


# ----- Signal emit -----

## Sends a request to the server to emit a [param signal] from the [param target].
## [br][color=yellow]This request emits the specified signal only if the sender is the target[/color].
## @experimental
func send_emit_signal_request(target: Node, signal_to_emit: Signal, ...signal_args: Array) -> void:
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_emit_signal_server(1, target_path, signal_to_emit.get_name(), signal_args)
	else:
		_request_emit_signal.rpc_id(1, target_path, signal_to_emit.get_name(), signal_args)


@rpc("reliable","any_peer","call_local")
func _request_emit_signal(target_path: NodePath, signal_name: StringName, signal_args: Array) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_emit_signal_server(sender_id, target_path, signal_name, signal_args)


func _request_emit_signal_server(sender_id: int, target_path: NodePath, signal_name: StringName, signal_args: Array) -> void:
	if not multiplayer.is_server(): return
	var target = get_node_or_null(target_path)
	if not target: return
	
	if target.get_multiplayer_authority() != sender_id: return
	
	if signal_args.is_empty():
		target.emit_signal(signal_name)
	else:
		target.emit_signal.callv([signal_name] + signal_args)


## Sends a request to the server to emit a signal on all [param target] peers
## @experimental
func send_emit_signal_global_request(target: Node, signal_to_emit: Signal, ...signal_args: Array) -> void:
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	_request_emit_signal_global.rpc(1, target_path, signal_to_emit.get_name(), signal_args)


@rpc("reliable","any_peer","call_local")
func _request_emit_signal_global(_sender_id: int, target_path: NodePath, signal_name: StringName, signal_args: Array) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	if signal_args.is_empty():
		target.emit_signal(signal_name)
	else:
		target.emit_signal.callv([signal_name] + signal_args)


# ----- Effect requests -----

## Sends a request to the server to remove an effect from the [param target].
## If [member force_remove] is true, the effect will be removed despite being permanent.
## @experimental
func send_remove_effect_request(target: Node3D, effect_id: int, force_remove: bool = false) -> void:
	if not target: return
	if multiplayer.is_server():
		_request_remove_effect_server(1, target.get_path(), effect_id, force_remove)
	else:
		_request_remove_effect.rpc_id(1, target.get_path(), effect_id, force_remove)


@rpc("reliable", "any_peer", "call_local")
func _request_remove_effect(target_path: NodePath, effect_id: int, force_remove: bool = false) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_remove_effect_server(sender_id, target_path, effect_id, force_remove)


func _request_remove_effect_server(_sender_id: int, target_path: NodePath, effect_id:int, force_remove: bool = false) -> void:
	if not multiplayer.is_server(): return
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id: return
	
	var ec = target.get_node_or_null("EffectsComponent") as EffectsComponent
	if ec: ec.remove_effect(effect_id, force_remove)


## Sends a request to the server to add an effect to the [param target]
## @experimental
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


# ----- Health requests -----

## Sends a request to the server to damaga the [param target] for [amount]
## @experimental
func send_damage_request(target: Node, amount: int) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_damage_server(1, target_path, amount)
	else:
		_request_damage.rpc_id(1, target_path, amount)


@rpc("reliable","any_peer","call_local")
func _request_damage(target_path: NodePath, amount: int) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_damage_server(sender_id, target_path, amount)


func _request_damage_server(_sender_id: int, target_path: NodePath, amount: int) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	
	#if target.get_multiplayer_authority() != sender_id:
		#return
	
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc: hc.damage(amount)


## Sends a request to the server to heal the [param target] for [amount]
## @experimental
func send_heal_request(target: Node, amount: int) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_heal_server(1, target_path, amount)
	else:
		_request_heal.rpc_id(1, target_path, amount)


@rpc("reliable","any_peer","call_local")
func _request_heal(target_path: NodePath, amount: int) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_heal_server(sender_id, target_path, amount)


func _request_heal_server(_sender_id: int, target_path: NodePath, amount: int) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id:
		#return
	
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc: hc.heal(amount)


## Sends a request to the server to reset current health of the [param target]
## @experimental
func send_reset_current_health_request(target: Node) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_reset_current_health_server(1, target_path)
	else:
		_request_reset_current_health.rpc_id(1, target_path)


@rpc("reliable","any_peer","call_local")
func _request_reset_current_health(target_path: NodePath) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_reset_current_health_server(sender_id, target_path)


func _request_reset_current_health_server(_sender_id: int, target_path: NodePath) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id:
		#return
	
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc: hc.reset_current_health()



## Sends a request to the server to force set current health of the [param target] to 0
## @experimental
func send_force_kill_request(target: Node) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_force_kill_server(1, target_path)
	else:
		_request_force_kill_health.rpc_id(1, target_path)


@rpc("reliable","any_peer","call_local")
func _request_force_kill_health(target_path: NodePath) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_reset_current_health_server(sender_id, target_path)


func _request_force_kill_server(_sender_id: int, target_path: NodePath) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	
	#if target.get_multiplayer_authority() != sender_id:
		#return
	
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc: hc.force_kill()


## Sends a request to the server to set Invulnerability for the [param target] to [param value]
## @experimental
func send_set_invulnerability_request(target: Node, value: bool) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_set_invulnerability_server(1, target_path, value)
	else:
		_request_set_invulnerability.rpc_id(1, target_path, value)


@rpc("reliable","any_peer","call_local")
func _request_set_invulnerability(target_path:NodePath, value: bool) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_set_invulnerability_server(sender_id, target_path, value)


func _request_set_invulnerability_server(_sender_id: int, target_path: NodePath, value: bool) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.is_invulnerable = value


## Sends a request to the server to set God Mode for the [param target] to [param value]
## @experimental
func send_set_godmode_request(target: Node, value: bool) -> void:
	if not target: return
	
	var target_path: NodePath = target.get_path()
	if target_path.is_empty(): return
	
	if multiplayer.is_server():
		_request_set_godmode_server(1, target_path, value)
	else:
		_request_set_godmode.rpc_id(1, target_path, value)


@rpc("reliable","any_peer","call_local")
func _request_set_godmode(target_path:NodePath, value: bool) -> void:
	if not multiplayer.is_server(): return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_request_set_godmode_server(sender_id, target_path, value)


func _request_set_godmode_server(_sender_id: int, target_path: NodePath, value: bool) -> void:
	var target = get_node_or_null(target_path)
	if not target: return
	var hc = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.is_god_mode = value
