class_name PickupInteractorComponent
extends Node3D

@export var hold_node_path: NodePath
@onready var hold_node: Node3D = get_node_or_null(hold_node_path)

var held_item: InteractableObject = null

func _unhandled_input(event: InputEvent) -> void:
	# Optional: Press a drop key (e.g., "drop") to drop the currently held item
	#if event.is_action_pressed("drop") and held_item:
	#	drop()
	pass

@rpc("any_peer", "call_local", "unreliable")
func pick_up(item: InteractableObject) -> void:
	#if held_item:
	#	drop() # Drop current item before picking up a new one
	
	held_item = item
	
	# Disable the item's interaction triggers so it can't be interacted with while held
	held_item.disable_all_triggers()
	
	# If the item has physics bodies, you may want to disable collision/gravity here:
	# item.set_deferred("freeze", true)
	
	# Reparent the item to the hold node (or player)
	var old_transform = held_item.global_transform
	held_item.get_parent().remove_child(held_item)
	
	if hold_node:
		hold_node.add_child(held_item)
		held_item.transform = Transform3D.IDENTITY # Snap to hold position/rotation
	else:
		add_child(held_item)
		held_item.global_transform = old_transform


@rpc("any_peer", "call_local", "unreliable")
func drop() -> void:
	if not held_item:
		return
	
	var item_to_drop = held_item
	held_item = null
	
	# Remove from player/hold node
	item_to_drop.get_parent().remove_child(item_to_drop)
	
	# Add back to the main scene root (adjust path as needed for your project structure)
	var current_scene = get_tree().current_scene
	current_scene.add_child(item_to_drop)
	
	# Position in front of the player
	item_to_drop.global_transform = global_transform
	item_to_drop.translate_object_local(Vector3(0, 0, -2)) # Drop 2 units in front
	
	# Re-enable physics/gravity if disabled earlier:
	# item_to_drop.set_deferred("freeze", false)
	
	# Re-enable interaction triggers
	item_to_drop.enable_all_triggers()
