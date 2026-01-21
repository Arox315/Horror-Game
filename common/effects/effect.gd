@abstract
class_name Effect
extends Node

signal finished
signal deleted
signal stack_gained(stacks: int)
signal stack_lost(stacks: int)
signal locked(value: bool)
signal locked_reversed(value: bool)


@export_group("Stacks")
## Maximum number of stacks this effect can have.
@export_range(1, 10, 1, "or_greater") var max_stacks: int = 1
## Stacks the effect starts with when applied.
@export_range(0, 10, 1, "or_greater") var initial_stacks: int = 1:
	set(value): initial_stacks = clampi(value, 0, max_stacks)
## Duration (in seconds) of a single stack before it expires.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var stack_duration: float = 5.0
## If true, only one instance of this effect may be active on a target at a time.
## Reapplying will modify stacks/refresh rather than create a new instance.
@export var is_unique: bool = true
## If true, stacks do not expire over time.
@export var is_endless: bool = false
## If true, when the timer reaches 0 the entire effect ends immediately.
## If false, stacks expire one-by-one (each expiration removes a stack).
@export var expire_all_at_once: bool = false
## If true, the effect is not lost on reaching 0 stacks. Instead it goes on cooldown specified by 
## [member reapply_cooldown] after which new stacks can be gained again.
@export var is_permanent: bool = false

@export_group("Stack Rate Limits")
## Maximum stacks that can be lost within a given time window.
@export_range(1, 10, 1, "or_greater") var max_stack_loss_per_window: int = 1
## Time window (in seconds) used for max stack loss limiting.
## If 0, there is no loss rate limit.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var stack_loss_window: float = 0.0
## Maximum stacks that can be gained within a given time window.
@export_range(1, 10, 1, "or_greater") var max_stack_gain_per_window: int = 1
## Time window (in seconds) used for max stack gain limiting.
## If 0, there is no gain rate limit.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var stack_gain_window: float = 0.0
## Delay (in seconds) before stacks are allowed to start incrementing again after a stack loss.
## If 0, there is no delay.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var gain_delay_after_loss: float = 0.0
## Delay (in seconds) before stacks are allowed to start decrementing again after a stack gain.
## If 0, there is no delay.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var loss_delay_after_gain: float = 0.0

@export_group("Ticking")
## If true, the effect "ticks" repeatedly every physics frame while active (e.g. damage/heal over time).
@export var is_ticking: bool = false
## Time between ticks (in seconds) when [member is_ticking] is true.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var tick_interval: float = 1.0

@export_group("Stacking Rules")
## If true, stacks can be gained while the effect is already active (and/or duration can be refreshed at max stacks).
@export var can_gain_while_active: bool = true
## If true, the effect can gain stacks when reapplied from the original source
## ([method EffectsComponent.add_effect]) while already active.
@export var can_gain_from_source_reapply: bool = true
## If true, the effect gains stacks over time instead of losing them.
@export var is_reversed: bool = false
## If true and [member is_reversed] is true, the effect gains stacks every [member stack_duration].
@export var regenerates_stacks: bool = false

@export_group("Presentation and Tuning")
## Amount/value contributed per stack (depends on the concrete effect).
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var amount_per_stack: float = 1.0
## Delay (in seconds) after the effect ends before it can be applied again.
@export_range(0.0, 10.0, 0.0001, "or_greater", "hide_slider") var reapply_cooldown: float = 0.0
## Whether the effect should be shown in the player's UI.
@export var show_icon: bool = true
## Icon displayed for the effect in UI (if enabled).
@export var icon: Texture2D


const EFFECT_BANNER = preload("uid://b3xismmir0wg6")

var current_stacks: int = 1:
	set(value): current_stacks = clampi(value, 0, max_stacks)

var default_value: float
var target: Node3D
var _is_on_cooldown: bool = false
var _cooldown_timer: Timer = Timer.new()

var _recent_stacks_lost_count: int = 0: 
	set(value): _recent_stacks_lost_count= clampi(value, 0, max_stack_loss_per_window)
var _recent_stacks_gained_count: int = 0:
	set(value): _recent_stacks_gained_count = clampi(value, 0, max_stack_gain_per_window)

var _is_increment_locked: bool = false
var _is_decrement_locked: bool = false

var _increment_timer: Timer = Timer.new()
var _decrement_timer: Timer = Timer.new()


func _enter_tree() -> void:
	var sync := MultiplayerSynchronizer.new()
	var config := SceneReplicationConfig.new()
	config.add_property(^":max_stacks")
	config.add_property(^":current_stacks")
	config.add_property(^":_stack_livetime")
	sync.name = "EffectSync"
	sync.replication_config = config
	add_child(sync)

	_increment_timer.autostart = false
	_increment_timer.one_shot = true
	_increment_timer.name = "IncrementTimer"
	_increment_timer.timeout.connect(set_increment_lock.bind(false))
	
	_decrement_timer.autostart = false
	_decrement_timer.one_shot = true
	_decrement_timer.name = "DecrementTimer"
	_decrement_timer.timeout.connect(set_decrement_lock.bind(false))
	
	add_child(_increment_timer)
	add_child(_decrement_timer)
	
	_cooldown_timer.autostart = false
	_cooldown_timer.one_shot = true
	_cooldown_timer.name = "CooldownTimer"
	_cooldown_timer.timeout.connect(set_off_cooldown)
	
	add_child(_cooldown_timer)


func _ready() -> void:
	if not target: printerr("No target for effect: ", self)
	
	initial_stacks = initial_stacks # makes sure the setter corrects invalid values
	current_stacks = initial_stacks
	
	finished.connect(on_finished)
	deleted.connect(on_deleted)
	
	if not icon and show_icon:
		icon = PlaceholderTexture2D.new()
	
	update_effect()
	_setup_banner()
	_handle_stack_gain_limit(current_stacks)


var _stack_livetime: float = 0.0
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	
	if _is_on_cooldown: return
	
	if is_ticking:
		apply_effect(delta)
	
	if is_reversed:
		_process_reversed(delta)
	else:
		_process_regular(delta)


func _process_regular(delta: float) -> void:
	if is_endless: return
	if _is_decrement_locked: return
	if _is_increment_locked: return
	
	_stack_livetime += delta
	if _stack_livetime >= stack_duration:
		decrement_stack()
	
	if current_stacks <= 0:
		if is_permanent: 
			toggle_cooldown()
		else:
			print("[%s] Effect %s has finished" % [target, name])
			_delete_effect()


func _process_reversed(delta: float) -> void:
	if not regenerates_stacks: return
	if current_stacks == max_stacks: return
	if _is_decrement_locked: return
	if _is_increment_locked: return
	
	
	_stack_livetime += delta
	if _stack_livetime >= stack_duration:
		increment_stack()


func increment_stack(amount: int = 1) -> void:
	if not can_gain_while_active: return
	if _is_increment_locked: return
	
	if _recent_stacks_gained_count >= max_stack_gain_per_window: return 
	_handle_stack_gain_limit(amount)
	
	_stack_livetime = 0.0
	current_stacks += amount
	update_effect()
	
	ServerRequests.send_emit_signal_global_request(self, stack_gained, current_stacks)
	
	print("[%s] Effect %s incremented to: %d stacks" % [target, name, current_stacks])
	if loss_delay_after_gain > 0.0:
		set_decrement_lock(true)
		_decrement_timer.start(loss_delay_after_gain)


func decrement_stack(amount: int = 1) -> void:
	if _is_decrement_locked: return
	if _decrement_timer.time_left != 0.0: return
	
	if _recent_stacks_lost_count >= max_stack_loss_per_window: return
	_handle_stack_loss_limit(amount)
	
	_stack_livetime = 0.0
	current_stacks -= amount
	update_effect()
	
	ServerRequests.send_emit_signal_global_request(self, stack_lost, current_stacks)
	
	print("[%s] Effect %s decremented to: %d stacks" % [target, name, current_stacks])
	if gain_delay_after_loss > 0.0:
		set_increment_lock(true)
		_increment_timer.start(gain_delay_after_loss)


func end_effect() -> void:
	if is_permanent:
		decrement_stack()
	else:
		print("[%s] Effect %s has been removed" % [target, name])
		_delete_effect()


func add_effect(stack_amount: int = 1) -> void:
	if _is_on_cooldown: return
	if not can_gain_from_source_reapply: return
	increment_stack(stack_amount)


func set_increment_lock(value: bool) -> void:
	ServerRequests.send_emit_signal_global_request(self, locked_reversed, value)
	_is_increment_locked = value


func set_decrement_lock(value: bool) -> void:
	ServerRequests.send_emit_signal_global_request(self, locked, value)
	_is_decrement_locked = value


func set_on_cooldown() -> void:
	_is_on_cooldown = true


func set_off_cooldown() -> void:
	_is_on_cooldown = false
	if is_permanent: increment_stack()


func toggle_cooldown() -> void:
	set_on_cooldown()
	_cooldown_timer.start(reapply_cooldown)


func _delete_effect() -> void:
	ServerRequests.send_emit_signal_global_request(self, finished)
	
	_is_on_cooldown = true
	await get_tree().create_timer(reapply_cooldown).timeout
	
	print("[%s] Effect %s ready to be applied again" % [target, name])
	
	queue_free()
	ServerRequests.send_emit_signal_global_request(self, deleted)


func _setup_banner() -> void:
	if not show_icon: return
	if not get_parent().owner.is_in_group("Players"): return
	if target.get_multiplayer_authority() != multiplayer.get_unique_id(): return
	
	var effect_banner: EffectBanner = EFFECT_BANNER.instantiate()
	effect_banner.effect_icon = icon
	effect_banner.current_stacks = current_stacks
	effect_banner.max_stacks = max_stacks
	effect_banner.stack_duration = stack_duration
	effect_banner.is_endless = is_endless
	effect_banner.is_reversed = is_reversed
	effect_banner.regenerates_stacks = regenerates_stacks
	effect_banner.is_permanent = is_permanent
	stack_gained.connect(effect_banner.update_display)
	stack_lost.connect(effect_banner.update_display)
	finished.connect(effect_banner.delete)
	locked.connect(effect_banner.set_is_update_locked)
	locked_reversed.connect(effect_banner.set_is_update_reversed_locked)
	target.effects.add_child(effect_banner)


func _add_recent_stacks_lost(amount: int) -> void:
	_recent_stacks_lost_count += amount


func _remove_recent_stacks_lost(amount: int) -> void:
	_recent_stacks_lost_count -= amount


func _handle_stack_loss_limit(amount: int = 1) -> void:
	if stack_loss_window <= 0.0: return
	
	_add_recent_stacks_lost(amount)
	await get_tree().create_timer(stack_loss_window).timeout
	_remove_recent_stacks_lost(amount)


func _add_recent_stacks_gained(amount: int) -> void:
	_recent_stacks_gained_count += amount


func _remove_recent_stacks_gained(amount: int) -> void:
	_recent_stacks_gained_count -= amount


func _handle_stack_gain_limit(amount: int = 1) -> void:
	if stack_gain_window <= 0.0: return
	
	_add_recent_stacks_gained(amount)
	await get_tree().create_timer(stack_gain_window).timeout
	_remove_recent_stacks_gained(amount)


@abstract
func update_effect() -> void


@abstract
func apply_effect(delta: float) -> void


@abstract
func on_finished() -> void


@abstract
func on_deleted() -> void
