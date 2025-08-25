class_name InteractRay
extends RayCast3D

var current_interactable: InteractableTrigger = null:
	set(value):
		if current_interactable && current_interactable != value:
			current_interactable.hide_popup()
		current_interactable = value


func _ready() -> void:
	collide_with_areas = false
	collide_with_bodies = true
	set_collision_mask_value(1,true)
	set_collision_mask_value(2,true)


func _physics_process(_delta: float) -> void:
	if !is_colliding():
		hide_previous_popup_on_stop_colliding()
		return
	
	var collider = get_collider()
	
	if collider is not InteractableTrigger:
		hide_previous_popup_on_stop_colliding()
		return
	
	# show the popup only for the player that is looking at the interactable object
	if owner.is_multiplayer_authority():
		collider.show_popup()
	current_interactable = collider
	
	if collider.is_locked:
		return
	
	if Input.is_action_just_pressed(collider.prompt_input):
		collider.interact(owner)


func hide_previous_popup_on_stop_colliding() -> void:
	if current_interactable:
		current_interactable.hide_popup()
		current_interactable = null
