class_name EffectsComponent
extends Node

func _physics_process(_delta: float) -> void:
	if !owner.is_multiplayer_authority(): return
	if Input.is_action_just_pressed("debug_add_effect"):
		const ACCELERATING_MOVE_SPEED = preload("uid://dga6hld40vbyn")
		var effect_to_add = ACCELERATING_MOVE_SPEED.instantiate()
		add_effect(effect_to_add)


func add_effect(effect: Effect) -> void:
	if !owner.is_multiplayer_authority(): return
	#effect.target = owner
	effect.target = get_parent()
	
	for child in get_children():
		if child is not Effect: continue
		if child.is_unique:
			if child.get_script().get_global_name() == effect.get_script().get_global_name():
				child.increment_stack()
				return
	
	add_child(effect)
	#TODO: figure out multiplayer synch
	print("Effect %s added with %d stacks" % [effect.name, effect.current_stacks])
