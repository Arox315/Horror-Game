class_name HealthComponent
extends Node

signal died
signal damaged(amount: int)
signal healed(amount: int)
signal killed
signal revived

## Maximum amount of health the owner can have.
@export var max_health: int = 10: set = _set_max_health
## Amount of health the owner currently have.
@export var current_health: int = 10: set = _set_current_health
## If true [member current_health] cannot be lost from [method damage].
@export var is_invulnerable: bool = false
## If true gain immunity to [method damage] and [method force_kill].
@export var is_god_mode: bool = false


@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	current_health = current_health
	multiplayer_synchronizer.set_visibility_for(0, true)


## Substracts [param amount] from [member current_health]
func damage(amount: int) -> void:
	if is_invulnerable: return
	if is_god_mode: return
	if amount <= 0: return
	current_health -= amount
	ServerRequests.send_emit_signal_global_request(self, damaged, amount)
	print("[%s] Damaged for: %d" % [owner, amount])


## Adds [param amount] to [member current_health]
func heal(amount: int) -> void:
	if amount <= 0: return
	if current_health >= max_health: return
	current_health += amount
	ServerRequests.send_emit_signal_global_request(self, healed, amount)
	print("[%s] Healed for: %d" % [owner, amount])


## Sets [member current_health] to 0
func force_kill() -> void:
	if is_god_mode: return
	current_health = 0
	ServerRequests.send_emit_signal_global_request(self, killed)


## Sets [member current_health] to [member max_health]
func reset_current_health() -> void:
	_set_current_health(max_health)
	ServerRequests.send_emit_signal_global_request(self, revived)


func _set_current_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	if current_health <= 0:
		died.emit()


func _set_max_health(value: int) -> void:
	max_health = maxi(1, value)
