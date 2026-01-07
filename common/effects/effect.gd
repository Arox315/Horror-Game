@abstract
class_name Effect
extends Node

signal finished
signal deleted
signal stack_gained(stacks: int)
signal stack_lost(stacks: int)

##Max amount of stacks for the effect.
@export var max_stacks: int = 1
##Current amount of stacks of the effect. Effect will start with this amount.
@export var current_stacks: int = 1:
	set(value):
		current_stacks = clamp(value, 0, max_stacks)
##How long each stack lasts.
@export var stack_uptime: float = 5.0
##If effect is not unique gaining it again while active will not increase a stack but create another instance of the effect.
@export var is_unique: bool = true
##If effect is endless, stack uptime is ignored.
@export var is_endless: bool = false
##If true, the effect finishes if stack uptime reaches 0. Otherwise stacks diminish one by one.
@export var is_diminishing_all_stacks: bool = false
##If true, the effect can execute every physics frame.
@export var is_effect_overtime: bool = false
##If true, new stacks can be gained or on max stacks their uptime can be reset. Otherwise no new stacks can be gained.
@export var can_increment_while_active: bool = true
##Deley between effect execution if it is an overtime effect.
@export var overtime_interval: float = 1.0
##Value of an effect each stack gives.
@export var amount_per_stack: float = 1.0
##Delay between gaining the effect again after it has finished.
@export var cooldown_after_finished: float = 0.0
##Whether the effect has a display banner on Player's UI
@export var has_icon: bool = true
##Icon for the effect
@export var effect_icon: Texture2D

const EFFECT_BANNER = preload("uid://b3xismmir0wg6")

var default_value: float
var target: Node3D
var _is_on_cooldown: bool = false


func _enter_tree() -> void:
	var sync := MultiplayerSynchronizer.new()
	var config := SceneReplicationConfig.new()
	config.add_property(^":current_stacks")
	config.add_property(^":_stack_livetime")
	sync.name = "EffectSync"
	sync.replication_config = config
	add_child(sync)


func _ready() -> void:
	if not target: printerr("No target for effect: ", self)
	current_stacks = current_stacks # makes sure the setter corrects invalid values
	finished.connect(on_finished)
	deleted.connect(on_deleted)
	update_effect()
	_setup_banner()


var _stack_livetime: float = 0.0
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	if _is_on_cooldown: return
	
	if is_effect_overtime:
		apply_effect(delta)
	
	if is_endless: return
	
	_stack_livetime += delta
	if _stack_livetime >= stack_uptime:
		_stack_livetime = 0.0
		decrement_stack()
	
	if current_stacks <= 0:
		delete_effect()


func increment_stack(amount: int = 1) -> void:
	if _is_on_cooldown: return
	if not can_increment_while_active: return
	
	_stack_livetime = 0.0
	current_stacks += amount
	update_effect()
	
	_emit_stack_gained_global.rpc(current_stacks)
	
	print("[%s] Effect %s incremented to: %d stacks" % [target, name, current_stacks])


func decrement_stack(amount: int = 1) -> void:
	if _is_on_cooldown: return
	current_stacks -= amount
	update_effect()
	
	_emit_stack_lost_global.rpc(current_stacks)
	
	print("[%s] Effect %s decremented to: %d stacks" % [target, name, current_stacks])


@rpc("reliable","any_peer","call_local")
func _emit_finished_global() -> void:
	finished.emit()


@rpc("reliable","any_peer","call_local")
func _emit_deleted_global() -> void:
	deleted.emit()


@rpc("reliable","any_peer","call_local")
func _emit_stack_gained_global(stacks: int) -> void:
	stack_gained.emit(stacks)


@rpc("reliable","any_peer","call_local")
func _emit_stack_lost_global(stacks: int) -> void:
	stack_lost.emit(stacks)


func delete_effect() -> void:
	_emit_finished_global.rpc()
	
	_is_on_cooldown = true
	await get_tree().create_timer(cooldown_after_finished).timeout
	
	print("[%s] Effect %s ready to be applied again" % [target, name])
	
	queue_free()
	_emit_deleted_global.rpc()


func _setup_banner() -> void:
	if not has_icon: return
	if not get_parent().owner.is_in_group("Players"): return
	if target.get_multiplayer_authority() != multiplayer.get_unique_id(): return
	
	var effect_banner: EffectBanner = EFFECT_BANNER.instantiate()
	effect_banner.effect_icon = effect_icon
	effect_banner.stacks = str(current_stacks)
	effect_banner.max_stacks = max_stacks
	effect_banner.lifetime = stack_uptime
	effect_banner.is_endless = is_endless
	stack_gained.connect(effect_banner.update_display)
	stack_lost.connect(effect_banner.update_display)
	finished.connect(effect_banner.delete)
	target.effects.add_child(effect_banner)


@abstract
func update_effect() -> void


@abstract
func apply_effect(delta: float) -> void


@abstract
func on_finished() -> void


@abstract
func on_deleted() -> void
