@abstract
class_name Effect
extends Node

signal finished
signal to_be_deleted(effect: Effect)

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

var default_value: float
var target: Node3D
var _is_on_cooldown: bool = false

func _ready() -> void:
	if not target: printerr("No target for effect: ", self)
	current_stacks = current_stacks
	finished.connect(on_finished)
	update_effect()


var _stack_livetime: float = 0.0
func _physics_process(delta: float) -> void:
	if _is_on_cooldown: return
	
	if is_effect_overtime:
		apply_effect(delta)
	
	if is_endless: return
	
	_stack_livetime += delta
	if _stack_livetime >= stack_uptime:
		_stack_livetime = 0.0
		decrement_stack()


@abstract
func update_effect() -> void


@abstract
func apply_effect(delta: float) -> void


func increment_stack(amount: int = 1) -> void:
	if _is_on_cooldown: return
	if not can_increment_while_active: return
	_stack_livetime = 0.0
	current_stacks += amount
	update_effect()
	print("Effect %s incremented to: %d stacks" % [name, current_stacks])


func decrement_stack(amount: int = 1) -> void:
	if _is_on_cooldown: return
	current_stacks -= amount
	update_effect()
	if current_stacks <= 0:
		finished.emit()
		_delete_effect()
	print("Effect %s decremented to: %d stacks" % [name, current_stacks])


func _delete_effect() -> void:
	#if cooldown_after_diminished > 0.0:
	_is_on_cooldown = true
	await get_tree().create_timer(cooldown_after_finished).timeout
	queue_free()
	print("Effect %s ready to be applied again" % name)
	to_be_deleted.emit(self)


@abstract
func on_finished() -> void
