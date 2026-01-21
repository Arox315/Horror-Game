class_name EffectsComponent
extends Node

@onready var effect_spawner: MultiplayerSpawner = $EffectSpawner

var spawn_table: Dictionary = {}

func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	effect_spawner.spawn_function = Callable(_spawn_effect)
	multiplayer.allow_object_decoding = true
	spawn_table = EffectsTable.TABLE


func add_effect(effect_id: int) -> void:
	if not multiplayer.is_server(): return
	
	for child in get_children():
		if child is not Effect: continue
		if child.is_unique:
			if child.get_meta("id") == effect_id:
				child.add_effect()
				return
	
	effect_spawner.spawn(effect_id)


func remove_effect(effect_id: int, force_remove: bool = false) -> void:
	if not multiplayer.is_server(): return
	
	for child in get_children():
		if child is not Effect: continue
		if child.get_meta("id") == effect_id:
			if force_remove:
				child.remove_effect()
			else:
				child.end_effect()
			return


func _spawn_effect(effect_id: int) -> Effect:
	var effect: Effect = spawn_table[effect_id].instantiate()
	effect.target = owner
	effect.set_meta("id", effect_id)
	
	if multiplayer.is_server():
		print("[%s] Effect %s added with %d stacks" % [effect.target, effect.name, effect.initial_stacks])
	
	return effect
