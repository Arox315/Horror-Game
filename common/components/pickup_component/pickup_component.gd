class_name PickupComponent
extends Node

@export var drop_offset: Vector3 = Vector3(0, 0, -2)
var is_picked_up: bool = false

func get_prompt_text() -> String:
	if is_picked_up: return ""
	return "Press [{str}] to Pick Up"

func interact(body: Variant, sender: InteractableTrigger) -> void:
	if is_picked_up: 
		return # Already picked up by someone else!

	# Request the pickup across the network using an RPC
	var object_path = get_parent().get_path()
	rpc("_sync_pickup", body.name, object_path)


@rpc("any_peer", "call_local", "reliable")
func _sync_pickup(body_name: String, _object_path: NodePath) -> void:
	if is_picked_up: 
		return # Prevent double-pickup race conditions
	
	is_picked_up = true
	var interactable_object = get_parent() as InteractableObject
	
	if not interactable_object: 
		return

	# 1. Instantly disable all triggers so no one else can interact with it
	interactable_object.disable_all_triggers()
	
	# 2. Find the interactor body in the scene tree
	var body = interactable_object.get_tree().get_root().find_child(body_name, true, false)
	if body:
		var interactor = body.get_node_or_null("PickupInteractorComponent")
		if interactor and interactor is PickupInteractorComponent:
			interactor.pick_up(interactable_object)
