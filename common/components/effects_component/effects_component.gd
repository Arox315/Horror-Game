class_name EffectsComponent
extends Node

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
const EFFECT_BANNER = preload("uid://b3xismmir0wg6")

var spawn_table: Dictionary = {}

func _ready() -> void:
	multiplayer_spawner.spawn_function = Callable(_custom_spawn)
	multiplayer.allow_object_decoding = true
	spawn_table = EffectsTable.TABLE

func _physics_process(_delta: float) -> void:
	if !owner.is_multiplayer_authority(): return
	if Input.is_action_just_pressed("debug_add_effect"):
		var effect_to_add = EffectsTable.Effects.ACCELERATING_MOVE_SPEED
		add_effect.rpc(effect_to_add)


@rpc("reliable","any_peer","call_local")
func add_effect(effect_id: int) -> void:
	if !owner.is_multiplayer_authority(): return
	
	for child in get_children():
		if child is not Effect: continue
		if child.is_unique:
			if child.get_meta("id") == effect_id:
				child.increment_stack.rpc()
				return
	
	multiplayer_spawner.spawn(effect_id)


@rpc("reliable","any_peer","call_local")
func remove_custom(effect: Effect) -> void:
	if !owner.is_multiplayer_authority(): return
	effect.queue_free()


func _custom_spawn(effect_id: int) -> Effect:
	var effect: Effect = spawn_table[effect_id].instantiate()
	effect.target = owner
	effect.set_meta("id", effect_id)
	if owner.is_multiplayer_authority():
		print("Effect %s added with %d stacks" % [effect.name, effect.current_stacks])
	effect.to_be_deleted.connect(remove_custom)
	
	if owner is CharacterBody3D and owner.is_multiplayer_authority():
		var effect_banner: EffectBanner = EFFECT_BANNER.instantiate()
		effect_banner.active_color = effect.active_color
		effect_banner.diminished_color = effect.diminished_color
		effect_banner.stacks = str(effect.current_stacks)
		effect_banner.lifetime = effect.stack_uptime
		effect_banner.is_endless = effect.is_endless
		effect.stack_gained.connect(effect_banner.update_display)
		effect.stack_lost.connect(effect_banner.update_display)
		effect.finished.connect(effect_banner.delete)
		owner.effects.add_child(effect_banner)
	
	return effect
